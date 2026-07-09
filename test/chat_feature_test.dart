import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_cepat/features/chat/screen/chat_screen.dart';

void main() {
  testWidgets('Chat screen shows a technician conversation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));

    expect(find.text('Chat'), findsOneWidget);
    expect(find.textContaining('Budi Setiawan'), findsOneWidget);
    expect(
      find.text('Halo pak, saya sudah di jalan ya menuju rumah.'),
      findsOneWidget,
    );
  });
}
