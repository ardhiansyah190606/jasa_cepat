import 'package:flutter/material.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:jasa_cepat/features/auth/screen/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final AppStorageService _storage = AppStorageService();
  late TabController _tabController;

  // Controllers Layanan
  final TextEditingController _svcNameController = TextEditingController();
  final TextEditingController _svcDescController = TextEditingController();
  final TextEditingController _svcDetailController = TextEditingController();
  final TextEditingController _svcPriceController = TextEditingController();
  final TextEditingController _svcPriceUnitController = TextEditingController();
  final TextEditingController _svcCategoryController = TextEditingController();
  final TextEditingController _svcIconController = TextEditingController();
  final TextEditingController _svcLatController = TextEditingController();
  final TextEditingController _svcLngController = TextEditingController();
  String _selectedPlaceId = '';

  // Controllers Tempat
  final TextEditingController _plcNameController = TextEditingController();
  final TextEditingController _plcAddressController = TextEditingController();
  final TextEditingController _plcLatController = TextEditingController();
  final TextEditingController _plcLngController = TextEditingController();
  final TextEditingController _plcDescController = TextEditingController();

  List<ServiceItem> _services = [];
  List<PlaceItem> _places = [];
  List<OrderItem> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _svcNameController.dispose();
    _svcDescController.dispose();
    _svcDetailController.dispose();
    _svcPriceController.dispose();
    _svcPriceUnitController.dispose();
    _svcCategoryController.dispose();
    _svcIconController.dispose();
    _svcLatController.dispose();
    _svcLngController.dispose();
    _plcNameController.dispose();
    _plcAddressController.dispose();
    _plcLatController.dispose();
    _plcLngController.dispose();
    _plcDescController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final services = await _storage.getServices();
    final places = await _storage.getPlaces();
    final orders = await _storage.getOrders();
    if (!mounted) return;
    setState(() {
      _services = services;
      _places = places;
      _orders = orders;
      _isLoading = false;
    });
  }

  // ==================== TAMBAH LAYANAN ====================
  Future<void> _addService() async {
    if (_svcNameController.text.trim().isEmpty ||
        _svcPriceController.text.trim().isEmpty) {
      _showSnack('Nama layanan dan harga wajib diisi.', isError: true);
      return;
    }

    final rawLat = _svcLatController.text.trim();
    final rawLng = _svcLngController.text.trim();
    double? serviceLat;
    double? serviceLng;

    if (rawLat.isNotEmpty || rawLng.isNotEmpty) {
      serviceLat = double.tryParse(rawLat.replaceAll(',', '.'));
      serviceLng = double.tryParse(rawLng.replaceAll(',', '.'));
      if (serviceLat == null || serviceLng == null) {
        _showSnack(
          'Koordinat layanan harus berisi latitude dan longitude yang valid.',
          isError: true,
        );
        return;
      }
    }

    await _storage.addService(
      name: _svcNameController.text.trim(),
      description: _svcDescController.text.trim(),
      detail: _svcDetailController.text.trim(),
      price: _svcPriceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      priceUnit: _svcPriceUnitController.text.trim().isEmpty
          ? 'per panggilan'
          : _svcPriceUnitController.text.trim(),
      category: _svcCategoryController.text.trim().isEmpty
          ? 'Umum'
          : _svcCategoryController.text.trim(),
      placeId: _selectedPlaceId,
      iconName: _svcIconController.text.trim().isEmpty
          ? 'build'
          : _svcIconController.text.trim(),
      lat: serviceLat,
      lng: serviceLng,
    );

    _svcNameController.clear();
    _svcDescController.clear();
    _svcDetailController.clear();
    _svcPriceController.clear();
    _svcPriceUnitController.clear();
    _svcCategoryController.clear();
    _svcIconController.clear();
    _svcLatController.clear();
    _svcLngController.clear();
    setState(() => _selectedPlaceId = '');

    await _loadData();
    _showSnack('Layanan berhasil ditambahkan!');
  }

  Future<void> _deleteService(String id) async {
    await _storage.deleteService(id);
    await _loadData();
    _showSnack('Layanan dihapus.');
  }

  // ==================== TAMBAH TEMPAT ====================
  Future<void> _addPlace() async {
    if (_plcNameController.text.trim().isEmpty ||
        _plcAddressController.text.trim().isEmpty) {
      _showSnack('Nama dan alamat tempat wajib diisi.', isError: true);
      return;
    }

    final rawLat = _plcLatController.text.trim();
    final rawLng = _plcLngController.text.trim();
    final lat = rawLat.isEmpty
        ? -6.175392
        : double.tryParse(rawLat.replaceAll(',', '.'));
    final lng = rawLng.isEmpty
        ? 106.827153
        : double.tryParse(rawLng.replaceAll(',', '.'));

    if (lat == null || lng == null) {
      _showSnack(
        'Koordinat tempat harus berisi latitude dan longitude yang valid.',
        isError: true,
      );
      return;
    }

    await _storage.addPlace(
      name: _plcNameController.text.trim(),
      address: _plcAddressController.text.trim(),
      lat: lat,
      lng: lng,
      description: _plcDescController.text.trim(),
    );

    _plcNameController.clear();
    _plcAddressController.clear();
    _plcLatController.clear();
    _plcLngController.clear();
    _plcDescController.clear();

    await _loadData();
    _showSnack('Tempat berhasil ditambahkan!');
  }

  Future<void> _deletePlace(String id) async {
    await _storage.deletePlace(id);
    await _loadData();
    _showSnack('Tempat dihapus.');
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    await _storage.updateOrderStatus(orderId, status);
    await _loadData();
    _showSnack('Status pesanan diperbarui.');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Admin Panel JasaCepat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 2,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.power_settings_new,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Log Out',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.build, size: 18), text: 'Kelola Jasa'),
            Tab(icon: Icon(Icons.store, size: 18), text: 'Kelola Tempat'),
            Tab(
              icon: Icon(Icons.analytics_outlined, size: 18),
              text: 'Pesanan',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabLayanan(),
                _buildTabTempat(),
                _buildTabPesanan(),
              ],
            ),
    );
  }

  // ==================== TAB 1: KELOLA LAYANAN ====================
  Widget _buildTabLayanan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelola Layanan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_services.length} layanan terdaftar',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),

          // FORM TAMBAH LAYANAN
          _buildCard(
            title: 'Tambah Layanan Baru',
            icon: Icons.add_circle_outline,
            child: Column(
              children: [
                _buildTextField(
                  _svcNameController,
                  'Nama Layanan *',
                  Icons.label_outline,
                  hint: 'Contoh: Servis AC',
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  _svcDescController,
                  'Deskripsi Singkat',
                  Icons.short_text,
                  hint: 'Contoh: Cuci dan tambah freon AC',
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  _svcDetailController,
                  'Detail Layanan Lengkap',
                  Icons.description_outlined,
                  maxLines: 3,
                  hint:
                      'Tulis detail layanan (pisah per baris untuk tampil sebagai poin-poin)',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _svcPriceController,
                        'Harga (Rp) *',
                        Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        hint: '185000',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _svcPriceUnitController,
                        'Satuan Harga',
                        Icons.straighten,
                        hint: 'per unit / per sesi',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _svcCategoryController,
                        'Kategori',
                        Icons.category_outlined,
                        hint: 'AC & Pendingin / Kelistrikan',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _svcIconController,
                        'Nama Icon',
                        Icons.image_outlined,
                        hint: 'ac_unit / grass / lightbulb',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Dropdown pilih tempat
                DropdownButtonFormField<String>(
                  initialValue: _selectedPlaceId.isEmpty
                      ? null
                      : _selectedPlaceId,
                  decoration: InputDecoration(
                    labelText: 'Tempat Penyedia (opsional)',
                    prefixIcon: const Icon(
                      Icons.store_outlined,
                      color: Colors.blue,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  hint: const Text('Pilih tempat...'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('— Tidak ada —'),
                    ),
                    ..._places.map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedPlaceId = val ?? ''),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _svcLatController,
                        'Latitude Layanan',
                        Icons.my_location_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        hint: 'Kosongkan jika ikut tempat',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _svcLngController,
                        'Longitude Layanan',
                        Icons.my_location_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        hint: '110.821781',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.near_me_outlined,
                        color: Colors.blue,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Koordinat ini dipakai untuk rekomendasi jasa/teknisi terdekat. Jika kosong, layanan memakai koordinat tempat penyedia.',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildSubmitButton(
                  'Simpan Layanan',
                  Icons.save_alt,
                  _addService,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // DAFTAR LAYANAN
          const Text(
            'Daftar Layanan Terdaftar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_services.isEmpty)
            _buildEmptyState('Belum ada layanan. Tambahkan layanan di atas.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = _services[index];
                return _buildServiceCard(s);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem s) {
    // Cari nama tempat terkait
    String placeName = '';
    PlaceItem? linkedPlace;
    if (s.placeId.isNotEmpty) {
      try {
        linkedPlace = _places.firstWhere((p) => p.id == s.placeId);
        placeName = linkedPlace.name;
      } catch (_) {}
    }
    final hasServiceCoordinate = s.lat != null && s.lng != null;
    final hasPlaceCoordinate = linkedPlace != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.12),
            child: const Icon(Icons.build, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (s.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildChip(s.category, Colors.blue),
                    _buildChip('Rp ${s.price} / ${s.priceUnit}', Colors.green),
                    if (placeName.isNotEmpty)
                      _buildChip(placeName, Colors.purple),
                    if (hasServiceCoordinate)
                      _buildChip(
                        '${s.lat!.toStringAsFixed(4)}, ${s.lng!.toStringAsFixed(4)}',
                        Colors.teal,
                      )
                    else if (hasPlaceCoordinate)
                      _buildChip('Ikut koordinat tempat', Colors.teal)
                    else
                      _buildChip('Belum ada koordinat', Colors.red),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(
              () => _deleteService(s.id),
              'layanan "${s.name}"',
            ),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: KELOLA TEMPAT ====================
  Widget _buildTabTempat() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelola Tempat',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_places.length} tempat terdaftar',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),

          // FORM TAMBAH TEMPAT
          _buildCard(
            title: 'Tambah Tempat / Lokasi Jasa',
            icon: Icons.add_location_alt_outlined,
            child: Column(
              children: [
                _buildTextField(
                  _plcNameController,
                  'Nama Tempat *',
                  Icons.store_outlined,
                  hint: 'Contoh: JasaCepat Hub Pusat',
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  _plcAddressController,
                  'Alamat Lengkap *',
                  Icons.location_on_outlined,
                  hint: 'Jl. Merdeka No. 1, Jakarta Pusat',
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _plcLatController,
                        'Latitude',
                        Icons.explore_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        hint: '-6.175392',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _plcLngController,
                        'Longitude',
                        Icons.explore_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        hint: '106.827153',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  _plcDescController,
                  'Deskripsi Tempat',
                  Icons.info_outline,
                  hint: 'Contoh: Pusat layanan utama JasaCepat',
                ),
                const SizedBox(height: 14),

                // PANDUAN KOORDINAT
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Untuk koordinat, buka Google Maps → klik lokasi → salin lat,lng dari URL atau popup.',
                          style: TextStyle(fontSize: 11, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildSubmitButton(
                  'Simpan Tempat',
                  Icons.add_location,
                  _addPlace,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // DAFTAR TEMPAT
          const Text(
            'Daftar Tempat Terdaftar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_places.isEmpty)
            _buildEmptyState('Belum ada tempat. Tambahkan tempat di atas.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _places.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final place = _places[index];
                return _buildPlaceCard(place);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(PlaceItem place) {
    // Hitung jumlah layanan di tempat ini
    final serviceCount = _services.where((s) => s.placeId == place.id).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple.withOpacity(0.12),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.address,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildChip(
                      '${place.lat.toStringAsFixed(4)}, ${place.lng.toStringAsFixed(4)}',
                      Colors.teal,
                    ),
                    _buildChip('$serviceCount layanan', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(
              () => _deletePlace(place.id),
              'tempat "${place.name}"',
            ),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: PESANAN ====================
  Widget _buildTabPesanan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Pesanan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_orders.length} pesanan masuk',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),

          // Ringkasan statistik
          Row(
            children: [
              _buildStatCard(
                'Total',
                '${_orders.length}',
                Icons.assignment,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Menunggu',
                '${_orders.where((o) => o.status == 'Menunggu').length}',
                Icons.pending,
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Selesai',
                '${_orders.where((o) => o.status == 'Selesai').length}',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_orders.isEmpty)
            _buildEmptyState(
              'Belum ada pesanan yang harus diverifikasi atau diterima.',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.12)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, thickness: 0.6),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final color = _orderStatusColor(order.status);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rp ${_formatHarga(order.price)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.serviceName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          order.userEmail,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildChip(_orderStatusLabel(order.status), color),
                            if (order.status == 'Menunggu')
                              _buildSmallAction(
                                'Terima',
                                Icons.check,
                                Colors.blue,
                                () => _updateOrderStatus(order.id, 'Diterima'),
                              ),
                            if (order.status == 'Diterima')
                              _buildSmallAction(
                                'Selesaikan',
                                Icons.done_all,
                                Colors.green,
                                () => _updateOrderStatus(order.id, 'Selesai'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==================== WIDGET HELPERS ====================

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A237E), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String hint = '',
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.blue, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color color = const Color(0xFF1A237E),
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            msg,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Colors.blue;
      case 'diterima':
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

  String _orderStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu Verifikasi';
      case 'diterima':
        return 'Diterima';
      default:
        return status;
    }
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

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(radius: 4, backgroundColor: Colors.green),
          SizedBox(width: 6),
          Text(
            'Online',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(VoidCallback onConfirm, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus $itemName? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
