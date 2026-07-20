import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jasa_cepat/core/app_storage_service.dart';
import 'package:jasa_cepat/core/location_recommendation.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceItem service;
  final PlaceItem? place;
  final double? distanceKm;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    this.place,
    this.distanceKm,
  });

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
      case 'carpenter':
        return Icons.carpenter;
      case 'roofing':
        return Icons.roofing;
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
      case 'plumbing':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(service.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // === SLIVER APP BAR dengan warna kategori ===
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _resolveIcon(service.iconName),
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HARGA ===
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.green,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rp ${_formatHarga(service.price)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              service.priceUnit,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (distanceKm != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Jarak ${LocationRecommendation.formatDistance(distanceKm!)} dari lokasi Anda',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === DESKRIPSI SINGKAT ===
                  if (service.description.isNotEmpty) ...[
                    const Text(
                      'Tentang Layanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        service.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // === DETAIL LENGKAP ===
                  if (service.detail.isNotEmpty) ...[
                    const Text(
                      'Detail Layanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...service.detail
                              .split('\n')
                              .where((line) => line.trim().isNotEmpty)
                              .map((line) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 5),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          line.trim(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // === TEMPAT / LOKASI PENYEDIA ===
                  if (place != null) ...[
                    const Text(
                      'Lokasi Penyedia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.place,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  place!.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (place!.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    place!.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // === KEUNGGULAN ===
                  const Text(
                    'Mengapa JasaCepat?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildKeunggulan(
                    Icons.verified_outlined,
                    'Teknisi Bersertifikat',
                    'Semua teknisi sudah terverifikasi dan berpengalaman',
                  ),
                  _buildKeunggulan(
                    Icons.timer_outlined,
                    'Cepat & Tepat Waktu',
                    'Teknisi tiba dalam waktu singkat sesuai jadwal',
                  ),
                  _buildKeunggulan(
                    Icons.price_check_outlined,
                    'Harga Transparan',
                    'Tidak ada biaya tersembunyi, harga sudah termasuk',
                  ),
                  _buildKeunggulan(
                    Icons.security_outlined,
                    'Bergaransi',
                    'Garansi 7 hari jika ada masalah setelah servis',
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // === BOTTOM BUTTON PESAN ===
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              AppStorageService()
                  .createOrder(service: service, place: place)
                  .then((_) async {
                    if (!context.mounted) return;

                    // Buat pesan invoice WhatsApp
                    final invoiceMessage = StringBuffer();
                    invoiceMessage.writeln('📋 *INVOICE PESANAN - JasaCepat*');
                    invoiceMessage.writeln('━━━━━━━━━━━━━━━━━━━━━');
                    invoiceMessage.writeln('');
                    invoiceMessage.writeln('🔧 *Layanan:* ${service.name}');
                    invoiceMessage.writeln('📂 *Kategori:* ${service.category}');
                    invoiceMessage.writeln('💰 *Harga:* Rp ${_formatHarga(service.price)} (${service.priceUnit})');
                    if (service.description.isNotEmpty) {
                      invoiceMessage.writeln('📝 *Deskripsi:* ${service.description}');
                    }
                    if (place != null) {
                      invoiceMessage.writeln('');
                      invoiceMessage.writeln('📍 *Lokasi Penyedia:* ${place!.name}');
                      invoiceMessage.writeln('🏠 *Alamat:* ${place!.address}');
                    }
                    if (distanceKm != null) {
                      invoiceMessage.writeln('📏 *Jarak:* ${LocationRecommendation.formatDistance(distanceKm!)}');
                    }
                    invoiceMessage.writeln('');
                    invoiceMessage.writeln('━━━━━━━━━━━━━━━━━━━━━');
                    invoiceMessage.writeln('Saya ingin memesan layanan ini. Mohon konfirmasi ketersediaan. Terima kasih! 🙏');

                    // Redirect ke WhatsApp
                    final waUrl = Uri.parse(
                      'https://wa.me/6289630984128?text=${Uri.encodeComponent(invoiceMessage.toString())}',
                    );

                    if (await canLaunchUrl(waUrl)) {
                      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Pesanan ${service.name} masuk ke riwayat pesanan.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
                  })
                  .catchError((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal membuat pesanan. Coba lagi.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
            },
            icon: const Icon(Icons.flash_on),
            label: Text(
              'Pesan Sekarang — Rp ${_formatHarga(service.price)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeunggulan(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
