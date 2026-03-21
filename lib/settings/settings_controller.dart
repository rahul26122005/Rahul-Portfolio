import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> getUserRole() async {
    if (currentUser == null) return null;

    final doc = await _db.collection('users').doc(currentUser!.uid).get();
    if (!doc.exists) return null;

    return doc.data()?['role'];
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final doc = await _db.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateTheme(bool isDark) async {
    if (currentUser == null) return;

    await _db.collection('users').doc(currentUser!.uid).update({
      'darkMode': isDark,
    });
  }
}
