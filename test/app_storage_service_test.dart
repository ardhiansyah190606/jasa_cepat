import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerUser stores a new account and allows login', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = AppStorageService();

    await storage.registerUser(
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'budi123',
      role: 'user',
    );

    final profile = await storage.authenticateUser(
      email: 'budi@example.com',
      password: 'budi123',
    );

    expect(profile['name'], 'Budi Santoso');
    expect(profile['role'], 'user');
  });
}