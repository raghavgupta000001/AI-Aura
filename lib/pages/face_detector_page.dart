import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_detector/services/face_detector_service.dart';
import 'package:face_detector/main.dart'; // To access the global cameras list

class FaceDetectorPage extends StatefulWidget {
  const FaceDetectorPage({super.key});

  @override
  State<FaceDetectorPage> createState() => _FaceDetectorPageState();
}

class _FaceDetectorPageState extends State<FaceDetectorPage> {
  CameraController? _cameraController;

  // Initialize our new AI Service
  final FaceDetectorService _aiService = FaceDetectorService();

  bool _isProcessing = false;
  String _conditionText = "Detecting...";
  bool _isCameraInitialized = false;

  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  String _lightingText = "Analyzing Light...";
  IconData _lightingIcon = Icons.lightbulb_outline;
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
    // --- LIGHTING LOGIC ---
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

    // --- FACE DETECTION LOGIC ---
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

    // Use the AI Service to process the image
    final List<Face> faces = await _aiService.processImage(inputImage);

    if (faces.isNotEmpty) {
      // Use the AI Service to analyze the specific face
      String newCondition = _aiService.analyzeFace(faces.first);

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
    _aiService.dispose(); // Dispose the service properly
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          // NEW: A Back Button so the user can return to the Home Page
          Positioned(
            top: 50,
            left: 16,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context), // Pops the screen off the stack
                ),
              ),
            ),
          ),

          // MOVED: The Lighting Indicator is now on the top right
          Positioned(
            top: 58,
            right: 20,
            child: SafeArea(
              child: Row(
                children: [
                  Text(
                    _lightingText,
                    style: TextStyle(color: _lightingColor, fontSize: 14, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 4, color: Colors.black)]),
                  ),
                  const SizedBox(width: 8),
                  Icon(_lightingIcon, color: _lightingColor, size: 24),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
          : const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
    );
  }
}