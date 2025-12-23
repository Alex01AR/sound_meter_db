import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_open_ad_manager.dart';

import 'home_page.dart';
import 'permission_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppOpenAdManager _adManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();
    _adManager.loadAd();
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // Artificial delay for splash effect (2 seconds)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    _adManager.showAdIfAvailable(() {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    // Check shared preferences for "first launch"
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    // Check microphone permission
    var status = await Permission.microphone.status;

    if (!mounted) return;

    if (isFirstLaunch || !status.isGranted) {
      // Navigate to Permission Page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PermissionPage()),
      );
    } else {
      // Navigate to Home Page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.graphic_eq,
              size: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'NoiseSense',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Noise & Sound Level Meter',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
