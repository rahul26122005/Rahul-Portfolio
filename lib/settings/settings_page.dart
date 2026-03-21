import 'package:flutter/material.dart';
import 'settings_controller.dart';
import 'settings_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsController controller = SettingsController();

  bool isDarkMode = false;
  String role = "";
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final r = await controller.getUserRole();
    final profile = await controller.getUserProfile();

    if (!mounted) return;

    setState(() {
      role = r ?? "guest";
      userData = profile;
      isDarkMode = profile?['darkMode'] ?? false;
    });
  }

  void _toggleTheme(bool value) async {
    setState(() => isDarkMode = value);
    await controller.updateTheme(value);
  }

  void _logout() async {
    await controller.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/attendance/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // ================= PROFILE =================
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(userData?['name'] ?? "User"),
            subtitle: Text(role.toUpperCase()),
          ),

          const Divider(),

          // ================= COMMON =================
          SettingsTile(
            title: "Dark Mode",
            icon: Icons.dark_mode,
            trailing: Switch(value: isDarkMode, onChanged: _toggleTheme),
          ),

          SettingsTile(
            title: "Edit Profile",
            icon: Icons.edit,
            onTap: () {
              // Navigate later
            },
          ),

          SettingsTile(
            title: "Change Password",
            icon: Icons.lock,
            onTap: () {
              // Add reset logic
            },
          ),

          const Divider(),

          // ================= ROLE BASED =================
          if (role == "admin") ..._adminSettings(),

          if (role == "teacher") ..._teacherSettings(),

          if (role == "student") ..._studentSettings(),

          const Divider(),

          // ================= LOGOUT =================
          SettingsTile(title: "Logout", icon: Icons.logout, onTap: _logout),
        ],
      ),
    );
  }

  // ================= ADMIN =================
  List<Widget> _adminSettings() {
    return [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          "Admin Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      SettingsTile(title: "Manage Users", icon: Icons.people, onTap: () {}),
      SettingsTile(
        title: "System Analytics",
        icon: Icons.analytics,
        onTap: () {},
      ),
    ];
  }

  // ================= TEACHER =================
  List<Widget> _teacherSettings() {
    return [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          "Teacher Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      SettingsTile(title: "My Classes", icon: Icons.class_, onTap: () {}),
      SettingsTile(
        title: "Attendance Preferences",
        icon: Icons.check_circle,
        onTap: () {},
      ),
    ];
  }

  // ================= STUDENT =================
  List<Widget> _studentSettings() {
    return [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          "Student Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      SettingsTile(
        title: "My Attendance",
        icon: Icons.assignment,
        onTap: () {},
      ),
      SettingsTile(title: "Marks", icon: Icons.grade, onTap: () {}),
    ];
  }
}
