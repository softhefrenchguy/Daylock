import 'package:daylock/models/daily_plan.dart';
import 'package:daylock/models/freedom_settings.dart';
import 'package:daylock/models/task.dart';
import 'package:daylock/services/freedom_service.dart';
import 'package:daylock/services/instagram_detection_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final date = DateTime(2026, 10, 13, 18);
NativeFreedomInput input({
  List<Task>? tasks,
  bool committed = true,
  DateTime? now,
}) {
  final plan = DailyPlan(
    date: date,
    tasks:
        tasks ??
        [
          Task(
            name: 'Private goal name',
            type: TaskType.goal,
            isCompleted: true,
          ),
        ],
  );
  final tomorrow = DailyPlan(
    date: DateTime(2026, 10, 14),
    tasks: [],
    isCommitted: committed,
  );
  return NativeFreedomInput.fromEligibility(
    plan,
    const FreedomService().evaluate(
      now: now ?? date,
      settings: const FreedomSettings(enabled: true),
      todayPlan: plan,
      tomorrowPlan: tomorrow,
    ),
    tomorrowPlan: tomorrow,
  );
}

Map<String, Object?> statusMap({
  bool enabled = true,
  bool connected = true,
  String freedom = 'earned',
  int? latest,
}) => {
  'supported': true,
  'enabled': enabled,
  'connected': connected,
  'detectionSaveFailed': false,
  'freedom': {
    'state': freedom,
    'reason': freedom == 'unknown' ? 'expired' : 'conditions_satisfied',
  },
  'lastDetection': latest == null
      ? null
      : {
          'detectedAtMs': latest,
          'freedomState': 'earned',
          'freedomReason': 'conditions_satisfied',
        },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('test/daylock_detection');
  const eventControl = MethodChannel('test/daylock_detection/events');
  const events = EventChannel('test/daylock_detection/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return statusMap(
        freedom: call.method == 'invalidateSnapshot' ? 'unknown' : 'earned',
      );
    });
    messenger.setMockMethodCallHandler(eventControl, (_) async => null);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(eventControl, null);
  });
  InstagramDetectionBridge bridge() =>
      InstagramDetectionBridge(methods: methods, events: events, android: true);

  test(
    'Freedom input excludes excuses, names, reasons and all unrelated app data',
    () {
      final value = input(
        tasks: [
          Task(
            name: 'Sensitive completed',
            type: TaskType.goal,
            isCompleted: true,
          ),
          Task(
            name: 'Sensitive excuse',
            type: TaskType.goal,
            outcome: TaskOutcome.excused,
            excuseReason: 'Private reason',
          ),
        ],
      ).values;
      expect(value['eligibleCount'], 1);
      expect(value['completedCount'], 1);
      expect(value['tomorrowCommitted'], isTrue);
      expect(value.keys.toSet(), {
        'date',
        'enabled',
        'hour',
        'minute',
        'timeReached',
        'eligibleCount',
        'completedCount',
        'tomorrowCommitted',
        'runningFocus',
        'tomorrowPlan',
      });
      expect(value.toString(), isNot(contains('Sensitive')));
      expect(() => value.clear(), throwsUnsupportedError);
    },
  );
  test('Empty/all-excused plans send zero eligible rather than claiming completion', () {
    for (final tasks in [
      <Task>[],
      [
        Task(
          name: 'Unavailable',
          type: TaskType.goal,
          outcome: TaskOutcome.excused,
          excuseReason: 'Impossible',
        ),
      ],
    ]) {
      expect(input(tasks: tasks).values['eligibleCount'], 0);
      expect(input(tasks: tasks).values['completedCount'], 0);
    }
  });
  test('Active Focus is marked for conservative native reconciliation', () {
    final focus = Task(
      name: 'Read',
      type: TaskType.focus,
      minimumFocusMinutes: 20,
    )..startFocus(date);
    expect(input(tasks: [focus]).values['runningFocus'], isTrue);
    expect(
      input(tasks: [focus]).values['focusCompletesAtMs'],
      date.add(const Duration(minutes: 20)).millisecondsSinceEpoch,
    );
    focus.changeOutcome(
      TaskOutcome.excused,
      now: date.add(const Duration(minutes: 2)),
      reason: 'No electricity',
    );
    expect(input(tasks: [focus]).values['runningFocus'], isFalse);
    expect(focus.accumulatedFocusMilliseconds, 120000);
  });
  test(
    'Startup invalidates previous cache and starts status reporting',
    () async {
      final service = bridge();
      await service.start();
      expect(calls.single.method, 'invalidateSnapshot');
      expect(service.status.value.supported, isTrue);
      expect(service.status.value.enabled, isTrue);
      expect(service.status.value.freedomState, 'unknown');
      await service.close();
    },
  );
  test('Unchanged durable inputs are deduplicated; updates and lifecycle force synchronise', () async {
    final service = bridge();
    await service.start();
    await service.publishSnapshot(input());
    await service.publishSnapshot(input());
    expect(
      calls.where((call) => call.method == 'publishSnapshot'),
      hasLength(1),
    );
    final payload = calls.last.arguments as Map;
    expect(payload['expectedRevision'], 0);
    expect(payload.containsKey('sourceWallMs'), isFalse);
    await service.publishSnapshot(input(committed: false));
    await service.publishSnapshot(input(committed: false), force: true);
    expect(
      calls.where((call) => call.method == 'publishSnapshot'),
      hasLength(3),
    );
    // The native Settings status refreshes immediately across Freedom Time,
    // even though counts/settings themselves have not changed.
    await service.publishSnapshot(
      input(committed: false, now: DateTime(2026, 10, 13, 17, 59)),
    );
    await service.publishSnapshot(input(committed: false, now: date));
    expect(
      calls.where((call) => call.method == 'publishSnapshot'),
      hasLength(5),
    );
    await service.close();
  });
  test(
    'Invalidation clears deduplication and channel operations stay ordered',
    () async {
      final service = bridge();
      await service.start();
      final publish = service.publishSnapshot(input());
      final invalidate = service.invalidateSnapshot();
      final changed = service.publishSnapshot(input());
      await Future.wait([publish, invalidate, changed]);
      expect(calls.map((call) => call.method), [
        'invalidateSnapshot',
        'publishSnapshot',
        'invalidateSnapshot',
        'publishSnapshot',
      ]);
      await service.close();
    },
  );
  test('Live events deliver latest detection, permission revocation and unknown state', () async {
    final service = bridge();
    await service.start();
    await Future<void>.delayed(Duration.zero);
    final stamp = date.millisecondsSinceEpoch;
    await messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope(
        statusMap(latest: stamp),
      ),
      (_) {},
    );
    expect(service.status.value.lastDetectedAt, date);
    expect(service.status.value.freedomAtDetection, 'earned');
    await messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope(
        statusMap(
          enabled: false,
          connected: true,
          freedom: 'unknown',
          latest: stamp,
        ),
      ),
      (_) {},
    );
    expect(service.status.value.enabled, isFalse);
    expect(service.status.value.connected, isFalse);
    expect(service.status.value.freedomState, 'unknown');
    expect(
      service.status.value.freedomAtDetection,
      'earned',
    ); // Historical, not current.
    await service.close();
  });
  test(
    'Channel failures never report enabled/earned and can be retried',
    () async {
      final service = bridge();
      await service.start();
      messenger.setMockMethodCallHandler(
        methods,
        (_) async => throw PlatformException(code: 'FAILED'),
      );
      await service.refresh();
      expect(service.status.value.enabled, isFalse);
      expect(service.status.value.connected, isFalse);
      expect(service.status.value.freedomState, 'unknown');
      expect(service.status.value.error, isNotNull);
      messenger.setMockMethodCallHandler(
        methods,
        (_) async => statusMap(enabled: false, connected: false),
      );
      await service.refresh();
      expect(service.status.value.error, isNull);
      await service.close();
    },
  );
  test(
    'Missing native plugin or non-Android platform is safely unsupported',
    () async {
      messenger.setMockMethodCallHandler(methods, null);
      for (final android in [true, false]) {
        final service = InstagramDetectionBridge(
          methods: methods,
          events: events,
          android: android,
        );
        await service.start();
        await service.publishSnapshot(input());
        expect(service.status.value.supported, isFalse);
        expect(service.status.value.enabled, isFalse);
        await service.close();
      }
    },
  );
  test(
    'Closing bridge prevents later publications or status updates',
    () async {
      final service = bridge();
      await service.start();
      await service.close();
      final count = calls.length;
      await service.publishSnapshot(input(), force: true);
      await service.refresh();
      expect(calls, hasLength(count));
    },
  );
  test('Publications use acknowledged revisions; older stream events cannot replace newer state', () async {
    var revision = 0;
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      if (call.method == 'publishSnapshot') {
        expect((call.arguments as Map)['expectedRevision'], revision);
      }
      if ([
        'invalidateSnapshot',
        'publishSnapshot',
        'setBlockingEnabled',
      ].contains(call.method)) {
        revision++;
      }
      return {...statusMap(), 'revision': revision};
    });
    final service = bridge();
    await service.start();
    await Future<void>.delayed(Duration.zero);
    await service.publishSnapshot(input());
    await service.invalidateSnapshot();
    await service.setBlockingEnabled(false);
    await service.publishSnapshot(input());
    expect(service.status.value.revision, 5);
    await messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope({
        ...statusMap(freedom: 'unknown'),
        'revision': 2,
      }),
      (_) {},
    );
    expect(service.status.value.revision, 5);
    expect(service.status.value.freedomState, 'earned');
    await service.close();
  });
  test(
    'Failed publication can retry immediately with identical durable inputs',
    () async {
      final service = bridge();
      await service.start();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        throw PlatformException(code: 'DISK_FAILED');
      });
      await service.publishSnapshot(input());
      expect(service.status.value.error, isNotNull);
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        return {...statusMap(), 'revision': 3};
      });
      await service.refresh();
      await service.publishSnapshot(input());
      expect(
        calls.where((call) => call.method == 'publishSnapshot'),
        hasLength(2),
      );
      expect((calls.last.arguments as Map)['expectedRevision'], 3);
      await service.close();
    },
  );
}
