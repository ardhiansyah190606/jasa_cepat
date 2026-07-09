import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppStorageService {
  static const String _profileKey = 'app_profile';
  static const String _profilesKey = 'app_profiles';
  static const String _servicesKey = 'app_services';
  static const String _placesKey = 'app_places';
  static const String _ordersKey = 'app_orders';
  static const String _userLocationKey = 'app_user_location';

  bool _supabaseAvailable() {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== PROFIL ====================

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await saveProfile(name: name, email: email, password: password, role: role);
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };

    final profiles = await _getProfilesList();
    final index = profiles.indexWhere(
      (item) => item['email']?.toString() == email,
    );
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    await prefs.setString(_profilesKey, jsonEncode(profiles));
    await prefs.setString(_profileKey, jsonEncode(profile));

    await _syncProfileToSupabase(profile);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_profileKey);
    if (rawData == null || rawData.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(rawData);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<Map<String, dynamic>> authenticateUser({
    required String email,
    required String password,
  }) async {
    if (_supabaseAvailable()) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('email', email)
            .eq('password', password)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          final profile = Map<String, dynamic>.from(response as Map);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_profileKey, jsonEncode(profile));
          return profile;
        }
      } catch (_) {}
    }

    final profiles = await _getProfilesList();
    if (profiles.isEmpty) {
      await ensureDefaultProfiles();
      return authenticateUser(email: email, password: password);
    }

    for (final profile in profiles) {
      if (profile['email']?.toString() == email &&
          profile['password']?.toString() == password) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileKey, jsonEncode(profile));
        return profile;
      }
    }

    return <String, dynamic>{};
  }

  Future<void> ensureDefaultProfiles() async {
    final profiles = await _getProfilesList();
    if (profiles.isNotEmpty) {
      return;
    }

    final defaults = [
      {
        'name': 'Admin JasaCepat',
        'email': 'admin@gmail.com',
        'password': 'admin123',
        'role': 'admin',
      },
      {
        'name': 'Pengguna JasaCepat',
        'email': 'user@gmail.com',
        'password': 'user123',
        'role': 'user',
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, jsonEncode(defaults));
    await prefs.setString(_profileKey, jsonEncode(defaults.first));

    for (final profile in defaults) {
      await _syncProfileToSupabase(profile);
    }
  }

  Future<List<Map<String, dynamic>>> _getProfilesList() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_profilesKey);
    if (rawData == null || rawData.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(rawData);
    if (decoded is List) {
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return <Map<String, dynamic>>[];
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? password,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await getProfile();
    if (profile.isEmpty) {
      return;
    }

    final updatedProfile = Map<String, dynamic>.from(profile);
    if (name != null) updatedProfile['name'] = name;
    if (email != null) updatedProfile['email'] = email;
    if (password != null) updatedProfile['password'] = password;
    if (role != null) updatedProfile['role'] = role;

    final profiles = await _getProfilesList();
    final currentEmail = profile['email']?.toString();
    final index = profiles.indexWhere(
      (item) => item['email']?.toString() == currentEmail,
    );
    if (index >= 0) {
      profiles[index] = updatedProfile;
    } else {
      profiles.add(updatedProfile);
    }

    await prefs.setString(_profilesKey, jsonEncode(profiles));
    await prefs.setString(_profileKey, jsonEncode(updatedProfile));
    try {
      await _syncProfileToSupabase(updatedProfile, previousEmail: currentEmail);
    } catch (_) {}
  }

  Future<void> updatePassword(String password) async {
    await updateProfile(password: password);
  }

  // ==================== LOKASI USER ====================

  Future<void> saveUserLocation({
    required double lat,
    required double lng,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final loc = {'lat': lat, 'lng': lng, 'address': address};
    await prefs.setString(_userLocationKey, jsonEncode(loc));

    // Sync ke Supabase
    if (_supabaseAvailable()) {
      try {
        final profile = await getProfile();
        final email = profile['email']?.toString();
        if (email != null && email.isNotEmpty) {
          await Supabase.instance.client.from('user_locations').upsert({
            'user_email': email,
            'address': address,
            'latitude': lat,
            'longitude': lng,
            'is_default': true,
          }, onConflict: 'user_email').select();
        }
      } catch (_) {}
    }
  }

  Future<UserLocation> getUserLocation() async {
    // Coba dari Supabase dulu
    if (_supabaseAvailable()) {
      try {
        final profile = await getProfile();
        final email = profile['email']?.toString();
        if (email != null && email.isNotEmpty) {
          final response = await Supabase.instance.client
              .from('user_locations')
              .select()
              .eq('user_email', email)
              .eq('is_default', true)
              .limit(1)
              .maybeSingle();
          if (response != null) {
            return UserLocation(
              lat: (response['latitude'] as num).toDouble(),
              lng: (response['longitude'] as num).toDouble(),
              address: response['address']?.toString() ?? 'Lokasi Saya',
            );
          }
        }
      } catch (_) {}
    }

    // Fallback ke local
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_userLocationKey);
    if (rawData != null && rawData.isNotEmpty) {
      final decoded = jsonDecode(rawData);
      return UserLocation(
        lat: (decoded['lat'] as num).toDouble(),
        lng: (decoded['lng'] as num).toDouble(),
        address: decoded['address']?.toString() ?? 'Lokasi Saya',
      );
    }

    // Default: Monas Jakarta
    return UserLocation(
      lat: -6.175392,
      lng: 106.827153,
      address: 'Jl. Urban Raya No. 42, Jakarta',
    );
  }

  // ==================== TEMPAT (PLACES) ====================

  Future<void> addPlace({
    required String name,
    required String address,
    required double lat,
    required double lng,
    String description = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getPlaces();
    final place = PlaceItem(
      id: 'place_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      description: description,
    );

    places.add(place);
    await prefs.setString(
      _placesKey,
      jsonEncode(places.map((e) => e.toJson()).toList()),
    );
    await _syncPlaceToSupabase(place);
  }

  Future<void> deletePlace(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getPlaces();
    places.removeWhere((p) => p.id == placeId);
    await prefs.setString(
      _placesKey,
      jsonEncode(places.map((e) => e.toJson()).toList()),
    );

    if (_supabaseAvailable()) {
      try {
        await Supabase.instance.client
            .from('places')
            .delete()
            .eq('id', placeId);
      } catch (_) {}
    }
  }

  Future<List<PlaceItem>> getPlaces() async {
    if (_supabaseAvailable()) {
      try {
        final response = await Supabase.instance.client
            .from('places')
            .select()
            .eq('is_active', true);
        return response
            .map(
              (item) =>
                  PlaceItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_placesKey);
    if (rawData == null || rawData.isEmpty) {
      return <PlaceItem>[];
    }

    final decoded = jsonDecode(rawData);
    if (decoded is List) {
      return decoded
          .map((item) => PlaceItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return <PlaceItem>[];
  }

  // ==================== LAYANAN (SERVICES) ====================

  Future<void> addService({
    required String name,
    required String description,
    String detail = '',
    required String price,
    String priceUnit = 'per panggilan',
    required String category,
    String placeId = '',
    String iconName = 'build',
    double? lat,
    double? lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final services = await getServices();
    final service = ServiceItem(
      id: 'svc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      detail: detail,
      price: price,
      priceUnit: priceUnit,
      category: category,
      placeId: placeId,
      iconName: iconName,
      lat: lat,
      lng: lng,
    );

    services.add(service);
    await prefs.setString(
      _servicesKey,
      jsonEncode(services.map((e) => e.toJson()).toList()),
    );
    await _syncServiceToSupabase(service);
  }

  Future<void> updateService(ServiceItem service) async {
    final prefs = await SharedPreferences.getInstance();
    final services = await getServices();
    final index = services.indexWhere((item) => item.id == service.id);
    if (index >= 0) {
      services[index] = service;
      await prefs.setString(
        _servicesKey,
        jsonEncode(services.map((e) => e.toJson()).toList()),
      );
      await _syncServiceToSupabase(service);
    }
  }

  Future<void> deleteService(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final services = await getServices();
    services.removeWhere((s) => s.id == serviceId);
    await prefs.setString(
      _servicesKey,
      jsonEncode(services.map((e) => e.toJson()).toList()),
    );

    if (_supabaseAvailable()) {
      try {
        await Supabase.instance.client
            .from('services')
            .delete()
            .eq('id', serviceId);
      } catch (_) {}
    }
  }

  Future<List<ServiceItem>> getServices() async {
    if (_supabaseAvailable()) {
      try {
        final response = await Supabase.instance.client
            .from('services')
            .select()
            .eq('is_active', true);
        return response
            .map(
              (item) =>
                  ServiceItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_servicesKey);
    if (rawData == null || rawData.isEmpty) {
      return <ServiceItem>[];
    }

    final decoded = jsonDecode(rawData);
    if (decoded is List) {
      return decoded
          .map((item) => ServiceItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return <ServiceItem>[];
  }

  // ==================== PESANAN (ORDERS) ====================

  Future<OrderItem> createOrder({
    required ServiceItem service,
    PlaceItem? place,
    String notes = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await getProfile();
    final userEmail = profile['email']?.toString().isNotEmpty == true
        ? profile['email'].toString()
        : 'user@gmail.com';
    final now = DateTime.now();
    final order = OrderItem(
      id: 'JC-${now.millisecondsSinceEpoch.toString().substring(7)}',
      userEmail: userEmail,
      serviceId: service.id,
      serviceName: service.name,
      placeId: place?.id ?? service.placeId,
      placeName: place?.name ?? '',
      technicianName: 'Mencari Teknisi...',
      price: service.price,
      notes: notes,
      status: 'Menunggu',
      createdAt: now,
      updatedAt: now,
    );

    final orders = await getOrders();
    orders.insert(0, order);
    await prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((e) => e.toJson()).toList()),
    );
    await _syncOrderToSupabase(order);
    return order;
  }

  Future<List<OrderItem>> getOrders({String? userEmail}) async {
    if (_supabaseAvailable()) {
      try {
        List<dynamic> response;
        if (userEmail == null || userEmail.isEmpty) {
          response = await Supabase.instance.client
              .from('orders')
              .select()
              .order('created_at', ascending: false);
        } else {
          response = await Supabase.instance.client
              .from('orders')
              .select()
              .eq('user_email', userEmail)
              .order('created_at', ascending: false);
        }
        return response
            .map(
              (item) =>
                  OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_ordersKey);
    if (rawData == null || rawData.isEmpty) {
      return <OrderItem>[];
    }

    final decoded = jsonDecode(rawData);
    if (decoded is! List) {
      return <OrderItem>[];
    }

    final orders = decoded
        .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
        .where(
          (order) =>
              userEmail == null ||
              userEmail.isEmpty ||
              order.userEmail == userEmail,
        )
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final index = orders.indexWhere((item) => item.id == orderId);
    if (index >= 0) {
      orders[index] = orders[index].copyWith(
        status: status,
        technicianName:
            status == 'Diterima' &&
                orders[index].technicianName == 'Mencari Teknisi...'
            ? 'Teknisi JasaCepat'
            : orders[index].technicianName,
        updatedAt: DateTime.now(),
      );
      await prefs.setString(
        _ordersKey,
        jsonEncode(orders.map((e) => e.toJson()).toList()),
      );
    }

    if (_supabaseAvailable()) {
      try {
        final updateData = {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (status == 'Diterima') {
          updateData['technician_name'] = 'Teknisi JasaCepat';
        }
        await Supabase.instance.client
            .from('orders')
            .update(updateData)
            .eq('id', orderId);
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_profilesKey);
    await prefs.remove(_servicesKey);
    await prefs.remove(_placesKey);
    await prefs.remove(_ordersKey);
    await prefs.remove(_userLocationKey);
  }

  // ==================== SUPABASE SYNC ====================

  Future<void> _syncProfileToSupabase(
    Map<String, dynamic> profile, {
    String? previousEmail,
  }) async {
    if (!_supabaseAvailable()) return;

    try {
      final payload = {
        'email': profile['email']?.toString(),
        'name': profile['name']?.toString(),
        'password': profile['password']?.toString(),
        'role': profile['role']?.toString(),
      };

      if (previousEmail != null && previousEmail.isNotEmpty) {
        await Supabase.instance.client
            .from('profiles')
            .update(payload)
            .eq('email', previousEmail);
        return;
      }

      await Supabase.instance.client
          .from('profiles')
          .upsert(payload, onConflict: 'email')
          .select();
    } catch (_) {}
  }

  Future<void> _syncServiceToSupabase(ServiceItem service) async {
    if (!_supabaseAvailable()) return;

    try {
      await Supabase.instance.client.from('services').upsert({
        'id': service.id,
        'name': service.name,
        'description': service.description,
        'detail': service.detail,
        'price': service.price,
        'price_unit': service.priceUnit,
        'category': service.category,
        'place_id': service.placeId.isEmpty ? null : service.placeId,
        'icon_name': service.iconName,
        'latitude': service.lat,
        'longitude': service.lng,
        'is_active': true,
      }, onConflict: 'id').select();
    } catch (_) {}
  }

  Future<void> _syncPlaceToSupabase(PlaceItem place) async {
    if (!_supabaseAvailable()) return;

    try {
      await Supabase.instance.client.from('places').upsert({
        'id': place.id,
        'name': place.name,
        'address': place.address,
        'latitude': place.lat,
        'longitude': place.lng,
        'description': place.description,
        'is_active': true,
      }, onConflict: 'id').select();
    } catch (_) {}
  }

  Future<void> _syncOrderToSupabase(OrderItem order) async {
    if (!_supabaseAvailable()) return;

    try {
      await Supabase.instance.client.from('orders').upsert({
        'id': order.id,
        'user_email': order.userEmail,
        'service_id': order.serviceId.isEmpty ? null : order.serviceId,
        'service_name': order.serviceName,
        'place_id': order.placeId.isEmpty ? null : order.placeId,
        'place_name': order.placeName,
        'technician_name': order.technicianName,
        'price': order.price,
        'notes': order.notes,
        'status': order.status,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': order.updatedAt.toIso8601String(),
      }, onConflict: 'id').select();
    } catch (_) {}
  }
}

// ==================== MODEL CLASSES ====================

class UserLocation {
  final double lat;
  final double lng;
  final String address;

  UserLocation({required this.lat, required this.lng, required this.address});
}

class PlaceItem {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String description;

  PlaceItem({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'description': description,
  };

  factory PlaceItem.fromJson(Map<String, dynamic> json) {
    return PlaceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: json['lat'] != null
          ? (json['lat'] as num).toDouble()
          : json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : -6.175392,
      lng: json['lng'] != null
          ? (json['lng'] as num).toDouble()
          : json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : 106.827153,
      description: json['description']?.toString() ?? '',
    );
  }
}

class ServiceItem {
  final String id;
  final String name;
  final String description;
  final String detail;
  final String price;
  final String priceUnit;
  final String category;
  final String placeId;
  final String iconName;
  final double? lat;
  final double? lng;

  ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    this.detail = '',
    required this.price,
    this.priceUnit = 'per panggilan',
    required this.category,
    this.placeId = '',
    this.iconName = 'build',
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'detail': detail,
    'price': price,
    'price_unit': priceUnit,
    'category': category,
    'place_id': placeId,
    'icon_name': iconName,
    'lat': lat,
    'lng': lng,
  };

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    double? parseCoordinate(String firstKey, String secondKey) {
      final raw = json[firstKey] ?? json[secondKey];
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString());
    }

    return ServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      priceUnit:
          (json['price_unit'] ?? json['priceUnit'])?.toString() ??
          'per panggilan',
      category: json['category']?.toString() ?? 'Umum',
      placeId: (json['place_id'] ?? json['placeId'])?.toString() ?? '',
      iconName: (json['icon_name'] ?? json['iconName'])?.toString() ?? 'build',
      lat: parseCoordinate('lat', 'latitude'),
      lng: parseCoordinate('lng', 'longitude'),
    );
  }
}

class OrderItem {
  final String id;
  final String userEmail;
  final String serviceId;
  final String serviceName;
  final String placeId;
  final String placeName;
  final String technicianName;
  final String price;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem({
    required this.id,
    required this.userEmail,
    required this.serviceId,
    required this.serviceName,
    this.placeId = '',
    this.placeName = '',
    this.technicianName = 'Mencari Teknisi...',
    required this.price,
    this.notes = '',
    this.status = 'Menunggu',
    required this.createdAt,
    required this.updatedAt,
  });

  OrderItem copyWith({
    String? technicianName,
    String? status,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id,
      userEmail: userEmail,
      serviceId: serviceId,
      serviceName: serviceName,
      placeId: placeId,
      placeName: placeName,
      technicianName: technicianName ?? this.technicianName,
      price: price,
      notes: notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_email': userEmail,
    'service_id': serviceId,
    'service_name': serviceName,
    'place_id': placeId,
    'place_name': placeName,
    'technician_name': technicianName,
    'price': price,
    'notes': notes,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) {
      final rawValue = json[key]?.toString();
      if (rawValue == null || rawValue.isEmpty) {
        return DateTime.now();
      }
      return DateTime.tryParse(rawValue) ?? DateTime.now();
    }

    return OrderItem(
      id: json['id']?.toString() ?? '',
      userEmail: (json['user_email'] ?? json['userEmail'])?.toString() ?? '',
      serviceId: (json['service_id'] ?? json['serviceId'])?.toString() ?? '',
      serviceName:
          (json['service_name'] ?? json['serviceName'])?.toString() ?? '',
      placeId: (json['place_id'] ?? json['placeId'])?.toString() ?? '',
      placeName: (json['place_name'] ?? json['placeName'])?.toString() ?? '',
      technicianName:
          (json['technician_name'] ?? json['technicianName'])?.toString() ??
          'Mencari Teknisi...',
      price: json['price']?.toString() ?? '0',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Menunggu',
      createdAt: parseDate('created_at'),
      updatedAt: parseDate('updated_at'),
    );
  }
}
