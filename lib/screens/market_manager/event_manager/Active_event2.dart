import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../main.dart';
import 'event_management_service.dart';

class ActiveEventCard2 extends StatefulWidget {
  const ActiveEventCard2({super.key});

  @override
  State<ActiveEventCard2> createState() => _ActiveEventCard2State();
}

class _ActiveEventCard2State extends State<ActiveEventCard2> {
  bool _isDeleting = false;

  String _fmtDate(DateTime d)=>
    '${d.day.toString().padLeft(2,'0')}/'
    '${d.month.toString().padLeft(2,'0')}'
    '${d.year}';

    Future<void> _closeEvent(DateTime start,DateTime end)async{
      final confirm =await showDialog<bool>(
        context:context,
        builder:(_)=>AlertDialog(
          title:   const Text('Close Sales Window'),
        content: const Text(
          'This will close the sales window immediately.\n\n'
          'Coins will be awarded automatically based on each '
          "salesperson's performance during this event:\n\n"
          '🥇 Rank 1 → 500 coins\n'
          '🥈 Rank 2 → 300 coins\n'
          '🥉 Rank 3 → 200 coins\n'
          '✅ Participated → 100 coins\n\n'
          'Points will be reset to 0 for the next event.',
        ),
          actions: [
            TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
            ),
            FilledButton(
            style:     FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close & Award'),
            ),
          ],
          ),
      );
      if (confirm != true) return;

      setState(()=>_isDeleting=true);

      try{
        final awards = await EventManagementService.deleteEvent(start, end);
        if (!mounted) return;

        final msg = awards.isEmpty
            ? 'Event closed. No participants — no coins awarded.'
          : 'Event closed! Coins awarded to ${awards.length} salesperson(s).';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: awards.isEmpty ? Colors.orange : Colors.green,
            ),
        );
      }catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Error closing event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
    }

    @override
    Widget build(BuildContext context){
      return StreamBuilder<DocumentSnapshot>(
        stream: EventManagementService.eventStream(), 
        builder: (context,snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if(data == null){
            return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const ListTile(
              leading:  Icon(Icons.event_busy, color: Colors.grey),
              title:    Text('No active sales window'),
              subtitle: Text('Use the picker below to create one.'),
            ),
          );
          }

          final start = (data['startDate'] as Timestamp).toDate();
          final end      = (data['endDate']   as Timestamp).toDate();
          final now      = DateTime.now();
          final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
          final isLive   = now.isAfter(start) && now.isBefore(endOfDay);
          final isPast   = now.isAfter(endOfDay);

          final statusColor = isLive ? Colors.green : (isPast ? Colors.red : Colors.orange);
          final statusLabel = isLive ? 'OPEN'       : (isPast ? 'CLOSED'   : 'UPCOMING');

          return Card(
            elevation:2,
            shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment : CrossAxisAlignment.start,
              children: [
                _StatusBadge(label: statusLabel,color: statusColor),
                const SizedBox(height:12),
                _DateRangeRow(start: start, end: end, fmtDate: _fmtDate),
                const SizedBox(height: 16),

                _CloseEventButton(
                  isLoading: _isDeleting,
                  onTap:     () => _closeEvent(start, end),
                ),
              ],
              ),
          );

        }
        );
    }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.start,
    required this.end,
    required this.fmtDate,
  });
  final DateTime start;
  final DateTime end;
  final String Function(DateTime) fmtDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: kPrimaryColor),
        const SizedBox(width: 8),
        Text(
          '${fmtDate(start)}  →  ${fmtDate(end)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CloseEventButton extends StatelessWidget {
  const _CloseEventButton({required this.isLoading, required this.onTap});
  final bool         isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
              )
            : const Icon(Icons.close_outlined),
        label: const Text('Close Sales Window'),
      ),
    );
  }
}