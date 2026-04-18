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
      final user = credential.user!;

      // if (!user.emailVerified) {
      //   await FirebaseAuth.instance.signOut();
      //   if (!mounted) return;
      //   setState(() => _isLoading = false);
      //   _showVerificationDialog(user.email ?? _emailController.text.trim());
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

      if (role == 'admin') {
        // Admins go to the admin dashboard 
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
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

  // function that verify the email of the user
  // void _showVerificationDialog(String email) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text('Email Not Verified'),
  //       content: Text(
  //         'Please verify your email address ($email) before logging in. '
  //         'Check your inbox for the verification link.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () async {
  //             try {
  //               final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
  //                 email: _emailController.text.trim(),
  //                 password: _passwordController.text.trim(),
  //               );
  //               await cred.user!.sendEmailVerification();
  //               await FirebaseAuth.instance.signOut();
  //               if (!mounted) return;
  //               Navigator.of(ctx).pop();
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(content: Text('Verification email resent. Check your inbox.')),
  //               );
  //             } catch (_) {
  //               if (!ctx.mounted) return;
  //               ScaffoldMessenger.of(ctx).showSnackBar(
  //                 const SnackBar(content: Text('Could not resend email. Try logging in again.')),
  //               );
  //             }
  //           },
  //           child: const Text('Resend Email'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.of(ctx).pop(),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }



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