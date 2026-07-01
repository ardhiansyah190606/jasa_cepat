import 'package:flutter/material.dart';
import 'package:jasa_cepat/features/auth/screen/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // LOGO ANDALAN KELOMPOK 9 YANG SUDAH BERHASIL MUNCUL
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Daftar / Masuk Akun', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Lengkapi data diri Anda di bawah ini untuk mulai memanggil teknisi.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 24),
                
                // Input Nama
                const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nama lengkap Anda', 
                    prefixIcon: const Icon(Icons.person_outline), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),

                // Input Email
                const Text('Alamat Gmail', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'nama@gmail.com', 
                    prefixIcon: const Icon(Icons.email_outlined), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Gmail tidak boleh kosong';
                    if (!value.contains('@')) return 'Format Gmail salah';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Input Nomor HP - BAGIAN YANG DIPERBAIKI AGAR TETAP DAN TIDAK HILANG
                const Text('Nomor Handphone', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  // Menghilangkan prefixText eksternal agar teks tidak tabrakan dengan keyboard bawaan HP
                  decoration: InputDecoration(
                    hintText: 'Contoh: 08123456789',
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // Validator diperkuat agar input nomor HP wajib diisi angka valid
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor HP tidak boleh kosong';
                    }
                    if (value.trim().length < 9) {
                      return 'Nomor HP terlalu pendek';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Tombol Masuk
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => const HomeScreen())
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                      elevation: 0
                    ),
                    child: const Text('Masuk / Daftar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}