import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '/routes/app_routes.dart';
import '/Attendance/widgets/dashbordcard.dart';

//import '../screens/student_report_page.dart';
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
      bool _isDarkMode = true;

  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
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
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/student_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fade,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome ",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Student Dashboard",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 30),

                            /// Attendance Card
                            DashboardCard(
                              title: "Attendance Report",
                              subtitle: "Monthly & Daily attendance",
                              image: 'assets/images/attendance_icon.png',
                              color: Colors.green,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.studentReport,
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            ///  Marks Card
                            DashboardCard(
                              title: "Exam Marks",
                              subtitle: "Internal & University exams",
                              image: 'assets/images/attendance_icon.png',
                              color: Colors.orange,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Marks module coming soon"),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
           
    );
  }
}
