import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import 'package:lafargeholcim_sales_game/widgets/gradient_app_bar.dart';
import '../main.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'AI Coach'),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  size: 48,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Under Maintenance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The AI Coach is temporarily unavailable.\nWe\'ll be back shortly!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
            ],
          ),
        ),
      ),
    );
  }
}
