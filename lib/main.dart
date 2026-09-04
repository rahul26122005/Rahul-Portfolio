import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';


final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint("Firebase Error: $e");

    debugPrintStack(stackTrace: stack);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeNotifier())],

      child: const MyApp(),
    ),
  );
}

// =====================================================
// THEME NOTIFIER
// =====================================================

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }
}

// =====================================================
// MAIN APP
// =====================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Rahul Portfolio',

      // =================================================
      // LIGHT THEME
      // =================================================
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

        scaffoldBackgroundColor: Colors.grey.shade100,

        cardColor: Colors.white,

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,

          foregroundColor: Colors.white,

          elevation: 0,
        ),

        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,

          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      // =================================================
      // DARK THEME
      // =================================================
      darkTheme: ThemeData(
        useMaterial3: true,

        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,

          brightness: Brightness.dark,
        ),

        scaffoldBackgroundColor: const Color(0xFF121212),

        cardColor: const Color(0xFF1E1E1E),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),

          foregroundColor: Colors.white,

          elevation: 0,
        ),

        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF121212)),
      ),

      themeMode: themeNotifier.themeMode,

      // =================================================
      // SAFE AREA
      // =================================================
      builder: (context, child) {
        return SafeArea(child: child ?? const SizedBox());
      },

      // =================================================
      // ANALYTICS
      // =================================================
      navigatorObservers: [
        FirebaseAnalyticsObserver(
          analytics: analytics,

          nameExtractor: (settings) {
            return settings.name ?? 'unknown_route';
          },
        ),
      ],

      initialRoute: AppRoutes.dashboard,

      routes: AppRoutes.routes,

      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
