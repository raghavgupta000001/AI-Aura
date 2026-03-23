import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// This service handles all the heavy lifting for the AI.
class FaceDetectorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
    ),
  );

  // Processes the raw camera image
  Future<List<Face>> processImage(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  // Contains our custom logic for mapping face data to emotions
  String analyzeFace(Face face) {
    double? smileProb = face.smilingProbability;
    double? leftEyeProb = face.leftEyeOpenProbability;
    double? rightEyeProb = face.rightEyeOpenProbability;

    String condition = "Stressed 😫"; // Default baseline

    if (leftEyeProb != null && rightEyeProb != null && (leftEyeProb < 0.2 && rightEyeProb < 0.2)) {
      condition = "Tired 😴";
    } else if (smileProb != null && smileProb > 0.60) {
      condition = "Happy 😁";
    }

    return condition;
  }

  void dispose() {
    _faceDetector.close();
  }
}