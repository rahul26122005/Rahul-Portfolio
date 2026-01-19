import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';
import 'package:my_flutter_webside/routes/app_routes.dart';

class StudentMarkPage extends StatefulWidget {
  const StudentMarkPage({super.key});

  @override
  State<StudentMarkPage> createState() => _StudentMarkPageState();
}

class _StudentMarkPageState extends State<StudentMarkPage> {
  bool _isDarkMode = true;

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? registerNo;
  String selectedExamType = 'Internal';

  final List<String> examTypes = ['Internal', 'Model', 'Semester'];

  @override
  void initState() {
    super.initState();
    _loadRegisterNoFromStudentProfile();
  }

  // ================= LOAD REGISTER NO =================
  Future<void> _loadRegisterNoFromStudentProfile() async {
    try {
      final uid = _auth.currentUser!.uid;

      final userSnap = await _db.collection('users').doc(uid).get();
      if (!userSnap.exists) {
        throw Exception("User record not found");
      }

      final userData = userSnap.data() as Map<String, dynamic>;
      final String? regNo = userData['registerNo'];

      if (regNo == null || regNo.isEmpty) {
        throw Exception("Register number not linked");
      }

      final studentSnap = await _db
          .collection('students')
          .where('registerNo', isEqualTo: regNo)
          .get();

      if (studentSnap.docs.isEmpty) {
        throw Exception("Student profile not found");
      }

      setState(() {
        registerNo = regNo.trim();
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  // ================= FETCH MARKS (FUTURE) =================
  Future<QuerySnapshot> _fetchMarks() async {
    try {
      if (registerNo == null || registerNo!.isEmpty) {
        throw Exception("Register number not available");
      }

      final querySnapshot = await _db
          .collection('marks')
          .where('registerNo', isEqualTo: registerNo)
          .where('ExamType', isEqualTo: selectedExamType)
          .get();

      return querySnapshot;
    } on FirebaseException catch (e) {
      // Firestore specific errors
      throw Exception("Firestore error: ${e.message}");
    } catch (e) {
      // Any other unexpected error
      throw Exception("Failed to fetch marks: $e");
    }
  }

  // ================= ERROR DIALOG =================
  void _showErrorDialog(String msg) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, AppRoutes.studentDashboard);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Text(
              "My Marks",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: constraints.maxWidth < 600 ? 18 : 24,
                color: Colors.white,
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
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.studentDashboard);
            },
            icon: const Icon(Icons.home, color: Colors.white),
          ),
        ],
        backgroundColor: const Color(0xFF1E3C72),
      ),
      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: _toggleTheme,
      ),
      body: registerNo == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _examTypeSelector(),
                const Divider(),
                Expanded(child: _marksList()),
              ],
            ),
    );
  }

  // ================= EXAM TYPE SELECTOR =================
  Widget _examTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        initialValue: selectedExamType,
        decoration: const InputDecoration(
          labelText: "Exam Type",
          border: OutlineInputBorder(),
        ),
        items: examTypes
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() => selectedExamType = v!);
        },
      ),
    );
  }

  // ================= MARKS LIST (FUTURE BUILDER) =================
  Widget _marksList() {
    return FutureBuilder<QuerySnapshot>(
      future: _fetchMarks(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(snap.error.toString());
          });
          return const SizedBox();
        }

        // if (!snap.hasData || snap.data!.docs.isEmpty) {
        //   return const Center(
        //     child: Text("No marks available", style: TextStyle(fontSize: 16)),
        //   );
        // }

        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final data = snap.data!.docs[i];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: Text(
                  data['subject'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    data['marks'].toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
