import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Event countdown banner ───────────────────────────────────────────────────

class EventCountdownBanner extends StatefulWidget {
  const EventCountdownBanner();

  @override
  State<EventCountdownBanner> createState() => _EventCountdownBannerState();
}

class _EventCountdownBannerState extends State<EventCountdownBanner> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Tick every second so the countdown stays live
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('salesEvent')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink(); // no event — hide

        final start = (data['startDate'] as Timestamp).toDate();
        final end   = (data['endDate']   as Timestamp).toDate();

        // Event hasn't started yet
        if (_now.isBefore(start)) {
          final diff = start.difference(_now);
          return _banner(
            icon:    Icons.schedule_outlined,
            message: 'Event starts in ${_formatDuration(diff)}',
            color:   Colors.orange.shade700,
          );
        }

        // Event is live — show time remaining
        if (_now.isBefore(end)) {
          final diff     = end.difference(_now);
          final isUrgent = diff.inHours < 24;
          return _banner(
            icon:    isUrgent ? Icons.warning_amber_rounded : Icons.timer_outlined,
            message: 'Event ends in ${_formatDuration(diff)}',
            color:   isUrgent ? Colors.red.shade600 : const Color(0xFF8DC21F),
            pulse:   isUrgent,
          );
        }

        // Event is over
        return _banner(
          icon:    Icons.event_busy_outlined,
          message: 'Event has ended — awaiting coin distribution',
          color:   Colors.grey.shade600,
        );
      },
    );
  }

  Widget _banner({
    required IconData icon,
    required String   message,
    required Color    color,
    bool pulse = false,
  }) {
    final child = Container(
      width:   double.infinity,
      color:   color.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color:      color,
              fontSize:   12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    // Subtle opacity pulse for urgent warnings (< 24 h left)
    if (pulse) {
      final opacity = 0.6 + 0.4 * ((_now.second % 2 == 0) ? 1.0 : 0.0);
      return Opacity(opacity: opacity, child: child);
    }
    return child;
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours.remainder(24);
      return '${d.inDays}d ${h}h';
    }
    if (d.inHours >= 1) {
      final m = d.inMinutes.remainder(60);
      return '${d.inHours}h ${m.toString().padLeft(2, '0')}m';
    }
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }
}
