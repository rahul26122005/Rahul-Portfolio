/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResumeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  CollectionReference get _ref =>
      _db.collection('users').doc(uid).collection('resumes');

  Stream<QuerySnapshot> getResumes() {
    return _ref.snapshots();
  }

  Future<void> addResume(Map<String, dynamic> data) async {
    await _ref.add({
      ...data,
      'isPublished': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResume(String id) async {
    await _ref.doc(id).delete();
  }

  Future<void> publishResume(String id) async {
    final batch = _db.batch();

    final all = await _ref.get();

    for (var doc in all.docs) {
      batch.update(doc.reference, {'isPublished': false});
    }

    batch.update(_ref.doc(id), {'isPublished': true});

    await batch.commit();
  }
}
*/
