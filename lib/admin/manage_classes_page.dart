import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageClassesPage extends StatefulWidget {
  const ManageClassesPage({super.key});

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController classCtrl = TextEditingController();

  Future<void> _addClass() async {
    if (classCtrl.text.isEmpty) return;

    await _db
        .collection('schools')
        .doc('school_01')
        .collection('classes')
        .doc(classCtrl.text.trim())
        .set({'sections': [], 'subjects': []});

    classCtrl.clear();
    Navigator.pop((!context.mounted) ? context : context);
  }

  Future<void> _editClass(
    String className,
    List sections,
    List subjects,
  ) async {
    final sectionCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Class $className"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: sectionCtrl,
                decoration: const InputDecoration(labelText: "Add Section"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (sectionCtrl.text.isNotEmpty) {
                    sections.add(sectionCtrl.text.trim());
                    await _db
                        .collection('schools')
                        .doc('school_01')
                        .collection('classes')
                        .doc(className)
                        .update({'sections': sections});
                    sectionCtrl.clear();
                  }
                },
                child: const Text("Add Section"),
              ),
              const Divider(),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: "Add Subject"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (subjectCtrl.text.isNotEmpty) {
                    subjects.add(subjectCtrl.text.trim());
                    await _db
                        .collection('schools')
                        .doc('school_01')
                        .collection('classes')
                        .doc(className)
                        .update({'subjects': subjects});
                    subjectCtrl.clear();
                  }
                },
                child: const Text("Add Subject"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Classes"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Add New Class"),
            content: TextField(
              controller: classCtrl,
              decoration: const InputDecoration(labelText: "Class Name"),
            ),
            actions: [
              TextButton(onPressed: _addClass, child: const Text("SAVE")),
            ],
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('schools')
            .doc('school_01')
            .collection('classes')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sections = data['sections'] ?? [];
              final subjects = data['subjects'] ?? [];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    "Class ${doc.id}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Sections: ${sections.join(', ')}\nSubjects: ${subjects.join(', ')}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editClass(doc.id, sections, subjects),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
