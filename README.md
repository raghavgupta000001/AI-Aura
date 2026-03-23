# 🌟 Aura AI: Real-Time Sentiment Logger
**CCExtractor GSoC 2026 Qualification Task**

A privacy-first, on-device Flutter application built for the CCExtractor qualification task. Aura AI utilizes Google ML Kit to track facial telemetry and infer user conditions (Happy, Tired, Stressed) in real-time, while dynamically adjusting camera hardware exposure based on environmental lighting.

*(Drop your demo video or screenshot here!)*

## ✨ Key Features

* **Real-time Condition Tracking:** Infers user states using localized facial telemetry (smiling probability and eye-open probability).
* **Dynamic Hardware Exposure:** Calculates average pixel luminance in real-time. Automatically boosts hardware camera exposure in low-light environments and dims it in overly bright settings to maintain AI tracking accuracy.
* **Premium UI/UX:** Features a minimalist, wellness-inspired "Light Mode" dashboard, smooth screen transitions, and persistent local storage for user onboarding.
* **100% On-Device:** No cloud APIs are used for inference, ensuring zero latency and complete user privacy.

## 🧠 Technical Architecture & Problem Solving

During development, two major technical hurdles were overcome to ensure stable, high-framerate performance on Android hardware:

1. **The `YUV_420_888` to `NV21` Pipeline Deadlock:** By default, Android camera streams output the `YUV_420_888` format, causing Google ML Kit to throw `InputImageConverterError` platform exceptions and drop frames. This was resolved by forcing the `CameraController` to utilize an `ImageFormatGroup.nv21` byte grouping directly at the hardware initialization level, bypassing the need for expensive, bottlenecking software conversions.

2. **Zero-Latency Lighting Calculation:** Instead of running a heavy secondary AI model for environmental lighting, the app mathematically samples the luminance bytes of the first image plane (`image.planes[0].bytes`), checking every 10th pixel. This provides an incredibly fast average room brightness score (0-255) without blocking the main camera UI thread.

## 📂 Project Structure (Clean Architecture)

The codebase is strictly separated to ensure high maintainability and scalability:
```text
lib/
 ├── main.dart                  # App entry point and theme configuration
 ├── home_page.dart             # Onboarding UI, shared_preferences, and dashboard
 ├── pages/
 │    └── face_detector_page.dart # UI layer for the camera stream and state overlays
 └── services/
      └── face_detector_service.dart # The "Brain": Handles ML Kit initialization and logic
