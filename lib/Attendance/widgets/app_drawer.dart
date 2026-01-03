import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_webside/main.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';
import 'package:provider/provider.dart';

class DrawerPage extends StatefulWidget {
  final Function(bool) onThemeChange;
  final bool isDarkMode;

  const DrawerPage({
    super.key,
    required this.onThemeChange,
    required this.isDarkMode,
  });

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ================= NAVIGATION =================
  void _navigate(String route) {
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.attendanceLogin,
        (route) => false,
      );
    }
  }

  bool _isAdminOrTeacher(String role) => role == 'admin' || role == 'teacher';

  // ================= MENU TILE =================
  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Drawer(child: Center(child: Text("Not logged in")));
    }

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _errorDrawer(context);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String name = data['name'] ?? 'User';
          final String email = data['email'] ?? user.email ?? '';
          final String role = data['role'] ?? 'guest';
          final String? photoUrl = data['userPhotoUrl'];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // ================= HEADER =================
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                otherAccountsPictures: [
                  Chip(
                    label: Text(
                      role.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),

              // ================= ADMIN / TEACHER =================
              if (_isAdminOrTeacher(role)) ...[
                _menuTile(
                  icon: Icons.dashboard,
                  title: 'Teacher Dashboard',
                  onTap: () => _navigate(AppRoutes.teacherDashboard),
                ),
                _menuTile(
                  icon: Icons.people,
                  title: 'Upload Students',
                  onTap: () => _navigate(AppRoutes.uploadStudents),
                ),
                _menuTile(
                  icon: Icons.check_circle,
                  title: 'Mark Attendance',
                  onTap: () => _navigate(AppRoutes.markAttendance),
                ),
                _menuTile(
                  icon: Icons.upload_file,
                  title: 'Upload Marks',
                  onTap: () => _navigate(AppRoutes.uploadMarks),
                ),
                _menuTile(
                  icon: Icons.picture_as_pdf,
                  title: 'Generate Report',
                  onTap: () => _navigate(AppRoutes.generateReport),
                ),
                const Divider(),
              ],

              // ================= STUDENT =================
              if (role == 'student' || role == 'admin') ...[
                _menuTile(
                  icon: Icons.school,
                  title: 'Student Dashboard',
                  onTap: () => _navigate(AppRoutes.studentDashboard),
                ),
                _menuTile(
                  icon: Icons.bar_chart,
                  title: 'Attendance Report',
                  onTap: () => _navigate(AppRoutes.studentReport),
                ),
                _menuTile(
                  icon: Icons.assignment,
                  title: 'Marks Report',
                  onTap: () => _navigate(AppRoutes.studentReport),
                ),
                const Divider(),
              ],

              // ================= COMMON =================
              _menuTile(
                icon: Icons.workspaces_outline,
                title: 'Portfolio Dashboard',
                onTap: () => _navigate(AppRoutes.dashboard),
              ),

              const Divider(),

              // ================= SETTINGS =================
              SwitchListTile(
                secondary: Icon(
                  context.watch<ThemeNotifier>().themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: const Text('Dark Mode'),
                value:
                    context.watch<ThemeNotifier>().themeMode == ThemeMode.dark,
                onChanged: (value) {
                  widget.onThemeChange(value);
                  context.read<ThemeNotifier>().toggleTheme();
                },
              ),

              _menuTile(icon: Icons.logout, title: 'Logout', onTap: _logout),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  '© 2025 Rahul Portfolio',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  // ================= ERROR DRAWER =================
  Widget _errorDrawer(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile load failed. Redirecting...')),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.notFound,
        (route) => false,
      );
    });

    return const Center(child: CircularProgressIndicator());
  }
}
