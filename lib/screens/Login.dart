import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
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
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~/]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }


  //______password rest Function____________________________
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email above, then tap Forgot Password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      //send the email to reset the password__________
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );


    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'user-not-found'
          ? 'No account found for that email.'
          : 'Failed to send reset email. (${e.code})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
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
      final user = credential.user!;

      //Block login if email is not verified — disabled during testing
      // if (!user.emailVerified) {
      //   await FirebaseAuth.instance.signOut();
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: const Text('Please verify your email before logging in.'),
      //       backgroundColor: Colors.orange,
      //       duration: const Duration(seconds: 6),
      //       action: SnackBarAction(
      //         label: 'Resend',
      //         textColor: Colors.white,
      //         onPressed: () async {
      //           try {
      //             final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      //               email: _emailController.text.trim(),
      //               password: _passwordController.text.trim(),
      //             );
      //             await cred.user!.sendEmailVerification();
      //             await FirebaseAuth.instance.signOut();
      //             if (!mounted) return;
      //             ScaffoldMessenger.of(context).showSnackBar(
      //               const SnackBar(
      //                 content: Text('Verification email resent!'),
      //                 backgroundColor: Colors.green,
      //               ),
      //             );
      //           } catch (_) {}
      //         },
      //       ),
      //     ),
      //   );
      //   setState(() => _isLoading = false);
      //   return;
      // }

      final uid = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      //check if the user exists in the fire store, if not it deletes the user authentification
      if (!doc.exists) {
        await FirebaseAuth.instance.currentUser?.delete();
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

      final role = doc.data()?['role'] ?? 'salesperson';

      // Save this device's FCM token so Cloud Functions can notify it.
      // Fire-and-forget: getToken / the Firestore write can hang on a flaky
      // connection, and navigation must never wait on it.
      unawaited(NotificationService.instance.saveTokenForCurrentUser());

      if (role == 'admin') {
        // Admins go to the admin dashboard
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } 
       else if (role == 'sales-manager') {
        // Start listening so this device pops a notification when a sale is submitted
        NotificationService.instance.startListeningForNotifications();
        Navigator.pushReplacementNamed(context, '/manager/dashboard');
      } else if (role == 'market-manager') {
        Navigator.pushReplacementNamed(context, '/market-manager/dashboard');
      } else {
        // Salespeople go to the Rankings screen.
        Navigator.pushReplacementNamed(context, '/rankings');
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
    } catch (e) {
      // Non-auth failures (Firestore errors, timeouts...) — without this
      // catch they were swallowed and the user got no feedback.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      //no matter what happend before this code it will always run the code here
    } finally {
      //if the widejet still exists then you can get out of the loading state
      if (mounted) setState(() => _isLoading = false);
    }
  }

//____UI________________________________________________
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF94C12E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1D4370), // Holcim dark blue
              Color(0xFF10BBE1), // Holcim light blue
              Color(0xFF94C12E), // Holcim light green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white54),
                prefixIconColor: Colors.white70,
                suffixIconColor: Colors.white70,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                errorStyle: TextStyle(color: Colors.white),
              ),
            ),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),


                // ── Logo ─────────────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Blue circle — top-right
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0055CC), Color(0xFF0096E6)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
                        // Teal-green circle — bottom-left
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF00B87C), Color(0xFF00AEEF)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
                        // Trending-up chart arrow
                        const Icon(
                          Icons.trending_up,
                          size: 58,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),



                const SizedBox(height: 20),



                const Text(
                  'SalesQuest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),




                const Text(
                  'Holcim Maroc',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),




                const SizedBox(height: 40),




                // ── Email Field ────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
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


                //____Password Reset text Button____________________
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                 const SizedBox(height: 12),




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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
      ),
    );
  }
}