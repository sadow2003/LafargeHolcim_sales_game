import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/gradient_app_bar.dart';

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

  // email must be a valid @holcim.com address.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';

    //only official Holcim emails are allowed.
    if (!value.toLowerCase().endsWith('@holcim.com')) {
      return 'Only @holcim.com emails are allowed';
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
  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Force an ID token refresh so the callable request carries a valid
      // Firebase Auth token (Gen 2 callable functions reject requests without one).
      await userCredential.user!.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable('createUserProfile');
      await callable.call({
        'firstName': _firstNameController.text.trim(),
        'lastName':  _lastNameController.text.trim(),
        'email':     _emailController.text.trim(),
        'role':      _selectedRole,
        'secret':    _adminSecretController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created!'),
          duration: Duration(seconds: 6),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseFunctionsException catch (e) {
      // Roll back the Firebase Auth account so the user can retry cleanly.
      await userCredential?.user?.delete();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Invalid secret key for $_selectedRole.'
          : 'Registration failed: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use. Please log in or use a different email.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Please choose a stronger password.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      await userCredential?.user?.delete();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF94C12E),
      appBar: GradientAppBar(
        title: 'Register',
        automaticallyImplyLeading: false,// No back button
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
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
                // ── First Name ─────────────────────────────────────────────
                TextFormField(
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'yourname@holcim.com',
                  ),
                  validator: _validateEmail,
                ),



                const SizedBox(height: 16),

                // ── Role Dropdown  ────────────────────────────────────
                // DropdownButtonFormField shows a list of options when tapped.
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1D4370),
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
                    style: const TextStyle(color: Colors.white),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Sales Manager Secret Key',
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
                        return 'Sales Manager secret key is required';
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
                    style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
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
