import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/widgets/gradient_app_bar.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import 'package:lafargeholcim_sales_game/screens/market_manager/event_manager/event_management_service.dart';
import 'active_event_rewards_view.dart';
import 'congrats_view.dart';

class RewardStorePage extends StatefulWidget {
  const RewardStorePage({super.key});

  @override
  State<RewardStorePage> createState() => _RewardStorePageState();
}

class _RewardStorePageState extends State<RewardStorePage> {
  late Timer _ticker;
  // Streams initialized at declaration so they are ready before the first build,
  // and hot reload cannot leave them uninitialized.
  final Stream<DocumentSnapshot> _eventStream  = EventManagementService.eventStream();
  final Stream<DocumentSnapshot> _resultStream = EventManagementService.lastResultStream();

  @override
  void initState() {
    super.initState();
    // Tick every second so isLive flips the moment the event clock expires,
    // without waiting for a Firestore change to trigger a StreamBuilder rebuild.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: GradientAppBar(title: 'Rewards'),
      drawer: const AppDrawer(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _eventStream,
        builder: (context, eventSnap) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _resultStream,
            builder: (context, resultSnap) {
              if (eventSnap.connectionState == ConnectionState.waiting ||
                  resultSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final eventData  = eventSnap.data?.data()  as Map<String, dynamic>?;
              final resultData = resultSnap.data?.data() as Map<String, dynamic>?;

              // Active event that is currently live
              if (eventData != null) {
                final start = (eventData['startDate'] as Timestamp).toDate();
                final end   = (eventData['endDate']   as Timestamp).toDate();
                final now   = DateTime.now();

                if (now.isAfter(start) && now.isBefore(end)) {
                  return ActiveEventRewardsView(
                    end:        end,
                    rawRewards: (eventData['rewards'] as Map<String, dynamic>?) ?? {},
                  );
                }

                // Event doc still exists but time has passed → results pending
                if (now.isAfter(end) && resultData == null) {
                  return const _PendingResultsView();
                }
              }

              // Results are ready → congrats screen
              if (resultData != null) {
                final closedAt = resultData['closedAt'] != null
                    ? (resultData['closedAt'] as Timestamp).toDate()
                    : DateTime.now();
                return CongratsView(
                  winners:      (resultData['winners']      as List<dynamic>?) ?? [],
                  participants: (resultData['participants'] as List<dynamic>?) ?? [],
                  currentUid:   uid,
                  closedAt:     closedAt,
                );
              }

              return const _NoEventView();
            },
          );
        },
      ),
    );
  }
}

// ── Waiting for results (event ended, manager hasn't closed yet) ─────────────

class _PendingResultsView extends StatelessWidget {
  const _PendingResultsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            const SizedBox(height: 24),
            const Text(
              'Event has ended!',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.bold,
                color:      kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Results are being calculated.\nThe winners screen will appear automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No event ──────────────────────────────────────────────────────────────────

class _NoEventView extends StatelessWidget {
  const _NoEventView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No active event',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Prizes will appear here when a new\nevent is launched by your manager.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
