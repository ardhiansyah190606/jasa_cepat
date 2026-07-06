import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_cepat/main.dart';

void main() {
  testWidgets('JasaCepat Login Screen Smoke Test', (WidgetTester tester) async {
    // 1. Build aplikasi JasaCepatApp dan picu frame pertama.
    await tester.pumpWidget(const JasaCepatApp());

    // 2. Verifikasi bahwa teks 'JasaCepat' muncul di Splash Screen.
    expect(find.text('JasaCepat'), findsOneWidget);
    expect(find.text('Teknisi Terpercaya dalam Genggaman'), findsOneWidget);

    // 3. Majukan waktu agar Splash Screen bertransisi ke Halaman Login.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 4. Verifikasi halaman login dimuat dengan benar.
    expect(find.text('Selamat Datang Kembali!'), findsOneWidget);
    expect(find.text('Silakan masuk akun JasaCepat Anda.'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // 5. Verifikasi tombol 'Masuk' ada.
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
  });
}