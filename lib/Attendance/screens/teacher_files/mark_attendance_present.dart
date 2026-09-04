import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';

class ManageAttendancePageAbsent extends StatefulWidget {
  const ManageAttendancePageAbsent({super.key});

  @override
  State<ManageAttendancePageAbsent> createState() =>
      _ManageAttendancePageAbsentState();
}

class _ManageAttendancePageAbsentState
    extends State<ManageAttendancePageAbsent> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ============================================================
  // THEME
  // ============================================================

  bool _isDarkMode = true;

  void _toggleTheme(bool value) {
    if (!mounted) return;

    setState(() {
      _isDarkMode = value;
    });
  }

  // ============================================================
  // SELECTION
  // ============================================================

  String? selectedClass;
  String? selectedSection;
  DateTime? selectedDate;

  List<String> classes = [];
  List<String> sections = [];

  // ============================================================
  // STUDENTS
  // ============================================================

  List<Map<String, dynamic>> students = [];

  // ============================================================
  // ATTENDANCE
  //
  // registerNo -> P / A / OD / HD / ""
  //
  // IMPORTANT:
  // Empty/null means the teacher has NOT marked an exception.
  // During submission, empty values automatically become P.
  // ============================================================

  final Map<String, String?> attendanceState = {};

  // ============================================================
  // EXISTING ATTENDANCE
  // ============================================================

  bool attendanceExists = false;

  // ============================================================
  // SUBMISSION
  // ============================================================

  bool isSubmitting = false;

  // ============================================================
  // STATUS FILTER
  // ============================================================

  String selectedStatusFilter = "All";

  // ============================================================
  // STATISTICS
  // ============================================================

  int present = 0;
  int absent = 0;
  int od = 0;
  int hd = 0;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController searchCtrl = TextEditingController();

  // ============================================================
  // FILTERED STUDENTS
  // ============================================================

  List<Map<String, dynamic>> get filteredStudents {
    Iterable<Map<String, dynamic>> result = students;

    // SEARCH
    final search = searchCtrl.text.trim().toLowerCase();

    if (search.isNotEmpty) {
      result = result.where((student) {
        final name = student['name'].toString().toLowerCase();
        final regNo = student['registerNo'].toString().toLowerCase();

        return name.contains(search) || regNo.contains(search);
      });
    }

    // STATUS FILTER
    if (selectedStatusFilter != "All") {
      result = result.where((student) {
        final regNo = student['registerNo'].toString();

        final status = attendanceState[regNo];

        return status == selectedStatusFilter;
      });
    }

    return result.toList();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadClasses();

    searchCtrl.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMsg(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  void showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> loadClasses() async {
    try {
      final snap = await db.collection("students").get();

      final set = <String>{};

      for (final doc in snap.docs) {
        final value = doc.data()["class"];

        if (value != null) {
          set.add(value.toString());
        }
      }

      if (!mounted) return;

      setState(() {
        classes = set.toList()..sort();
      });
    } catch (e) {
      showError("Failed loading classes\n$e");
    }
  }

  // ============================================================
  // LOAD SECTIONS
  // ============================================================

  Future<void> loadSections(String className) async {
    try {
      final snap = await db
          .collection("students")
          .where("class", isEqualTo: className)
          .get();

      final set = <String>{};

      for (final doc in snap.docs) {
        final value = doc.data()["section"];

        if (value != null) {
          set.add(value.toString());
        }
      }

      if (!mounted) return;

      setState(() {
        sections = set.toList()..sort();
      });
    } catch (e) {
      showError("Failed loading sections\n$e");
    }
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

  Future<void> loadStudents() async {
    if (selectedClass == null || selectedSection == null) {
      return;
    }

    try {
      final snap = await db
          .collection("students")
          .where("class", isEqualTo: selectedClass)
          .where("section", isEqualTo: selectedSection)
          .orderBy("registerNo")
          .get();

      final loadedStudents = snap.docs.map((doc) {
        final data = doc.data();

        return {"name": data["name"], "registerNo": data["registerNo"]};
      }).toList();

      if (!mounted) return;

      setState(() {
        students = loadedStudents;

        // Initialize only missing students.
        for (final student in students) {
          final regNo = student["registerNo"].toString();

          attendanceState.putIfAbsent(regNo, () => null);
        }
      });
    } catch (e) {
      showError("Failed loading students\n$e");
    }
  }

  // ============================================================
  // PICK DATE
  // ============================================================

  Future<void> pickDate() async {
    if (selectedClass == null || selectedSection == null) {
      showError("Select Class & Section first");
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2050),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;

      attendanceState.clear();

      attendanceExists = false;

      present = 0;
      absent = 0;
      od = 0;
      hd = 0;
    });

    await loadStudents();
    await loadAttendance();
  }

  // ============================================================
  // LOAD EXISTING ATTENDANCE
  // ============================================================

  Future<void> loadAttendance() async {
    if (selectedDate == null ||
        selectedClass == null ||
        selectedSection == null) {
      return;
    }

    try {
      final classSection = "$selectedClass-$selectedSection";

      final monthKey = DateFormat("yyyy-MM").format(selectedDate!);

      final dateKey = DateFormat("yyyy-MM-dd").format(selectedDate!);

      final doc = await db
          .collection("attendance")
          .doc(classSection)
          .collection(monthKey)
          .doc(dateKey)
          .get();

      final Map<String, dynamic> attendanceMap = {};

      if (doc.exists) {
        final rawRecords = doc.data()?["records"];

        if (rawRecords is Map) {
          attendanceMap.addAll(Map<String, dynamic>.from(rawRecords));
        }
      }

      final Map<String, String?> ordered = {};

      for (final student in students) {
        final regNo = student["registerNo"].toString();

        final existingStatus = attendanceMap[regNo]?.toString();

        if (existingStatus == "P" ||
            existingStatus == "A" ||
            existingStatus == "OD" ||
            existingStatus == "HD") {
          ordered[regNo] = existingStatus;
        } else {
          ordered[regNo] = null;
        }
      }

      if (!mounted) return;

      setState(() {
        attendanceExists = doc.exists;

        attendanceState
          ..clear()
          ..addAll(ordered);

        selectedStatusFilter = "All";

        calculateStats();
      });
    } catch (e) {
      showError("Failed loading attendance\n$e");
    }
  }

  // ============================================================
  // CALCULATE STATS
  // ============================================================

  void calculateStats() {
    present = 0;
    absent = 0;
    od = 0;
    hd = 0;

    for (final student in students) {
      final regNo = student["registerNo"].toString();

      final status = attendanceState[regNo];

      if (status == "P") {
        present++;
      } else if (status == "A") {
        absent++;
      } else if (status == "OD") {
        od++;
      } else if (status == "HD") {
        hd++;
      }
    }
  }

  // ============================================================
  // SET STATUS
  // ============================================================

  void setAttendanceStatus(String regNo, String? status) {
    setState(() {
      attendanceState[regNo] = status;

      calculateStats();
    });
  }

  // ============================================================
  // SUBMIT ATTENDANCE
  //
  // CORE LOGIC
  //
  // If:
  //
  // 1 -> A
  // 2 -> A
  // 5 -> A
  //
  // Every other student automatically becomes P.
  //
  // If:
  //
  // 2 -> A
  // 40 -> A
  // 4 -> OD
  // 58 -> OD
  // 32 -> HD
  //
  // Everyone else -> P.
  // ============================================================

  Future<void> submitAttendance() async {
    if (selectedClass == null || selectedSection == null) {
      _showMsg("Please select Class and Section", error: true);
      return;
    }

    if (selectedDate == null) {
      _showMsg("Please select the attendance date", error: true);
      return;
    }

    if (students.isEmpty) {
      _showMsg("No students found", error: true);
      return;
    }

    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final classSectionId = "$selectedClass-$selectedSection";

      final monthKey = DateFormat("yyyy-MM").format(selectedDate!);

      final dateKey = DateFormat("yyyy-MM-dd").format(selectedDate!);

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        _showMsg("User is not logged in", error: true);

        setState(() {
          isSubmitting = false;
        });

        return;
      }

      final docRef = db
          .collection("attendance")
          .doc(classSectionId)
          .collection(monthKey)
          .doc(dateKey);

      // ========================================================
      // CHECK EXISTING ATTENDANCE
      // ========================================================

      final docSnap = await docRef.get();

      final bool isEditMode = docSnap.exists;

      // ========================================================
      // BUILD NEW RECORDS
      //
      // IMPORTANT:
      //
      // Explicit P/A/OD/HD -> use selected status.
      //
      // Null -> P.
      //
      // Therefore teacher only needs to mark exceptions.
      // ========================================================

      final Map<String, String> newRecords = {};

      for (final student in students) {
        final regNo = student["registerNo"].toString();

        final selectedStatus = attendanceState[regNo];

        if (selectedStatus == null || selectedStatus.isEmpty) {
          // UNMARKED = PRESENT
          newRecords[regNo] = "P";
        } else {
          // Explicit selection
          newRecords[regNo] = selectedStatus;
        }
      }

      // ========================================================
      // EXISTING RECORDS
      // ========================================================

      Map<String, String> finalRecords = {};

      if (isEditMode) {
        final rawOldRecords = docSnap.data()?["records"];

        if (rawOldRecords is Map) {
          final oldRecords = Map<String, String>.from(
            rawOldRecords.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          );

          // ----------------------------------------------------
          // EDIT MODE
          //
          // Existing data is preserved first.
          // New status selection overrides it.
          // ----------------------------------------------------

          finalRecords = {...oldRecords, ...newRecords};
        } else {
          finalRecords = newRecords;
        }
      } else {
        // ======================================================
        // FIRST SUBMISSION
        //
        // Every student receives a status.
        // Unmarked students become P.
        // ======================================================

        finalRecords = newRecords;
      }

      // ========================================================
      // SAVE TO FIRESTORE
      //
      // Same structure as mark_attendance.dart
      //
      // attendance
      //    └── Class-Section
      //         └── yyyy-MM
      //              └── yyyy-MM-dd
      //                   ├── class
      //                   ├── section
      //                   ├── records
      //                   ├── submittedBy
      //                   ├── submittedAt
      //                   └── isEdited
      // ========================================================

      await docRef.set({
        "class": selectedClass,
        "section": selectedSection,
        "records": finalRecords,
        "submittedBy": uid,
        "submittedAt": FieldValue.serverTimestamp(),
        "isEdited": isEditMode,
      }, SetOptions(merge: true));

      // ========================================================
      // UPDATE LOCAL STATE
      // ========================================================

      if (!mounted) return;

      setState(() {
        attendanceExists = true;

        attendanceState.clear();

        for (final student in students) {
          final regNo = student["registerNo"].toString();

          attendanceState[regNo] = finalRecords[regNo];
        }

        calculateStats();
      });

      // ========================================================
      // SUCCESS MESSAGE
      // ========================================================

      _showMsg(
        isEditMode
            ? "Attendance updated successfully"
            : "Attendance submitted successfully",
      );
    } catch (e) {
      _showMsg("Submission failed: $e", error: true);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAR ALL MARKINGS
  //
  // This does NOT submit.
  //
  // It simply clears teacher selections.
  //
  // When Submit is pressed after this:
  // every student becomes P.
  // ============================================================

  void clearMarkings() {
    setState(() {
      for (final student in students) {
        final regNo = student["registerNo"].toString();

        attendanceState[regNo] = null;
      }

      selectedStatusFilter = "All";

      calculateStats();
    });

    _showMsg("All manual markings cleared. Unmarked students will be Present.");
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: const [
          Icon(Icons.fact_check, size: 40, color: Colors.cyan),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Mark Attendance",
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTION FILTERS
  // ============================================================

  Widget _selectionFilters(bool isMobile) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selection Filters",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // ==================================================
                // CLASS
                // ==================================================
                SizedBox(
                  width: isMobile ? double.infinity : 180,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: const InputDecoration(
                      labelText: "Class",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedClass,
                    items: classes
                        .map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(
                                c,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedClass = value;
                        selectedSection = null;
                        selectedDate = null;
                        sections.clear();
                        students.clear();
                        attendanceState.clear();
                        attendanceExists = false;

                        present = 0;
                        absent = 0;
                        od = 0;
                        hd = 0;
                      });

                      if (value != null) {
                        await loadSections(value);
                      }
                    },
                  ),
                ),

                // ==================================================
                // SECTION
                // ==================================================
                SizedBox(
                  width: isMobile ? double.infinity : 180,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: const InputDecoration(
                      labelText: "Section",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedSection,
                    items: sections
                        .map((s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(
                                s,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: selectedClass == null
                        ? null
                        : (value) async {
                            setState(() {
                              selectedSection = value;
                              selectedDate = null;
                              students.clear();
                              attendanceState.clear();
                              attendanceExists = false;

                              present = 0;
                              absent = 0;
                              od = 0;
                              hd = 0;
                            });
                          },
                  ),
                ),

                // ==================================================
                // DATE
                // ==================================================
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    selectedDate == null
                        ? "Pick Date"
                        : DateFormat("yyyy-MM-dd").format(selectedDate!),
                  ),
                  onPressed: pickDate,
                ),

                // ==================================================
                // STATUS FILTER
                // ==================================================
                SizedBox(
                  width: isMobile ? double.infinity : 180,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedStatusFilter,
                    items: const [
                      DropdownMenuItem<String>(
                         value: "All",
                         child: Text("All", maxLines: 1, overflow: TextOverflow.ellipsis),
                       ),
                      DropdownMenuItem<String>(
                         value: "P",
                         child: Text("Present", maxLines: 1, overflow: TextOverflow.ellipsis),
                       ),
                      DropdownMenuItem<String>(
                         value: "A",
                         child: Text("Absent", maxLines: 1, overflow: TextOverflow.ellipsis),
                       ),
                      DropdownMenuItem<String>(
                         value: "OD",
                         child: Text("OD", maxLines: 1, overflow: TextOverflow.ellipsis),
                       ),
                      DropdownMenuItem<String>(
                         value: "HD",
                         child: Text("Half Day", maxLines: 1, overflow: TextOverflow.ellipsis),
                       ),
                    ],
                    onChanged: attendanceState.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedStatusFilter = value ?? "All";
                            });
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ======================================================
            // INFORMATION MESSAGE
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withAlpha(20),
                border: Border.all(color: Colors.blue.withAlpha(80)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Mark only students who are Absent, On Duty, or Half Day. "
                      "Students left unmarked will automatically be recorded as Present when you submit.",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchBox(bool isMobile) {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: searchCtrl,
        decoration: InputDecoration(
          labelText: "Search Student",
          hintText: "Search by name or register number",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    searchCtrl.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS RADIO
  // ============================================================

  Widget _buildRadio(String label, String value, String regNo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          // ignore: deprecated_member_use
          groupValue: attendanceState[regNo],
          // ignore: deprecated_member_use
          onChanged: (v) {
            setAttendanceStatus(regNo, v);
          },
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // STUDENT CARD - MOBILE
  // ============================================================

  Widget _mobileStudentCard(Map<String, dynamic> student) {
    final name = student["name"].toString();

    final regNo = student["registerNo"].toString();

    final status = attendanceState[regNo];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // CURRENT STATUS
                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              "Reg: $regNo",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // RADIO OPTIONS
            // ====================================================
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildRadio("P", "P", regNo),
                _buildRadio("A", "A", regNo),
                _buildRadio("OD", "OD", regNo),
                _buildRadio("HD", "HD", regNo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT CARD - DESKTOP
  // ============================================================

  Widget _desktopStudentCard(Map<String, dynamic> student) {
    final name = student["name"].toString();

    final regNo = student["registerNo"].toString();

    final status = attendanceState[regNo];

    return Card(
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Reg: $regNo"),
        trailing: SizedBox(
          width: 390,
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              _buildRadio("P", "P", regNo),
              _buildRadio("A", "A", regNo),
              _buildRadio("OD", "OD", regNo),
              _buildRadio("HD", "HD", regNo),
              const SizedBox(width: 8),
              _statusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String? status) {
    String text;
    Color color;

    switch (status) {
      case "P":
        text = "Present";
        color = Colors.green;
        break;

      case "A":
        text = "Absent";
        color = Colors.red;
        break;

      case "OD":
        text = "OD";
        color = Colors.blue;
        break;

      case "HD":
        text = "Half Day";
        color = Colors.orange;
        break;

      default:
        text = "Not Marked";
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _studentList(bool isMobile) {
    if (selectedClass == null || selectedSection == null) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: Text("Select Class & Section")),
      );
    }

    if (selectedDate == null) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: Text("Select the attendance date")),
      );
    }

    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: Text("No students found")),
      );
    }

    final visibleStudents = filteredStudents;

    if (visibleStudents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: Text("No students match the selected filter.")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleStudents.length,
      itemBuilder: (context, index) {
        final student = visibleStudents[index];

        if (isMobile) {
          return _mobileStudentCard(student);
        }

        return _desktopStudentCard(student);
      },
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            "$value",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _statistics() {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _statCard("Present", present, Colors.green),
          _statCard("Absent", absent, Colors.red),
          _statCard("OD", od, Colors.blue),
          _statCard("HD", hd, Colors.orange),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _actionButtons() {
    if (students.isEmpty || selectedDate == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          // ======================================================
          // CLEAR
          // ======================================================
          ElevatedButton.icon(
            icon: const Icon(Icons.clear_all),
            label: const Text("Clear Markings"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: isSubmitting ? null : clearMarkings,
          ),

          // ======================================================
          // SUBMIT
          // ======================================================
          ElevatedButton.icon(
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              isSubmitting
                  ? "Submitting..."
                  : attendanceExists
                  ? "Update Attendance"
                  : "Submit Attendance",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3C72),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: isSubmitting ? null : submitAttendance,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final bool isMobile = size.width < 800;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
        ],

        title: Text(
          "Attendance Management System",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
            color: Colors.white,
          ),
        ),

        backgroundColor: const Color(0xFF1E3C72),

        elevation: 4,
      ),

      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: EdgeInsets.all(isMobile ? 12 : 24),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              _header(),

              const SizedBox(height: 20),

              // ==================================================
              // FILTERS
              // ==================================================
              _selectionFilters(isMobile),

              const SizedBox(height: 4),

              // ==================================================
              // SEARCH
              // ==================================================
              _searchBox(isMobile),

              const SizedBox(height: 20),

              // ==================================================
              // STATISTICS
              // ==================================================
              _statistics(),

              const SizedBox(height: 20),

              // ==================================================
              // STUDENT LIST
              // ==================================================
              _studentList(isMobile),

              // ==================================================
              // ACTIONS
              // ==================================================
              _actionButtons(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
