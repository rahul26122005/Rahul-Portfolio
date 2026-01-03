import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthlySummaryPage extends StatefulWidget {
  const MonthlySummaryPage({super.key});

  @override
  State<MonthlySummaryPage> createState() => _MonthlySummaryPageState();
}

class _MonthlySummaryPageState extends State<MonthlySummaryPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Selection
  String? selectedClass;
  String? selectedSection;
  String? selectedMonth; // yyyy-MM

  //  Summary
  int p = 0, a = 0, od = 0, hd = 0, workingDays = 0;
  bool loading = false;

  // 🔹 Firestore streams
  Stream<QuerySnapshot> get classStream =>
      _db.collection('students').snapshots();

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
    }
  }

  Future<void> _loadSummary() async {
    if (selectedClass == null ||
        selectedSection == null ||
        selectedMonth == null) {
      return;
    }

    setState(() {
      loading = true;
      p = a = od = hd = workingDays = 0;
    });

    final classSection = "$selectedClass-$selectedSection";

    final snap = await _db
        .collection('attendance')
        .doc(classSection)
        .collection(selectedMonth!)
        .get();

    for (var d in snap.docs) {
      workingDays++;

      final records = Map<String, dynamic>.from(d['records']);

      for (final v in records.values) {
        if (v == "P") {
          p++;
        } else if (v == "A") {
          a++;
        } else if (v == "OD") {
          od++;
        } else if (v == "HD") {
          hd++;
        }
      }
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final total = p + a + od + hd;
    final percent = total == 0 ? 0 : ((p + od + (hd * 0.5)) / total) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Attendance Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _classSectionSelector(),

            const SizedBox(height: 12),

            // 🔹 MONTH PICKER
            ListTile(
              title: Text(
                selectedMonth ?? "Select Month",
                style: const TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickMonth,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _loadSummary,
              icon: const Icon(Icons.analytics),
              label: const Text("Generate Summary"),
            ),

            const SizedBox(height: 20),

            if (loading)
              const CircularProgressIndicator()
            else if (selectedMonth != null)
              Expanded(
                child: ListView(
                  children: [
                    _tile("Working Days", workingDays),
                    _tile("Present", p),
                    _tile("Absent", a),
                    _tile("On Duty", od),
                    _tile("Half Day", hd),
                    const Divider(),
                    _tile("Average Attendance %", percent.toStringAsFixed(2)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, Object value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _classSectionSelector() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// CLASS
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
                        (c) =>
                            DropdownMenuItem(value: c, child: Text("Class $c")),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedClass = v;
                      selectedSection = null;
                      selectedMonth = null;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            /// SECTION
            if (selectedClass != null)
              StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('students')
                    .where('class', isEqualTo: selectedClass)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();

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
                    onChanged: (v) {
                      setState(() {
                        selectedSection = v;
                        selectedMonth = null;
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
