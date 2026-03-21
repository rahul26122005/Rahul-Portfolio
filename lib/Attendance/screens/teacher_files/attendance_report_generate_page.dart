import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
//import 'package:my_flutter_webside/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class AttendanceReportGeneratePage extends StatefulWidget {
  const AttendanceReportGeneratePage({super.key});

  @override
  State<AttendanceReportGeneratePage> createState() =>
      _AttendanceReportGeneratePageState();
}

class _AttendanceReportGeneratePageState
    extends State<AttendanceReportGeneratePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isDarkMode = true;
  bool loading = false;

  String? selectedClass;
  String? selectedSection;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<String> classes = [];
  List<String> sections = [];

  final Map<DateTime, String> manualHolidays = {};
  final workingDays = <int>[];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  Future<void> _loadClasses() async {
    final snap = await _db.collection('students').get();
    final set = <String>{};

    for (var d in snap.docs) {
      set.add(d['class']);
    }

    setState(() => classes = set.toList()..sort());
  }

  Future<void> _loadSections(String className) async {
    final snap = await _db
        .collection('students')
        .where('class', isEqualTo: className)
        .get();

    final set = <String>{};

    for (var d in snap.docs) {
      set.add(d['section']);
    }

    setState(() {
      sections = set.toList()..sort();
      selectedSection = null;
    });
  }

  Future<void> generateReport() async {
    if (selectedClass == null || selectedSection == null) {
      _showMessage("Select class & section");
      return;
    }

    setState(() => loading = true);

    try {
      final classSection = "$selectedClass-$selectedSection";
      final monthKey =
          "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}";

      final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

      workingDays.clear();

      final studentsSnap = await _db
          .collection('students')
          .where('class', isEqualTo: selectedClass)
          .where('section', isEqualTo: selectedSection)
          .orderBy('registerNo')
          .get();

      if (studentsSnap.docs.isEmpty) {
        _showMessage("No students found");
        return;
      }

      final Map<String, String> studentNames = {};
      final Map<String, Map<int, String>> attendanceMap = {};

      for (var s in studentsSnap.docs) {
        final regNo = s['registerNo'].toString();
        studentNames[regNo] = s['name'];
        attendanceMap[regNo] = {};
      }

      final attSnap = await _db
          .collection('attendance')
          .doc(classSection)
          .collection(monthKey)
          .get();

      for (var d in attSnap.docs) {
        DateTime date;

        try {
          date = DateFormat('yyyy-MM-dd').parse(d.id);
        } catch (_) {
          continue;
        }

        final day = date.day;
        final records = Map<String, dynamic>.from(d['records']);

        for (final regNo in records.keys) {
          if (!attendanceMap.containsKey(regNo)) continue;
          attendanceMap[regNo]![day] = records[regNo];
        }
      }

      final excel = Excel.createExcel();
      final sheet = excel['Attendance'];

      sheet.appendRow([TextCellValue("ATTENDANCE REPORT")]);
      sheet.appendRow([TextCellValue("Class"), TextCellValue(classSection)]);
      sheet.appendRow([
        TextCellValue("Month"),
        TextCellValue(
          "${DateFormat.MMMM().format(DateTime(selectedYear, selectedMonth))} $selectedYear",
        ),
      ]);

      sheet.appendRow([
        TextCellValue("Total Working Days"),
        TextCellValue("Auto Calculated Below"),
      ]);

      sheet.appendRow([]);

      final header = <CellValue>[
        TextCellValue("Register No"),
        TextCellValue("Name"),
      ];

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(selectedYear, selectedMonth, d);

        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          continue;
        }

        workingDays.add(d);
        header.add(TextCellValue(d.toString()));
      }

      header.addAll([
        TextCellValue("P"),
        TextCellValue("A"),
        TextCellValue("OD"),
        TextCellValue("HD"),
        TextCellValue("Total Days"),
        TextCellValue("Absent Days"),
        TextCellValue("%"),
      ]);

      sheet.appendRow(header);

      attendanceMap.forEach((regNo, daily) {
        double total = 0;
        int validDays = 0;
        int p = 0, a = 0, od = 0, hd = 0;

        final row = <CellValue>[
          TextCellValue(regNo),
          TextCellValue(studentNames[regNo]!),
        ];

        for (int d in workingDays) {
          final value = daily.containsKey(d) ? daily[d]! : "NT";

          row.add(TextCellValue(value));

          if (value != "NT") {
            validDays++;
          }

          if (value == "P") {
            p++;
            total += 1;
          } else if (value == "OD") {
            od++;
            total += 1;
          } else if (value == "HD") {
            hd++;
            total += 0.5;
          } else if (value == "A") {
            a++;
          }
        }

        final percent = validDays == 0 ? 0 : (total / validDays) * 100;

        row.addAll([
          IntCellValue(p),
          IntCellValue(a),
          IntCellValue(od),
          IntCellValue(hd),
          IntCellValue(validDays), // 🔥 TOTAL DAYS
          IntCellValue(a), // 🔥 ABSENT DAYS
          DoubleCellValue(double.parse(percent.toStringAsFixed(2))),
        ]);

        sheet.appendRow(row);
      });

      final bytes = Uint8List.fromList(excel.encode()!);
      final fileName = "Attendance_${classSection}_$monthKey.xlsx";

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..download = fileName
          ..click();

        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(bytes);
        _showMessage("Saved to ${file.path}");
      }
    } catch (e) {
      _showMessage("Failed: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        title: const Text(
          "Attendance Management System",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Report Generation",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _dropdown("Class", selectedClass, classes, (v) {
              setState(() => selectedClass = v);
              _loadSections(v!);
            }),
            _dropdown(
              "Section",
              selectedSection,
              sections,
              (v) => setState(() => selectedSection = v),
            ),
            _dropdown(
              "Month",
              selectedMonth,
              List.generate(12, (i) => i + 1),
              (v) => setState(() => selectedMonth = v!),
              display: (v) => DateFormat.MMMM().format(DateTime(0, v)),
            ),
            _dropdown(
              "Year",
              selectedYear,
              List.generate(5, (i) => DateTime.now().year - i),
              (v) => setState(() => selectedYear = v!),
            ),
            const SizedBox(height: 30),
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Generate Excel"),
                    onPressed: generateReport,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T? value,
    List<T> items,
    ValueChanged<T?> onChanged, {
    String Function(T)? display,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(display != null ? display(e) : e.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
