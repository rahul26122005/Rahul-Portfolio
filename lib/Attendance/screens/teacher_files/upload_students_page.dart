import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/app_drawer.dart';

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
      //appBar: AppBar(title: const Text("Upload Students")),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
    try {
      setState(() => isUploading = true);

      final bytes = selectedFile!.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final teacherId = _auth.currentUser!.uid;

      // Secondary Firebase App
      final secondaryApp = await Firebase.initializeApp(
        name: 'studentCreator',
        options: Firebase.app().options,
      );

      final FirebaseAuth studentAuth = FirebaseAuth.instanceFor(
        app: secondaryApp,
      );

      int uploaded = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        if (row.length < 6) continue;

        final name = row[0]?.value?.toString().trim();
        final registerNo = row[1]?.value?.toString().trim();
        final className = row[2]?.value?.toString().trim();
        final section = row[3]?.value?.toString().trim();
        final dob = row[4]?.value?.toString().trim();
        final fatherMobile = row[5]?.value?.toString().trim();

        if ([
          name,
          registerNo,
          className,
          section,
          dob,
          fatherMobile,
        ].any((e) => e == null || e.isEmpty)) {
          continue;
        }

        final email = "$registerNo.student.rahulportfolio@gmail.com";
        final password = dob!; // 2006-05-21T00:00:00.000Z

        UserCredential cred;

        try {
          cred = await studentAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            cred = await studentAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
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
      }

      await secondaryApp.delete(); // cleanup

      setState(() => isUploading = false);
      _showSuccess(uploaded);
    } catch (e) {
      setState(() => isUploading = false);
      _showError(e.toString());
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
