import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:8081";

  //---------------------------------------------------------
  // 1. PING SERVER → cek apakah backend aktif
  //---------------------------------------------------------
  Future<String> pingServer() async {
    final url = Uri.parse("$baseUrl/ping");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["message"] ?? "No message";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  //---------------------------------------------------------
  // 2. GET USERS → Ambil data user dari backend
  //---------------------------------------------------------
  Future<List<dynamic>> getUsers() async {
    final url = Uri.parse("$baseUrl/api/user/user");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"];
      } else {
        throw Exception("Failed to load users");
      }
    } catch (e) {
      print("ERROR API GET USERS: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 3. CREATE USER → Register user baru
  //---------------------------------------------------------
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/user/user");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data; // { "message": "...", "data": {...} }
      } else {
        throw Exception(data["error"] ?? "Gagal membuat user");
      }
    } catch (e) {
      print("ERROR API CREATE USER: $e");
      rethrow;
    }
  }
}
