import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:face_detector/home_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }
  runApp(const FaceApp());
}

class FaceApp extends StatelessWidget {
  const FaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCExtractor Sentiment Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange, // Matches the CC Orange
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// Keep the splash screen here since it acts as the initial router
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orangeAccent.withOpacity(0.2),
              ),
              child: const Icon(Icons.receipt_long, size: 80, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 30),
            const Text(
              'Sentiment Logger',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Initializing System... 85%',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }
}