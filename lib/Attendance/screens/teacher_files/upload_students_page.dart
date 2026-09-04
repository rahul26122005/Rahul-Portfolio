import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';

import 'package:my_flutter_webside/routes/app_routes.dart';

class UploadStudentsPage extends StatefulWidget {
  const UploadStudentsPage({super.key});

  @override
  State<UploadStudentsPage> createState() => _UploadStudentsPageState();
}

class _UploadStudentsPageState extends State<UploadStudentsPage> {
  bool _isDarkMode = true;

  // ================= THEME =================
  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  bool isUploading = false;
  String? selectedFileName;
  PlatformFile? selectedFile;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, AppRoutes.teacherDashboard);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(Icons.menu, color: Colors.white),
              iconSize: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.teacherDashboard);
            },
            icon: const Icon(Icons.home, color: Colors.white),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _header(),

          Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Excel Columns (ALL REQUIRED)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Excel Columns must be in the following order:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Name | Register No | Class | Section | DOB | Father Mobile",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text("Choose Excel File"),
                      onPressed: isUploading ? null : _pickFile,
                    ),

                    if (selectedFileName != null) ...[
                      const SizedBox(height: 12),
                      Text("Selected: $selectedFileName"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: isUploading ? null : _confirmUpload,
                        child: const Text("Confirm & Upload"),
                      ),
                    ],

                    if (isUploading) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                    ],
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
        Icon(Icons.people, size: 40, color: Colors.cyan),
        SizedBox(width: 10),
        Text(
          "Upload Students",
          style: TextStyle(
            color: Colors.cyan,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= PICK FILE =================
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null) return;

    setState(() {
      selectedFile = result.files.single;
      selectedFileName = selectedFile!.name;
    });
  }

  // ================= CONFIRM =================
  void _confirmUpload() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Upload"),
        content: Text("Upload students from:\n\n$selectedFileName ?"),
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

  // ================= CORE UPLOAD =================
  Future<void> _uploadExcel() async {
    FirebaseApp? secondaryApp;

    try {
      setState(() => isUploading = true);

      if (selectedFile == null) {
        throw Exception("Please select an Excel file");
      }

      final teacher = _auth.currentUser;

      if (teacher == null) {
        throw Exception("Teacher not logged in");
      }

      final teacherId = teacher.uid;

      final bytes = selectedFile!.bytes;

      if (bytes == null) {
        throw Exception("Invalid Excel file");
      }

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception("Excel sheet is empty");
      }

      final sheet = excel.tables.values.first;

      // Secondary Firebase App
      secondaryApp = await Firebase.initializeApp(
        name: 'studentCreator',
        options: Firebase.app().options,
      );

      final FirebaseAuth studentAuth = FirebaseAuth.instanceFor(
        app: secondaryApp,
      );

      int uploaded = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        try {
          final row = sheet.rows[i];

          if (row.length < 6) continue;

          final name = row[0]?.value?.toString().trim() ?? "";
          final registerNo = row[1]?.value?.toString().trim() ?? "";
          final className = row[2]?.value?.toString().trim() ?? "";
          final section = row[3]?.value?.toString().trim() ?? "";
          final dob = row[4]?.value?.toString().trim() ?? "";
          final fatherMobile = row[5]?.value?.toString().trim() ?? "";

          if (name.isEmpty ||
              registerNo.isEmpty ||
              className.isEmpty ||
              section.isEmpty ||
              dob.isEmpty ||
              fatherMobile.isEmpty) {
            continue;
          }

          final email = "$registerNo.student.rahulportfolio@gmail.com";

          // SAFE PASSWORD
          final password = dob;

          UserCredential cred;

          try {
            cred = await studentAuth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } on FirebaseAuthException catch (e) {
            // USER ALREADY EXISTS
            if (e.code == 'email-already-in-use') {
              debugPrint("Student already exists: $email");
              continue;
            }

            rethrow;
          }

          final uid = cred.user!.uid;

          // USERS COLLECTION
          await _db.collection('users').doc(uid).set({
            'uid': uid,
            'name': name,
            'registerNo': registerNo,
            'class': className,
            'section': section,
            'dob': dob,
            'email': email,
            'role': 'student',
            'teacherId': teacherId,
            'fatherMobile': fatherMobile,
            'active': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // STUDENTS COLLECTION
          await _db.collection('students').doc(uid).set({
            'name': name,
            'registerNo': registerNo,
            'class': className,
            'section': section,
            'dob': dob,
            'teacherId': teacherId,
            'fatherMobile': fatherMobile,
            'createdAt': FieldValue.serverTimestamp(),
          });

          uploaded++;
        } catch (e) {
          debugPrint("Row Upload Error: $e");
        }
      }

      // cleanup
      await secondaryApp.delete();

      if (!mounted) return;

      setState(() => isUploading = false);

      _showSuccess(uploaded);
    } catch (e) {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }

      if (!mounted) return;

      setState(() => isUploading = false);

      _showError(e.toString());

      debugPrint("Upload Error: $e");
    }
  }

  // ================= SUCCESS =================
  void _showSuccess(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Upload Successful"),
        content: Text("Uploaded $count students successfully"),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ================= ERROR =================
  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Upload Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
