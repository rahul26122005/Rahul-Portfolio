import 'package:flutter/material.dart';
import 'package:my_flutter_webside/admin/manage_attendance_page.dart';
import 'package:my_flutter_webside/settings/settings_page.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_classes_page.dart';
import 'manage_teachers_page.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isDarkMode = true;

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: Icon(Icons.menu, color: Colors.white),
              iconSize: 22,
            ),
          ),
        ],
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Text(
              "AMS-Admin Panel",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: constraints.maxWidth < 600 ? 18 : 24,
                color: Colors.white,
                fontFeatures: const [FontFeature.enable('swap')],
                fontStyle: FontStyle.italic,
                shadows: const [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 10,
                    color: Colors.black,
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF1E3C72),
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _adminTile(
            icon: Icons.class_,
            title: "Manage Classes & Sections",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageStudentsPage()),
            ),
          ),
          _adminTile(
            icon: Icons.people,
            title: "Manage Teachers",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageUsersPage()),
            ),
          ),
          _adminTile(
            icon: Icons.people,
            title: "Manage Attendance",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageAttendancePage()),
            ),
          ),

          _adminTile(
            icon: Icons.people,
            title: "Settings",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
