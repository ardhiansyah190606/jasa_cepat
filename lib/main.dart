import 'package:flutter/material.dart';
import 'package:jasa_cepat/features/auth/screen/splash_screen.dart';

void main() {
  runApp(const JasaCepatApp());
}

class JasaCepatApp extends StatelessWidget {
  const JasaCepatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JasaCepat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Memulai aplikasi dari Splash Screen
    );
  }
}