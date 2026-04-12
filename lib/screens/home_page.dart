import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/screens/_buildDrawer.dart';


// Home Page with Drawer and Logout Functionality
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}




class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      // AppBar with title and styling
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),



      // Drawer with user info and logout option
      drawer: const AppDrawer(),

// Main content of the Home Page
      body: Center(
        child: Text(
          'Welcome to the Home Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
