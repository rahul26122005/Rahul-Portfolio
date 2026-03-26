/*
import 'package:flutter/material.dart';
import 'resume_service.dart';

class ResumeEditorPage extends StatefulWidget {
  const ResumeEditorPage({super.key});

  @override
  State<ResumeEditorPage> createState() => _ResumeEditorPageState();
}

class _ResumeEditorPageState extends State<ResumeEditorPage> {
  final service = ResumeService();

  final titleController = TextEditingController();
  final nameController = TextEditingController();
  final summaryController = TextEditingController();

  String photoUrl = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Resume")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: summaryController,
              decoration: const InputDecoration(labelText: "Summary"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await service.addResume({
                  'title': titleController.text,
                  'name': nameController.text,
                  'summary': summaryController.text,
                  'photoUrl': photoUrl,
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
*/