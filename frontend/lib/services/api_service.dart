import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:8081";

  // PING SERVER → cek apakah backend aktif
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

  // GET USERS → Ambil data user dari backend
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

  // UPDATE USER (ubah role gudang)
 Future<bool> updateUser({
  required int idUser,
  required int roleGudang,
}) async {
  final url = Uri.parse('$baseUrl/api/user/update');

  final response = await http.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "idUser": idUser,
      "role_gudang": roleGudang,
    }),
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

  final response = await http.delete(url);

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception("Gagal hapus user");
  }
}

  // GET INBOUND LIST
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
      print("ERROR API CREATE INBOUND: $e");
      rethrow;
    }
  }

  // GET PRODUK
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

  // GET GUDANG
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

  // GET SATUAN
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

  // CREATE PRODUK
  Future<bool> createProduk({
    required String kodeProduk,
    required String namaProduk,
  }) async {
    final url = Uri.parse("$baseUrl/api/produk/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "kode_produk": kodeProduk,
          "nama_produk": namaProduk,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("ERROR API CREATE PRODUK: $e");
      rethrow;
    }
  }

  // CREATE GUDANG
  Future<bool> createGudang({
    required String namaGudang,
    required String alamat_gudang,
  }) async {
    final url = Uri.parse("$baseUrl/api/gudang/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama_gudang": namaGudang,
          "alamat": alamat_gudang,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("ERROR API CREATE GUDANG: $e");
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

  // GET USER GUDANG
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

  // GET INVENTORY BY GUDANG ID
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



  // GET INVENTORY BY WAREHOUSE — FIXED
  Future<List<dynamic>> getInventoryByWarehouse(int idGudang) async {
    final url = Uri.parse(
        "$baseUrl/api/inventory/by-warehouse?id_gudang=$idGudang");

    try {
      final response = await http.get(url);

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
      print('🔍 Sending to: $url');
      print('🔍 Payload: $payload');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

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

  // UPDATE INBOUND STATUS → Update status inbound_stock

  Future<bool> updateOrderStatus(int idOrder, String status) async {
  final url = Uri.parse('$baseUrl/api/orders/update-status/$idOrder');

  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"status": status}),
  );

  return response.statusCode == 200;
}

 Future<List<dynamic>> getAllInventory() async {
  final url = Uri.parse("$baseUrl/api/inventory/all");

  try {
    final response = await http.get(url);

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
      print('🔍 Sending to: $url');
      print('🔍 Payload: $payload');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

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

  Future<List<dynamic>> getQualityControl({required int gudangId}) async {
 final url = Uri.parse("$baseUrl/api/quality-control?gudang_asal=$gudangId");

  try {
    print("🔍 Fetching QC from: $url");

    final response = await http.get(url);

    print("🔍 Response: ${response.statusCode}");
    print("🔍 Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      return [];
    }
  } catch (e) {
    print("❌ Error QC GET: $e");
    return [];
  }
}
}
