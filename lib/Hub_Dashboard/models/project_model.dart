class Project {
  final String title;
  final String description;
  final String url;
  final String role;

  Project({
    required this.title,
    required this.description,
    required this.url,
    required this.role,
  });

  // ================= FROM FIRESTORE =================
  factory Project.fromMap(Map<String, dynamic> data) {
    return Project(
      title: data['title'] ?? 'Untitled Project',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      role: data['role'] ?? 'user',
    );
  }

  // ================= TO FIRESTORE =================
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'role': role,
    };
  }
}
