import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/zoomable_scaffold.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class AttendanceReportGeneratePage extends StatefulWidget {
  const AttendanceReportGeneratePage({super.key});

  @override
  State<AttendanceReportGeneratePage> createState() =>
      _AttendanceReportGeneratePageState();
}

class _AttendanceReportGeneratePageState
    extends State<AttendanceReportGeneratePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isDarkMode = true;
  String? selectedClass;
  String? selectedSection;

  List<String> classes = [];
  List<String> sections = [];
  List<Map<String, dynamic>> students = [];

  bool loading = false;
  Map<String, Map<String, int>> studentStats =
      {}; // regNo -> {P: count, A: count, ...}
  List<String> processedMonths = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

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

  Future<void> generateReport() async {
    if (selectedClass == null || selectedSection == null) {
      showError("Please select Class and Section");
      return;
    }

    setState(() {
      loading = true;
      studentStats.clear();
      processedMonths.clear();
    });

    try {
      await loadStudents();

      final classSection = "$selectedClass-$selectedSection";
      DateTime now = DateTime.now();

      // Initialize stats for all students
      for (var student in students) {
        studentStats[student['registerNo']] = {
          "P": 0,
          "A": 0,
          "OD": 0,
          "HD": 0,
          "Total": 0,
        };
      }

      // We want to check the last 6 months (including current)
      for (int i = 0; i < 6; i++) {
        DateTime monthDate = DateTime(now.year, now.month - i, 1);
        String monthKey = DateFormat('yyyy-MM').format(monthDate);

        final monthSnap = await db
            .collection("attendance")
            .doc(classSection)
            .collection(monthKey)
            .get();

        if (monthSnap.docs.isNotEmpty) {
          processedMonths.add(DateFormat('MMMM yyyy').format(monthDate));

          for (var dateDoc in monthSnap.docs) {
            Map<String, dynamic> records = Map<String, dynamic>.from(
              dateDoc.data()['records'] ?? {},
            );

            records.forEach((regNo, status) {
              if (studentStats.containsKey(regNo)) {
                if (status == "P") {
                  studentStats[regNo]!["P"] =
                      (studentStats[regNo]!["P"] ?? 0) + 1;
                }
                if (status == "A") {
                  studentStats[regNo]!["A"] =
                      (studentStats[regNo]!["A"] ?? 0) + 1;
                }
                if (status == "OD") {
                  studentStats[regNo]!["OD"] =
                      (studentStats[regNo]!["OD"] ?? 0) + 1;
                }
                if (status == "HD") {
                  studentStats[regNo]!["HD"] =
                      (studentStats[regNo]!["HD"] ?? 0) + 1;
                }

                if (status != "") {
                  studentStats[regNo]!["Total"] =
                      (studentStats[regNo]!["Total"] ?? 0) + 1;
                }
              }
            });
          }
        }
      }

      if (processedMonths.isEmpty) {
        showError("No attendance records found for the last 6 months.");
      }
    } catch (e) {
      showError("Failed to generate report\n$e");
    }

    setState(() => loading = false);
  }

  void exportToExcel() {
    if (!kIsWeb) {
      showError("Excel export is currently supported on Web only.");
      return;
    }

    if (studentStats.isEmpty) {
      showError("No data to export. Generate report first.");
      return;
    }

    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Attendance Report'];

    sheet.appendRow([
      excel_lib.TextCellValue("Register No"),
      excel_lib.TextCellValue("Name"),
      excel_lib.TextCellValue("Present (P)"),
      excel_lib.TextCellValue("Absent (A)"),
      excel_lib.TextCellValue("On Duty (OD)"),
      excel_lib.TextCellValue("Half Day (HD)"),
      excel_lib.TextCellValue("Total Days"),
      excel_lib.TextCellValue("Attendance %"),
    ]);

    for (var student in students) {
      final reg = student['registerNo'];
      final name = student['name'];
      final stats = studentStats[reg]!;

      double percentage = stats['Total']! > 0
          ? (stats['P']! + stats['OD']! + (stats['HD']! * 0.5)) /
                stats['Total']! *
                100
          : 0.0;

      sheet.appendRow([
        excel_lib.TextCellValue(reg),
        excel_lib.TextCellValue(name),
        excel_lib.IntCellValue(stats['P']!),
        excel_lib.IntCellValue(stats['A']!),
        excel_lib.IntCellValue(stats['OD']!),
        excel_lib.IntCellValue(stats['HD']!),
        excel_lib.IntCellValue(stats['Total']!),
        excel_lib.TextCellValue("${percentage.toStringAsFixed(2)}%"),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
          "download",
          "Attendance_Report_${selectedClass}_$selectedSection.xlsx",
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 800;

    return ZoomableScaffold(
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
        title: const Text(
          "Six Months Report",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3C72),
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Report Configuration",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: isMobile ? double.infinity : 200,
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
                                  sections = [];
                                });
                                if (v != null) loadSections(v);
                              },
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? double.infinity : 200,
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
                              onChanged: (v) =>
                                  setState(() => selectedSection = v),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: loading ? null : generateReport,
                            icon: const Icon(Icons.analytics),
                            label: const Text("Generate Report"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              backgroundColor: const Color(0xFF1E3C72),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (studentStats.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: exportToExcel,
                              icon: const Icon(Icons.download),
                              label: const Text("Export Excel"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 18,
                                ),
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (processedMonths.isNotEmpty) ...[
                Text(
                  "Report Duration: ${processedMonths.last} to ${processedMonths.first}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // Mobile view: Cards
                if (isMobile)
                  ...students.map((student) {
                    final reg = student['registerNo'];
                    final stats = studentStats[reg]!;
                    double percentage = stats['Total']! > 0
                        ? (stats['P']! + stats['OD']! + (stats['HD']! * 0.5)) /
                              stats['Total']! *
                              100
                        : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Reg No: $reg",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _miniStat("P", stats['P']!, Colors.green),
                                _miniStat("A", stats['A']!, Colors.red),
                                _miniStat("OD", stats['OD']!, Colors.blue),
                                _miniStat("HD", stats['HD']!, Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total Days: ${stats['Total']}"),
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: percentage >= 75
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                else
                  // Desktop view: Table
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Reg No')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('P')),
                          DataColumn(label: Text('A')),
                          DataColumn(label: Text('OD')),
                          DataColumn(label: Text('HD')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('%')),
                        ],
                        rows: students.map((student) {
                          final reg = student['registerNo'];
                          final stats = studentStats[reg]!;
                          double percentage = stats['Total']! > 0
                              ? (stats['P']! +
                                        stats['OD']! +
                                        (stats['HD']! * 0.5)) /
                                    stats['Total']! *
                                    100
                              : 0.0;

                          return DataRow(
                            cells: [
                              DataCell(Text(reg)),
                              DataCell(Text(student['name'])),
                              DataCell(Text("${stats['P']}")),
                              DataCell(Text("${stats['A']}")),
                              DataCell(Text("${stats['OD']}")),
                              DataCell(Text("${stats['HD']}")),
                              DataCell(Text("${stats['Total']}")),
                              DataCell(
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: percentage >= 75
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ] else if (!loading && selectedSection != null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("No records found for the selected criteria."),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
