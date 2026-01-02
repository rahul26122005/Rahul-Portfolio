import 'package:flutter/material.dart';
import '../../../admin/admin_panel.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';

class TeacherDashboard extends StatefulWidget {
  final String role; // teacher / admin
  const TeacherDashboard({super.key, required this.role});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = true;

  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  String? selectedClass;
  String? selectedSection;

  List<String> classes = [];
  List<String> sections = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnm;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnm = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    //_controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
              appBar: AppBar(
                title: const Text(
                  "Attendance Management System",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.white,
                    fontFeatures: [FontFeature.enable('swap')],
                    fontStyle: FontStyle.italic,

                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 10,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                backgroundColor: Color(0xFF1E3C72),
              ),
              drawer: DrawerPage(isDarkMode: _isDarkMode, onThemeChange: _toggleTheme),
              body: FadeTransition(
                opacity: _fadeAnm,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _header(),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          Expanded(child: _dashboardGrid()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),


    );


  }

  // HEADER
  Widget _header() {
    return Row(
      children: const [
        Icon(Icons.school, size: 40, color: Colors.white),
        SizedBox(width: 10),
        Text(
          "Teacher Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // GRID MENU
  Widget _dashboardGrid() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _dashboardCard(
          icon: Icons.upload_file,
          title: "Upload Students",
          color: Colors.deepPurple,
          onTap: () => Navigator.pushNamed(context, AppRoutes.uploadStudents),
        ),
        _dashboardCard(
          icon: Icons.check_circle,
          title: "Mark Attendance",
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, AppRoutes.markAttendance),
        ),
        _dashboardCard(
          icon: Icons.assignment,
          title: "Upload Marks",
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.uploadMarks),
        ),
        _dashboardCard(
          icon: Icons.bar_chart,
          title: "generate Report",
          color: Colors.pink,
          onTap: () => Navigator.pushNamed(context, AppRoutes.generateReport),
        ),
        _dashboardCard(
          icon: Icons.bar_chart,
          title: "Monthly Summary",
          color: Colors.teal,
          onTap: () => Navigator.pushNamed(context, AppRoutes.monthlysummary),
        ),
        if (widget.role == "admin")
          _dashboardCard(
            icon: Icons.admin_panel_settings,
            title: "Admin Panel",
            color: Colors.redAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPanel()),
            ),
          ),
      ],
    );
  }

  // CARD
  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
