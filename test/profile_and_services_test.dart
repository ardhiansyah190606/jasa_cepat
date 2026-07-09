import 'package:flutter_test/flutter_test.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:jasa_cepat/core/location_recommendation.dart';
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

    final admin = await storage.authenticateUser(
      email: 'admin@gmail.com',
      password: 'admin123',
    );
    final user = await storage.authenticateUser(
      email: 'user@gmail.com',
      password: 'user123',
    );

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
      lat: -7.557628,
      lng: 110.821781,
    );

    final services = await storage.getServices();
    expect(services.length, 1);
    expect(services.first.name, 'Servis AC');
    expect(services.first.price, '150000');
    expect(services.first.lat, -7.557628);
    expect(services.first.lng, 110.821781);
  });

  test('recommendations sort services by nearest coordinate', () {
    final places = [
      PlaceItem(
        id: 'place_far',
        name: 'Cabang Jauh',
        address: 'Jakarta',
        lat: -6.175392,
        lng: 106.827153,
      ),
    ];

    final services = [
      ServiceItem(
        id: 'svc_far',
        name: 'Jasa Jauh',
        description: 'Ikut tempat jauh',
        price: '100000',
        category: 'Umum',
        placeId: 'place_far',
      ),
      ServiceItem(
        id: 'svc_near',
        name: 'Jasa Dekat',
        description: 'Koordinat dekat',
        price: '100000',
        category: 'Umum',
        lat: -7.557700,
        lng: 110.821800,
      ),
    ];

    final recommendations = LocationRecommendation.nearestServices(
      services: services,
      places: places,
      userLat: -7.557628,
      userLng: 110.821781,
    );

    expect(recommendations.first.service.id, 'svc_near');
    expect(recommendations.first.hasLocation, true);
  });

  test('order storage can create and update order status', () async {
    final storage = AppStorageService();
    await storage.clearAll();

    await storage.saveProfile(
      name: 'Pengguna JasaCepat',
      email: 'user@gmail.com',
      password: 'user123',
      role: 'user',
    );

    final service = ServiceItem(
      id: 'svc_001',
      name: 'Servis AC',
      description: 'Cuci AC',
      price: '150000',
      category: 'AC & Pendingin',
    );

    final order = await storage.createOrder(service: service);
    expect(order.status, 'Menunggu');

    await storage.updateOrderStatus(order.id, 'Diterima');
    final orders = await storage.getOrders(userEmail: 'user@gmail.com');

    expect(orders.length, 1);
    expect(orders.first.status, 'Diterima');
    expect(orders.first.technicianName, 'Teknisi JasaCepat');
  });
}
