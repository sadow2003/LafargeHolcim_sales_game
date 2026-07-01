import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/widgets/gradient_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

// ── Bell icon with live unread badge ────────────────────────────────────────
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});


  //___________________ui________________________
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid; 
    if (uid == null) return const SizedBox.shrink();

    // Streams unread notifications for the current user to update the badge count
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .snapshots(),

          // Renders the bell icon with a red badge showing the unread count
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.length ?? 0;

        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              if (unread > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}








// ── Notifications screen ─────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> _markOneRead(DocumentSnapshot doc) async {
    await doc.reference.update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Notifications',
        actions: [
          TextButton.icon(
            onPressed: () => _markAllRead(uid),
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) {
              final aTs = (a.data() as Map)['timestamp'] as Timestamp?;
              final bTs = (b.data() as Map)['timestamp'] as Timestamp?;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs); // newest first
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, i) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['read'] == true;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return ListTile(
                onTap: isRead ? null : () => _markOneRead(doc),
                tileColor:
                    isRead ? null : kPrimaryColor.withValues(alpha: 0.05),
                leading: CircleAvatar(
                  backgroundColor: isRead
                      ? Colors.grey.shade200
                      : kPrimaryColor.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: isRead ? Colors.grey : kPrimaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  data['title'] ?? 'Notification',
                  style: TextStyle(
                    fontWeight:
                        isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      data['body'] ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(timestamp),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
                trailing: isRead
                    ? null
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
