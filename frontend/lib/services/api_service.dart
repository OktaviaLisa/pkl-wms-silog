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
  // 3. LOGIN → Validasi username dan password
  //---------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // { "message": "Login berhasil", "user": {...} }
      } else {
        throw Exception(data["error"] ?? "Login gagal");
      }
    } catch (e) {
      print("ERROR API LOGIN: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 4. CREATE USER → Register user baru
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
  //---------------------------------------------------------
  // 5. GET INBOUND LIST → Ambil semua data inbound_stock
  //---------------------------------------------------------
  Future<List<dynamic>> getInbound({int? userId}) async {
    String urlString = "$baseUrl/api/inbound/list";
    if (userId != null) {
      urlString += "?user_id=$userId";
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"];
      } else {
        throw Exception("Failed to load inbound stock");
      }
    } catch (e) {
      print("ERROR API GET INBOUND: $e");
      rethrow;
    }
  }

  Future<bool> createInbound(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/inbound/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["error"] ?? "Gagal menyimpan inbound");
      }
    } catch (e) {
      print("ERROR API CREATE INBOUND WITH NAMES: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 6. GET PRODUK → Ambil data produk untuk dropdown
  //---------------------------------------------------------
  Future<List<dynamic>> getProduk() async {
    final url = Uri.parse("$baseUrl/api/produk/list");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load produk");
      }
    } catch (e) {
      print("ERROR API GET PRODUK: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 7. GET GUDANG → Ambil data gudang untuk dropdown
  //---------------------------------------------------------
  Future<List<dynamic>> getGudang() async {
    final url = Uri.parse("$baseUrl/api/gudang/list");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load gudang");
      }
    } catch (e) {
      print("ERROR API GET GUDANG: $e");
      rethrow;
    }
  }

}
