import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('profile service can save and update password', () async {
    final storage = AppStorageService();
    await storage.clearAll();

    await storage.saveProfile(
      name: 'Admin JasaCepat',
      email: 'admin@gmail.com',
      password: 'admin123',
      role: 'admin',
    );

    final profile = await storage.getProfile();
    expect(profile['name'], 'Admin JasaCepat');

    await storage.updatePassword('newPassword123');
    final updatedProfile = await storage.getProfile();
    expect(updatedProfile['password'], 'newPassword123');
  });

  test('authenticate user can match admin and user accounts', () async {
    final storage = AppStorageService();
    await storage.clearAll();
    await storage.ensureDefaultProfiles();

    final admin = await storage.authenticateUser(email: 'admin@gmail.com', password: 'admin123');
    final user = await storage.authenticateUser(email: 'user@gmail.com', password: 'user123');

    expect(admin['role'], 'admin');
    expect(user['role'], 'user');
  });

  test('service storage can add and retrieve services', () async {
    final storage = AppStorageService();
    await storage.clearAll();

    await storage.addService(
      name: 'Servis AC',
      description: 'Cuci AC dan tambah freon',
      price: '150000',
      category: 'Kebersihan',
    );

    final services = await storage.getServices();
    expect(services.length, 1);
    expect(services.first.name, 'Servis AC');
    expect(services.first.price, '150000');
  });
}