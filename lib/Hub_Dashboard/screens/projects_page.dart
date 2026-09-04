import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/app_drawer.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDarkMode = true;
  final bool isOwner = true; // CHANGE TO false FOR PUBLIC VIEW

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  // ================= ADD / EDIT PROJECT =================
  Future<void> _openProjectDialog({
    String? docId,
    String? title,
    String? description,
    String? url,
  }) async {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);
    final urlCtrl = TextEditingController(text: url);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? 'Add Project' : 'Edit Project'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'Project URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Save'),
            onPressed: () async {
              final data = {
                'title': titleCtrl.text,
                'description': descCtrl.text,
                'url': urlCtrl.text,
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (docId == null) {
                await _firestore.collection('projects').add(data);
              } else {
                await _firestore.collection('projects').doc(docId).update(data);
              }

              Navigator.pop((!context.mounted) ? context : context);
            },
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================
  Future<void> _deleteProject(String docId) async {
    await _firestore.collection('projects').doc(docId).delete();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerPage(isDarkMode: _isDarkMode, onThemeChange: _toggleTheme),

      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Add Project',
              icon: const Icon(Icons.add),
              onPressed: () => _openProjectDialog(),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('you are not an authorized person'),
            ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('projects')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load projects'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No projects available'));
          }

          final projects = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: projects.length,
            itemBuilder: (_, index) {
              final doc = projects[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    data['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //  OPEN
                      IconButton(
                        tooltip: 'Open',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () async {
                          final url = data['url'];
                          if (url != null && url.isNotEmpty) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),

                      // EDIT
                      if (isOwner)
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openProjectDialog(
                            docId: doc.id,
                            title: data['title'],
                            description: data['description'],
                            url: data['url'],
                          ),
                        ),

                      // DELETE
                      if (isOwner)
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProject(doc.id),
                        ),
                    ],
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
