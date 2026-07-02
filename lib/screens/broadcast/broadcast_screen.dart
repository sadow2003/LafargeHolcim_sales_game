import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../widgets/_buildDrawer.dart';
import '../../widgets/gradient_app_bar.dart';
import 'broadcast_feed.dart';
import 'broadcast_post_sheet.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

// Main screen for the Broadcast feature, showing a feed of broadcasts and allowing users to post new ones
class _BroadcastScreenState extends State<BroadcastScreen>
    with SingleTickerProviderStateMixin {// for TabController
  
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  String _currentUserRole = 'salesperson';
  // Define the tabs for filtering broadcasts
  static const _tabs = ['All', 'Messages', 'Milestones', 'Events'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadCurrentUserRole();
  }

  // Method to load the current user's role from Firestore
  Future<void> _loadCurrentUserRole() async {
    final data = await _fetchCurrentUserData();
    if (mounted && data != null) {
      setState(() => _currentUserRole = data['role'] ?? 'salesperson');
    }
  }

  // Method to fetch current user's data from Firestore
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  // Method to build the Firestore stream based on the selected tab filter
  Stream<QuerySnapshot> _buildStream(String filter) {
    final col = FirebaseFirestore.instance.collection('broadcasts');
    if (filter == 'All') {
      return col.orderBy('createdAt', descending: true).limit(60).snapshots();
    }
    if (filter == 'Messages') {
      return col
          .where('type', isEqualTo: 'general')
          .orderBy('createdAt', descending: true)
          .limit(60)
          .snapshots();
    }
    if (filter == 'Events') {
      return col
          .where('type', isEqualTo: 'event')
          .orderBy('createdAt', descending: true)
          .limit(60)
          .snapshots();
    }
    // Milestones
    return col
        .where('type', isEqualTo: 'milestone')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots();
  }

  // Method to fetch current user's data from Firestore
  Future<Map<String, dynamic>?> _fetchCurrentUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser?.uid)
        .get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return null;
  }

  // Method to fetch current user's rank among salespeople based on total points
  Future<int> _fetchCurrentUserRank() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .orderBy('totalPoints', descending: true)
        .get();
    final idx = snap.docs.indexWhere((d) => d.id == _currentUser?.uid);
    return idx >= 0 ? idx + 1 : 0;
  }

  // Method to show the post broadcast sheet, first fetching necessary user data and rank
  void _showPostSheet() async {
    final results = await Future.wait([
      _fetchCurrentUserData(),
      _fetchCurrentUserRank(),
    ]);

    //if the widget is not mounted, dont show the sheet
    if (!mounted) return;

    // Show the post broadcast sheet with the fetched user data and rank
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostBroadcastSheet(
        currentUser: _currentUser,
        userData: results[0] as Map<String, dynamic>?,
        currentRank: results[1] as int,
      ),
    );
  }

  //____UI BUILDING_____
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with gradient background and tabs for filtering the broadcast feed
      appBar: GradientAppBar(
        title: 'Broadcast',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          indicatorColor: kSecondaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
        ),
      ),

      //drawer for navigation
      drawer: const AppDrawer(),

      //floating action button to add a broadcast post
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostSheet,
        backgroundColor: kSecondaryColor,
        icon: const Icon(Icons.campaign_outlined, color: Colors.white),
        label: const Text(
          'Broadcast',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      // Body with a TabBarView that shows the BroadcastFeed for the selected tab filter
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E2040), Color(0xFF1A3A6B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: _tabs
              .map((tab) => BroadcastFeed(
                    stream: _buildStream(tab),
                    currentUid: _currentUser?.uid,
                    currentUserRole: _currentUserRole,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
