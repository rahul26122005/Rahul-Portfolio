import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/emptystate.dart';
import '../widgets/errorstate.dart';
import '../widgets/project_card.dart';
import '../widgets/app_drawer.dart';
import '/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isDarkMode = true;
  String _searchQuery = '';

  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  // ================= RESPONSIVE GRID =================
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerPage(isDarkMode: _isDarkMode, onThemeChange: _toggleTheme),

      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              context.watch<ThemeNotifier>().themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeNotifier>().toggleTheme();
            },
          ),
          IconButton(
            tooltip: 'Projects',
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.projects);
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          //  PROJECTS GRID
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return ErrorState(message: snapshot.error.toString());
                }

                // Empty
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyState();
                }

                final projects = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery);
                }).toList();

                if (projects.isEmpty) {
                  return const EmptyState(
                    message: 'No matching projects found',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    itemCount: projects.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                    ),
                    itemBuilder: (context, index) {
                      final project =
                          projects[index].data() as Map<String, dynamic>;

                      return ProjectCard(
                        title: project['title'] ?? 'Untitled',
                        description: project['description'] ?? '',
                        icon: Icons.dashboard,
                        projectUrl: project['url'],
                        color: Colors.blueAccent,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Opening ${project['title'] ?? 'Project'}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
