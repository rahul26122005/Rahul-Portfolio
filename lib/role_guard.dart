//route guard.dart(Page)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/zoomable_scaffold.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';
import 'Attendance/auth_screens/login_screen.dart';

class RoleGuard extends StatefulWidget {
  final List<String> allowedRoles;
  final Widget child;

  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isDarkMode = true;

    // ================= THEME =================
    void toggleTheme(bool value) {
      if (!mounted) return;
      setState(() => isDarkMode = value);
    }

    //  Not logged in
    if (user == null) {
      return LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("User profile not found")),
          );
        }

        final role = (snapshot.data!.data() as Map<String, dynamic>)['role'];

        // Authorized
        if (widget.allowedRoles.contains(role)) {
          return widget.child;
        }

        // Unauthorized
        return ZoomableScaffold(
          drawer: DrawerPage(
            isDarkMode: isDarkMode,
            onThemeChange: toggleTheme,
          ),
          appBar: AppBar(
            title: const Text('Page Not Found'),
            actions: [
              IconButton(
                tooltip: "teacher Dashboard",
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.teacherDashboard);
                },
                icon: const Icon(Icons.dashboard),
              ),
              IconButton(
                tooltip: "Student Dashboard",
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.studentDashboard);
                },
                icon: const Icon(Icons.school),
              ),
              IconButton(
                tooltip: "Portfolio Dashboard",
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.dashboard);
                },
                icon: const Icon(Icons.workspaces),
              ),
              IconButton(
                tooltip: "Logout",
                onPressed: () => logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: const Center(
            child: Text(
              "Access Denied",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.attendanceLogin,
      (route) => false,
    );
  }
}
