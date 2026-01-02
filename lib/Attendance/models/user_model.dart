class AppUser {
  // ================= CORE =================
  final String uid;
  final String role; // admin | teacher | student | guest
  final String name;
  final String email;

  // ================= STUDENT =================
  final String? registerNo;
  final String? classId;
  final String? sectionId;
  final String? fatherMobile;
  final String? dob;

  // ================= TEACHER =================
  final List<String>? assignedClasses;

  // ================= COMMON =================
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,

    // Student
    this.registerNo,
    this.classId,
    this.sectionId,
    this.fatherMobile,
    this.dob,

    // Teacher
    this.assignedClasses,

    // Common
    this.createdAt,
  });

  // 🔹 Firestore → AppUser
  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      role: data['role'] ?? 'guest',
      name: data['name'] ?? '',
      email: data['email'] ?? '',

      // Student
      registerNo: data['registerNo'],
      classId: data['classId'],
      sectionId: data['sectionId'],
      fatherMobile: data['fatherMobile'],
      dob: data['dob'],

      // Teacher
      assignedClasses: data['assignedClasses'] != null
          ? List<String>.from(data['assignedClasses'])
          : null,

      // Common
      createdAt: data['createdAt']?.toDate(),
    );
  }

  // 🔹 AppUser → Firestore
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'email': email,

      if (registerNo != null) 'registerNo': registerNo,
      if (classId != null) 'classId': classId,
      if (sectionId != null) 'sectionId': sectionId,
      if (fatherMobile != null) 'fatherMobile': fatherMobile,
      if (dob != null) 'dob': dob,

      if (assignedClasses != null) 'assignedClasses': assignedClasses,

      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  // ================= ROLE HELPERS =================
  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
  bool get isGuest => role == 'guest';
}


