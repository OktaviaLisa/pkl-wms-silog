import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:8081";

  // 1. PING SERVER → cek apakah backend aktif
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

  // 2. GET USERS → Ambil data user dari backend
  Future<List<dynamic>> getAllUsers() async {
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

  // Tambahan khusus untuk register.dart supaya error getUsers hilang
  Future<List<dynamic>> getUsers() async {
    return await getAllUsers(); // alias tanpa merubah struktur
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
        body: jsonEncode({"username": username, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data["error"] ?? "Login gagal");
      }
    } catch (e) {
      print("ERROR API LOGIN: $e");
      rethrow;
    }
  }

  // 4. CREATE USER → Register user baru
Future<Map<String, dynamic>> createUser({
  required String email,
  required String username,
  required String password,
  required int roleGudang,   // <<< WAJIB INTEGER
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
        "role_gudang": roleGudang,  
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
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

  //---------------------------------------------------------
  // 8. GET SATUAN → Ambil data satuan untuk dropdown
  //---------------------------------------------------------
  Future<List<dynamic>> getSatuan() async {
    final url = Uri.parse("$baseUrl/api/satuan/list");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load satuan");
      }
    } catch (e) {
      print("ERROR API GET SATUAN: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 9. CREATE PRODUK → Buat produk baru
  //---------------------------------------------------------
  Future<bool> createProduk({
    required String kodeProduk,
    required String namaProduk,
    required int volumeProduk,
    required int idSatuan,
  }) async {
    final url = Uri.parse("$baseUrl/api/produk/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "kode_produk": kodeProduk,
          "nama_produk": namaProduk,
          "volume": volumeProduk,
          "id_satuan": idSatuan,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("ERROR API CREATE PRODUK: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 10. CREATE GUDANG → Buat gudang baru
  //---------------------------------------------------------
  Future<bool> createGudang({
    required String namaGudang,
    required String alamatGudang,
  }) async {
    final url = Uri.parse("$baseUrl/api/gudang/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama_gudang": namaGudang,
          "alamat": alamatGudang,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("ERROR API CREATE GUDANG: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getOutbound({int? userId}) async {
    String urlString = "$baseUrl/api/outbound/getOutbound";
    if (userId != null) {
      urlString += "?user_id=$userId";
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load outbound stock");
      }
    } catch (e) {
      print("ERROR API GET OUTBOUND: $e");
      rethrow;
    }
  }

    Future<bool> createOutbound(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/outbound/postOutbound");

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
        throw Exception(errorData["error"] ?? "Gagal menyimpan outbound");
      }
    } catch (e) {
      print("ERROR API CREATE OUTBOUND: $e");
      rethrow;
    }
  }

  //---------------------------------------------------------
  // 9. CREATE PRODUK → Tambah produk baru
  //-------------------------------------------------------
  Future<Map<String, dynamic>> getUserGudang({required int userId}) async {
    final url = Uri.parse("$baseUrl/api/gudang/user?user_id=$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"];
      } else {
        throw Exception("Failed to load user gudang");
      }
    } catch (e) {
      print("ERROR API GET USER GUDANG: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getInventory({required int gudangId}) async {
    final url = Uri.parse("$baseUrl/api/inventory/list?gudang_id=$gudangId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load inventory");
      }
    } catch (e) {
      print("ERROR API GET INVENTORY: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getAvailableProduk({required int gudangId}) async {
    final url = Uri.parse("$baseUrl/api/produk/available?gudang_id=$gudangId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load available produk");
      }
    } catch (e) {
      print("ERROR API GET AVAILABLE PRODUK: $e");
      rethrow;
    }
  }


}

  