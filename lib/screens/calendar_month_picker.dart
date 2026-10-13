import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/daylock_theme.dart';

// Calendar navigation only: no plan, event or storage state is edited here.
class CalendarMonthPicker extends StatefulWidget {
  final DateTime initialMonth;
  const CalendarMonthPicker({super.key, required this.initialMonth});

  @override
  State<CalendarMonthPicker> createState() => _CalendarMonthPickerState();
}

class _CalendarMonthPickerState extends State<CalendarMonthPicker> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _year;
  late int _month;
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year = TextEditingController(text: '${widget.initialMonth.year}');
    _month = widget.initialMonth.month;
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  int? get _validYear {
    final year = int.tryParse(_year.text);
    // Same four-digit calendar-date domain as existing Daylock plans and events.
    return year != null && year >= 1 && year <= 9999 ? year : null;
  }

  void _stepYear(int delta) {
    final year = _validYear;
    if (year == null || year + delta < 1 || year + delta > 9999) return;
    setState(() => _year.text = '${year + delta}');
  }

  void _select() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, DateTime(_validYear!, _month));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Resolve widths outside AlertDialog: its intrinsic layout cannot contain a
    // LayoutBuilder. The inset and content padding are both known here.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 96).clamp(1.0, 360.0).toDouble();
        final minimum = MediaQuery.textScalerOf(context).scale(15) * 3 + 32;
        final columns = (width / minimum).floor().clamp(1, 3);
        final monthWidth = (width - (columns - 1) * 8) / columns;
        return AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.all(24),
          title: const Text('Choose month'),
          content: SizedBox(
            width: width,
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Previous year',
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _validYear == null || _validYear == 1
                            ? null
                            : () => _stepYear(-1),
                      ),
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('calendar-picker-year'),
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            errorMaxLines: 4,
                          ),
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _select(),
                          validator: (_) => _validYear == null
                              ? 'Enter a year from 1 to 9999.'
                              : null,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next year',
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _validYear == null || _validYear == 9999
                            ? null
                            : () => _stepYear(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: DaylockSpace.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (var month = 1; month <= 12; month++)
                        SizedBox(
                          width: monthWidth,
                          child: Semantics(
                            selected: month == _month,
                            child: TextButton(
                              key: ValueKey('calendar-picker-month-$month'),
                              style: TextButton.styleFrom(
                                foregroundColor: month == _month
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                backgroundColor: month == _month
                                    ? theme.colorScheme.primary
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => setState(() => _month = month),
                              child: Text(_months[month - 1]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('calendar-picker-select'),
              onPressed: _select,
              child: const Text('Show month'),
            ),
          ],
        );
      },
    );
  }
}
