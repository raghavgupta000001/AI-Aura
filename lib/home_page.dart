import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:face_detector/pages/face_detector_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = "";
  bool _isLoading = true;

  // Colors based on your elegant UI reference
  final Color _bgColor = const Color(0xFFF3F4ED);
  final Color _darkGreen = const Color(0xFF3F564C);
  final Color _lightGreen = const Color(0xFFD9F2E6);

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  // Checks local storage to see if the user already entered their name
  Future<void> _checkUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('userName');

    if (savedName == null || savedName.isEmpty) {
      // First time opening the app! Show the popup.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOnboardingDialog();
      });
    } else {
      // Welcome back! Load the name.
      setState(() {
        _name = savedName;
        _isLoading = false;
      });
    }
  }

  // The popup that asks for Name and Age once
  void _showOnboardingDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Forces them to enter info
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Welcome to Aura", style: TextStyle(color: _darkGreen, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "What is your first name?",
                  labelStyle: TextStyle(color: _darkGreen.withOpacity(0.6)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _darkGreen)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "How old are you?",
                  labelStyle: TextStyle(color: _darkGreen.withOpacity(0.6)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _darkGreen)),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty && ageController.text.isNotEmpty) {
                  // Save to device memory
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userName', nameController.text);
                  await prefs.setString('userAge', ageController.text);

                  setState(() {
                    _name = nameController.text;
                    _isLoading = false;
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Begin", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: _bgColor, body: Center(child: CircularProgressIndicator(color: _darkGreen)));
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE5CCB9), // Subtle peach
                        radius: 16,
                        child: Icon(Icons.person, size: 20, color: _darkGreen.withOpacity(0.6)),
                      ),
                      const SizedBox(width: 12),
                      Text("Aura AI", style: TextStyle(color: _darkGreen, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  Icon(Icons.notifications_none, color: _darkGreen),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // GREETING
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Welcome home, $_name.",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _darkGreen, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ready to check in?",
                    style: TextStyle(fontSize: 28, color: _darkGreen.withOpacity(0.6), fontWeight: FontWeight.w400, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // THE GIANT SCAN BUTTON
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FaceDetectorPage()));
              },
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 40, spreadRadius: 5, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: _darkGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "SCAN MOOD",
                      style: TextStyle(color: _darkGreen, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // BOTTOM NAVIGATION BAR (Visual Match)
            Container(
              margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavIcon(Icons.spa, "REFLECT", isActive: true),
                  _buildNavIcon(Icons.bar_chart, "INSIGHTS"),
                  _buildNavIcon(Icons.edit_note, "LOG"),
                  _buildNavIcon(Icons.settings, "SETTINGS"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the bottom nav bar
  Widget _buildNavIcon(IconData icon, String label, {bool isActive = false}) {
    return Container(
      padding: isActive ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.all(0),
      decoration: isActive ? BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? _darkGreen : Colors.grey, size: 24),
          if (isActive) const SizedBox(height: 4),
          if (isActive)
            Text(label, style: TextStyle(color: _darkGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}