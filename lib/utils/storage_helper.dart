import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const _reminderKey = 'reminders';
  static const _userNameKey = 'user_name';

  // Fungsi menyimpan daftar pengingat
  static Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final reminderStrings = reminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList(_reminderKey, reminderStrings);
  }

  // Fungsi memuat daftar pengingat
  static Future<List<Map<String, dynamic>>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderStrings = prefs.getStringList(_reminderKey) ?? [];

    return reminderStrings.map((str) {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return {
        'title': decoded['title'],
        'description': decoded['description'],
        'time': decoded['time'], // format ISO8601 string (String)
      };
    }).toList();
  }

  // Fungsi menyimpan nama user
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Fungsi memuat nama user
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }
}
