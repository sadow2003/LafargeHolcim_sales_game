import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../widgets/gradient_app_bar.dart';

const String _kadminScreat         = 'admin123';
const String _kManagerScreat       = 'manager123';
const String _kMarketManagerSecret = 'marketmanager123';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}



// The _RegisterPageState class holds all the state and logic for the registration page.
class _RegisterScreenState extends State<RegisterScreen> {
  // One controller per text field.
  final _firstNameController        = TextEditingController();
  final _lastNameController         = TextEditingController();
  final _emailController            = TextEditingController();
  final _passwordController         = TextEditingController();
  final _confirmPasswordController  = TextEditingController();
  final _adminSecretController      = TextEditingController();

// this create a unique key that links to the form widget allowing us to manipulate it
  final _formKey = GlobalKey<FormState>(); 

  bool _passwordVisible     = false;
  //admin secret password input text is hidden
  bool _adminSecretVisible  = false;
  bool _isLoading           = false;

   // Role is selected from a dropdown; default is 'salesperson'.
  String _selectedRole = 'salesperson';

  // The two allowed roles, shown in the dropdown menu.
  final List<String> _roles = ['salesperson', 'admin', 'sales-manager', 'market-manager'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminSecretController.dispose();
    super.dispose();
  }
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  // email must be a valid @lafargeholcim.com address.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';

    //only official LafargeHolcim emails are allowed.
    if (!value.toLowerCase().endsWith('@lafargeholcim.com')) {
      return 'Only @lafargeholcim.com emails are allowed';
    }
    return null;
   }


  
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~/]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }


  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }
   Future<void> _saveUserToFirestore({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'firstName':   firstName,
      'lastName':    lastName,
      'email':       email,
      'role':        role,         
      'totalPoints': 0,            
      'rank':        0,            
      'createdAt':   FieldValue.serverTimestamp(), 
    });
  }

  Future<void> _registerUser() async {
    if(_formKey.currentState?.validate() != true) return;
    if (_selectedRole == 'admin' && _adminSecretController.text != _kadminScreat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid admin secret key')),
      );
      return;
    }
    if (_selectedRole == 'sales-manager' && _adminSecretController.text != _kManagerScreat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid manager secret key')),
      );
      return;
    }
    if (_selectedRole == 'market-manager' && _adminSecretController.text != _kMarketManagerSecret) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid market manager secret key')),
      );
      return;
    }
    setState( () => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _saveUserToFirestore(
        userId: userCredential.user!.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
      );


      //send an email to a the account to verity that it is the user
      // await userCredential.user!.sendEmailVerification();
      // await FirebaseAuth.instance.signOut();
      // Navigator.popAndPushNamed(context, '/login');

      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! '),
          duration: Duration(seconds: 6),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
}on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use. Please log in or use a different email.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Please choose a stronger password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState( () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GradientAppBar(
        title: 'Register',
        automaticallyImplyLeading: false,// No back button
      ),
      body: SafeArea( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── First Name ─────────────────────────────────────────────
                TextFormField(
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => _validateName(v, 'first name'),
                ),



                const SizedBox(height: 16),

                // ── Last Name ──────────────────────────────────────────────
                TextFormField(
                  controller: _lastNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => _validateName(v, 'last name'),
                ),




                const SizedBox(height: 16),

                // ── Email ──────────────────────────────────────────────────
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



                const SizedBox(height: 16),

                // ── Role Dropdown  ────────────────────────────────────
                // DropdownButtonFormField shows a list of options when tapped.
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole, 
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      // Capitalize first letter for display: 'salesperson' → 'Salesperson'
                      child: Text(
                        role[0].toUpperCase() + role.substring(1),
                      ),
                    );
                  }).toList(),
                  // Called whenever the user picks a different role.
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRole = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a role' : null,
                ),



                // ── Admin Secret Code (only shown when Admin is selected) ───
                if (_selectedRole == 'admin') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminSecretController,
                    obscureText: !_adminSecretVisible,
                    decoration: InputDecoration(
                      labelText: 'Admin Access Code',
                      prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _adminSecretVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _adminSecretVisible = !_adminSecretVisible);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'admin' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Admin access code is required';
                      }
                      return null;//null means no errors
                    },
                  ),
                ],

                // ── Manager Secret Code (only shown when Manager is selected) ───
                if (_selectedRole == 'sales-manager') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminSecretController,
                    obscureText: !_adminSecretVisible,
                    decoration: InputDecoration(
                      labelText: 'Manager Secret Key',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _adminSecretVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _adminSecretVisible = !_adminSecretVisible);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'sales-manager' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Manager secret key is required';
                      }
                      return null;//null means no errors
                    },
                  ),
                ],

                // ── Market Manager Secret Code ──────────────────────────────
                if (_selectedRole == 'market-manager') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminSecretController,
                    obscureText: !_adminSecretVisible,
                    decoration: InputDecoration(
                      labelText: 'Market Manager Secret Key',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _adminSecretVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _adminSecretVisible = !_adminSecretVisible);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'market-manager' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Market manager secret key is required';
                      }
                      return null;//null means no errors
                    },
                  ),
                ],

                const SizedBox(height: 16),
                // ── Password ───────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _passwordVisible = !_passwordVisible);
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),



                const SizedBox(height: 16),


                // ── Confirm Password ───────────────────────────────────────
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_passwordVisible,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: _validateConfirmPassword,
                ),



                const SizedBox(height: 28),



                // ── Submit Button ──────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Account', style: TextStyle(fontSize: 16)),
                ),



                const SizedBox(height: 12),




                // ── Back to Login ──────────────────────────────────────────
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Already have an account? Login here',
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
