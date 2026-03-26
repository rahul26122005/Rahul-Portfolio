/*
import 'package:flutter/material.dart';
import 'resume_service.dart';
import 'resume_model.dart';
import 'resume_view_page.dart';
import 'resume_editor_page.dart';

class ResumeListPage extends StatelessWidget {
  const ResumeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ResumeService();

    return Scaffold(
      appBar: AppBar(title: const Text("My Resumes")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResumeEditorPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: service.getResumes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final resume = ResumeModel.fromDoc(docs[i]);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: resume.photoUrl.isNotEmpty
                        ? NetworkImage(resume.photoUrl)
                        : null,
                    child: resume.photoUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(resume.title),
                  subtitle: Text(
                    resume.isPublished ? "Published" : "Private",
                    style: TextStyle(
                      color: resume.isPublished ? Colors.green : Colors.grey,
                    ),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: resume.isPublished,
                        onChanged: (_) {
                          service.publishResume(resume.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          service.deleteResume(resume.id);
                        },
                      ),
                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResumeViewPage(resume: resume),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
*/