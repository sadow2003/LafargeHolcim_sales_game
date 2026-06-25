import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequireAuth2 extends StatefulWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RequireAuth2({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  State<RequireAuth2> createState() => _RequireAuth2State();
}

class _RequireAuth2State extends State<RequireAuth2> {
  late final Future<_AuthCheck> _check;

  @override
  void initState() {
    super.initState();
    _check = _verify();
  }

  Future<_AuthCheck> _verify() async {
    final user =  FirebaseAuth.instance.currentUser;
    if (user == null) return const _AuthCheck(redirect: '/login');

    try {
      final doc = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        
        if(!doc.exists) return const _AuthCheck(redirect: '/login');

        final role = (doc.data()?['role'] as String?) ?? 'salesperson';
        if (widget.allowedRoles.contains(role)) return const _AuthCheck();

        return _AuthCheck(redirect: _homeRoute(role));
    } catch (_) {
      return const _AuthCheck(redirect: '/login');
    }
  }

  static String _homeRoute(String role) {
    switch (role) {
      case 'admin':
        return '/admin/dashboard';
      case 'sales_manager':
        return '/maneger/dashboard';
      case 'market-manager':
        return '/market-manager/dashboard';
      default:
        return '/rankings';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthCheck>(
      future:_check,
      builder:(context,snapshot){
        if(snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body :Center(child: CircularProgressIndicator()),
          );
        }

        final redirect = snapshot.data?.redirect;
        if(redirect != null) {
          WidgetsBinding.instance.addPostFrameCallback((_){
            if(mounted) Navigator.pushReplacementNamed(context, redirect);
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        return widget.child;
      }
    );
  }
}

class _AuthCheck {
  final String? redirect;
  const _AuthCheck({this.redirect});
}