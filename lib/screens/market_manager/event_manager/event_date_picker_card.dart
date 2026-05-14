import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';
import '../../../main.dart';
import 'event_management_service.dart';
import 'event_reward.dart';
import 'reward_fields_input.dart';

class EventDatePickerCard extends StatefulWidget {
  const EventDatePickerCard({super.key});

  @override
  State<EventDatePickerCard> createState() => _EventDatePickerCardState();
}

class _EventDatePickerCardState extends State<EventDatePickerCard> {
  DateTimeRange? _pickedRange;
  bool           _isSaving = false;

  final _rewardAmounts = List.generate(3, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _rewardAmounts) { c.dispose(); }
    super.dispose();
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    // Opens the calendar picker so the user can select start and end dates
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

    //the start time of the event
    final startTime = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(_pickedRange?.start ?? now),
      helpText:    'Start Time',
    );
    if (startTime == null || !mounted) return;

    //the end time of the event
    final endTime = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(_pickedRange?.end ?? now),
      helpText:    'End time',
    );
    if (endTime == null || !mounted) return;

    // Combines the chosen dates with the chosen times into the final range
    setState(() => _pickedRange = DateTimeRange(
      start: DateTime(dates.start.year, dates.start.month, dates.start.day,
                      startTime.hour, startTime.minute),
      end:   DateTime(dates.end.year,   dates.end.month,   dates.end.day,
                      endTime.hour,   endTime.minute),
    ));
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  bool get _canSave {
    if (_pickedRange == null) return false;
    return _rewardAmounts.every((c) {
      final v = double.tryParse(c.text.trim());
      return v != null && v > 0;
    });
  }

// Builds the reward list and persists the event; shows a success or error snackbar
  Future<void> _saveEvent() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      final rewards = _rewardAmounts.map((c) =>
          MoneyReward(amount: double.parse(c.text.trim()))).toList();
      await EventManagementService.saveEvent(_pickedRange!, rewards);
      
      if (!mounted) return;
     
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Sales event saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      // Resets the form so the manager can create another event
      setState(() {
        _pickedRange = null;
        for (final c in _rewardAmounts) { c.clear(); }
      });
    } catch (e) {
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Main card container with rounded corners and subtle shadow
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            const Text(
              'Event Rewards',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),

            // Subtitle describing the reward input purpose
            const SizedBox(height: 4),
            const Text(
              'Set the cash prize (MAD) for each of the top 3 salespersons.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),


            // Reward amount input for 1st place
            const SizedBox(height: 14),
            RewardFieldsInput(
              rankLabel:  '${AppEmojis.gold} 1st Place',
              rankColor:  const Color(0xFFFFD700),
              amountCtrl: _rewardAmounts[0],
            ),



            // Reward amount input for 2nd place
            const SizedBox(height: 12),
            RewardFieldsInput(
              rankLabel:  '${AppEmojis.silver} 2nd Place',
              rankColor:  const Color(0xFFC0C0C0),
              amountCtrl: _rewardAmounts[1],
            ),


            // Reward amount input for 3rd place
            const SizedBox(height: 12),
            RewardFieldsInput(
              rankLabel:  '${AppEmojis.bronze} 3rd Place',
              rankColor:  const Color(0xFFCD7F32),
              amountCtrl: _rewardAmounts[2],
            ),



            // Tappable field that triggers the date/time range picker
            const SizedBox(height: 20),
            _DateRangeField(
              pickedRange:  _pickedRange,
              fmtDateTime:  _fmtDateTime,
              onTap:        _pickDateRange,
            ),



            // Save button — disabled until all reward amounts and date range are valid
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_canSave && !_isSaving) ? _saveEvent : null,
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

// ── Date range tap field ──────────────────────────────────────────────────────

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.pickedRange,
    required this.fmtDateTime,
    required this.onTap,
  });

  final DateTimeRange?            pickedRange;
  final String Function(DateTime) fmtDateTime;
  final VoidCallback              onTap;
//__________UI_______________________
  @override
  Widget build(BuildContext context) {
    
    // Tappable bordered container showing the selected range or a placeholder hint
    return InkWell(
      onTap:        onTap, // launches the date/time picker flow
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border:       Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),

        // Calendar icon + formatted range text (or placeholder)
        child: Row(
          children: [
            const Icon(Icons.date_range_outlined, color: kPrimaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pickedRange == null
                    ? 'Tap to pick a date range'
                    : '${fmtDateTime(pickedRange!.start)}  →  ${fmtDateTime(pickedRange!.end)}',
                style: TextStyle(
                  fontSize: 15,
                  color: pickedRange == null ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
