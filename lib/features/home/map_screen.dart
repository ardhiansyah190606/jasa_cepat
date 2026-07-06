import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
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
  String _address = 'Lokasi Anda';
  final MapController _mapController = MapController();
  bool _isLoading = true;
  List<PlaceItem> _places = [];

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
        _address = widget.initialAddress ?? 'Lokasi Anda';
      } else {
        final loc = await AppStorageService().getUserLocation();
        _center = LatLng(loc.lat, loc.lng);
        _address = loc.address;
      }

      final places = await AppStorageService().getPlaces();

      if (!mounted) return;
      setState(() {
        _places = places;
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
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jasa_cepat',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker lokasi pengguna
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
                                child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Saya',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Marker teknisi terdekat (hardcode contoh)
                        Marker(
                          point: LatLng(_center.latitude + 0.001, _center.longitude + 0.001),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _tampilkanDetailTeknisi(context, 'Budi Setiawan', 'Servis AC'),
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ),
                        Marker(
                          point: LatLng(_center.latitude - 0.001, _center.longitude + 0.002),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _tampilkanDetailTeknisi(context, 'Slamet Riyadi', 'Kelistrikan'),
                            child: const Icon(Icons.location_on, color: Colors.orange, size: 40),
                          ),
                        ),

                        // Marker tempat dari admin
                        ..._places.map((place) => Marker(
                              point: LatLng(place.lat, place.lng),
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () => _tampilkanDetailTempat(context, place),
                                child: const Icon(Icons.store, color: Colors.purple, size: 36),
                              ),
                            )),
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
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegend(Icons.my_location, Colors.blue, 'Lokasi Anda'),
                        const SizedBox(height: 4),
                        _buildLegend(Icons.location_on, Colors.red, 'Teknisi'),
                        const SizedBox(height: 4),
                        _buildLegend(Icons.store, Colors.purple, 'Tempat Jasa'),
                      ],
                    ),
                  ),
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
                          _mapController.move(_center, 15.0);
                        },
                        child: const Icon(Icons.my_location, color: Colors.white),
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

  void _tampilkanDetailTeknisi(BuildContext context, String nama, String keahlian) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(keahlian, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Status: Sedang menuju ke rumah Anda.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hubungi via Chat', style: TextStyle(color: Colors.white)),
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
                        Text(place.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(place.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              if (place.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(place.description, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Lihat Layanan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
