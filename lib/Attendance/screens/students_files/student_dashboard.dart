import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/zoomable_scaffold.dart';
import 'package:my_flutter_webside/Attendance/widgets/dashbordcard.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';

//import '../screens/student_report_page.dart';
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = true;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return ZoomableScaffold(
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
              "Attendance Management System",
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/student_bg.jpg', fit: BoxFit.cover),
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
                    _header(),
                    const SizedBox(height: 30),
                    FutureBuilder<String>(
                      future: _firestore
                          .collection('users')
                          .doc(user?.uid)
                          .get()
                          .then((doc) {
                            if (doc.exists) {
                              return doc['name'] ?? 'Student';
                            } else {
                              return 'Student';
                            }
                          }),
                      builder: (context, snapshot) {
                        String displayName = snapshot.data ?? 'Student';
                        return AnimatedOpacity(
                          opacity:
                              snapshot.connectionState == ConnectionState.done
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            "Welcome $displayName",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),

                    /// Attendance Card
                    DashboardCard(
                      title: "Attendance Report",
                      subtitle: "Monthly & Daily attendance",
                      image: 'assets/images/attendance_icon.png',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.studentReport);
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
                        Navigator.pushNamed(context, AppRoutes.studentMark);
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

  // HEADER
  Widget _header() {
    return Row(
      children: const [
        Icon(Icons.cabin_outlined, size: 40, color: Colors.cyan),
        SizedBox(width: 10),
        Text(
          "Student Dashboard",
          style: TextStyle(
            color: Colors.cyan,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
