import 'package:flutter/material.dart';
import 'package:jasa_cepat/features/auth/screen/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lohgzrbhyuvgztoivwxe.supabase.co',
    anonKey: 'sb_publishable_udZPxcouemCprT4lpmc2SQ_wmwBOSEI',
  );

  // Inisialisasi akun demo default jika belum ada
  await AppStorageService().ensureDefaultProfiles();

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
      home: const SplashScreen(),
    );
  }
}
