import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;

class ManageAttendancePage extends StatefulWidget {
  const ManageAttendancePage({super.key});

  @override
  State<ManageAttendancePage> createState() => _ManageAttendancePageState();
}

class _ManageAttendancePageState extends State<ManageAttendancePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isDarkMode = true;
  String? selectedClass;
  String? selectedSection;
  DateTime? selectedDate;

  List<String> classes = [];
  List<String> sections = [];

  Map<String, dynamic> records = {};
  Map<String, dynamic> filteredRecords = {};

  /// STUDENT DATA (name + regno)
  List<Map<String, dynamic>> students = [];

  final searchCtrl = TextEditingController();

  int present = 0;
  int absent = 0;
  int od = 0;
  int hd = 0;

  bool loading = false;
  bool attendanceExists = false;

  /// ERROR DIALOG
  void showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  /// LOAD CLASSES
  Future<void> loadClasses() async {
    try {
      final snap = await db.collection("students").get();

      final set = <String>{};

      for (var d in snap.docs) {
        set.add(d['class']);
      }

      setState(() => classes = set.toList()..sort());
    } catch (e) {
      showError("Failed loading classes\n$e");
    }
  }

  /// LOAD SECTIONS
  Future<void> loadSections(String className) async {
    try {
      final snap = await db
          .collection("students")
          .where("class", isEqualTo: className)
          .get();

      final set = <String>{};

      for (var d in snap.docs) {
        set.add(d['section']);
      }

      setState(() => sections = set.toList()..sort());
    } catch (e) {
      showError("Failed loading sections\n$e");
    }
  }

  /// LOAD STUDENTS
  Future<void> loadStudents() async {
    try {
      final snap = await db
          .collection("students")
          .where("class", isEqualTo: selectedClass)
          .where("section", isEqualTo: selectedSection)
          .orderBy("registerNo")
          .get();

      students = snap.docs
          .map((e) => {"name": e['name'], "registerNo": e['registerNo']})
          .toList();
    } catch (e) {
      showError("Failed loading students\n$e");
    }
  }

  /// PICK DATE
  Future<void> pickDate() async {
    if (selectedClass == null || selectedSection == null) {
      showError("Select Class & Section first");
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);

      await loadStudents();
      await loadAttendance();
    }
  }

  /// LOAD ATTENDANCE
  Future<void> loadAttendance() async {
    if (selectedDate == null) return;

    try {
      setState(() => loading = true);

      final classSection = "$selectedClass-$selectedSection";

      final monthKey = DateFormat('yyyy-MM').format(selectedDate!);
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate!);

      final doc = await db
          .collection("attendance")
          .doc(classSection)
          .collection(monthKey)
          .doc(dateKey)
          .get();

      Map<String, dynamic> attendanceMap = {};

      attendanceExists = doc.exists;

      if (doc.exists) {
        attendanceMap = Map<String, dynamic>.from(doc['records']);
      }

      /// BUILD ORDERED RECORDS
      Map<String, dynamic> ordered = {};

      for (var s in students) {
        final reg = s['registerNo'];

        ordered[reg] = attendanceMap[reg] ?? "";
      }

      records = ordered;
      filteredRecords = Map.from(ordered);

      calculateStats();
    } catch (e) {
      showError("Failed loading attendance\n$e");
    }

    setState(() => loading = false);
  }

  /// CREATE ATTENDANCE
  Future<void> createAttendance() async {
    if (selectedDate == null) return;

    try {
      Map<String, dynamic> map = {};

      for (var s in students) {
        map[s['registerNo']] = "P";
      }

      records = map;
      filteredRecords = Map.from(map);

      await updateAttendance();
    } catch (e) {
      showError("Create attendance failed\n$e");
    }
  }

  /// CALCULATE STATS
  void calculateStats() {
    present = 0;
    absent = 0;
    od = 0;
    hd = 0;

    records.forEach((k, v) {
      if (v == "P") present++;
      if (v == "A") absent++;
      if (v == "OD") od++;
      if (v == "HD") hd++;
    });
  }

  /// UPDATE ATTENDANCE
  Future<void> updateAttendance() async {
    try {
      final classSection = "$selectedClass-$selectedSection";

      final monthKey = DateFormat('yyyy-MM').format(selectedDate!);
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate!);

      await db
          .collection("attendance")
          .doc(classSection)
          .collection(monthKey)
          .doc(dateKey)
          .set({"records": records, "isEdited": true});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attendance Updated")));
    } catch (e) {
      showError("Update failed\n$e");
    }
  }

  /// DELETE ATTENDANCE
  Future<void> deleteAttendance() async {
    try {
      final classSection = "$selectedClass-$selectedSection";

      final monthKey = DateFormat('yyyy-MM').format(selectedDate!);
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate!);

      await db
          .collection("attendance")
          .doc(classSection)
          .collection(monthKey)
          .doc(dateKey)
          .delete();

      setState(() {
        records.clear();
        filteredRecords.clear();
      });
    } catch (e) {
      showError("Delete failed\n$e");
    }
  }

  /// EXPORT EXCEL
  void exportExcel() {
    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];

    sheet.appendRow([
      TextCellValue("RegisterNo"),
      TextCellValue("Name"),
      TextCellValue("Status"),
    ]);

    for (var s in students) {
      final reg = s['registerNo'];
      final name = s['name'];

      sheet.appendRow([
        TextCellValue(reg),
        TextCellValue(name),
        TextCellValue(records[reg] ?? ""),
      ]);
    }

    final bytes = excel.encode();

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "attendance.xlsx")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// STUDENT LIST
  Widget attendanceList() {
    return Expanded(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: students.length,

              itemBuilder: (context, i) {
                final student = students[i];

                final reg = student['registerNo'];
                final name = student['name'];

                final status = records[reg] ?? "";

                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text("Reg: $reg"),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio(
                          value: "P",
                          groupValue: status,
                          onChanged: (v) {
                            setState(() => records[reg] = "P");
                          },
                        ),

                        const Text("P"),

                        Radio(
                          value: "A",
                          groupValue: status,
                          onChanged: (v) {
                            setState(() => records[reg] = "A");
                          },
                        ),

                        const Text("A"),

                        Radio(
                          value: "OD",
                          groupValue: status,
                          onChanged: (v) {
                            setState(() => records[reg] = "OD");
                          },
                        ),

                        const Text("OD"),

                        Radio(
                          value: "HD",
                          groupValue: status,
                          onChanged: (v) {
                            setState(() => records[reg] = "HD");
                          },
                        ),

                        const Text("HD"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              "AMS-Admin Panel",
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
        backgroundColor: const Color(0xFF1E3C72),
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            /// FILTERS
            Row(
              children: [
                DropdownButton<String>(
                  hint: const Text("Class"),

                  value: selectedClass,

                  items: classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),

                  onChanged: (v) {
                    setState(() => selectedClass = v);

                    loadSections(v!);
                  },
                ),

                const SizedBox(width: 20),

                DropdownButton<String>(
                  hint: const Text("Section"),

                  value: selectedSection,

                  items: sections
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),

                  onChanged: selectedClass == null
                      ? null
                      : (v) => setState(() => selectedSection = v),
                ),

                const SizedBox(width: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    selectedDate == null
                        ? "Pick Date"
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                  onPressed: pickDate,
                ),

                const SizedBox(width: 20),

                if (!attendanceExists && selectedDate != null)
                  ElevatedButton(
                    onPressed: createAttendance,
                    child: const Text("Create Attendance"),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            /// STATS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Present: $present"),
                Text("Absent: $absent"),
                Text("OD: $od"),
                Text("HD: $hd"),
              ],
            ),

            const SizedBox(height: 10),

            attendanceList(),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                ElevatedButton(
                  onPressed: updateAttendance,
                  child: const Text("Update"),
                ),

                const SizedBox(width: 20),

                ElevatedButton(
                  onPressed: deleteAttendance,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete"),
                ),

                const SizedBox(width: 20),

                ElevatedButton(
                  onPressed: exportExcel,
                  child: const Text("Export Excel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
