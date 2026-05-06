import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../main.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/_buildDrawer.dart';

class EventManagementPage extends StatefulWidget {
  const EventManagementPage({super.key});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  // The date range the market-manager has picked in the UI (before saving).
  DateTimeRange? _pickedRange;

  bool _isSaving   = false;
  bool _isDeleting = false;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Open the system date-range picker ────────────────────────────────────
  Future<void> _pickDateRange() async {
    final now    = DateTime.now();
    final picked = await showDateRangePicker(
      context:      context,
      firstDate:    DateTime(now.year, now.month, now.day), // cannot pick past dates
      lastDate:     DateTime(now.year + 2),
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

    if (picked != null) {
      setState(() => _pickedRange = picked);
    }
  }



  // ── Save the picked range to Firestore ────────────────────────────────────
  Future<void> _saveEvent() async {
    if (_pickedRange == null) return;

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('salesEvent')
          .set({
        'startDate': Timestamp.fromDate(_pickedRange!.start),
        'endDate':   Timestamp.fromDate(_pickedRange!.end),
        'createdBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
        SnackBar(
          content:         Text('Error saving event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }



  // ── Delete the active event from Firestore ────────────────────────────────
  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Remove Event'),
        content: const Text(
          'This will close the sales window immediately. '
          'Salespeople will no longer be able to submit sales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:     FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('salesEvent')
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Sales event removed.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Error removing event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: GradientAppBar(
        title: 'Event Management',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),



      //Drawer of market manager
      drawer: const AppDrawer(),



      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current Active Event ────────────────────────────────────
            const Text(
              'Current Sales Window',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Real-time listener on the salesEvent document
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('settings')
                  .doc('salesEvent')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    snapshot.data?.data() as Map<String, dynamic>?;

                if (data == null) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: const ListTile(
                      leading: Icon(Icons.event_busy, color: Colors.grey),
                      title:   Text('No active sales window'),
                      subtitle: Text('Use the picker below to create one.'),
                    ),
                  );
                }

                final start    = (data['startDate'] as Timestamp).toDate();
                final end      = (data['endDate']   as Timestamp).toDate();
                final now      = DateTime.now();
                final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
                final isLive   = now.isAfter(start) && now.isBefore(endOfDay);
                final isPast   = now.isAfter(endOfDay);

                final statusColor = isLive
                    ? Colors.green
                    : (isPast ? Colors.red : Colors.orange);
                final statusLabel = isLive
                    ? 'OPEN'
                    : (isPast ? 'CLOSED' : 'UPCOMING');

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color:      statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize:   12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date range row
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: kPrimaryColor),
                            const SizedBox(width: 8),
                            Text(
                              '${_fmtDate(start)}  →  ${_fmtDate(end)}',
                              style: const TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Remove button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            onPressed: _isDeleting ? null : _deleteEvent,
                            icon:  _isDeleting
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.red),
                                  )
                                : const Icon(Icons.delete_outline),
                            label: const Text('Remove Sales Window'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),



            // ── New / Updated Event Picker ──────────────────────────────
            const Text(
              'Set New Sales Window',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pick a date range. Salespeople can only submit sales during this period.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // ── Date Range Picker card ──────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Tappable row that launches the date-range picker
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_outlined,
                                color: kPrimaryColor),
                            const SizedBox(width: 12),
                            Text(
                              _pickedRange == null
                                  ? 'Tap to pick a date range'
                                  : '${_fmtDate(_pickedRange!.start)}  →  ${_fmtDate(_pickedRange!.end)}',
                              style: TextStyle(
                                fontSize: 15,
                                color: _pickedRange == null
                                    ? Colors.black38
                                    : Colors.black87,
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
                        onPressed: (_pickedRange == null || _isSaving)
                            ? null
                            : _saveEvent,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save Sales Window'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
