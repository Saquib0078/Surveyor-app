

import 'package:damagedetection1/surveyor/MainNavigationScreen.dart';
import 'package:flutter/material.dart';

import 'Login.dart';
import 'SurveyorMapScreen.dart';
import 'UsePrefs.dart';


class SurveyorSplashScreen extends StatefulWidget {
  @override
  _SurveyorSplashScreenState createState() => _SurveyorSplashScreenState();
}

class _SurveyorSplashScreenState extends State<SurveyorSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    String? surveyorId = await UserPreferences.getSurveyorId();

    if (surveyorId != null && surveyorId.isNotEmpty) {
      // Already logged in → go to map screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigationScreen()),
      );
    } else {
      // Not logged in → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
