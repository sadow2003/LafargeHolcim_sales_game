import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';       
import '_buildDrawer.dart'; 


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}


class _ProfilePageState extends State<ProfilePage>{
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    //check if the user is login or not throws an error message if not
    if(_currentUser == null){
      return const Scaffold(
        body:Center(child:Text('no authentication, please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      drawer: const AppDrawer(),


      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get(),
        builder: (context,snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found.'));
          }
          // extract all the info from the documents
          final data        = snapshot.data!.data() as Map<String, dynamic>;
          final firstName   = data['firstName']   ?? 'Unknown';
          final lastName    = data['lastName']    ?? '';
          final email       = data['email']       ?? '';
          final role        = data['role']        ?? 'salesperson';
          //if total points is not there then you can use the old ponits if they also not there use 0
          final totalPoints = data['totalPoints'] ?? data['points'] ?? 0;
          final rank        = data['rank']        ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // ── Avatar ───────────────────────────────────────────────
                CircleAvatar(
                  radius: 50,
                  backgroundColor: kPrimaryColor,
                  child: Text(
                    // Show the first letter of the first name as an avatar.
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

              //____Name________________
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),

                const SizedBox(height: 6),
              //____Role____________________
                Container(
                  padding:const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 238, 195, 120),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kSecondaryColor),
                  ),
                  child: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: const TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),



                const SizedBox(height: 24),

                //the info card____________________________
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _infoRow(Icons.email_outlined, 'Email', email),


                        const Divider(height: 24),

                        _infoRow(
                          Icons.star_outline,
                          'Total Points',
                          totalPoints.toString(),
                          valueColor: kSecondaryColor,
                        ),



                        const Divider(height: 24),



                        _infoRow(
                          Icons.military_tech_outlined,
                          'Rank',
                          rank == 0 ? '—' : '#$rank',
                          valueColor: Colors.amber.shade700,
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 28),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sales History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),


                const SizedBox(height: 12),

                _buildSalesHistory(),
              ],
            ),
          );
        }
        ),
      );
  }
// ── Sales History Stream ──────────────────────────────────────────────────
  Widget _buildSalesHistory() {
    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore.instance
          .collection('sales')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true) // Newest first
          .snapshots(),
      builder: (context, snapshot) {


        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }


        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }


        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Empty state illustration.
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'No sales submitted yet.\nTap "Submit Sale" to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }



        // Build one card per sale.
        return ListView.builder(
          shrinkWrap: true, //let the upper container (parent) control the height
          physics: const NeverScrollableScrollPhysics(), // Disable inner scroll
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc  = snapshot.data!.docs[index];
            final sale = doc.data() as Map<String, dynamic>;

            final productName   = sale['productName']   ?? 'Unknown Product';
            final quantity      = sale['quantity']      ?? 0;
            final status        = sale['status']        ?? 'pending';
            final pointsAwarded = sale['pointsAwarded'] ?? 0;
            final createdAt     = sale['createdAt'] != null
                ? (sale['createdAt'] as Timestamp).toDate()
                : null;



            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    // Icon on the left.
                    const Icon(Icons.inventory_2_outlined,
                        color: kPrimaryColor, size: 28),
                    const SizedBox(width: 12),

                    // Product name, date, and quantity.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

// Date is only shown if available (it should be, but just in case).
                          if (createdAt != null)
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),



                          Text(
                            'Qty: $quantity',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),


                    // Right side: status badge + points.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [


                        // Colored status badge.
                        _statusBadge(status),
                        const SizedBox(height: 6),
                        // Points are only shown when the sale is approved.
                        if (status == 'approved')
                          Text(
                            '+$pointsAwarded pts',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  // ── Helper: Info Row ──────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }





  // ── Helper: Status Badge ──────────────────────────────────────────────────
  
  Widget _statusBadge(String status) {
    
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      default: // 'pending'
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        // Capitalize the first letter of the status.
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

}