import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<String?> getSurveyorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('surveyor_id');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<Map<String, dynamic>> getAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'surveyor_id': prefs.getString('surveyor_id'),
      'user_name': prefs.getString('user_name'),
      'user_ref': prefs.getString('user_ref'),
      'ref_id': prefs.getString('ref_id'),
      'assigned_tasks': prefs.getInt('assigned_tasks'),
      'is_logged_in': prefs.getBool('is_logged_in'),
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Removes all stored data
  }
}
