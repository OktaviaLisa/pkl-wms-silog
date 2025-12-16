import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8081";

  // PING SERVER → cek apakah backend aktif
  Future<String> pingServer() async {
    final url = Uri.parse("$baseUrl/ping");

    try {
      print('🏓 Testing ping to: $url');
      final response = await http.get(url);
      print('🏓 Ping response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["message"] ?? "No message";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      print('🏓 Ping error: $e');
      return "Error: $e";
    }
  }

  // GET USERS → Ambil data user dari backend
  Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse("$baseUrl/api/user/user");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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

  Future<List<dynamic>> getUsers() async {
    return await getAllUsers();
  }

  // LOGIN
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
        // Simpan token ke SharedPreferences
        if (data['token'] != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', data['token']);
            print('🔐 Token saved: ${data['token'].substring(0, 20)}...');

            // Verify token tersimpan
            final savedToken = prefs.getString('token');
            print('✅ Token verified: ${savedToken?.substring(0, 20)}...');
          } catch (e) {
            print('❌ Error saving token: $e');
          }
        } else {}
        return data;
      } else {
        throw Exception(data["error"] ?? "Login gagal");
      }
    } catch (e) {
      print("ERROR API LOGIN: $e");
      rethrow;
    }
  }

  // CREATE USER
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String username,
    required String password,
    required int roleGudang,
  }) async {
    final url = Uri.parse("$baseUrl/api/user/user");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
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

  // UPDATE USER (ubah role gudang)
  Future<bool> updateUser({
    required int idUser,
    required int roleGudang,
  }) async {
    final url = Uri.parse('$baseUrl/api/user/update');

    final headers = await _getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({"idUser": idUser, "role_gudang": roleGudang}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Gagal update user");
    }
  }

  // DELETE USER
  Future<bool> deleteUser(int idUser) async {
    final url = Uri.parse('$baseUrl/api/user/delete/$idUser');

    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Gagal hapus user");
    }
  }

  // Helper untuk mendapatkan token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
    } else {}
    return token;
  }

  // Set token manual untuk testing
  Future<void> setAdminToken() async {
    const adminToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo5OTksInJvbGUiOjk5LCJleHAiOjE3NjU3NzQ2NTh9.8noNqaoG342-aDcGBDFm7Enz7rEqpQrASahVxAaxsO0";
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', adminToken);
  }

  // Helper untuk membuat headers dengan token
  Future<Map<String, String>> _getHeaders() async {
    var token = await _getToken();
    final headers = {"Content-Type": "application/json"};

    // Jika tidak ada token, set token admin otomatis
    if (token == null) {
      await setAdminToken();
      token = await _getToken();
    }

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    } else {
      print('❌ Still no token after auto-set');
    }
    return headers;
  }

  // GET INBOUND LIST
  Future<List<dynamic>> getInbound({int? userId}) async {
    String urlString = "$baseUrl/api/inbound/list";
    if (userId != null) {
      urlString += "?user_id=$userId";
    }
    final url = Uri.parse(urlString);

    try {
      final headers = await _getHeaders();
      print('🔑 Headers: $headers');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        print("HTTP Error ${response.statusCode}: ${response.body}");
        return [];
      }
    } catch (e) {
      print("ERROR API GET INBOUND: $e");
      return [];
    }
  }

  Future<bool> createInbound(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/inbound/create");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["error"] ?? "Gagal menyimpan inbound");
      }
    } catch (e) {
      print("ERROR API CREATE INBOUND: $e");
      rethrow;
    }
  }

  // GET PRODUK
  Future<List<dynamic>> getProduk() async {
    final url = Uri.parse("$baseUrl/api/produk/list");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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

  // GET GUDANG
  Future<List<dynamic>> getGudang() async {
    final url = Uri.parse("$baseUrl/api/gudang/list");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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

  // GET SATUAN
  Future<List<dynamic>> getSatuan() async {
    final url = Uri.parse("$baseUrl/api/satuan/list");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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

  // CREATE PRODUK
  Future<Map<String, dynamic>?> createProduk({
    required String kodeProduk,
    required String namaProduk,
  }) async {
    final url = Uri.parse("$baseUrl/api/produk/create");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "kode_produk": kodeProduk,
          "nama_produk": namaProduk,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["data"] ??
            {"kode_produk": kodeProduk, "nama_produk": namaProduk};
      } else {
        print("ERROR CREATE PRODUK: ${response.body}");
        return null;
      }
    } catch (e) {
      print("ERROR API CREATE PRODUK: $e");
      rethrow;
    }
  }

  // CREATE GUDANG
  Future<Map<String, dynamic>?> createGudang({
    required String namaGudang,
    required String alamat,
  }) async {
    final url = Uri.parse("$baseUrl/api/gudang/create");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"nama_gudang": namaGudang, "alamat": alamat}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["data"] ?? {"nama_gudang": namaGudang, "alamat": alamat};
      } else {
        print("ERROR CREATE GUDANG: ${response.body}");
        return null;
      }
    } catch (e) {
      print("ERROR API CREATE GUDANG: $e");
      rethrow;
    }
  }

  // UPDATE GUDANG
  Future<bool> updateGudang({
    required int idGudang,
    required String namaGudang,
    required String alamat,
  }) async {
    final url = Uri.parse("$baseUrl/api/gudang/update/$idGudang");

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({"nama_gudang": namaGudang, "alamat": alamat}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR API UPDATE GUDANG: $e");
      rethrow;
    }
  }

  // DELETE GUDANG
  Future<bool> deleteGudang(int idGudang) async {
    final url = Uri.parse("$baseUrl/api/gudang/delete/$idGudang");

    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR API DELETE GUDANG: $e");
      rethrow;
    }
  }

  // OUTBOUND
  Future<List<dynamic>> getOutbound({int? userId}) async {
    String urlString = "$baseUrl/api/outbound/getOutbound";
    if (userId != null) {
      urlString += "?user_id=$userId";
    }
    final url = Uri.parse(urlString);

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
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

  // GET USER GUDANG
  Future<Map<String, dynamic>> getUserGudang({required int userId}) async {
    final url = Uri.parse("$baseUrl/api/gudang/user?user_id=$userId");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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

  // GET INVENTORY BY GUDANG ID
  Future<List<dynamic>> getInventory({required int gudangId}) async {
    final url = Uri.parse("$baseUrl/api/inventory/list?gudang_id=$gudangId");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

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

  // GET QUALITY CONTROL BY GUDANG ID
  Future<List<dynamic>> getQualityControl({required int gudangId}) async {
    final url = Uri.parse("$baseUrl/api/quality-control?gudang_id=$gudangId");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load quality control");
      }
    } catch (e) {
      print("ERROR API GET QUALITY CONTROL: $e");
      rethrow;
    }
  }

  // GET INVENTORY BY WAREHOUSE — FIXED
  Future<List<dynamic>> getInventoryByWarehouse(int idGudang) async {
    final url = Uri.parse(
      "$baseUrl/api/inventory/by-warehouse?idGudang=$idGudang",
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load inventory for warehouse $idGudang");
      }
    } catch (e) {
      print("ERROR API GET INVENTORY BY WAREHOUSE: $e");
      rethrow;
    }
  }

  Future<bool> addInventory(Map<String, dynamic> payload) async {
    final url = Uri.parse("$baseUrl/api/inventory/add");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return false;
    }
  }

  // GET INVENTORY DETAIL
  Future<Map<String, dynamic>> getInventoryDetail({
    required int inventoryId,
  }) async {
    final url = Uri.parse("$baseUrl/api/inventory/detail/$inventoryId");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"];
      } else {
        throw Exception("Failed to load inventory detail");
      }
    } catch (e) {
      print("ERROR API GET INVENTORY DETAIL: $e");
      rethrow;
    }
  }

  // UPDATE INBOUND STATUS → Update status inbound_stock

  Future<bool> updateOrderStatus(dynamic idOrder, String status) async {
    final url = Uri.parse('$baseUrl/api/orders/update-status/$idOrder');

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({"status": status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAllInventory() async {
    final url = Uri.parse("$baseUrl/api/inventory/all");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return (data["data"] as List).map((item) {
          return {
            "gudang": item["gudang"] ?? "",
            "nama_produk": item["nama_produk"] ?? "",
            "volume": item["volume"] ?? 0,
            "jenis_satuan": item["jenis_satuan"] ?? "",
            "kode_produk": item["kode_produk"] ?? "",
          };
        }).toList();
      } else {
        throw Exception("Failed to load all inventory");
      }
    } catch (e) {
      print("ERROR API GET ALL INVENTORY: $e");
      rethrow;
    }
  }

  Future<bool> addQualityControl(Map<String, dynamic> payload) async {
    final url = Uri.parse("$baseUrl/api/quality-control/add");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return false;
    }
  }

  Future<bool> processQC(Map<String, dynamic> payload) async {
    final url = Uri.parse("$baseUrl/api/quality-control/process");

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["error"] ?? "Gagal proses QC");
      }
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getReturn({required int gudangId}) async {
    final url = Uri.parse("$baseUrl/api/return?gudang_id=$gudangId");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to load return data");
      }
    } catch (e) {
      print("ERROR API GET RETURN: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionChart({String? year}) async {
    String urlString = "$baseUrl/api/chart/transactions";
    if (year != null) {
      urlString += "?year=$year";
    }
    final url = Uri.parse(urlString);

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("Failed to load chart data");
      }
    } catch (e) {
      print("ERROR API GET CHART: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getTransactionDetail({
    required int monthIndex, // 0 - 11
    required String type, // inbound / outbound
    String? year,
  }) async {
    final month = monthIndex + 1;

    String urlString =
        "$baseUrl/api/chart/transactions/detail?month=$month&type=$type";

    if (year != null) {
      urlString += "&year=$year";
    }

    final url = Uri.parse(urlString);

    try {
      final headers = await _getHeaders(); // 🔥 INI PENTING
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"] ?? [];
      } else {
        print("❌ ERROR ${response.statusCode}: ${response.body}");
        throw Exception("Gagal memuat data transaksi");
      }
    } catch (e) {
      print("❌ ERROR API TRANSACTION DETAIL: $e");
      rethrow;
    }
  }

  // Debug methods
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print('🗑️ Token cleared');
  }

  Future<void> setTokenManually(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('🔐 Token set manually: ${token.substring(0, 20)}...');
  }

  Future<String> getMetabaseChartUrl() async {
    final token = await _getToken(); // ← Perbaikan: ambil token dengan benar

    final response = await http.get(
      Uri.parse('$baseUrl/api/metabase/inbound-outbound'),
      headers: {'Authorization': 'Bearer ${token ?? ""}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); // ← Perbaikan: gunakan jsonDecode
      return data['embed_url'];
    } else {
      throw Exception('Failed to load Metabase chart');
    }
  }
}
