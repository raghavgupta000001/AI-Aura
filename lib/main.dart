import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// Global variable to hold our cameras
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

// 1. App wrapper
class FaceApp extends StatelessWidget {
  const FaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Condition Detector',
      debugShowCheckedModeBanner: false, // Removes the red 'DEBUG' banner
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // Clean, modern font
      ),
      home: const SplashScreen(), // Start at the Splash Screen now!
    );
  }
}

// ==========================================
// 2. THE NEW SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 2.5 seconds, then smoothly transition to the main screen
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const FaceDetectorScreen(),
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
      backgroundColor: const Color(0xFF121212), // Sleek dark mode background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A nice big icon for the app
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.2),
              ),
              child: const Icon(Icons.face_retouching_natural, size: 80, color: Colors.blueAccent),
            ),
            const SizedBox(height: 30),
            const Text(
              'Aura AI',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Real-time Condition & Lighting Detection',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.blueAccent), // Loading spinner
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. THE UPGRADED MAIN SCREEN
// ==========================================
class FaceDetectorScreen extends StatefulWidget {
  const FaceDetectorScreen({super.key});

  @override
  State<FaceDetectorScreen> createState() => _FaceDetectorScreenState();
}

class _FaceDetectorScreenState extends State<FaceDetectorScreen> {
  CameraController? _cameraController;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
    ),
  );

  bool _isProcessing = false;
  String _conditionText = "Detecting...";
  bool _isCameraInitialized = false;

  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  String _lightingText = "Analyzing Light...";
  IconData _lightingIcon = Icons.lightbulb_outline; // Dynamic icon
  Color _lightingColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    CameraDescription frontCamera = cameras.length > 1 ? cameras[1] : cameras[0];

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      _minAvailableExposureOffset = await _cameraController!.getMinExposureOffset();
      _maxAvailableExposureOffset = await _cameraController!.getMaxExposureOffset();

      _cameraController!.startImageStream((CameraImage image) async {
        if (_isProcessing) return;
        _isProcessing = true;
        try {
          await _processCameraFrame(image);
        } catch (e) {
          print("🚨 AI CRASHED: $e");
        } finally {
          _isProcessing = false;
        }
      });

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Camera init error: $e');
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    // --- LIGHTING DETECTION ---
    final Uint8List luminanceBytes = image.planes[0].bytes;
    int totalLuminance = 0;
    for (int i = 0; i < luminanceBytes.length; i += 10) {
      totalLuminance += luminanceBytes[i];
    }
    double avgLuminance = totalLuminance / (luminanceBytes.length / 10);

    if (avgLuminance < 60) {
      _lightingText = "Low Light (Boosting)";
      _lightingIcon = Icons.brightness_3;
      _lightingColor = Colors.amberAccent;
      _cameraController!.setExposureOffset(_maxAvailableExposureOffset);
    } else if (avgLuminance > 210) {
      _lightingText = "Bright Light (Dimming)";
      _lightingIcon = Icons.brightness_high;
      _lightingColor = Colors.orangeAccent;
      _cameraController!.setExposureOffset(_minAvailableExposureOffset);
    } else {
      _lightingText = "Optimal Lighting";
      _lightingIcon = Icons.brightness_auto;
      _lightingColor = Colors.greenAccent;
      _cameraController!.setExposureOffset(0.0);
    }

    // --- FACE DETECTION ---
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation imageRotation = InputImageRotation.rotation270deg;
    final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize, rotation: imageRotation, format: inputImageFormat, bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final Face firstFace = faces.first;
      double? smileProb = firstFace.smilingProbability;
      double? leftEyeProb = firstFace.leftEyeOpenProbability;
      double? rightEyeProb = firstFace.rightEyeOpenProbability;

      String newCondition = "Stressed 😫";

      if (leftEyeProb != null && rightEyeProb != null && (leftEyeProb < 0.2 && rightEyeProb < 0.2)) {
        newCondition = "Tired 😴";
      } else if (smileProb != null && smileProb > 0.60) {
        newCondition = "Happy 😁";
      }

      if (_conditionText != newCondition) {
        setState(() { _conditionText = newCondition; });
      }
    } else {
      if (_conditionText != "No face found") {
        setState(() { _conditionText = "No face found"; });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Makes the edges clean if camera aspect ratio is different
      body: _isCameraInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          // The Camera Feed
          CameraPreview(_cameraController!),

          // Top App Bar Area (Transparent)
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                Icon(_lightingIcon, color: _lightingColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  _lightingText,
                  style: TextStyle(color: _lightingColor, fontSize: 16, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 4, color: Colors.black)]),
                ),
              ],
            ),
          ),

          // The Modern Bottom Dashboard
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.85), // Sleek dark grey with transparency
                borderRadius: BorderRadius.circular(24), // Smooth rounded corners
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1), // Subtle outline
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "CURRENT STATE",
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _conditionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      )
          : const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );
  }
}