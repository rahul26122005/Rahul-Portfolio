import 'package:flutter/material.dart';
import 'package:my_flutter_webside/Hub_Dashboard/screens/screens.dart';
import 'package:my_flutter_webside/admin/admin_panel.dart';
import 'package:my_flutter_webside/admin/manage_classes_page.dart';
import 'package:my_flutter_webside/admin/manage_teachers_page.dart';
import 'package:my_flutter_webside/notfound_page.dart';
import 'package:my_flutter_webside/Attendance/screens/screens.dart';
import 'package:my_flutter_webside/role_guard.dart';

class AppRoutes {
  // ================= ROUTE NAMES =================
  static const String attendanceLogin = '/attendance/login';
  static const String teacherSignup = '/attendance/signup';
  static const String forgotPassword = '/attendance/forgot_password';

  static const String teacherDashboard = '/attendance/teacher/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String guestDashboard = '/attendance/guest/dashboard';

  static const String uploadStudents = '/attendance/teacher/upload_students';
  static const String markAttendance = '/attendance/teacher/mark_attendance';
  static const String uploadMarks = '/attendance/teacher/upload_marks';
  static const String generateReport = '/attendance/teacher/generate_report';
  static const String monthlysummary = '/attendance/teacher/monthly_summary';

  static const String studentDashboard = '/attendance/student/dashboard';
  static const String studentReport = '/attendance/student/report';

  static const String adminPanel = '/admin/panel';
  static const String manageClasses = '/admin/classes';
  static const String manageTeachers = '/admin/teachers';

  static const String dashboard = '/portfolio/dashboard';
  static const String projects = '/portfolio/projects';

  static const String notFound = '/not_found';

  // ================= ROUTE TABLE =================
  static Map<String, WidgetBuilder> routes = {
    // ---------- PUBLIC ----------
    attendanceLogin: (context) => LoginScreen(),
    teacherSignup: (context) => SignupScreen(),
    forgotPassword: (context) => const ForgotPassword(),

    // ---------- TEACHER / ADMIN ----------
    teacherDashboard: (context) => RoleGuard(
      allowedRoles: const ['teacher', 'admin'],
      child: const TeacherDashboard(role: 'teacher'),
    ),

    adminDashboard: (context) => RoleGuard(
      allowedRoles: const ['admin'],
      child: const TeacherDashboard(role: 'admin'),
    ),

    uploadStudents: (context) => RoleGuard(
      allowedRoles: const ['teacher', 'admin'],
      child: const UploadStudentsPage(),
    ),

    markAttendance: (context) => RoleGuard(
      allowedRoles: const ['teacher', 'admin'],
      child: const AttendancePage(),
    ),

    uploadMarks: (context) => RoleGuard(
      allowedRoles: const ['teacher', 'admin'],
      child: const UploadMarksPage(),
    ),

    generateReport: (context) => RoleGuard(
      allowedRoles: const ['teacher', 'admin'],
      child: const AttendanceReportGeneratePage(),
    ),
    monthlysummary: (context) => RoleGuard(
      allowedRoles: const ['teacher', 'admin'],
      child: const MonthlySummaryPage(),
    ),

    // ---------- STUDENT ----------
    studentDashboard: (context) => RoleGuard(
      allowedRoles: const ['student'],
      child: const StudentDashboard(),
    ),

    studentReport: (context) => RoleGuard(
      allowedRoles: const ['student'],
      child: const StudentReportPage(),
    ),

    // ---------- ADMIN ONLY ----------
    adminPanel: (context) =>
        RoleGuard(allowedRoles: const ['admin'], child: const AdminPanel()),

    manageClasses: (context) => RoleGuard(
      allowedRoles: const ['admin'],
      child: const ManageClassesPage(),
    ),

    manageTeachers: (context) => RoleGuard(
      allowedRoles: const ['admin'],
      child: const ManageTeachersPage(),
    ),

    // ---------- PORTFOLIO (PUBLIC OR AUTH — YOUR CHOICE) ----------
    dashboard: (context) => const DashboardPage(),
    projects: (context) => const ProjectsPage(),

    // ---------- GUEST ----------
    guestDashboard: (context) => const GuestDashboard(),

    // ---------- NOT FOUND ----------
    notFound: (context) => const NotFoundPage(),
  };

  // ================= FALLBACK (WEB URL PROTECTION) =================
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => const NotFoundPage());
  }
}
