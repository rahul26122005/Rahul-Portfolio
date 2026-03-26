import 'package:flutter/material.dart';

class ResumeViewPage extends StatelessWidget {
  const ResumeViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: Center(
        child: Container(
          width: 950,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              // ================= LEFT PANEL =================
              Container(
                width: 280,
                color: const Color(0xFFEDEDED),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PHOTO
                    Center(
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage:
                            const AssetImage('assets/images/profile.jpg'),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // CONTACT
                    const Text("CONTACT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1)),
                    const Divider(thickness: 1),

                    const SizedBox(height: 8),

                    const Text("📧 rahul@email.com"),
                    const SizedBox(height: 6),
                    const Text("📞 9876543210"),
                    const SizedBox(height: 6),
                    const Text("📍 Tamil Nadu"),
                    const SizedBox(height: 6),
                    const Text("🔗 linkedin.com/rahul"),

                    const SizedBox(height: 25),

                    // EDUCATION
                    const Text("EDUCATION",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1)),
                    const Divider(thickness: 1),

                    const SizedBox(height: 8),

                    const Text(
                      "B.E Biomedical Engineering",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text("Anna University"),
                    const Text("2022 - 2026"),

                    const SizedBox(height: 25),

                    // SKILLS
                    const Text("SKILLS",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1)),
                    const Divider(thickness: 1),

                    const SizedBox(height: 8),

                    const Text("• Flutter"),
                    const Text("• Firebase"),
                    const Text("• Python"),
                    const Text("• Machine Learning"),

                    const SizedBox(height: 25),

                    // LANGUAGES
                    const Text("LANGUAGES",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1)),
                    const Divider(thickness: 1),

                    const SizedBox(height: 8),

                    const Text("English (Fluent)"),
                    const Text("Tamil (Native)"),
                  ],
                ),
              ),

              // ================= RIGHT PANEL =================
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NAME
                        const Text(
                          "RAHUL R",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 5),

                        // ROLE
                        const Text(
                          "Flutter Developer",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              letterSpacing: 1),
                        ),

                        const SizedBox(height: 10),

                        const Divider(thickness: 2),

                        const SizedBox(height: 15),

                        // CAREER OBJECTIVE
                        const Text("CAREER OBJECTIVE",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1)),

                        const SizedBox(height: 6),
                        const Divider(),

                        const Text(
                          "Motivated Flutter developer with strong analytical and problem-solving skills. Passionate about building scalable and user-friendly applications.",
                        ),

                        const SizedBox(height: 20),

                        // PROJECTS
                        const Text("PROJECTS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1)),

                        const SizedBox(height: 6),
                        const Divider(),

                        const Text(
                            "• Attendance Management System\nBuilt using Flutter + Firebase with role-based authentication."),

                        const SizedBox(height: 8),

                        const Text(
                            "• Customer Churn Prediction\nMachine Learning model using Random Forest (Accuracy: 86.49%)."),

                        const SizedBox(height: 20),

                        // INTERNSHIP
                        const Text("INTERNSHIP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1)),

                        const SizedBox(height: 6),
                        const Divider(),

                        const Text(
                            "Intern - XYZ Company\nWorked on mobile UI development and Firebase backend integration."),

                        const SizedBox(height: 20),

                        // CERTIFICATIONS
                        const Text("CERTIFICATIONS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1)),

                        const SizedBox(height: 6),
                        const Divider(),

                        const Text(
                            "• Flutter Development - Udemy\n• Machine Learning - Coursera"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),),
    );
  }
}