import 'package:flutter/material.dart';
import 'Attendance/widgets/app_drawer.dart';

class NotFoundPage extends StatefulWidget {
  const NotFoundPage({super.key});

  @override
  State<NotFoundPage> createState() => _NotFoundPageState();
}

class _NotFoundPageState extends State<NotFoundPage> {
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
      appBar: AppBar(title: const Text('Page Not Found')),
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
              'Failed to load profile.\nPlease contact admin.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
