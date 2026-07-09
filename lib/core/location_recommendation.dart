import 'dart:math' as math;

import 'package:jasa_cepat/core/app_storage_service.dart';

class LocationRecommendation {
  static const double _earthRadiusKm = 6371.0;
  static const double maxNearbyDistanceKm = 60.0;

  static double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final lat1 = _toRadians(fromLat);
    final lat2 = _toRadians(toLat);
    final deltaLat = _toRadians(toLat - fromLat);
    final deltaLng = _toRadians(toLng - fromLng);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    }
    if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
    return '${distanceKm.round()}km';
  }

  static ServiceCoordinate? resolveServiceCoordinate(
    ServiceItem service,
    List<PlaceItem> places,
  ) {
    if (service.lat != null && service.lng != null) {
      PlaceItem? linkedPlace;
      if (service.placeId.isNotEmpty) {
        for (final place in places) {
          if (place.id == service.placeId) {
            linkedPlace = place;
            break;
          }
        }
      }
      return ServiceCoordinate(
        lat: service.lat!,
        lng: service.lng!,
        place: linkedPlace,
        fromServiceCoordinate: true,
      );
    }

    if (service.placeId.isEmpty) {
      return null;
    }

    for (final place in places) {
      if (place.id == service.placeId) {
        return ServiceCoordinate(
          lat: place.lat,
          lng: place.lng,
          place: place,
          fromServiceCoordinate: false,
        );
      }
    }

    return null;
  }

  static List<ServiceDistance> nearestServices({
    required List<ServiceItem> services,
    required List<PlaceItem> places,
    required double userLat,
    required double userLng,
    double? maxDistanceKm,
    bool includeWithoutLocation = true,
  }) {
    final result = services.map((service) {
      final coordinate = resolveServiceCoordinate(service, places);
      if (coordinate == null) {
        return ServiceDistance(service: service);
      }

      return ServiceDistance(
        service: service,
        place: coordinate.place,
        lat: coordinate.lat,
        lng: coordinate.lng,
        distanceKm: distanceKm(
          fromLat: userLat,
          fromLng: userLng,
          toLat: coordinate.lat,
          toLng: coordinate.lng,
        ),
        fromServiceCoordinate: coordinate.fromServiceCoordinate,
      );
    }).toList();

    result.sort((a, b) {
      if (a.hasLocation && b.hasLocation) {
        return a.distanceKm!.compareTo(b.distanceKm!);
      }
      if (a.hasLocation) return -1;
      if (b.hasLocation) return 1;
      return a.service.name.toLowerCase().compareTo(
        b.service.name.toLowerCase(),
      );
    });

    return result.where((item) {
      final distance = item.distanceKm;
      if (distance == null) return includeWithoutLocation;
      return maxDistanceKm == null || distance <= maxDistanceKm;
    }).toList();
  }

  static List<PlaceDistance> nearestPlaces({
    required List<PlaceItem> places,
    required double userLat,
    required double userLng,
    double? maxDistanceKm,
  }) {
    final result = places
        .map(
          (place) => PlaceDistance(
            place: place,
            distanceKm: distanceKm(
              fromLat: userLat,
              fromLng: userLng,
              toLat: place.lat,
              toLng: place.lng,
            ),
          ),
        )
        .toList();

    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    if (maxDistanceKm == null) return result;
    return result
        .where((item) => item.distanceKm <= maxDistanceKm)
        .toList();
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}

class ServiceCoordinate {
  final double lat;
  final double lng;
  final PlaceItem? place;
  final bool fromServiceCoordinate;

  const ServiceCoordinate({
    required this.lat,
    required this.lng,
    this.place,
    required this.fromServiceCoordinate,
  });
}

class ServiceDistance {
  final ServiceItem service;
  final PlaceItem? place;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final bool fromServiceCoordinate;

  const ServiceDistance({
    required this.service,
    this.place,
    this.lat,
    this.lng,
    this.distanceKm,
    this.fromServiceCoordinate = false,
  });

  bool get hasLocation => lat != null && lng != null && distanceKm != null;

  String get distanceLabel {
    final distance = distanceKm;
    if (distance == null) return 'Belum ada koordinat';
    return LocationRecommendation.formatDistance(distance);
  }

  String get locationSourceLabel {
    if (!hasLocation) return 'Belum masuk rekomendasi';
    if (fromServiceCoordinate) return 'Koordinat layanan';
    return 'Koordinat tempat';
  }
}

class PlaceDistance {
  final PlaceItem place;
  final double distanceKm;

  const PlaceDistance({required this.place, required this.distanceKm});

  String get distanceLabel => LocationRecommendation.formatDistance(distanceKm);
}
