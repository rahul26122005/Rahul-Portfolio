import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/app_drawer.dart';
//import '/services/sms_services.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isDarkMode = true;


  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  String? selectedClass;
  String? selectedSection;

  /// registerNo -> P | A | OD | HD
  final Map<String, String?> attendanceState = {};

  bool isSubmitting = false;

  late final String month;
  late final String date;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateFormat('yyyy-MM').format(now);
    date = DateFormat('yyyy-MM-dd').format(now);
  }

  // ================= MESSAGE =================
  void _showMsg(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // ================= VALIDATION =================
  bool _isValid(int totalStudents) {
    return attendanceState.length == totalStudents &&
        attendanceState.values.every((v) => v != null);
  }

  // ================= SUBMIT =================
  Future<void> _submitAttendance(List<QueryDocumentSnapshot> students) async {
    try {
      if (!_isValid(students.length)) {
        _showMsg("Please mark attendance for all students", error: true);
        return;
      }
    } catch (e) {
      _showMsg("Error: $e", error: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final classSectionId = "$selectedClass-$selectedSection";
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final Map<String, String> records = {};

      for (final s in students) {
        final regNo = s['registerNo'].toString();
        records[regNo] = attendanceState[regNo]!;
      }

      await _db
          .collection('attendance')
          .doc(classSectionId)
          .collection(month)
          .doc(date)
          .set({
            'class': selectedClass,
            'section': selectedSection,
            'records': records,
            'submittedBy': uid,
            'submittedAt': FieldValue.serverTimestamp(),
          });

      /// Send SMS only for ABSENT
      /*for (final s in students) {
        final regNo = s['registerNo'].toString();
        if (attendanceState[regNo] == "A") {
          await SmsService.sendAbsentSMS(
            mobile: s['fatherMobile'],
            studentName: s['name'],
            date: date,
          );
        }
      }*/

      _showMsg("Attendance saved successfully");
    } catch (e) {
      _showMsg("Submission failed $e", error: true);
    }

    setState(() => isSubmitting = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
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
      // appBar: AppBar(title: const Text("Mark Attendance")),
      body: Column(
        children: [
          _classSectionSelector(),
          Expanded(child: _studentList()),
        ],
      ),
    );
  }

  // ================= CLASS & SECTION =================
  Widget _classSectionSelector() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// CLASS
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('students').snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();

                final classes =
                    snap.data!.docs
                        .map((d) => d['class'].toString())
                        .toSet()
                        .toList()
                      ..sort();

                return DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: "Class"),
                  items: classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text("Class $c")),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedClass = v;
                      selectedSection = null;
                      attendanceState.clear();
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            /// SECTION
            if (selectedClass != null)
              StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('students')
                    .where('class', isEqualTo: selectedClass)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();

                  final sections =
                      snap.data!.docs
                          .map((d) => d['section'].toString())
                          .toSet()
                          .toList()
                        ..sort();

                  return DropdownButtonFormField<String>(
                    initialValue: selectedSection,
                    decoration: const InputDecoration(labelText: "Section"),
                    items: sections
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text("Section $s"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSection = v;
                        attendanceState.clear();
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ================= STUDENT LIST =================
  Widget _studentList() {
    if (selectedClass == null || selectedSection == null) {
      return const Center(child: Text("Select Class & Section"));
    }

    return FutureBuilder<QuerySnapshot>(
      future: _db
          .collection('students')
          .where('class', isEqualTo: selectedClass)
          .where('section', isEqualTo: selectedSection)
          .get(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snap.data!.docs;

        if (students.isEmpty) {
          return const Center(child: Text("No students found"));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  final regNo = s['registerNo'].toString();

                  attendanceState.putIfAbsent(regNo, () => null);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Reg No: $regNo"),

                          const SizedBox(height: 6),

                          /// RADIO BUTTONS
                          Wrap(
                            spacing: 10,
                            children: ["P", "A", "OD", "HD"].map((status) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: status,
                                    groupValue: attendanceState[regNo],
                                    onChanged: (v) {
                                      setState(() {
                                        attendanceState[regNo] = v;
                                      });
                                    },
                                  ),
                                  Text(
                                    status == "P"
                                        ? "Present"
                                        : status == "A"
                                        ? "Absent"
                                        : status == "OD"
                                        ? "On Duty"
                                        : "Half Day",
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// SUBMIT
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () => _submitAttendance(students),
                child: isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text("Submit Attendance"),
              ),
            ),
          ],
        );
      },
    );
  }
}
