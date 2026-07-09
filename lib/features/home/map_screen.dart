import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:jasa_cepat/core/location_recommendation.dart';
import 'package:jasa_cepat/features/home/service_detail_screen.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const MapScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _center = const LatLng(-6.175392, 106.827153);
  LatLng _userPoint = const LatLng(-6.175392, 106.827153);
  String _address = 'Lokasi Anda';
  final MapController _mapController = MapController();
  bool _isLoading = true;
  List<PlaceItem> _places = [];
  List<ServiceItem> _services = [];

  List<ServiceDistance> get _nearestServices =>
      LocationRecommendation.nearestServices(
        services: _services,
        places: _places,
        userLat: _center.latitude,
        userLng: _center.longitude,
        maxDistanceKm: LocationRecommendation.maxNearbyDistanceKm,
        includeWithoutLocation: false,
      ).where((item) => item.hasLocation).toList();

  bool get _showUserPointMarker =>
      LocationRecommendation.distanceKm(
        fromLat: _center.latitude,
        fromLng: _center.longitude,
        toLat: _userPoint.latitude,
        toLng: _userPoint.longitude,
      ) >
      0.03;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Gunakan parameter yang dikirim, atau load dari storage
      if (widget.initialLat != null && widget.initialLng != null) {
        _center = LatLng(widget.initialLat!, widget.initialLng!);
        _userPoint = _center;
        _address = widget.initialAddress ?? 'Lokasi Anda';
      } else {
        final loc = await AppStorageService().getUserLocation();
        _center = LatLng(loc.lat, loc.lng);
        _userPoint = _center;
        _address = loc.address;
      }

      final places = await AppStorageService().getPlaces();
      final services = await AppStorageService().getServices();

      if (!mounted) return;
      setState(() {
        _places = places;
        _services = services;
        _isLoading = false;
      });

      // Gerakkan peta ke lokasi tersimpan
      _mapController.move(_center, 15.0);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peta Teknisi JasaCepat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              _address,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15.0,
                    maxZoom: 18.0,
                    minZoom: 3.0,
                    onPositionChanged: (position, hasGesture) {
                      final movedCenter = position.center;
                      if (!hasGesture || movedCenter == null) return;
                      setState(() {
                        _center = movedCenter;
                        _address =
                            'Titik peta ${movedCenter.latitude.toStringAsFixed(5)}, ${movedCenter.longitude.toStringAsFixed(5)}';
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jasa_cepat',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker titik rekomendasi aktif
                        Marker(
                          point: _center,
                          width: 60,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Titik',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Marker lokasi user tersimpan
                        if (_showUserPointMarker)
                          Marker(
                            point: _userPoint,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home_filled,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),

                        // Marker layanan/teknisi terdekat dari data admin
                        ..._nearestServices.map(
                          (recommendation) => Marker(
                            point: LatLng(
                              recommendation.lat!,
                              recommendation.lng!,
                            ),
                            width: 52,
                            height: 52,
                            child: GestureDetector(
                              onTap: () => _tampilkanDetailLayanan(
                                context,
                                recommendation,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 42,
                              ),
                            ),
                          ),
                        ),

                        // Marker tempat dari admin
                        ..._places.map(
                          (place) => Marker(
                            point: LatLng(place.lat, place.lng),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () =>
                                  _tampilkanDetailTempat(context, place),
                              child: const Icon(
                                Icons.store,
                                color: Colors.purple,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Legenda
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegend(
                          Icons.my_location,
                          Colors.blue,
                          'Titik Peta',
                        ),
                        const SizedBox(height: 4),
                        _buildLegend(
                          Icons.home_filled,
                          Colors.blue,
                          'Lokasi Anda',
                        ),
                        const SizedBox(height: 4),
                        _buildLegend(
                          Icons.location_on,
                          Colors.red,
                          'Jasa/Teknisi',
                        ),
                        const SizedBox(height: 4),
                        _buildLegend(Icons.store, Colors.purple, 'Tempat Jasa'),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  right: 86,
                  bottom: 20,
                  child: _buildMapRecommendationPanel(),
                ),

                // Tombol zoom
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'zoom_in',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        child: const Icon(Icons.add, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoom_out',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'my_location',
                        mini: true,
                        backgroundColor: Colors.blue,
                        onPressed: () {
                          setState(() {
                            _center = _userPoint;
                            _address = widget.initialAddress ?? 'Lokasi Anda';
                          });
                          _mapController.move(_userPoint, 15.0);
                        },
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegend(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildMapRecommendationPanel() {
    final nearest = _nearestServices.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12),
        ],
      ),
      child: nearest.isEmpty
          ? const Text(
              'Belum ada jasa dalam radius 60 km dari titik peta.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekomendasi Terdekat',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < nearest.length; i++) ...[
                  _buildMapRecommendationTile(nearest[i]),
                  if (i < nearest.length - 1) const Divider(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _buildMapRecommendationTile(ServiceDistance recommendation) {
    return InkWell(
      onTap: () => _tampilkanDetailLayanan(context, recommendation),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          const Icon(Icons.home_repair_service, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.service.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  recommendation.place?.name ??
                      recommendation.locationSourceLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            recommendation.distanceLabel,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanDetailLayanan(
    BuildContext context,
    ServiceDistance recommendation,
  ) {
    final service = recommendation.service;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          service.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Jarak dari titik peta: ${recommendation.distanceLabel}'),
              if (recommendation.place != null) ...[
                const SizedBox(height: 6),
                Text(
                  recommendation.place!.address,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailScreen(
                          service: service,
                          place: recommendation.place,
                          distanceKm: recommendation.distanceKm,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat Detail Jasa',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _tampilkanDetailTempat(BuildContext context, PlaceItem place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: const Icon(Icons.store, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          place.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (place.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  place.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Lihat Layanan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
