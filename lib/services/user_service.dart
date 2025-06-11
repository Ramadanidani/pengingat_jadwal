import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  static const String baseUrl = 'https://6840967d5b39a8039a589083.mockapi.io/api/v1/users';

  // Register
  static Future<void> register(UserModel user) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal daftar');
    }
  }

  // Login
  static Future<bool> login(String email, String password) async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List users = json.decode(response.body);
      return users.any((user) =>
      user['email'] == email && user['password'] == password);
    } else {
      return false;
    }
  }

  // ✅ Tambahkan ini: Ambil user berdasarkan email
  static Future<UserModel?> getUserByEmail(String email) async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List users = json.decode(response.body);
      final userData = users.firstWhere(
            (user) => user['email'] == email,
        orElse: () => null,
      );

      if (userData != null) {
        return UserModel.fromJson(userData);
      }
    }

    return null;
  }
}
