import 'package:flutter/material.dart';
import 'package:jasa_cepat/features/auth/screen/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index halaman yang aktif (0 = Beranda)
  int _currentIndex = 0;

  // Daftar Kategori Jasa
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Servis AC', 'icon': Icons.ac_unit, 'color': Colors.blue},
    {'name': 'Potong Rumput', 'icon': Icons.grass, 'color': Colors.green},
    {'name': 'Kuras Toren', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {'name': 'Pasang Lampu', 'icon': Icons.lightbulb, 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    // List halaman berdasarkan menu bawah yang diklik
    final List<Widget> _pages = [
      _buildBerandaPage(), // Halaman Utama saat ini
      const Center(
        child: Text(
          'Halaman Pesanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      const Center(
        child: Text(
          'Halaman Chat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      const Center(
        child: Text(
          'Halaman Profil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'JasaCepat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        elevation: 0.5,
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),

      // Menampilkan halaman sesuai dengan menu bawah yang sedang aktif
      body: _pages[_currentIndex],

      // ==========================================
      // KODE MENU BAWAH (BOTTOM NAVIGATION BAR) sesuai gambar
      // ==========================================
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
          onTap: (index) {
            setState(() {
              _currentIndex = index; // Mengubah halaman aktif saat menu diklik
            });
          },
          type: BottomNavigationBarType
              .fixed, // Memastikan menu tidak bergeser aneh saat diklik
          backgroundColor: Colors.white,
          selectedItemColor:
              Colors.blue, // Warna biru saat menu aktif sesuai gambar
          unselectedItemColor:
              Colors.grey[400], // Warna abu-abu saat menu tidak aktif
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_filled),
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.assignment_outlined),
              ),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_outline),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk isi konten halaman Beranda
  Widget _buildBerandaPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Lokasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Lokasi Anda',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          'Jl. Urban Raya No. 42, Jakarta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Judul Kategori
            const Text(
              'Layanan yang Anda Butuhkan?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Grid Kategori Jasa
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: item['color'].withOpacity(0.1),
                      child: Icon(item['icon'], color: item['color'], size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Daftar Tukang Terdekat
            const Text(
              'Teknisi Terdekat di Area Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildMitraCard('Budi Setiawan', 'Spesialis AC', '4.8', '350m'),
            const SizedBox(height: 8),
            _buildMitraCard('Slamet Riyadi', 'Ahli Kelistrikan', '4.9', '800m'),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Kartu Teknisi
  Widget _buildMitraCard(
    String name,
    String keahlian,
    String rating,
    String jarak,
  ) {
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
            Text(
              keahlian,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(
                  ' $rating • ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  jarak,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
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
}