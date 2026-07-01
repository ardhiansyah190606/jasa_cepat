// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:jasa_cepat/main.dart';

void main() {
  testWidgets('JasaCepat Login Screen Smoke Test', (WidgetTester tester) async {
    // 1. Build aplikasi JasaCepatApp dan picu frame pertama.
    await tester.pumpWidget(const JasaCepatApp());

    // 2. Verifikasi bahwa teks 'Selamat Datang di JasaCepat' muncul di layar awal.
    expect(find.text('Selamat Datang di JasaCepat'), findsOneWidget);

    // 3. Verifikasi bahwa teks panduan nomor handphone juga muncul.
    expect(
      find.text('Masuk dengan nomor handphone Anda untuk mulai memanggil teknisi terdekat.'),
      findsOneWidget,
    );

    // 4. Verifikasi bahwa tombol 'Masuk / Daftar' tersedia di halaman login.
    expect(find.text('Masuk / Daftar'), findsOneWidget);
  });
}