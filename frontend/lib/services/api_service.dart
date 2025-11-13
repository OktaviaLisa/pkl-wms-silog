import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti port sesuai backend kamu
  static const String baseUrl = "http://localhost:8081";

  static Future<String> pingServer() async {
    final response = await http.get(Uri.parse("$baseUrl/ping"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'];
    } else {
      throw Exception("Gagal connect ke backend");
    }
  }
}
