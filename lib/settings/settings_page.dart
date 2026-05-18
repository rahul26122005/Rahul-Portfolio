import 'package:flutter/material.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/zoomable_scaffold.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import 'settings_tile.dart';
import 'package:my_flutter_webside/main.dart';

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
    context.read<ThemeNotifier>().toggleTheme();
    await controller.updateTheme(value);
  }

  void _logout() async {
    await controller.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/attendance/login");
  }

  @override
  Widget build(BuildContext context) {
    return ZoomableScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
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
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      endDrawer: DrawerPage(
        isDarkMode: isDarkMode,
        onThemeChange: _toggleTheme,
      ),
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
            trailing: Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, _) {
                return Switch(
                  value: themeNotifier.themeMode == ThemeMode.dark,
                  onChanged: _toggleTheme,
                );
              },
            ),
          ),

          SettingsTile(title: "Edit Profile", icon: Icons.edit, onTap: () {}),

          SettingsTile(
            title: "Change Password",
            icon: Icons.lock,
            onTap: () {
              Navigator.pushNamed(context, "/attendance/forgot_password");
            },
          ),

          const Divider(),

          // ================= ROLE BASED =================
          if (role == "admin") ..._adminSettings(),

          if (role == "teacher" || role == "admin") ..._teacherSettings(),

          if (role == "student" || role == "admin") ..._studentSettings(),

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
