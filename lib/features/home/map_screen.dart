import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Koordinat awal (Contoh: Monas, Jakarta)
  final LatLng _initialPosition = const LatLng(-6.175392, 106.827153);

  // Controller untuk mengontrol pergerakan peta secara programatis
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peta Teknisi JasaCepat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. KOMPONEN UTAMA WIDGET FLUTTER MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition, // Pusat peta awal
              initialZoom: 15.0, // Tingkat kedekatan/zoom awal
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              // Layer Ubin Peta (Mengambil gambar peta dari server OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.jasa_cepat', // Sesuaikan dengan id package aplikasi Anda
              ),

              // Layer Penanda / Marker (Tempat menaruh ikon lokasi)
              MarkerLayer(
                markers: [
                  // Contoh Marker 1: Lokasi Pengguna
                  Marker(
                    point: _initialPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 35,
                    ),
                  ),

                  // Contoh Marker 2: Lokasi Teknisi Terdekat
                  Marker(
                    point: const LatLng(-6.177000, 106.828000),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        _tampilkanDetailTeknisi(
                          context,
                          'Budi Setiawan (Servis AC)',
                        );
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. TOMBOL FLOAT KUSTOM (Opsi Tambahan untuk navigasi zoom)
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk memunculkan modal kecil saat marker diklik
  void _tampilkanDetailTeknisi(BuildContext context, String namaTeknisi) {
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
              Text(
                namaTeknisi,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Status: Sedang menuju ke rumah Anda.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hubungi via Chat',
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
