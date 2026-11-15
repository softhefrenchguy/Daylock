import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/daylock_scene.dart';
import '../design/daylock_theme.dart';

/// One stop on the guided tour: which tab to show, what to spotlight there
/// (the first key found wins), and what to say about it.
class TourStop {
  final int page;
  final List<Key> targets;
  final String title, body;
  const TourStop({
    required this.page,
    required this.targets,
    required this.title,
    required this.body,
  });
}

/// The walk through the real app. Pages: 0 Today, 1 Plan, 2 Journey.
const daylockTour = [
  TourStop(
    page: 0,
    targets: [ValueKey('today-sky')],
    title: 'This is your day',
    body: 'The sun climbs as you keep today’s commitments. Keep them all and it’s fully risen.',
  ),
  TourStop(
    page: 0,
    targets: [ValueKey('today-commitments'), ValueKey('today-empty')],
    title: 'Today’s commitments',
    body: 'Tap the circle to keep one. Tap the row to run a stopwatch, or excuse it with a reason if something really came up.',
  ),
  TourStop(
    page: 0,
    targets: [ValueKey('freedom-indicator')],
    title: 'Freedom',
    body: 'Apps you restrict open at Freedom Time, once today is kept and tomorrow is locked in. Tap here any time to see what’s left.',
  ),
  TourStop(
    page: 1,
    targets: [ValueKey('plan-sky')],
    title: 'Plan tomorrow',
    body: 'Each evening, plan tomorrow while today is still fresh. Pick a few things you’ll really do.',
  ),
  TourStop(
    page: 1,
    targets: [ValueKey('open-commitment-editor')],
    title: 'Add and repeat',
    body: 'Add a commitment and give it an Area. Turn on Repeat for habits, and they fill themselves in on their days.',
  ),
  TourStop(
    page: 1,
    targets: [ValueKey('plan-commit-bar')],
    title: 'Lock it in',
    body: 'When tomorrow looks right, lock it in. After that it can’t change. That’s what makes it a commitment.',
  ),
  TourStop(
    page: 2,
    targets: [ValueKey('journey-streak'), ValueKey('journey-content')],
    title: 'Your Journey',
    body: 'Every kept day counts here: your streak, the effort you put in, and the achievements you’re proud of.',
  ),
  TourStop(
    page: 2,
    targets: [ValueKey('journey-manage-areas')],
    title: 'Areas',
    body: 'Each Area tracks one part of your life, like Body, Mind or Career. Add, rename or archive them here. Further down, open one to see its history.',
  ),
  TourStop(
    page: 0,
    targets: [ValueKey('open-settings')],
    title: 'Settings',
    body: 'Freedom Time, app blocking, routines, reminders and colours live here. You can replay this tour from Settings too.',
  ),
];

/// Dims the app, cuts a spotlight around the current stop's target, and
/// shows a speech bubble with Back / Next / Skip. Nothing behind it can be
/// tapped, so the tour never makes anyone do anything.
///
/// Moving between stops is choreographed so nothing jumps: the bubble fades
/// out and the spotlight closes, the tab changes ([onShowPage]) and the target
/// scrolls into view, then the spotlight opens on it and the bubble eases in.
class AppTourOverlay extends StatefulWidget {
  final int index;
  final List<TourStop> stops;

  /// Where to look for targets (the app's navigator).
  final BuildContext? Function() searchRoot;

  /// Shows a tab (0 Today, 1 Plan, 2 Journey) at the right moment.
  final ValueChanged<int> onShowPage;
  final VoidCallback onNext, onBack, onClose;
  const AppTourOverlay({
    super.key,
    required this.index,
    required this.searchRoot,
    required this.onShowPage,
    required this.onNext,
    required this.onBack,
    required this.onClose,
    this.stops = daylockTour,
  });

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 180);
  static const _travel = Duration(milliseconds: 380);
  static const _enter = Duration(milliseconds: 260);

  /// The stop whose text is showing. It changes only while the bubble is
  /// hidden, so words never swap in front of the reader.
  late int _shown;
  bool _bubbleVisible = false, _settled = false, _entered = false;
  bool _leaving = false;
  int _generation = 0;

  /// Where the spotlight is going; null means no target (full dim).
  Rect? _target;
  late final AnimationController _hole = AnimationController(
    vsync: this,
    duration: _travel,
  );
  Rect _holeFrom = Rect.zero, _holeTo = Rect.zero;

  /// The bubble's laid-out height from the last frame, for placing it.
  final _bubbleKey = GlobalKey();
  double _bubbleHeight = 240;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);
  Duration _d(Duration value) => _reduce ? Duration.zero : value;
  TourStop get _stop => widget.stops[_shown];
  Size get _size =>
      (context.findRenderObject() as RenderBox?)?.size ??
      MediaQuery.sizeOf(context);

  Rect get _holeNow =>
      Rect.lerp(
        _holeFrom,
        _holeTo,
        Curves.easeInOutCubic.transform(_hole.value),
      ) ??
      _holeTo;

  /// A spotlight shrunk to nothing at [rect]'s centre (or mid-screen).
  Rect _closed(Rect? rect) => Rect.fromCenter(
    center: rect?.center ?? _size.center(Offset.zero),
    width: 0,
    height: 0,
  );

  void _moveHole(Rect to, {Rect? from}) {
    _holeFrom = from ?? _holeNow;
    _holeTo = to;
    if (_reduce) {
      _hole.value = 1;
    } else {
      _hole.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _shown = widget.index;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _holeFrom = _holeTo = _closed(null);
      setState(() => _entered = true);
      unawaited(_transition(first: true));
    });
  }

  @override
  void didUpdateWidget(covariant AppTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      unawaited(_transition());
    } else if (_settled) {
      // The app rebuilds (clock ticks, saves); keep the spotlight on target.
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  @override
  void didChangeMetrics() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());

  @override
  void dispose() {
    _generation++;
    _hole.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _wait(Duration duration) =>
      duration == Duration.zero ? Future.value() : Future.delayed(duration);

  Future<void> _transition({bool first = false}) async {
    final generation = ++_generation;
    bool stale() => !mounted || generation != _generation;
    final next = widget.index;
    final pageChanges = widget.stops[next].page != _stop.page;
    if (!first) {
      _settled = false;
      // 1. Bubble out; on a tab change the spotlight closes where it is.
      setState(() => _bubbleVisible = false);
      if (pageChanges) _moveHole(_closed(_target));
      await _wait(_d(pageChanges ? _travel * .6 : _fade));
      if (stale()) return;
    }
    // 2. New words (still hidden), the right tab, the target in view.
    setState(() => _shown = next);
    widget.onShowPage(_stop.page);
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (stale()) return;
    final element = _find();
    // Scroll only when the target isn't already comfortably on screen.
    if (element != null && element.mounted && !_comfortablyVisible()) {
      await Scrollable.ensureVisible(
        element,
        alignment: 0.2,
        duration: _d(const Duration(milliseconds: 320)),
        curve: Curves.easeInOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    if (stale()) return;
    // 3. Spotlight opens on the target: grows in place after a tab change,
    // glides across on the same tab.
    final target = _measure();
    setState(() => _target = target);
    _moveHole(
      target ?? _closed(null),
      from: first || pageChanges ? _closed(target) : null,
    );
    await WidgetsBinding.instance.endOfFrame;
    _measureBubble();
    await _wait(_d(_travel * .45));
    if (stale()) return;
    // 4. Bubble in.
    _settled = true;
    setState(() => _bubbleVisible = true);
  }

  bool _comfortablyVisible() {
    final rect = _rawRect();
    if (rect == null) return false;
    final padding = MediaQuery.paddingOf(context);
    // Fully on screen (the bottom bar is laid out below the page, so anything
    // visible is above it). Scrolling then would only add a pause.
    return rect.top >= padding.top &&
        rect.bottom <= _size.height - padding.bottom;
  }

  /// Keeps the spotlight on its target when the app below re-lays out.
  void _follow() {
    if (!mounted || !_settled) return;
    final target = _measure();
    if (target == _target) return;
    setState(() => _target = target);
    _moveHole(target ?? _closed(null));
  }

  Future<void> _leave(VoidCallback done) async {
    if (_leaving) return;
    _generation++;
    setState(() {
      _leaving = true;
      _bubbleVisible = false;
    });
    await _wait(_d(_enter));
    done();
  }

  Element? _find() {
    final root = widget.searchRoot();
    if (root == null || !root.mounted) return null;
    for (final key in _stop.targets) {
      Element? found;
      void visit(Element element) {
        if (found != null) return;
        if (element.widget.key == key) {
          found = element;
          return;
        }
        element.visitChildren(visit);
      }

      (root as Element).visitChildren(visit);
      if (found != null) return found;
    }
    return null;
  }

  /// The target's bounds in overlay coordinates, unclipped.
  Rect? _rawRect() {
    final element = _find();
    final overlay = context.findRenderObject() as RenderBox?;
    final box = element?.findRenderObject();
    if (overlay == null ||
        !overlay.hasSize ||
        box is! RenderBox ||
        !box.attached ||
        !box.hasSize) {
      return null;
    }
    return overlay.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
  }

  /// The spotlight: the target plus a margin, kept on screen.
  Rect? _measure() {
    final raw = _rawRect();
    if (raw == null) return null;
    final screen = Offset.zero & _size;
    final rect = raw.inflate(8).intersect(screen.deflate(4));
    return rect.width <= 0 || rect.height <= 0 ? null : rect;
  }

  void _measureBubble() {
    if (!mounted) return;
    final box = _bubbleKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final h = box.size.height;
      if ((h - _bubbleHeight).abs() > 1) setState(() => _bubbleHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBubble());
    return AnimatedOpacity(
      opacity: _entered && !_leaving ? 1 : 0,
      duration: _d(_enter),
      curve: Curves.easeOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final padding = MediaQuery.paddingOf(context);
          return Stack(
            children: [
              // Swallow every touch outside the bubble.
              Positioned.fill(
                child: BlockSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: AnimatedBuilder(
                      animation: _hole,
                      builder: (context, _) => CustomPaint(
                        size: size,
                        painter: _SpotlightPainter(
                          hole: _holeNow,
                          scrim: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? .72
                                : .6,
                          ),
                          ring: daylockGold(theme.brightness),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _bubble(size, padding),
            ],
          );
        },
      ),
    );
  }

  Widget _bubble(Size size, EdgeInsets padding) {
    final width = math.min(size.width - 32, 380.0);
    final hole = _target;
    final height = _bubbleHeight;
    const gap = 12.0;
    final minTop = padding.top + 8;
    final maxBottom = size.height - padding.bottom - 8;
    double left = (size.width - width) / 2;
    // Default: pinned to the bottom of the screen, no arrow.
    double top = maxBottom - height;
    double? arrowX;
    var arrowUp = true;
    if (hole != null) {
      left = (hole.center.dx - width / 2).clamp(16.0, size.width - 16 - width);
      if (hole.bottom + gap + height <= maxBottom) {
        top = hole.bottom + gap;
        arrowX = (hole.center.dx - left).clamp(28.0, width - 28);
      } else if (hole.top - gap - height >= minTop) {
        top = hole.top - gap - height;
        arrowX = (hole.center.dx - left).clamp(28.0, width - 28);
        arrowUp = false;
      }
    }
    top = math.max(minTop, top);
    // Very large text on a short screen: the bubble scrolls inside itself.
    final maxHeight = math.max(120.0, maxBottom - minTop);
    final visible = _bubbleVisible && !_leaving;
    return Positioned(
      left: left,
      width: width,
      top: top,
      // Mid-transition taps are ignored, so a double tap can't skip a stop.
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : Offset(0, arrowUp ? .04 : -.04),
          duration: _d(const Duration(milliseconds: 240)),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: visible ? 1 : .97,
            duration: _d(const Duration(milliseconds: 240)),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: _d(visible ? const Duration(milliseconds: 220) : _fade),
              curve: Curves.easeOut,
              child: _TourBubble(
                key: const ValueKey('tour-bubble'),
                sizeKey: _bubbleKey,
                maxHeight: maxHeight,
                stop: _stop,
                index: _shown,
                total: widget.stops.length,
                last: _shown == widget.stops.length - 1,
                arrowX: arrowX,
                arrowUp: arrowUp,
                onNext: _shown == widget.stops.length - 1
                    ? () => _leave(widget.onNext)
                    : widget.onNext,
                onBack: _shown == 0 ? null : widget.onBack,
                onClose: () => _leave(widget.onClose),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color scrim, ring;
  const _SpotlightPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null || hole.width < 1 || hole.height < 1) {
      canvas.drawPath(full, Paint()..color = scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(20));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, Path()..addRRect(rrect)),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = ring.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.scrim != scrim || old.ring != ring;
}

class _TourBubble extends StatelessWidget {
  final TourStop stop;
  final int index, total;
  final bool last, arrowUp;
  final double? arrowX;
  final VoidCallback onNext, onClose;
  final VoidCallback? onBack;
  final Key sizeKey;
  final double maxHeight;
  const _TourBubble({
    super.key,
    required this.sizeKey,
    required this.maxHeight,
    required this.stop,
    required this.index,
    required this.total,
    required this.last,
    required this.arrowX,
    required this.arrowUp,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surface = scheme.surfaceContainerHigh;
    final card = Material(
      color: surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(DaylockSpace.cardRadius + 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text scrolls if space is tight; the buttons always stay visible.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        // The sun glides up to its new place as each stop opens.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            end: total <= 1 ? 1.0 : index / (total - 1),
                          ),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, _) => CustomPaint(
                            size: const Size(56, 30),
                            painter: _RisingSun(
                              progress: progress,
                              sun: daylockGold(theme.brightness),
                              horizon: scheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${index + 1} of $total',
                          key: const ValueKey('tour-progress'),
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    header: true,
                    child: Text(
                      stop.title,
                      style: theme.textTheme.titleLarge!.copyWith(fontSize: 21),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stop.body,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (!last)
                  TextButton(
                    key: const ValueKey('tour-skip'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                    onPressed: onClose,
                    child: const Text('Skip tour'),
                  ),
                if (onBack != null)
                  TextButton(
                    key: const ValueKey('tour-back'),
                    onPressed: onBack,
                    child: const Text('Back'),
                  ),
                FilledButton(
                  key: const ValueKey('tour-next'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: onNext,
                  child: Text(last ? 'Done' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final arrow = arrowX == null
        ? null
        : Padding(
            padding: EdgeInsets.only(left: arrowX! - 10),
            child: CustomPaint(
              size: const Size(20, 10),
              painter: _Arrow(color: surface, up: arrowUp),
            ),
          );
    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'App tour, step ${index + 1} of $total',
      liveRegion: true,
      child: Column(
        key: sizeKey,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (arrow != null && arrowUp) arrow,
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight - 10),
            child: card,
          ),
          if (arrow != null && !arrowUp) arrow,
        ],
      ),
    );
  }
}

class _Arrow extends CustomPainter {
  final Color color;
  final bool up;
  const _Arrow({required this.color, required this.up});
  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Arrow old) => old.color != color || old.up != up;
}

/// A tiny sunrise: the sun climbs from the horizon as the tour goes on.
class _RisingSun extends CustomPainter {
  final double progress;
  final Color sun, horizon;
  const _RisingSun({
    required this.progress,
    required this.sun,
    required this.horizon,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - 3;
    final center = Offset(size.width / 2, base);
    final radius = size.width / 2 - 7;
    // The path the sun travels, then the horizon over it.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = horizon,
    );
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = horizon
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // From the left horizon up to the top of the arc.
    final angle = math.pi - progress * math.pi / 2;
    final position = Offset(
      center.dx + radius * math.cos(angle),
      base - radius * math.sin(angle),
    );
    canvas.drawCircle(
      position,
      10,
      Paint()
        ..color = sun.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(position, 6.5, Paint()..color = sun);
  }

  @override
  bool shouldRepaint(_RisingSun old) =>
      old.progress != progress || old.sun != sun || old.horizon != horizon;
}
