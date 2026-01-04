import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';
import 'Attendance/widgets/app_drawer.dart';

class NotFoundPage extends StatefulWidget {
  const NotFoundPage({super.key});

  @override
  State<NotFoundPage> createState() => _NotFoundPageState();
}

class _NotFoundPageState extends State<NotFoundPage> {
  final _auth = FirebaseAuth.instance;
  bool _isDarkMode = true;

  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerPage(isDarkMode: _isDarkMode, onThemeChange: _toggleTheme),
      appBar: AppBar(
        title: const Text('Page Not Found'),
        actions: [
          IconButton(
            tooltip: "teacher Dashboard",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.teacherDashboard);
            },
            icon: Icon(Icons.dashboard),
          ),
          IconButton(
            tooltip: "Student Dashboard",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.studentDashboard);
            },
            icon: Icon(Icons.school),
          ),
          IconButton(
            tooltip: "Portfolio Dashboard",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.dashboard);
            },
            icon: Icon(Icons.workspaces),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          const Center(
            child: Text(
              '404 - The page you are looking for does not exist.',
              style: TextStyle(fontSize: 18),
            ),
          ),

          Center(
            child: Text(
              'Failed to load profile.\nPlease contact admin.\n G-mail: biomed.rahulr1201@gmail.com',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.attendanceLogin,
        (route) => false,
      );
    }
  }
}
