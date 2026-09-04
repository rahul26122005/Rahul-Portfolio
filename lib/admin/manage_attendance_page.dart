import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

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
  String selectedStatusFilter = "All";

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

  List<Map<String, dynamic>> get filteredStudents {
    if (selectedStatusFilter == "All") return students;

    return students.where((student) {
      final reg = student['registerNo'];
      return records[reg] == selectedStatusFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

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

      Map<String, dynamic> ordered = {};
      for (var s in students) {
        final reg = s['registerNo'];
        ordered[reg] = attendanceMap[reg] ?? "";
      }

      records = ordered;
      filteredRecords = Map.from(ordered);
      selectedStatusFilter = "All";
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
      selectedStatusFilter = "All";
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

      calculateStats();
      setState(() {});
      if (!mounted) return;
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
        attendanceExists = false;
        calculateStats();
      });
    } catch (e) {
      showError("Delete failed\n$e");
    }
  }

  /// EXPORT EXCEL
  void exportExcel() {
    if (!kIsWeb) {
      showError("Excel export is currently supported on Web only.");
      return;
    }

    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Attendance'];

    sheet.appendRow([
      excel_lib.TextCellValue("RegisterNo"),
      excel_lib.TextCellValue("Name"),
      excel_lib.TextCellValue("Status"),
    ]);

    for (var s in students) {
      final reg = s['registerNo'];
      final name = s['name'];
      sheet.appendRow([
        excel_lib.TextCellValue(reg),
        excel_lib.TextCellValue(name),
        excel_lib.TextCellValue(records[reg] ?? ""),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
          "download",
          "attendance_${selectedClass}_${selectedSection}_${DateFormat('yyyyMMdd').format(selectedDate!)}.xlsx",
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Widget _buildRadio(String label, String value, String reg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          // ignore: deprecated_member_use
          groupValue: records[reg],

          // ignore: deprecated_member_use
          onChanged: (v) {
            setState(() {
              records[reg] = v;
              calculateStats();
            });
          },
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget attendanceList(bool isMobile) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (students.isEmpty) {
      return const Center(child: Text("No students found or select filters."));
    }
    final visibleStudents = filteredStudents;
    if (visibleStudents.isEmpty) {
      return const Center(child: Text("No students match this status filter."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleStudents.length,
      itemBuilder: (context, i) {
        final student = visibleStudents[i];
        final reg = student['registerNo'];
        final name = student['name'];

        if (isMobile) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Reg: $reg",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildRadio("P", "P", reg),
                      _buildRadio("A", "A", reg),
                      _buildRadio("OD", "OD", reg),
                      _buildRadio("HD", "HD", reg),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: ListTile(
            title: Text(name),
            subtitle: Text("Reg: $reg"),
            trailing: SizedBox(
              width: 280,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildRadio("P", "P", reg),
                  _buildRadio("A", "A", reg),
                  _buildRadio("OD", "OD", reg),
                  _buildRadio("HD", "HD", reg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
          "Manage Attendance",
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
              // FILTERS SECTION
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selection Filters",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: isMobile ? double.infinity : 150,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Class",
                                border: OutlineInputBorder(),
                              ),
                              initialValue: selectedClass,
                              items: classes
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  selectedClass = v;
                                  selectedSection = null;
                                });
                                if (v != null) loadSections(v);
                              },
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 150,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Section",
                                border: OutlineInputBorder(),
                              ),
                              initialValue: selectedSection,
                              items: sections
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: selectedClass == null
                                  ? null
                                  : (v) => setState(() => selectedSection = v),
                            ),
                          ),
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
                                  : DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(selectedDate!),
                            ),
                            onPressed: pickDate,
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 170,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Status",
                                border: OutlineInputBorder(),
                              ),
                              initialValue: selectedStatusFilter,
                              items: const [
                                DropdownMenuItem(
                                  value: "All",
                                  child: Text("All"),
                                ),
                                DropdownMenuItem(
                                  value: "P",
                                  child: Text("Present"),
                                ),
                                DropdownMenuItem(
                                  value: "A",
                                  child: Text("Absent"),
                                ),
                                DropdownMenuItem(
                                  value: "OD",
                                  child: Text("OD"),
                                ),
                              ],
                              onChanged: records.isEmpty
                                  ? null
                                  : (v) => setState(
                                      () => selectedStatusFilter = v ?? "All",
                                    ),
                            ),
                          ),
                          if (!attendanceExists &&
                              selectedDate != null &&
                              students.isNotEmpty)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                              onPressed: createAttendance,
                              child: const Text("Initialize Attendance"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // STATS SECTION
              if (students.isNotEmpty) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard("Present", present, Colors.green),
                    _statCard("Absent", absent, Colors.red),
                    _statCard("OD", od, Colors.blue),
                    _statCard("HD", hd, Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // LIST SECTION
              attendanceList(isMobile),

              const SizedBox(height: 24),

              // ACTIONS SECTION
              if (students.isNotEmpty)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Update Attendance"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0xFF1E3C72),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: updateAttendance,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete Record"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: deleteAttendance,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text("Export Excel"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: exportExcel,
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
