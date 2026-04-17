import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //it extract the input text from the application to manipulate in the code
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

//this create a unique key that links to the form widget allowing us to manipulate it
  final _formKey = GlobalKey<FormState>();

//we can control if the password id visible or not
  bool _passwordVisible = false; 
  //we can control if the the screenn is the the state of loading
  bool _isLoading       = false; 


//we empty the variables to that the memory is not full and it crashes the app
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null; // null means "no error"
  }


  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }




  // ── Login Logic ──────────────────────────────────────────────────────────
  Future<void> _loginUser() async {
    //it checks if all the forms are validated if there not it gives a error meassage and does nothing
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true); 

    try {

//it checks the firebase auth if the user is registerd
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid =credential.user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

//safety check for the application, if it see the user not connected to widget it return to new widget to not crash the application
      if (!mounted) return;


      // check if the user is in the fireStore database
      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deactivated'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      //see the role of the user id it salesperson or admin, if the anwser is null it will just be salesperson
      final role = doc.data()?['role'] ?? 'salesperson';

      if (role == 'admin') {
        // Admins go to the admin dashboard 
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else {
        // Salespeople go to the home/dashboard screen.
        Navigator.pushReplacementNamed(context, '/home');
      }


    } on FirebaseAuthException catch (e) {

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for that email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = 'Login failed. Please try again. (${e.code})';
      }

      if (!mounted) return;
      //shows the error message below the screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      //no matter what happend before this code it will always run the code here
    } finally {
      //if the widejet still exists then you can get out of the loading state
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),


                CircleAvatar(
                  radius: 50,
                  backgroundColor: kPrimaryColor,
                  child: const Icon(Icons.business, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),



                const Text(
                  'SalesQuest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),




                const Text(
                  'LafargeHolcim Maroc',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),




                const SizedBox(height: 40),




                // ── Email Field ────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'yourname@lafargeholcim.com',
                  ),
                  validator: _validateEmail,
                ),



                const SizedBox(height: 20),





                // ── Password Field ─────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible, 
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _passwordVisible = !_passwordVisible);
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),



                const SizedBox(height: 28),





                ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),





                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    "Don't have an account? Register here",
                    style: TextStyle(color: kPrimaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}