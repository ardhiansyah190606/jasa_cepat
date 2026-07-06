import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppStorageService {
  static const String _profileKey = 'app_profile';
  static const String _profilesKey = 'app_profiles';
  static const String _servicesKey = 'app_services';
  static const String _placesKey = 'app_places';
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
    await saveProfile(
      name: name,
      email: email,
      password: password,
      role: role,
    );
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
    final index = profiles.indexWhere((item) => item['email']?.toString() == email);
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

  Future<Map<String, dynamic>> authenticateUser({required String email, required String password}) async {
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
      if (profile['email']?.toString() == email && profile['password']?.toString() == password) {
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
    final index = profiles.indexWhere((item) => item['email']?.toString() == currentEmail);
    if (index >= 0) {
      profiles[index] = updatedProfile;
    } else {
      profiles.add(updatedProfile);
    }

    await prefs.setString(_profilesKey, jsonEncode(profiles));
    await prefs.setString(_profileKey, jsonEncode(updatedProfile));
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
    await prefs.setString(_placesKey, jsonEncode(places.map((e) => e.toJson()).toList()));
    await _syncPlaceToSupabase(place);
  }

  Future<void> deletePlace(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getPlaces();
    places.removeWhere((p) => p.id == placeId);
    await prefs.setString(_placesKey, jsonEncode(places.map((e) => e.toJson()).toList()));

    if (_supabaseAvailable()) {
      try {
        await Supabase.instance.client.from('places').delete().eq('id', placeId);
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
            .map((item) => PlaceItem.fromJson(Map<String, dynamic>.from(item as Map)))
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
      return decoded.map((item) => PlaceItem.fromJson(Map<String, dynamic>.from(item))).toList();
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
    );

    services.add(service);
    await prefs.setString(_servicesKey, jsonEncode(services.map((e) => e.toJson()).toList()));
    await _syncServiceToSupabase(service);
  }

  Future<void> updateService(ServiceItem service) async {
    final prefs = await SharedPreferences.getInstance();
    final services = await getServices();
    final index = services.indexWhere((item) => item.id == service.id);
    if (index >= 0) {
      services[index] = service;
      await prefs.setString(_servicesKey, jsonEncode(services.map((e) => e.toJson()).toList()));
      await _syncServiceToSupabase(service);
    }
  }

  Future<void> deleteService(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final services = await getServices();
    services.removeWhere((s) => s.id == serviceId);
    await prefs.setString(_servicesKey, jsonEncode(services.map((e) => e.toJson()).toList()));

    if (_supabaseAvailable()) {
      try {
        await Supabase.instance.client.from('services').delete().eq('id', serviceId);
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
            .map((item) => ServiceItem.fromJson(Map<String, dynamic>.from(item as Map)))
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
      return decoded.map((item) => ServiceItem.fromJson(Map<String, dynamic>.from(item))).toList();
    }

    return <ServiceItem>[];
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_profilesKey);
    await prefs.remove(_servicesKey);
    await prefs.remove(_placesKey);
    await prefs.remove(_userLocationKey);
  }

  // ==================== SUPABASE SYNC ====================

  Future<void> _syncProfileToSupabase(Map<String, dynamic> profile) async {
    if (!_supabaseAvailable()) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .upsert({
            'email': profile['email']?.toString(),
            'name': profile['name']?.toString(),
            'password': profile['password']?.toString(),
            'role': profile['role']?.toString(),
          }, onConflict: 'email')
          .select();
    } catch (_) {}
  }

  Future<void> _syncServiceToSupabase(ServiceItem service) async {
    if (!_supabaseAvailable()) return;

    try {
      await Supabase.instance.client
          .from('services')
          .upsert({
            'id': service.id,
            'name': service.name,
            'description': service.description,
            'detail': service.detail,
            'price': service.price,
            'price_unit': service.priceUnit,
            'category': service.category,
            'place_id': service.placeId.isEmpty ? null : service.placeId,
            'icon_name': service.iconName,
            'is_active': true,
          }, onConflict: 'id')
          .select();
    } catch (_) {}
  }

  Future<void> _syncPlaceToSupabase(PlaceItem place) async {
    if (!_supabaseAvailable()) return;

    try {
      await Supabase.instance.client
          .from('places')
          .upsert({
            'id': place.id,
            'name': place.name,
            'address': place.address,
            'latitude': place.lat,
            'longitude': place.lng,
            'description': place.description,
            'is_active': true,
          }, onConflict: 'id')
          .select();
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
      };

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      priceUnit: (json['price_unit'] ?? json['priceUnit'])?.toString() ?? 'per panggilan',
      category: json['category']?.toString() ?? 'Umum',
      placeId: (json['place_id'] ?? json['placeId'])?.toString() ?? '',
      iconName: (json['icon_name'] ?? json['iconName'])?.toString() ?? 'build',
    );
  }
}
