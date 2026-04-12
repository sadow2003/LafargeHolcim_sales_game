import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/screens/_buildDrawer.dart';




class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}




class _ProfilePageState extends State<ProfilePage> {
// Declare variables for current user and Firestore instance
  late final User? currentUser;
  late final FirebaseFirestore firestore;
  @override
  void initState() {

    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    firestore = FirebaseFirestore.instance;
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(

// AppBar with title and styling
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),



//Building drawer for profile page
      drawer: const AppDrawer(),



// Body with user profile information and logout button
      body: currentUser == null
          ? Center(
              child: Text('User not authenticated'),
            )
          : FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('users').doc(currentUser!.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }


// Handle errors and missing data
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }


// Handle case where user document does not exist
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('User data not found'),
                  );
                }


// Extract user data from Firestore document
                final userData =snapshot.data!.data() as Map<String, dynamic>;
                final firstName = userData['firstName'] ?? 'Unknown';
                final lastName = userData['lastName'] ?? 'Unknown';
                final email = userData['email'] ?? 'Unknown';
                final points = userData['points'] ?? 0;
                final rank = userData['rank'] ?? '--';


// Display user profile information in a card with styling
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [


// User avatar and name
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),


                        const SizedBox(height: 20),



// User full name 
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),



// Card with user details and points
                        Card(
                          elevation: 4,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [


//first name
                                _buildInfoRow(
                                  label: 'First Name',
                                  value: firstName,
                                  icon: Icons.person_outline,
                                ),


                                const Divider(height: 20),

// Last Name
                                _buildInfoRow(
                                  label: 'Last Name',
                                  value: lastName,
                                  icon: Icons.person_outline,
                                ),


                                const Divider(height: 20),

// Email
                                _buildInfoRow(
                                  label: 'Email',
                                  value: email,
                                  icon: Icons.email_outlined,
                                ),



                                
                              const Divider(height: 20),


// Points
                                _buildInfoRow(
                                  label: 'Points',
                                  value: points.toString(),
                                  icon: Icons.star_outlined,
                                  valueColor: Colors.orange,
                                ),


                                const Divider(height: 20),

// Rank
                                _buildInfoRow(
                                  label: 'Rank',
                                  value: rank.toString(),
                                  icon: Icons.military_tech_outlined,
                                  valueColor: Colors.amber,
                                ),



                              ],
                            ),
                          ),
                        ),
                      
                      
                      const SizedBox(height: 30),


// Products History Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sales History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildProductsHistory(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }


// Widget to display products/sales history
  Widget _buildProductsHistory() {
    if (currentUser == null) {
      return const Center(child: Text('User not authenticated'));
    }


// Listen to Firestore collection for user's sales history and display it in a list
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('sales')
          .orderBy('soldDate', descending: true)
          .snapshots(),



      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

// Handle errors and empty state
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }


// Handle case where there are no sales history documents
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sales history yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }



// Build list of sales history items
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final sale = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final productName = sale['productName'] ?? 'Unknown Product';
            final quantity = sale['quantity'] ?? 0;
            final price = sale['price'] ?? 0;
            final soldDate = sale['soldDate'] != null
                ? (sale['soldDate'] as Timestamp).toDate()
                : DateTime.now();
            final total = (price * quantity).toStringAsFixed(2);





            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [



                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          color: Colors.teal,
                          size: 24,
                        ),

                        const SizedBox(width: 12),



                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${soldDate.day}/${soldDate.month}/${soldDate.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),




                        Text(
                          '\$$total',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),




                    const SizedBox(height: 12),





                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qty: $quantity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Unit Price: \$$price',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
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



  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {



    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [




              // Label for the information (e.g., "Email", "Points")
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),




              // Value of the information (e.g., user's email or points)
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}