import 'package:flutter/material.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:jasa_cepat/core/location_recommendation.dart';
import 'package:jasa_cepat/features/auth/screen/edit_profile_screen.dart';
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
  List<OrderItem> _orders = [];
  bool _isLoadingServices = true;
  bool _isLoadingOrders = true;
  static const String _allServiceCategoriesLabel = 'Semua';
  String _selectedServiceCategory = _allServiceCategoriesLabel;

  List<ServiceDistance> get _recommendedServices =>
      LocationRecommendation.nearestServices(
        services: _services,
        places: _places,
        userLat: _userLat,
        userLng: _userLng,
        maxDistanceKm: LocationRecommendation.maxNearbyDistanceKm,
        includeWithoutLocation: false,
      );

  List<PlaceDistance> get _recommendedPlaces =>
      LocationRecommendation.nearestPlaces(
        places: _places,
        userLat: _userLat,
        userLng: _userLng,
        maxDistanceKm: LocationRecommendation.maxNearbyDistanceKm,
      );

  List<String> get _serviceCategories {
    final categories =
        _services
            .map((service) => service.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [_allServiceCategoriesLabel, ...categories];
  }

  List<ServiceItem> get _filteredServices {
    if (_selectedServiceCategory == _allServiceCategoriesLabel) {
      return _services;
    }

    return _services
        .where(
          (service) =>
              service.category.trim().toLowerCase() ==
              _selectedServiceCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLocation();
    _loadServicesAndPlaces();
    _loadOrders();
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
        final categories = services
            .map((service) => service.category.trim().toLowerCase())
            .where((category) => category.isNotEmpty)
            .toSet();
        final selectedStillAvailable =
            _selectedServiceCategory == _allServiceCategoriesLabel ||
            categories.contains(_selectedServiceCategory.toLowerCase());

        setState(() {
          _services = services;
          _places = places;
          if (!selectedStillAvailable) {
            _selectedServiceCategory = _allServiceCategoriesLabel;
          }
          _isLoadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final profile = await AppStorageService().getProfile();
      final email = profile['email']?.toString() ?? _userEmail;
      final orders = await AppStorageService().getOrders(userEmail: email);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrders = false);
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

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(currentName: _userName, currentEmail: _userEmail),
      ),
    );

    if (updated == true) {
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openCustomerServiceChat() {
    setState(() => _currentIndex = 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          contactName: 'Customer Service JasaCepat',
          subtitle: 'Pusat Bantuan CS',
          isCustomerService: true,
        ),
      ),
    );
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
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black,
              size: 26,
            ),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
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
        await _loadOrders();
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
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 14,
                      ),
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
              const SizedBox(height: 12),
              _isLoadingServices
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _services.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.design_services_outlined,
                      title: 'Belum ada jasa tersedia',
                      message:
                          'Admin belum menambahkan layanan. Silakan cek lagi nanti.',
                    )
                  : _buildServicesGrid(),
              const SizedBox(height: 24),

              // === TEMPAT JASA (dari database admin) ===
              if (_recommendedPlaces.isNotEmpty) ...[
                const Text(
                  'Tempat Penyedia Jasa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 138,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedPlaces.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final recommendation = _recommendedPlaces[index];
                      return _buildPlaceCard(
                        recommendation.place,
                        distanceLabel: recommendation.distanceLabel,
                      );
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
              _buildNearbyTechnicianList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    final categories = _serviceCategories;
    final services = _filteredServices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.length > 1) ...[
          _buildServiceCategorySelector(categories),
          const SizedBox(height: 12),
        ],
        if (services.isEmpty)
          _buildEmptyState(
            icon: Icons.category_outlined,
            title: 'Belum ada jasa di kategori ini',
            message: 'Pilih kategori lain untuk melihat layanan tersedia.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final color = _getCategoryColor(service.category);
              return GestureDetector(
                onTap: () async {
                  PlaceItem? place;
                  if (service.placeId.isNotEmpty) {
                    try {
                      place = _places.firstWhere(
                        (p) => p.id == service.placeId,
                      );
                    } catch (_) {}
                  }

                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ServiceDetailScreen(service: service, place: place),
                    ),
                  );
                  if (created == true) {
                    await _loadOrders();
                    if (mounted) {
                      setState(() => _currentIndex = 1);
                    }
                  }
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        _resolveIcon(service.iconName),
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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
          ),
      ],
    );
  }

  Widget _buildServiceCategorySelector(List<String> categories) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedServiceCategory;
          final color = category == _allServiceCategoriesLabel
              ? Colors.blue
              : _getCategoryColor(category);

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            selectedColor: color.withOpacity(0.14),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? color : Colors.grey.withOpacity(0.22),
            ),
            labelStyle: TextStyle(
              color: isSelected ? color : Colors.grey[700],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            onSelected: (_) {
              setState(() => _selectedServiceCategory = category);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceCard(PlaceItem place, {String? distanceLabel}) {
    return Container(
      width: 170,
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
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            place.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            place.address,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (distanceLabel != null) ...[
            const SizedBox(height: 3),
            Text(
              distanceLabel,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNearbyTechnicianList() {
    final nearby = _recommendedServices
        .where((item) => item.hasLocation)
        .take(3)
        .toList();

    if (nearby.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_off_outlined,
        title: 'Belum ada teknisi dalam radius 60 km',
        message:
            'Ubah lokasi Anda atau tambahkan koordinat layanan yang lebih dekat.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < nearby.length; i++) ...[
          _buildMitraCard(nearby[i]),
          if (i < nearby.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildMitraCard(ServiceDistance recommendation) {
    final service = recommendation.service;
    final place = recommendation.place;
    final color = _getCategoryColor(service.category);
    final technicianName = place?.name ?? 'Teknisi ${service.name}';
    final subtitle = '${service.name} - ${service.category}';
    final rating = _ratingForService(service.id);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          technicianName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(
                  ' $rating - ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(
                    recommendation.distanceLabel,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(
                  service: service,
                  place: place,
                  distanceKm: recommendation.distanceKm,
                ),
              ),
            );
            if (created == true) {
              await _loadOrders();
              if (mounted) {
                setState(() => _currentIndex = 1);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text(
            'Panggil',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _ratingForService(String serviceId) {
    final seed = serviceId.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final rating = 4.6 + (seed % 4) * 0.1;
    return rating.toStringAsFixed(1);
  }

  // ==================== PESANAN ====================
  Widget _buildPesananPage() {
    final activeOrders = _orders
        .where((order) => !_isHistoryStatus(order.status))
        .toList();
    final historyOrders = _orders
        .where((order) => _isHistoryStatus(order.status))
        .toList();

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
                _buildOrderList(
                  orders: activeOrders,
                  emptyTitle: 'Belum ada pesanan aktif',
                  emptyMessage: 'Pesanan yang baru dibuat akan muncul di sini.',
                ),
                _buildOrderList(
                  orders: historyOrders,
                  emptyTitle: 'Riwayat pesanan masih kosong',
                  emptyMessage:
                      'Pesanan selesai atau dibatalkan akan tersimpan di sini.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList({
    required List<OrderItem> orders,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: orders.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEmptyState(
                  icon: Icons.assignment_outlined,
                  title: emptyTitle,
                  message: emptyMessage,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildKartuPesanan(
                  idPesanan: order.id,
                  layanan: order.serviceName,
                  teknisi: order.technicianName,
                  status: _statusLabel(order.status),
                  statusColor: _statusColor(order.status),
                  tanggal: _formatTanggal(order.createdAt),
                  harga: 'Rp ${_formatHarga(order.price)}',
                  icon: Icons.home_repair_service,
                );
              },
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
              Text(
                idPesanan,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                tanggal,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
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
                    Text(
                      layanan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teknisi: $teknisi',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                harga,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== CHAT ====================
  Widget _buildChatPage() {
    final List<Map<String, dynamic>> chatList = [
      {
        'name': 'Budi Setiawan (Teknisi AC)',
        'message': 'Halo pak, saya sudah di jalan ya menuju rumah.',
        'time': '14:25',
        'unread': true,
        'icon': Icons.ac_unit,
      },
      {
        'name': 'Customer Service JasaCepat',
        'message': 'Apakah keluhan servis Anda kemarin sudah aman?',
        'time': 'Kemarin',
        'unread': false,
        'icon': Icons.support_agent,
      },
      {
        'name': 'Slamet Riyadi (Kelistrikan)',
        'message': 'Terima kasih banyak atas tip jasanya bos!',
        'time': '28 Juni',
        'unread': false,
        'icon': Icons.flash_on,
      },
    ];

    return ListView.separated(
      itemCount: chatList.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        final chat = chatList[index];
        return Container(
          color: chat['unread']
              ? Colors.blue.withOpacity(0.03)
              : Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
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
                Text(
                  chat['name'],
                  style: TextStyle(
                    fontWeight: chat['unread']
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  chat['time'],
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                chat['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chat['unread'] ? Colors.black87 : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
            onTap: () {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(
                      contactName: 'Customer Service JasaCepat',
                      subtitle: 'Pusat Bantuan CS',
                      isCustomerService: true,
                    ),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
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
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                // Tampilkan lokasi tersimpan di profil
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _userAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
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
            _buildProfilItem(
              Icons.person_outline,
              'Ubah Data Profil',
              onTap: _openEditProfile,
            ),
            _buildProfilItem(
              Icons.location_on_outlined,
              'Ubah Lokasi / Alamat Saya',
              onTap: _openEditLocation,
            ),
            _buildProfilItem(
              Icons.help_outline,
              'Pusat Bantuan CS',
              onTap: _openCustomerServiceChat,
            ),
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

  Widget _buildProfilItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar Akun'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi JasaCepat?',
          ),
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
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  bool _isHistoryStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'selesai' ||
        normalized == 'dibatalkan' ||
        normalized == 'batal';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Colors.blue;
      case 'diterima':
      case 'proses':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
      case 'batal':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu Admin';
      case 'diterima':
        return 'Diterima Admin';
      default:
        return status;
    }
  }

  String _formatTanggal(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}