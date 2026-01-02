import 'package:flutter/material.dart';

class GuestDashboard extends StatelessWidget {
  const GuestDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.green],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.visibility, size: 60, color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                "Guest Access",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: ListView(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.bar_chart),
                        title: Text("View Attendance Summary"),
                        subtitle: Text("Read-only"),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.assignment),
                        title: Text("View Marks Summary"),
                        subtitle: Text("Read-only"),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
