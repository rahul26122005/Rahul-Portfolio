import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_flutter_webside/main.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';

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

class _DrawerPageState extends State<DrawerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================= NAVIGATION HELPER =================
  void _navigate(String route) {
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  // ================= MENU TILE =================
  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      horizontalTitleGap: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person, size: 32),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'My portfolio & Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Unified Dashboard',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ================= DASHBOARD =================
              _menuTile(
                icon: Icons.dashboard,
                title: 'Dashboard',
                onTap: () => _navigate(AppRoutes.dashboard),
              ),

              _menuTile(
                icon: Icons.folder,
                title: 'Projects',
                onTap: () => _navigate(AppRoutes.projects),
              ),

              _menuTile(
                icon: Icons.assignment,
                title: 'Attendance',
                onTap: () => _navigate(AppRoutes.attendanceLogin),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),

              // ================= SETTINGS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

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

              _menuTile(
                icon: Icons.settings,
                title: 'App Settings',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  );
                },
              ),

              const Spacer(),

              const Divider(),

              // ================= FOOTER =================
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    '© 2025 Rahul Portfolio',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
