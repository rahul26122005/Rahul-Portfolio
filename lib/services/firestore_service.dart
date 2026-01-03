import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_webside/Hub_Dashboard/models/project_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= FETCH PROJECTS =================
  Stream<List<Project>> getProjects({String? role}) {
    Query query = _db.collection('projects');

    // Optional role-based filtering
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Project.fromMap(data);
      }).toList();
    });
  }
}
