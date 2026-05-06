import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/notification_service.dart';

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


  //______password rest Function____________________________
  // Future<void> _forgotPassword() async {
  //   final email = _emailController.text.trim();
  //   if (email.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Enter your email above, then tap Forgot Password.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }
  //   try {
  //     //send the email to reset the password__________
  //     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  //     if (!mounted) return;


  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Password reset email sent! Check your inbox.'),
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 5),
  //       ),
  //     );


  //   } on FirebaseAuthException catch (e) {
  //     if (!mounted) return;
  //     final message = e.code == 'user-not-found'
  //         ? 'No account found for that email.'
  //         : 'Failed to send reset email. (${e.code})';
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(message), backgroundColor: Colors.red),
  //     );
  //   }
  // }

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

      //Block login if email is not verified
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
          .get();

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

      // Save this device's FCM token so Cloud Functions can notify it
      await NotificationService.instance.saveTokenForCurrentUser();

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


                // ── LafargeHolcim Logo ─────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [



                        // Top-right circle — cyan to navy (blue half of logo)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [kPrimaryColor, kCyanColor],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),



                        // Bottom-left circle — green to cyan (green half of logo)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [kSecondaryColor, kCyanColor],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),


                        
                        // Bold S in the centre
                        const Text(
                          'S',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
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


                //____Password Reset text Button____________________
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: _forgotPassword,
                //     child: const Text(
                //       'Forgot Password?',
                //       style: TextStyle(color: kPrimaryColor),
                //     ),
                //   ),
                // ),

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