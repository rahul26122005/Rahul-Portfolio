import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeachersPage extends StatelessWidget {
  const ManageTeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Teachers"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No teachers found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final isActive = doc['isActive'] ?? true;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(doc['name'][0]),
                  ),
                  title: Text(doc['name']),
                  subtitle: Text(doc['email']),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (val) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .update({'isActive': val});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
