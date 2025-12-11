import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final ApiService apiService = ApiService();

  List users = [];
  List gudangList = [];
  int? selectedGudang;

  bool isLoading = true;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchGudang();
  }

  Future<void> fetchUsers() async {
    try {
      final data = await apiService.getAllUsers();
      setState(() {
        users = data;
        users.sort((a, b) =>
            int.parse(a["idUser"].toString())
                .compareTo(int.parse(b["idUser"].toString())));
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchGudang() async {
    try {
      final data = await apiService.getGudang();
      setState(() => gudangList = data);
    } catch (e) {
      print("Error fetch gudang: $e");
    }
  }

  String formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return "${date.day}-${date.month}-${date.year}";
    } catch (e) {
      return rawDate;
    }
  }

  String getGudangName(int? id) {
    if (id == null) return "-";
    final g = gudangList.firstWhere(
      (item) => item["idGudang"] == id,
      orElse: () => null,
    );
    return g?["nama_gudang"] ?? "-";
  }


  //      POPUP EDIT USER

  void showEditUserDialog(Map user) {
    int? selectedGudangEdit = user["role_gudang"];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Role Gudang",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B1E1E)),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: "Pilih Gudang",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: selectedGudangEdit,
                  items: gudangList.map<DropdownMenuItem<int>>((g) {
                    return DropdownMenuItem(
                      value: g["idGudang"],
                      child: Text(g["nama_gudang"]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedGudangEdit = value);
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Batal"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1E1E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Simpan"),
                      onPressed: () async {
                        await apiService.updateUser(
                          idUser: user["idUser"],
                          roleGudang: selectedGudangEdit!,
                        );

                        Navigator.pop(context);
                        fetchUsers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
  //      POPUP HAPUS USER
 
  void confirmDeleteUser(int idUser) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yakin ingin menghapus?"),
          content: const Text("User akan terhapus permanen."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await apiService.deleteUser(idUser);
                Navigator.pop(context);
                fetchUsers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }


  //     CREATE USER 
 
  void showCreateUserDialog() {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Buat User Baru",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B1E1E),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setStateDialog(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: "Pilih Gudang",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: selectedGudang,
                      items: gudangList.map<DropdownMenuItem<int>>((g) {
                        return DropdownMenuItem(
                          value: g["idGudang"],
                          child: Text(g["nama_gudang"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGudang = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text("Batal"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B1E1E),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Simpan"),
                          onPressed: () async {
                            if (selectedGudang == null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Pilih gudang dahulu"),
                              ));
                              return;
                            }

                            await apiService.createUser(
                              email: emailController.text.trim(),
                              username: usernameController.text.trim(),
                              password: passwordController.text.trim(),
                              roleGudang: selectedGudang!,
                            );

                            Navigator.pop(context);
                            fetchUsers();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      
      appBar: AppBar(
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF7B1E1E),
        title: const Text("User Management", style: TextStyle(color: Colors.white)),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFF7B1E1E)),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            dataRowHeight: 56,
                            columnSpacing: 60,
                            dividerThickness: .5,

                            columns: const [
                              DataColumn(label: Text("No")),
                              DataColumn(label: Text("Email")),
                              DataColumn(label: Text("Username")),
                              DataColumn(label: Text("Gudang")),
                              DataColumn(label: Text("Dibuat")),
                              DataColumn(label: Text("Aksi")), // ⬅ DITAMBAH
                            ],

                            rows: List.generate(users.length, (index) {
                              final user = users[index];
                              final isEven = index % 2 == 0;

                              return DataRow(
                                color: MaterialStateProperty.all(
                                  isEven ? Colors.white : const Color(0xFFEFF4F9),
                                ),
                                cells: [
                                  DataCell(Text("${index + 1}")),
                                  DataCell(Text(user["email"] ?? "-")),
                                  DataCell(Text(user["username"] ?? "-")),
                                  DataCell(Text(getGudangName(user["role_gudang"]))),
                                  DataCell(Text(formatDate(user["created_at"]))),

                                  //        Aksi
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => showEditUserDialog(user),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () =>
                                              confirmDeleteUser(user["idUser"]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B1E1E),
        onPressed: showCreateUserDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
