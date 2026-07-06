import 'package:flutter/material.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:jasa_cepat/features/auth/screen/login_screen.dart';
import 'package:jasa_cepat/features/chat/screen/chat_screen.dart';
import 'package:jasa_cepat/features/home/edit_location_screen.dart';
import 'package:jasa_cepat/features/home/map_screen.dart';
import 'package:jasa_cepat/features/home/service_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Pengguna JasaCepat';
  String _userEmail = 'user@gmail.com';

  // Lokasi pengguna (dinamis dari storage)
  String _userAddress = 'Memuat lokasi...';
  double _userLat = -6.175392;
  double _userLng = 106.827153;

  // Data dari database
  List<ServiceItem> _services = [];
  List<PlaceItem> _places = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLocation();
    _loadServicesAndPlaces();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AppStorageService().getProfile();
      if (profile.isNotEmpty && mounted) {
        setState(() {
          _userName = profile['name'] ?? 'Pengguna JasaCepat';
          _userEmail = profile['email'] ?? 'user@gmail.com';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await AppStorageService().getUserLocation();
      if (mounted) {
        setState(() {
          _userAddress = loc.address;
          _userLat = loc.lat;
          _userLng = loc.lng;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userAddress = 'Jl. Urban Raya No. 42, Jakarta';
        });
      }
    }
  }

  Future<void> _loadServicesAndPlaces() async {
    try {
      final services = await AppStorageService().getServices();
      final places = await AppStorageService().getPlaces();
      if (mounted) {
        setState(() {
          _services = services;
          _places = places;
          _isLoadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'ac_unit':
        return Icons.ac_unit;
      case 'grass':
        return Icons.grass;
      case 'water_drop':
        return Icons.water_drop;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'home_repair_service':
        return Icons.home_repair_service;
      default:
        return Icons.build;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ac & pendingin':
        return Colors.blue;
      case 'kebersihan':
        return Colors.green;
      case 'sanitasi':
        return Colors.cyan;
      case 'kelistrikan':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  // Fallback jika belum ada data dari admin
  List<Map<String, dynamic>> get _defaultCategories => [
        {'name': 'Servis AC', 'icon': Icons.ac_unit, 'color': Colors.blue},
        {'name': 'Potong Rumput', 'icon': Icons.grass, 'color': Colors.green},
        {'name': 'Kuras Toren', 'icon': Icons.water_drop, 'color': Colors.cyan},
        {'name': 'Pasang Lampu', 'icon': Icons.lightbulb, 'color': Colors.amber},
      ];

  Future<void> _openEditLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationScreen(
          currentLat: _userLat,
          currentLng: _userLng,
          currentAddress: _userAddress,
        ),
      ),
    );
    if (result == true) {
      await _loadLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBerandaPage(),
      _buildPesananPage(),
      _buildChatPage(),
      _buildProfilPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'JasaCepat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 24),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Pesanan'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  // ==================== BERANDA ====================
  Widget _buildBerandaPage() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadLocation();
        await _loadServicesAndPlaces();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === TOMBOL LOKASI (dapat diklik untuk edit) ===
              InkWell(
                onTap: _openEditLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Anda',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              _userAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ubah',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // === TOMBOL LIHAT PETA ===
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        initialLat: _userLat,
                        initialLng: _userLng,
                        initialAddress: _userAddress,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.map_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lihat Teknisi di Peta',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // === GRID LAYANAN (dari database admin) ===
              const Text(
                'Layanan yang Anda Butuhkan?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _isLoadingServices
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _services.isEmpty
                      ? _buildDefaultGrid()
                      : _buildServicesGrid(),
              const SizedBox(height: 24),

              // === TEMPAT JASA (dari database admin) ===
              if (_places.isNotEmpty) ...[
                const Text(
                  'Tempat Penyedia Jasa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _places.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return _buildPlaceCard(place);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // === TEKNISI TERDEKAT ===
              const Text(
                'Teknisi Terdekat di Area Anda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildMitraCard('Budi Setiawan', 'Spesialis AC', '4.8', '350m'),
              const SizedBox(height: 8),
              _buildMitraCard('Slamet Riyadi', 'Ahli Kelistrikan', '4.9', '800m'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        final color = _getCategoryColor(service.category);
        return GestureDetector(
          onTap: () async {
            // Cari place terkait
            PlaceItem? place;
            if (service.placeId.isNotEmpty) {
              try {
                place = _places.firstWhere((p) => p.id == service.placeId);
              } catch (_) {}
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(service: service, place: place),
              ),
            );
          },
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(_resolveIcon(service.iconName), color: color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                service.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
              Text(
                'Rp ${_formatHarga(service.price)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _defaultCategories.length,
      itemBuilder: (context, index) {
        final item = _defaultCategories[index];
        return Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: (item['color'] as Color).withOpacity(0.1),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              item['name'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceCard(PlaceItem place) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: Colors.purple, size: 16),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'JasaCepat Hub',
                  style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            place.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            place.address,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMitraCard(String name, String keahlian, String rating, String jarak) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keahlian, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(
                  ' $rating • ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(jarak, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Panggil', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ==================== PESANAN ====================
  Widget _buildPesananPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(text: 'Dalam Proses'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildKartuPesanan(
                      idPesanan: 'JC-90821',
                      layanan: 'Servis AC - Cuci AC & Tambah Freon',
                      teknisi: 'Budi Setiawan',
                      status: 'Teknisi Menuju Lokasi',
                      statusColor: Colors.orange,
                      tanggal: 'Hari ini, 14:20 WIB',
                      harga: 'Rp 185.000',
                      icon: Icons.ac_unit,
                    ),
                    const SizedBox(height: 12),
                    _buildKartuPesanan(
                      idPesanan: 'JC-90825',
                      layanan: 'Pasang Lampu Kamar & Ruang Tamu',
                      teknisi: 'Mencari Teknisi...',
                      status: 'Menunggu Konfirmasi',
                      statusColor: Colors.blue,
                      tanggal: 'Hari ini, 20:00 WIB',
                      harga: 'Rp 75.000',
                      icon: Icons.lightbulb,
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildKartuPesanan(
                      idPesanan: 'JC-88102',
                      layanan: 'Potong Rumput Halaman Depan',
                      teknisi: 'Slamet Riyadi',
                      status: 'Selesai',
                      statusColor: Colors.green,
                      tanggal: '28 Juni 2026',
                      harga: 'Rp 120.000',
                      icon: Icons.grass,
                    ),
                    const SizedBox(height: 12),
                    _buildKartuPesanan(
                      idPesanan: 'JC-87551',
                      layanan: 'Kuras Toren Air 1000L',
                      teknisi: 'Hendra Wijaya',
                      status: 'Dibatalkan',
                      statusColor: Colors.red,
                      tanggal: '20 Juni 2026',
                      harga: 'Rp 150.000',
                      icon: Icons.water_drop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuPesanan({
    required String idPesanan,
    required String layanan,
    required String teknisi,
    required String status,
    required Color statusColor,
    required String tanggal,
    required String harga,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(idPesanan, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12)),
              Text(tanggal, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const Divider(height: 20, thickness: 0.8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(icon, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(layanan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Teknisi: $teknisi', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text(harga, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CHAT ====================
  Widget _buildChatPage() {
    final List<Map<String, dynamic>> chatList = [
      {'name': 'Budi Setiawan (Teknisi AC)', 'message': 'Halo pak, saya sudah di jalan ya menuju rumah.', 'time': '14:25', 'unread': true, 'icon': Icons.ac_unit},
      {'name': 'Customer Service JasaCepat', 'message': 'Apakah keluhan servis Anda kemarin sudah aman?', 'time': 'Kemarin', 'unread': false, 'icon': Icons.support_agent},
      {'name': 'Slamet Riyadi (Kelistrikan)', 'message': 'Terima kasih banyak atas tip jasanya bos!', 'time': '28 Juni', 'unread': false, 'icon': Icons.flash_on},
    ];

    return ListView.separated(
      itemCount: chatList.length,
      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        final chat = chatList[index];
        return Container(
          color: chat['unread'] ? Colors.blue.withOpacity(0.03) : Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(chat['icon'], color: Colors.blue, size: 24),
                ),
                if (chat['unread'])
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(chat['name'], style: TextStyle(fontWeight: chat['unread'] ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                Text(chat['time'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                chat['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: chat['unread'] ? Colors.black87 : Colors.grey[600], fontSize: 13),
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
            },
          ),
        );
      },
    );
  }

  // ==================== PROFIL ====================
  Widget _buildProfilPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            width: double.infinity,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 12),
                // Tampilkan lokasi tersimpan di profil
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _userAddress,
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildMenuProfilGroup([
            _buildProfilItem(Icons.person_outline, 'Ubah Data Profil', onTap: () {}),
            _buildProfilItem(
              Icons.location_on_outlined,
              'Ubah Lokasi / Alamat Saya',
              onTap: _openEditLocation,
            ),
            _buildProfilItem(Icons.payment_outlined, 'Metode Pembayaran', onTap: () {}),
          ]),

          const SizedBox(height: 12),

          _buildMenuProfilGroup([
            _buildProfilItem(Icons.security, 'Keamanan Akun', onTap: () {}),
            _buildProfilItem(Icons.help_outline, 'Pusat Bantuan CS', onTap: () {}),
            _buildProfilItem(Icons.privacy_tip_outlined, 'Kebijakan Privasi', onTap: () {}),
          ]),

          const SizedBox(height: 24),

          // Versi aplikasi saja, tanpa keterangan kelompok
          Text(
            'JasaCepat v1.0.0',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuProfilGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.15)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfilItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar Akun'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi JasaCepat?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _formatHarga(String price) {
    try {
      final num = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
      final str = num.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
        buffer.write(str[i]);
      }
      return buffer.toString();
    } catch (_) {
      return price;
    }
  }
}
