import 'package:flutter/material.dart';
import '../../../main.dart';
import 'event_management_service.dart';

class EventDatePickerCard extends StatefulWidget {
  const EventDatePickerCard({super.key});

  @override
  State<EventDatePickerCard> createState() => _EventDatePickerCardState();
}

class _EventDatePickerCardState extends State<EventDatePickerCard> {
  DateTimeRange? _pickedRange;
  bool _isSaving = false;

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    // Step 1 — pick dates
    final dates = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(now.year, now.month, now.day),
      lastDate:         DateTime(now.year + 3),
      initialDateRange: _pickedRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   kPrimaryColor,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (dates == null || !mounted) return;

    // Step 2 — pick start time
    final startTime = await showTimePicker(
      context:      context,
      initialTime:  TimeOfDay.fromDateTime(_pickedRange?.start ?? now),
      helpText:     'Start time',
    );
    if (startTime == null || !mounted) return;

    // Step 3 — pick end time
    final endTime = await showTimePicker(
      context:      context,
      initialTime:  TimeOfDay.fromDateTime(_pickedRange?.end ?? now),
      helpText:     'End time',
    );
    if (endTime == null || !mounted) return;

    final start = DateTime(
      dates.start.year, dates.start.month, dates.start.day,
      startTime.hour,   startTime.minute,
    );
    final end = DateTime(
      dates.end.year, dates.end.month, dates.end.day,
      endTime.hour,   endTime.minute,
    );

    setState(() => _pickedRange = DateTimeRange(start: start, end: end));
  }

  Future<void> _saveEvent() async {
    if (_pickedRange == null) return;
    setState(() => _isSaving = true);
    try {
      await EventManagementService.saveEvent(_pickedRange!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Sales event saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _pickedRange = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable date range field
            InkWell(
              onTap:        _pickDateRange,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border:       Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_outlined, color: kPrimaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedRange == null
                            ? 'Tap to pick a date range'
                            : '${_fmtDateTime(_pickedRange!.start)}  →  ${_fmtDateTime(_pickedRange!.end)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: _pickedRange == null ? Colors.black38 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_pickedRange == null || _isSaving) ? null : _saveEvent,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Sales Window'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
