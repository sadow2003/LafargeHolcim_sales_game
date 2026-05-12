import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/_buildDrawer.dart';
import 'active_event_card.dart';
import 'event_date_picker_card.dart';

class EventManagementPage extends StatelessWidget {
  const EventManagementPage({super.key});

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
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current active event ──────────────────────────────────────
            const Text(
              'Current Sales Window',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const ActiveEventCard(),
            const SizedBox(height: 32),

            // ── Create / update event ─────────────────────────────────────
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
            const EventDatePickerCard(),
          ],
        ),
      ),
    );
  }
}
