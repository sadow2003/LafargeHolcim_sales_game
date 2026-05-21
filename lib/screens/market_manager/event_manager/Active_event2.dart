import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';
import '../../../main.dart';
import 'event_management_service.dart';
import 'event_card_widgets.dart';

class ActiveEventCard extends StatefulWidget {
  const ActiveEventCard({super.key});

  @override
  State<ActiveEventCard> createState() => _ActiveEventCardState();
}

class _ActiveEventCardState extends State<ActiveEventCard> {
  bool _isClosing          = false;
  bool _autoCloseTriggered = false;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  Future<void> _closeEvent(DateTime start, DateTime end) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Close Sales Window'),
        content: const Text(
          'This will close the event immediately.\n\n'
          'The top 3 salespersons will be identified and their '
          'rewards will be displayed on their screens.\n\n'
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
            child: const Text('Close Event'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isClosing = true);
    try {
      await EventManagementService.deleteEvent(start, end);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Event closed. Winners have been notified.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Error closing event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }
  List<Widget> _buildProgressSummary(Map<String,dynamic> data){
    final category =data['productCategory'] as String ?;
    final productName = data['productName'] as String ?;
    final target =(data['targetQuantity'] as num?)?.toInt();
    if(category == null || target == null) return[];

    final unit =category =='Concrete' ? 'm³' : 'tonnes';
    final filterLabel = productName != null
        ? ' Product : $productName'
        : 'Category: $category';

    return [
      const SizedBox(height: 16),
      const Text(
        'Progress Challenge',
        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 13),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(Icons.category_outlined,size: 15,color:Color(0xFF1565C0)),
          const SizedBox(width: 6),
          Text(filterLabel,
              style: const TextStyle(fontSize: 13,color: Color(0xFF1565C0))),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const Icon(Icons.flag_outlined,size: 15, color: Color(0xFFFFD700)),
          const SizedBox(width: 6),
          Text('Target: $target $unit',
              style: const TextStyle(fontSize: 13, color: Color(0xFFFFD700))),
        ],
      ),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: EventManagementService.eventStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const ListTile(
              leading:  Icon(Icons.event_busy, color: Colors.grey),
              title:    Text('No active sales window'),
              subtitle: Text('Use the picker below to create one.'),
            ),
          );
        }

        final start      = (data['startDate'] as Timestamp).toDate();
        final end        = (data['endDate']   as Timestamp).toDate();
        final now        = DateTime.now();
        final isLive     = now.isAfter(start) && now.isBefore(end);
        final isPast     = now.isAfter(end);
        final rawRewards = (data['rewards'] as Map<String, dynamic>?) ?? {};

        if (isPast && !_autoCloseTriggered && !_isClosing) {
          _autoCloseTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            setState(() => _isClosing = true);
            try {
              await EventManagementService.deleteEvent(start, end);
            } finally {
              if (mounted) setState(() => _isClosing = false);
            }
          });
        }

        final statusColor = isLive ? Colors.green : (isPast ? Colors.red   : Colors.orange);
        final statusLabel = isLive ? 'OPEN'       : (isPast ? 'CLOSING…'   : 'UPCOMING');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventStatusBadge(label: statusLabel, color: statusColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_fmtDate(start)}  →  ${_fmtDate(end)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                ..._buildProgressSummary(data),

                if (rawRewards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Event Rewards',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  EventRewardSummaryRow(rank: 1, emoji: AppEmojis.gold, rawRewards: rawRewards),
                  const SizedBox(height: 6),
                  EventRewardSummaryRow(rank: 2, emoji: AppEmojis.silver, rawRewards: rawRewards),
                  const SizedBox(height: 6),
                  EventRewardSummaryRow(rank: 3, emoji: AppEmojis.bronze, rawRewards: rawRewards),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: _isClosing ? null : () => _closeEvent(start, end),
                    icon: _isClosing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                          )
                        : const Icon(Icons.close_outlined),
                    label: const Text('Close Sales Window'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}