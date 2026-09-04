import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';
//import 'package:my_flutter_webside/services/sms_services.dart';

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

  Future<void> _submitAttendance(List<QueryDocumentSnapshot> students) async {
    setState(() => isSubmitting = true);

    try {
      final classSectionId = "$selectedClass-$selectedSection";
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final docRef = _db
          .collection('attendance')
          .doc(classSectionId)
          .collection(month)
          .doc(date);

      // Check if attendance already exists (Edit mode)
      final docSnap = await docRef.get();
      final bool isEditMode = docSnap.exists;

      /// ---------------- VALIDATION ----------------
      if (!isEditMode) {
        //  FIRST TIME SUBMISSION → MUST MARK ALL
        if (!_isValid(students.length)) {
          _showMsg("Please mark attendance for all students", error: true);
          setState(() => isSubmitting = false);
          return;
        }
      }

      /// ---------------- BUILD RECORDS ----------------
      final Map<String, String> newRecords = {};

      for (final s in students) {
        final regNo = s['registerNo'].toString();

        // Only take marked values during edit
        if (attendanceState.containsKey(regNo) &&
            attendanceState[regNo] != null) {
          newRecords[regNo] = attendanceState[regNo]!;
        }
      }

      /// ---------------- MERGE WITH OLD DATA ----------------
      Map<String, String> finalRecords = {};

      if (isEditMode) {
        //  Edit Mode → merge old + new
        final oldRecords = Map<String, String>.from(docSnap['records'] ?? {});
        finalRecords = {...oldRecords, ...newRecords};
      } else {
        // New submission
        finalRecords = newRecords;
      }

      /// ---------------- SAVE TO FIRESTORE ----------------
      await docRef.set({
        'class': selectedClass,
        'section': selectedSection,
        'records': finalRecords,
        'submittedBy': uid,
        'submittedAt': FieldValue.serverTimestamp(),
        'isEdited': isEditMode,
      }, SetOptions(merge: true));

      ///  Send SMS only for ABSENT students
      // for (final s in students) {
      //   final regNo = s['registerNo'].toString();

      //   if (attendanceState[regNo] == "A") {
      //     final mobile = s['fatherMobile']?.toString().trim();

      //     // Validate mobile number
      //     if (mobile == null || mobile.length != 10) {
      //       debugPrint("Invalid mobile for $regNo");
      //       continue;
      //     }

      //     try {
      //       await SmsService.sendAbsentSMS(
      //         mobile: mobile,
      //         studentName: s['name'].toString(),
      //         date: date,
      //       );
      //     } catch (e) {
      //       //  Never break attendance submission
      //       _showMsg(" SMS failed for $regNo : $e", error: true);
      //     }
      //   }
      // }

      _showMsg(
        isEditMode
            ? "Attendance updated successfully"
            : "Attendance submitted successfully",
      );
    } catch (e) {
      _showMsg("Submission failed: $e", error: true);
    }

    setState(() => isSubmitting = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, AppRoutes.teacherDashboard);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
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
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.teacherDashboard);
            },
            icon: Icon(Icons.home, color: Colors.white),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),

      body: Column(
        children: [
          _header(),
          const SizedBox(height: 20),
          _classSectionSelector(),
          Expanded(child: _studentList()),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: const [
        Icon(Icons.check_circle, size: 40, color: Colors.cyan),
        SizedBox(width: 10),
        Text(
          "Mark Attendance",
          style: TextStyle(
            color: Colors.cyan,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
          .orderBy('registerNo')
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
                                    // ignore: deprecated_member_use
                                    groupValue: attendanceState[regNo],
                                    // ignore: deprecated_member_use
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
