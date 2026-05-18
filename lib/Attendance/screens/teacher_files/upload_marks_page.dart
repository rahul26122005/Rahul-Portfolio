import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/Hub_Dashboard/widgets/zoomable_scaffold.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';

class UploadMarksPage extends StatefulWidget {
  const UploadMarksPage({super.key});

  @override
  State<UploadMarksPage> createState() => _UploadMarksPageState();
}

class _UploadMarksPageState extends State<UploadMarksPage> {
  bool _isDarkMode = true;

  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedClass;
  String? selectedSection;
  String? examType;

  PlatformFile? excelFile;
  bool isUploading = false;

  // ================= MESSAGE =================
  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ================= DIALOG =================
  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
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

  // ================= FILE PICK =================
  Future<void> _pickExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null) return;

    setState(() => excelFile = result.files.single);
  }

  // ================= CONFIRM =================
  void _confirmUpload() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Upload"),
        content: Text(
          "Class: $selectedClass\n"
          "Section: $selectedSection\n"
          "ExamType: $examType\n\n"
          "File: ${excelFile!.name}\n\n"
          "Proceed with marks upload?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadExcel();
            },
            child: const Text("Upload"),
          ),
        ],
      ),
    );
  }

  // ================= UPLOAD LOGIC =================
  Future<void> _uploadExcel() async {
    setState(() => isUploading = true);

    try {
      final bytes = excelFile!.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;

      if (sheet.rows.length <= 1) {
        _showDialog("Invalid File", "Excel has no data rows");
        setState(() => isUploading = false);
        return;
      }

      int uploaded = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        if (row.length < 3) {
          _showDialog("Error", "Row ${i + 1}: Missing columns");
          setState(() => isUploading = false);
          return;
        }

        final regNo = row[0]?.value?.toString().trim();
        final subjectName = row[1]?.value?.toString().trim();
        final marksStr = row[2]?.value?.toString().trim();

        if ([regNo, subjectName, marksStr].any((e) => e == null || e.isEmpty)) {
          _showDialog("Error", "Row ${i + 1}: Empty values");
          setState(() => isUploading = false);
          return;
        }

        final marks = int.tryParse(marksStr!);
        if (marks == null) {
          _showDialog("Error", "Row ${i + 1}: Invalid marks");
          setState(() => isUploading = false);
          return;
        }

        // 🔹 FIND STUDENT
        final studentSnap = await _db
            .collection('students')
            .where('registerNo', isEqualTo: regNo)
            .where('class', isEqualTo: selectedClass)
            .where('section', isEqualTo: selectedSection)
            .get();

        if (studentSnap.docs.isEmpty) {
          _showDialog("Error", "Row ${i + 1}: Student not found");
          setState(() => isUploading = false);
          return;
        }

        final student = studentSnap.docs.first;

        // 🔹 SUBJECT (AUTO CREATE)
        final subjectRef = await _getOrCreateSubject(
          subjectName!,
          selectedClass!,
        );

        // 🔹 MARKS (UPSERT)
        final markSnap = await _db
            .collection('marks')
            .where('studentId', isEqualTo: student.id)
            .where('subjectId', isEqualTo: subjectRef.id)
            .get();

        if (markSnap.docs.isNotEmpty) {
          await markSnap.docs.first.reference.update({
            'marks': marks,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _db.collection('marks').add({
            'studentId': student.id,
            'registerNo': regNo,
            'class': selectedClass,
            'section': selectedSection,
            'subjectId': subjectRef.id,
            'subject': subjectName,
            'ExamType': examType,
            'marks': marks,
            'teacherId': _auth.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        uploaded++;
      }

      _showSnack("Uploaded $uploaded marks successfully");
    } catch (e) {
      _showDialog("Upload Failed", e.toString());
    }

    setState(() => isUploading = false);
  }

  // ================= SUBJECT =================
  Future<DocumentReference> _getOrCreateSubject(
    String name,
    String className,
  ) async {
    final snap = await _db
        .collection('subjects')
        .where('name', isEqualTo: name)
        .where('class', isEqualTo: className)
        .get();

    if (snap.docs.isNotEmpty) return snap.docs.first.reference;

    return _db.collection('subjects').add({
      'name': name,
      'class': className,
      'teacherId': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return ZoomableScaffold(
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
          _selectors(),
          const Divider(),
          if (excelFile != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text("Selected File: ${excelFile!.name}"),
            ),
          if (excelFile != null)
            ElevatedButton(
              onPressed: isUploading ? null : _confirmUpload,
              child: const Text("Confirm & Upload"),
            ),
          if (isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: const [
        Icon(Icons.my_library_books_outlined, size: 40, color: Colors.cyan),
        SizedBox(width: 10),
        Text(
          "Upload Marks",
          style: TextStyle(
            color: Colors.cyan,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= SELECTORS =================
  Widget _selectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text("Class $c"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedClass = v;
                        selectedSection = null;
                        excelFile = null;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              if (selectedClass != null)
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('students')
                      .where('class', isEqualTo: selectedClass)
                      .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const LinearProgressIndicator();
                    }

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
                      onChanged: (v) => setState(() => selectedSection = v),
                    );
                  },
                ),
              const SizedBox(height: 9),
              _examtype(),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: examType == null || selectedSection == null
                    ? null
                    : _pickExcel,
                icon: const Icon(Icons.upload_file),
                label: const Text("Choose Excel File"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SELECTORS =================
  Widget _examtype() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _dropdown(
                "Exam Type",
                ["Internal", "Model", "Semester"],
                examType,
                (v) => setState(() => examType = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
