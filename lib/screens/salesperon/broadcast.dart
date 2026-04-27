import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import 'package:lafargeholcim_sales_game/widgets/gradient_app_bar.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Broadcast'),
      drawer: AppDrawer(),
      body: const Center(
        child: Text('This is the Broadcast screen.'),
      ),
    );
  }
}