import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';

class StudentReportPage extends StatefulWidget {
  const StudentReportPage({super.key});

  @override
  State<StudentReportPage> createState() => _StudentReportPageState();
}

class _StudentReportPageState extends State<StudentReportPage>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = true;
  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  late final AnimationController _controller;
  late final Animation<double> _fade;

  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance Management System",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.white,
            fontFeatures: [FontFeature.enable('smcp')],
            fontStyle: FontStyle.italic,

            shadows: [
              Shadow(offset: Offset(2, 2), blurRadius: 10, color: Colors.black),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1E3C72),
      ),
      drawer: DrawerPage(isDarkMode: _isDarkMode, onThemeChange: _toggleTheme),
      // appBar: AppBar(title: const Text("Attendance Report"), centerTitle: true),
      body: FadeTransition(
        opacity: _fade,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const Center(child: Text("User record not found"));
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final String? registerNo = userData['registerNo'] as String?;
            if (registerNo == null || registerNo.isEmpty) {
              return const Center(
                child: Text("Register number not linked to this account"),
              );
            }

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .where('registerNo', isEqualTo: registerNo)
                  .get(),
              builder: (context, stuSnap) {
                if (stuSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!stuSnap.hasData || stuSnap.data!.docs.isEmpty) {
                  return const Center(child: Text("Student profile not found"));
                }

                final student = stuSnap.data!.docs.first;
                final studentData = student.data() as Map<String, dynamic>;

                final String classId = studentData['class'];
                final String sectionId = studentData['section'];

                final String attendanceDocId =
                    "${classId}-$sectionId"; // ignore: unnecessary_brace_in_string_interps

                return Column(
                  children: [
                    _studentHeader(studentData),

                    /// 📅 MONTH SELECTOR
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: selectedMonth,
                            items: _last6Months()
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(_formatMonth(m)),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedMonth = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    /// 📊 ATTENDANCE
                    Expanded(
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('attendance')
                            .doc(attendanceDocId)
                            .collection(selectedMonth)
                            .get(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snap.hasData || snap.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                "No attendance data",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          int total = snap.data!.docs.length;
                          int present = 0;

                          final rows = snap.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final records =
                                data['records'] as Map<String, dynamic>? ?? {};

                            final bool isPresent = records[registerNo] == true;

                            if (isPresent) present++;

                            return ListTile(
                              leading: Icon(
                                isPresent ? Icons.check_circle : Icons.cancel,
                                color: isPresent ? Colors.green : Colors.red,
                              ),
                              title: Text(doc.id),
                              trailing: Text(
                                isPresent ? "Present" : "Absent",
                                style: TextStyle(
                                  color: isPresent ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          }).toList();

                          return Column(
                            children: [
                              _summary(total, present),
                              Expanded(child: ListView(children: rows)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 👤 STUDENT HEADER
  Widget _studentHeader(Map<String, dynamic> s) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Register No: ${s['registerNo']}"),
            Text("Class: ${s['class']}"),
            Text("Section: ${s['section']}"),
          ],
        ),
      ),
    );
  }

  /// 📈 SUMMARY
  Widget _summary(int total, int present) {
    final absent = total - present;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _summaryCard("Total", total, Colors.blue),
          _summaryCard("Present", present, Colors.green),
          _summaryCard("Absent", absent, Colors.red),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    return DateFormat('MMMM yyyy').format(date);
  }

  List<String> _last6Months() {
    final now = DateTime.now();
    return List.generate(
      6,
      (i) => DateFormat('yyyy-MM').format(DateTime(now.year, now.month - i)),
    );
  }
}
