import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_webside/Attendance/widgets/app_drawer.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? selectedRole;

  final List<String> roles = ["admin", "teacher", "student"];

  List<DocumentSnapshot> users = [];
  bool _isDarkMode = true;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleTheme(bool value) {
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  /// FETCH USERS BY ROLE
  Future<void> fetchUsers() async {
    if (selectedRole == null) return;

    try {
      setState(() => isLoading = true);

      Query query = db
          .collection('users')
          .where('role', isEqualTo: selectedRole);

      /// APPLY ORDERBY ONLY FOR STUDENTS
      if (selectedRole == "student") {
        query = query.orderBy('registerNo');
      }

      final snapshot = await query.get();

      setState(() {
        users = snapshot.docs;
      });
    } catch (e) {
      showError("Failed fetching users : $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// DELETE USER
  Future<void> deleteUser(String id) async {
    try {
      await db.collection('users').doc(id).delete();

      fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User deleted")));
      }
    } catch (e) {
      showError("Delete failed : $e");
    }
  }

  /// ADD / EDIT USER
  void userPopup({DocumentSnapshot? user}) {
    final nameCtrl = TextEditingController(text: user?['name']);
    final emailCtrl = TextEditingController(text: user?['email']);
    final classCtrl = TextEditingController(text: user?['class']);
    final sectionCtrl = TextEditingController(text: user?['section']);
    final regCtrl = TextEditingController(text: user?['registerNo']);
    final mobileCtrl = TextEditingController(text: user?['fatherMobile']);

    String roleValue = user?['role'] ?? "student";

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(user == null ? "Add User" : "Edit User"),

          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),

                DropdownButtonFormField<String>(
                  initialValue: roleValue,
                  items: roles.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (v) {
                    roleValue = v!;
                  },
                  decoration: const InputDecoration(labelText: "Role"),
                ),

                TextField(
                  controller: regCtrl,
                  decoration: const InputDecoration(labelText: "Register No"),
                ),

                TextField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: "Class"),
                ),

                TextField(
                  controller: sectionCtrl,
                  decoration: const InputDecoration(labelText: "Section"),
                ),

                TextField(
                  controller: mobileCtrl,
                  decoration: const InputDecoration(labelText: "Mobile"),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  child: const Text("Save"),
                  onPressed: () async {
                    try {
                      final data = {
                        "name": nameCtrl.text.trim(),
                        "email": emailCtrl.text.trim(),
                        "role": roleValue,
                        "registerNo": regCtrl.text.trim(),
                        "class": classCtrl.text.trim(),
                        "section": sectionCtrl.text.trim(),
                        "fatherMobile": mobileCtrl.text.trim(),
                        "createdAt": DateTime.now(),
                        "active": true,
                      };

                      if (user == null) {
                        await db.collection('users').add(data);
                      } else {
                        await db.collection('users').doc(user.id).update(data);
                      }

                      Navigator.pop(context);

                      fetchUsers();
                    } catch (e) {
                      showError("Save failed : $e");
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ERROR POPUP
  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// TABLE ROW
  DataRow buildRow(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final bool active = data['active'] ?? true;

    return DataRow(
      cells: [
        DataCell(Text(data['name'] ?? "")),
        DataCell(Text(data['email'] ?? "")),
        DataCell(Text(data['role'] ?? "")),
        DataCell(Text(data['class'] ?? "")),
        DataCell(Text(data['section'] ?? "")),
        DataCell(Text(data['registerNo'] ?? "")),

        /// ACTIVE SWITCH
        DataCell(
          Switch(
            value: active,
            onChanged: (val) {
              db.collection('users').doc(doc.id).update({'active': val});

              fetchUsers();
            },
          ),
        ),

        /// ACTIONS
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => userPopup(user: doc),
              ),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteUser(doc.id),
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
            /// ROLE FILTER
            DropdownButtonFormField<String>(
              hint: const Text("Select Role"),

              initialValue: selectedRole,

              items: roles.map((r) {
                return DropdownMenuItem(value: r, child: Text(r.toUpperCase()));
              }).toList(),

              onChanged: (v) {
                setState(() {
                  selectedRole = v;
                });

                fetchUsers();
              },
            ),

            const SizedBox(height: 20),

            /// TABLE VIEW
            if (selectedRole == null)
              const Expanded(
                child: Center(child: Text("Select role to view users")),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade200,
                    ),

                    columns: const [
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Class")),
                      DataColumn(label: Text("Section")),
                      DataColumn(label: Text("Register No")),
                      DataColumn(label: Text("Active")),
                      DataColumn(label: Text("Actions")),
                    ],

                    rows: users.map((doc) => buildRow(doc)).toList(),
                  ),
                ),
              ),

            if (isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
