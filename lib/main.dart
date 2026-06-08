import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:renalbites/screens/renalprofile_screen.dart';
import 'package:renalbites/screens/splash_screen.dart';
import 'package:renalbites/screens/report_screen.dart';
import 'package:renalbites/screens/foodlog_screen.dart';
import 'package:renalbites/screens/homepage_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const RenalBitesApp());
}

class RenalBitesApp extends StatelessWidget {
  const RenalBitesApp({super.key});

  Route _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return _buildRoute(const HomePage(), settings);
          case '/report':
            return _buildRoute(const ReportScreen(), settings);
          case '/calendar':
            return _buildRoute(const FoodLogScreen(), settings);
          case '/profile':
            return _buildRoute(const RenalProfileScreen(), settings);
          default:
            return _buildRoute(const SplashScreen(), settings);
        }
      },

      theme: ThemeData(
        primarySwatch: Colors.green,

        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 14, 63, 39),
          foregroundColor: Colors.white, // Set the text color of the AppBar
          elevation: 20, // Add shadow to the AppBar
        ),
      ),
    );
  }
}
