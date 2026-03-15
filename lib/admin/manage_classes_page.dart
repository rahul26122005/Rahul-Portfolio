import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final TextEditingController searchCtrl = TextEditingController();

  String? selectedClass;
  String? selectedSection;

  List<String> classes = [];
  Map<String, List<String>> classSections = {};

  DocumentSnapshot? lastDocument;
  final int limit = 30;

  List<DocumentSnapshot> students = [];

  bool isLoading = false;
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    loadFilters();
    fetchStudents();
  }

  /// NORMALIZE TEXT
  String normalize(String value) {
    return value.trim().toUpperCase();
  }

  /// LOAD FILTERS
  Future<void> loadFilters() async {
    try {
      final snapshot = await db.collection('students').get();

      Map<String, Set<String>> temp = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final className = normalize(data['class'] ?? "");
        final section = normalize(data['section'] ?? "");

        if (className.isEmpty || section.isEmpty) continue;

        if (!temp.containsKey(className)) {
          temp[className] = {};
        }

        temp[className]!.add(section);
      }

      setState(() {
        classes = temp.keys.toList();
        classSections = temp.map((key, value) => MapEntry(key, value.toList()));
      });
    } catch (e) {
      showError("Failed loading filters: $e");
    }
  }

  /// FETCH STUDENTS
  Future<void> fetchStudents({bool loadMore = false}) async {
    try {
      if (isLoading) return;

      setState(() => isLoading = true);

      Query query = db
          .collection('students')
          .orderBy('registerNo')
          .limit(limit);

      if (selectedClass != null) {
        query = query.where('class', isEqualTo: selectedClass);
      }

      if (selectedSection != null) {
        query = query.where('section', isEqualTo: selectedSection);
      }

      if (loadMore && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      setState(() {
        if (loadMore) {
          students.addAll(snapshot.docs);
        } else {
          students = snapshot.docs;
        }
      });
    } catch (e) {
      showError("Fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// SEARCH
  Future<void> searchStudent() async {
    try {
      final regNo = searchCtrl.text.trim();

      if (regNo.isEmpty) {
        fetchStudents();
        return;
      }

      final snapshot = await db
          .collection('students')
          .where('registerNo', isEqualTo: regNo)
          .get();

      setState(() {
        students = snapshot.docs;
      });
    } catch (e) {
      showError("Search error: $e");
    }
  }

  /// DELETE STUDENT
  Future<void> deleteStudent(String id) async {
    try {
      await db.collection('students').doc(id).delete();
      fetchStudents();
      loadFilters();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Student deleted")));
      }
    } catch (e) {
      showError("Delete failed: $e");
    }
  }

  /// ADD / EDIT STUDENT
  void studentPopup({DocumentSnapshot? student}) {
    final nameCtrl = TextEditingController(text: student?['name']);
    final regCtrl = TextEditingController(text: student?['registerNo']);
    final mobileCtrl = TextEditingController(text: student?['fatherMobile']);
    final dobCtrl = TextEditingController(text: student?['dob']);

    String? classValue = student?['class'];
    String? sectionValue = student?['section'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStatePopup) {
          return AlertDialog(
            title: Text(student == null ? "Add Student" : "Edit Student"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),

                  TextField(
                    controller: regCtrl,
                    decoration: const InputDecoration(labelText: "Register No"),
                  ),

                  const SizedBox(height: 10),

                  /// CLASS DROPDOWN
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Class"),
                    initialValue: classValue,
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setStatePopup(() {
                        classValue = v;
                        sectionValue = null;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  /// SECTION DROPDOWN
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Section"),
                    initialValue: sectionValue,
                    items: (classSections[classValue] ?? [])
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      setStatePopup(() {
                        sectionValue = v;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(
                      labelText: "Father Mobile",
                    ),
                  ),

                  TextField(
                    controller: dobCtrl,
                    decoration: const InputDecoration(labelText: "DOB"),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    child: const Text("Save"),
                    onPressed: () async {
                      try {
                        final data = {
                          "name": nameCtrl.text.trim(),
                          "registerNo": regCtrl.text.trim(),
                          "class": normalize(classValue ?? ""),
                          "section": normalize(sectionValue ?? ""),
                          "fatherMobile": mobileCtrl.text.trim(),
                          "dob": dobCtrl.text.trim(),
                          "createdAt": DateTime.now(),
                        };

                        if (student == null) {
                          await db.collection('students').add(data);
                        } else {
                          await db
                              .collection('students')
                              .doc(student.id)
                              .update(data);
                        }

                        Navigator.pop(context);

                        loadFilters();
                        fetchStudents();
                      } catch (e) {
                        showError("Save failed: $e");
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ERROR DIALOG
  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
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

  /// TABLE ROW
  DataRow buildRow(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DataRow(
      cells: [
        DataCell(Text(data['name'] ?? "")),
        DataCell(Text(data['registerNo'] ?? "")),
        DataCell(Text(data['class'] ?? "")),
        DataCell(Text(data['section'] ?? "")),
        DataCell(Text(data['fatherMobile'] ?? "")),
        DataCell(Text(data['dob'] ?? "")),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => studentPopup(student: doc),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteStudent(doc.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AMS Admin Panel"),
        backgroundColor: const Color(0xFF1E3C72),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => studentPopup(),
        child: const Icon(Icons.add),
      ),

      endDrawer: DrawerPage(
        isDarkMode: _isDarkMode,
        onThemeChange: (val) {
          setState(() => _isDarkMode = val);
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// SEARCH
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      labelText: "Search Register No",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: searchStudent,
                  child: const Text("Search"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// FILTERS
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    hint: const Text("Class"),
                    initialValue: selectedClass,
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedClass = v;
                        selectedSection = null;
                      });
                      fetchStudents();
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    hint: const Text("Section"),
                    initialValue: selectedSection,
                    items: (classSections[selectedClass] ?? [])
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedSection = v);
                      fetchStudents();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// TABLE
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Register No")),
                    DataColumn(label: Text("Class")),
                    DataColumn(label: Text("Section")),
                    DataColumn(label: Text("Mobile")),
                    DataColumn(label: Text("DOB")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: students.map((doc) => buildRow(doc)).toList(),
                ),
              ),
            ),

            if (isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => fetchStudents(loadMore: true),
              child: const Text("Load More"),
            ),
          ],
        ),
      ),
    );
  }
}
