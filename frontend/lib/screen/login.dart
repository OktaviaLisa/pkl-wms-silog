import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  final ApiService apiService = ApiService();

  void loginUser() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username == "admin" && password == "admin123") {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await apiService.login(
        username: username,
        password: password,
      );

      if (result["message"] == "Login berhasil") {
        Navigator.pushReplacementNamed(context, '/dashboard_user');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username atau Password salah!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B1E1E),
      body: Center(
        child: Container(
          width: 900,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // LEFT IMAGE SIDE
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: Image.asset(
                    "lib/assets/images/warehouses.jpg",
                    fit: BoxFit.cover, // memastikan gambar full cover
                  ),
                ),
              ),

              // RIGHT FORM SIDE
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B1E1E),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // USERNAME
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: "Username*",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PASSWORD
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password*",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: loginUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B1E1E),
                                  foregroundColor: Colors.white, // TEXT PUTIH
                                ),
                                child: const Text("Login"),
                              ),
                            ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Belum punya akun? "),
                          InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              "Daftar Sekarang",
                              style: TextStyle(
                                color: Color(0xFF7B1E1E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
