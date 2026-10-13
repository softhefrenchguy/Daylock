import 'package:flutter/material.dart';

import '../models/event.dart';

class EventEditor extends StatefulWidget {
  final DateTime date;
  final Event? event;

  const EventEditor({super.key, required this.date, this.event});

  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _notes;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _date = event?.date ?? widget.date;
    _title = TextEditingController(text: event?.title);
    _start = TextEditingController(text: event?.startTime?.toString());
    _end = TextEditingController(text: event?.endTime?.toString());
    _notes = TextEditingController(text: event?.notes);
  }

  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _end.dispose();
    _notes.dispose();
    super.dispose();
  }

  EventTime? _time(String text) =>
      text.trim().isEmpty ? null : EventTime.parse(text.trim());

  String? _validateTime(String? text) {
    try {
      _time(text ?? '');
      return null;
    } on FormatException {
      return 'Use HH:mm (00:00–23:59).';
    }
  }

  String? _validateEnd(String? text) {
    final error = _validateTime(text);
    if (error != null) return error;
    try {
      final start = _time(_start.text);
      final end = _time(text ?? '');
      if (start != null && end != null && end.compareTo(start) <= 0) {
        return 'End must be after start.';
      }
    } on FormatException {
      // The start field shows its own validation error.
    }
    return null;
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (mounted && date != null) setState(() => _date = date);
  }

  void _save() {
    if (widget.event?.isExternal == true) return;
    if (!_formKey.currentState!.validate()) return;
    final event = Event(
      id: widget.event?.id ?? Event.newId(),
      title: _title.text,
      date: _date,
      startTime: _time(_start.text),
      endTime: _time(_end.text),
      notes: _notes.text,
    );
    Navigator.pop(context, event);
  }

  @override
  Widget build(BuildContext context) => widget.event?.isExternal == true
      ? AlertDialog(
          scrollable: true,
          title: const Text('Read-only event'),
          content: const Text(
            'External events can only be changed in their calendar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        )
      : AlertDialog(
          scrollable: true,
          title: Text(widget.event == null ? 'Add event' : 'Edit event'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('event-title'),
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (text) => text == null || text.trim().isEmpty
                          ? 'Enter a title.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const ValueKey('event-date'),
                      onPressed: _chooseDate,
                      child: Text(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(_date),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const ValueKey('event-start'),
                      controller: _start,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Start time (optional)',
                        hintText: '14:00',
                      ),
                      validator: _validateTime,
                    ),
                    TextFormField(
                      key: const ValueKey('event-end'),
                      controller: _end,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'End time (optional)',
                        hintText: '16:00',
                      ),
                      validator: _validateEnd,
                    ),
                    TextFormField(
                      key: const ValueKey('event-notes'),
                      controller: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: _save, child: const Text('Save event')),
          ],
        );
}
