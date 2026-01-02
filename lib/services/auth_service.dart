import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/routes/app_routes.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ================= LOGIN WITH ROLE CHECK =================
  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        _showUnauthorizedDialog(context);
        await logout();
        return;
      }

      final role = doc.data()!['role'];

      if (!context.mounted) return;

      if (role == 'teacher') {
        Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
      } else if (role == 'student') {
        Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
      } else if (role == 'guest') {
        Navigator.pushReplacementNamed(context, AppRoutes.guestDashboard);
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        _showUnauthorizedDialog(context);
        await logout();
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
  }

  /// ================= TEACHER SIGNUP =================
  Future<void> teacherSignup({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': 'teacher',
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ================= STUDENT SIGNUP =================
  Future<void> studentSignup({
    required String name,
    required String email,
    required String password,

    required String registerNo,
    required String fatherMobile,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': 'student',

      'registerNo': registerNo,

      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// ================= UNAUTHORIZED DIALOG =================
  void _showUnauthorizedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Access Denied"),
        content: const Text(
          "You are not an authorized user or your account does not exist.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// ================= ERROR DIALOG =================
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

/// ================= INPUT FIELD =================
InputDecoration authField(String hint, IconData icon) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: Colors.white70),
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );
}
