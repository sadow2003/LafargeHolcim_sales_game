import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';


class MarketManagerDashboard extends StatelessWidget {
  const MarketManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar: GradientAppBar(
        title: 'Market Manager Dashboard',
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

            // ── Welcome Banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, Color(0xFF2E5FA3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Manager Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage sales events and campaign periods.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),



            // ── Active Event Status ─────────────────────────────────────
            const Text(
              'Active Sales Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            const _ActiveEventCard(),
            const SizedBox(height: 28),



            // ── Navigation Tiles ────────────────────────────────────────
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Manage Events tile.
            _NavTile(
              icon:     Icons.event_outlined,
              title:    'Event Management',
              subtitle: 'Set the sales window for salespeople',
              color:    kSecondaryColor,
              onTap:    () => Navigator.pushNamed(context, '/market-manager/events'),
            ),
            const SizedBox(height: 12),

            // Manage Progress Challenges tile.
            _NavTile(
              icon:     Icons.flag_outlined,
              title:    'Progress Challenges',
              subtitle: 'Set a point target for salespersons to reach',
              color:    kCyanColor,
              onTap:    () => Navigator.pushNamed(context, '/market-manager/progress'),
            ),
          ],
        ),
      ),
    );
  }
}



// ── Active Event Card ─────────────────────────────────────────────────────────
// Shows the current sales event period from Firestore in real time.
class _ActiveEventCard extends StatelessWidget {
  const _ActiveEventCard();

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('salesEvent')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null) {
          return _statusTile(
            icon:     Icons.event_busy,
            color:    Colors.grey,
            title:    'No event scheduled',
            subtitle: 'Go to Event Management to create one.',
          );
        }

        final start  = (data['startDate'] as Timestamp).toDate();
        final end    = (data['endDate']   as Timestamp).toDate();
        final now    = DateTime.now();
        final isLive = now.isAfter(start) && now.isBefore(end);
        final isPast = now.isAfter(end);

        return _statusTile(
          icon: isLive
              ? Icons.event_available
              : (isPast ? Icons.event_busy : Icons.event_outlined),
          color: isLive
              ? Colors.green
              : (isPast ? Colors.red : Colors.orange),
          title: isLive
              ? 'Sales window is OPEN'
              : (isPast ? 'Sales window CLOSED' : 'Upcoming event'),
          subtitle: '${_fmtDate(start)}  →  ${_fmtDate(end)}',
        );
      },
    );
  }

  Widget _statusTile({
    required IconData icon,
    required Color    color,
    required String   title,
    required String   subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title:    Text(title,    style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// ── Navigation Tile ───────────────────────────────────────────────────────────
// A tappable card that navigates to another admin screen.
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title:    Text(title,    style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
