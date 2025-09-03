import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';

class FAQItem {
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Semua',
    'Akun',
    'Pesanan',
    'Pembayaran',
    'Penyedia Jasa',
    'Lainnya',
  ];

  final List<FAQItem> _faqItems = [
    // Kategori Akun
    FAQItem(
      question: 'Bagaimana cara mendaftar di KlikJasa?',
      answer:
          'Untuk mendaftar di KlikJasa, buka aplikasi dan pilih "Daftar". Isi formulir pendaftaran dengan data yang valid, verifikasi email Anda, dan akun Anda siap digunakan.',
      category: 'Akun',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah kata sandi?',
      answer:
          'Untuk mengubah kata sandi, buka halaman Profil, pilih Pengaturan Akun, lalu pilih opsi "Ubah Kata Sandi". Masukkan kata sandi lama dan kata sandi baru Anda.',
      category: 'Akun',
    ),
    FAQItem(
      question: 'Bagaimana jika saya lupa kata sandi?',
      answer:
          'Jika Anda lupa kata sandi, pilih "Lupa Kata Sandi" di halaman login. Masukkan email terdaftar Anda, dan kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
      category: 'Akun',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah informasi profil?',
      answer:
          'Untuk mengubah informasi profil, buka halaman Profil, pilih Pengaturan Akun, lalu pilih "Profil Pengguna". Di sana Anda dapat mengubah nama, foto profil, dan informasi lainnya.',
      category: 'Akun',
    ),
    
    // Kategori Pesanan
    FAQItem(
      question: 'Bagaimana cara memesan jasa?',
      answer:
          'Untuk memesan jasa, pilih kategori jasa yang Anda butuhkan, pilih penyedia jasa, tentukan detail pesanan, lalu lakukan pembayaran. Pesanan Anda akan segera diproses.',
      category: 'Pesanan',
    ),
    FAQItem(
      question: 'Bagaimana cara membatalkan pesanan?',
      answer:
          'Untuk membatalkan pesanan, buka halaman "Pesanan Saya", pilih pesanan yang ingin dibatalkan, lalu pilih "Batalkan Pesanan". Perhatikan bahwa kebijakan pembatalan dapat berbeda untuk setiap penyedia jasa.',
      category: 'Pesanan',
    ),
    FAQItem(
      question: 'Bagaimana cara menilai penyedia jasa?',
      answer:
          'Setelah pesanan selesai, Anda akan diminta untuk memberikan penilaian dan ulasan. Anda juga dapat memberikan penilaian melalui halaman "Pesanan Selesai" di riwayat pesanan Anda.',
      category: 'Pesanan',
    ),
    FAQItem(
      question: 'Berapa lama waktu pengerjaan jasa?',
      answer:
          'Waktu pengerjaan jasa bervariasi tergantung pada jenis jasa dan penyedia jasa. Estimasi waktu pengerjaan akan ditampilkan saat Anda memesan jasa.',
      category: 'Pesanan',
    ),
    
    // Kategori Pembayaran
    FAQItem(
      question: 'Metode pembayaran apa saja yang tersedia?',
      answer:
          'KlikJasa menerima berbagai metode pembayaran, termasuk transfer bank, e-wallet (GoPay, OVO, DANA), dan kartu kredit/debit.',
      category: 'Pembayaran',
    ),
    FAQItem(
      question: 'Bagaimana cara melakukan top up saldo?',
      answer:
          'Untuk melakukan top up saldo, buka halaman "Saldo", pilih "Top Up", pilih nominal dan metode pembayaran, lalu ikuti petunjuk pembayaran.',
      category: 'Pembayaran',
    ),
    FAQItem(
      question: 'Bagaimana jika pembayaran saya gagal?',
      answer:
          'Jika pembayaran gagal, coba periksa koneksi internet Anda, pastikan saldo/limit kartu Anda mencukupi, atau coba metode pembayaran lain. Jika masalah berlanjut, hubungi layanan pelanggan kami.',
      category: 'Pembayaran',
    ),
    FAQItem(
      question: 'Bagaimana cara mendapatkan pengembalian dana?',
      answer:
          'Pengembalian dana akan diproses sesuai dengan kebijakan pembatalan. Dana akan dikembalikan ke metode pembayaran asli atau saldo KlikJasa Anda dalam 3-5 hari kerja.',
      category: 'Pembayaran',
    ),
    
    // Kategori Penyedia Jasa
    FAQItem(
      question: 'Bagaimana cara menjadi penyedia jasa?',
      answer:
          'Untuk menjadi penyedia jasa, daftar akun KlikJasa, pilih "Daftar sebagai Penyedia Jasa", lengkapi profil dan verifikasi, lalu tunggu persetujuan dari tim kami.',
      category: 'Penyedia Jasa',
    ),
    FAQItem(
      question: 'Bagaimana cara mengelola pesanan sebagai penyedia jasa?',
      answer:
          'Sebagai penyedia jasa, Anda dapat mengelola pesanan melalui dashboard penyedia jasa. Di sana Anda dapat menerima/menolak pesanan, berkomunikasi dengan pelanggan, dan menandai pesanan selesai.',
      category: 'Penyedia Jasa',
    ),
    FAQItem(
      question: 'Berapa biaya komisi untuk penyedia jasa?',
      answer:
          'KlikJasa mengenakan biaya komisi sebesar 10% dari nilai pesanan untuk setiap transaksi yang berhasil. Biaya ini akan otomatis dipotong dari pembayaran Anda.',
      category: 'Penyedia Jasa',
    ),
    
    // Kategori Lainnya
    FAQItem(
      question: 'Bagaimana cara menghubungi layanan pelanggan?',
      answer:
          'Anda dapat menghubungi layanan pelanggan kami melalui fitur "Hubungi Kami" di aplikasi, email support@klikjasa.com, atau nomor telepon 0800-1234-5678 (Senin-Jumat, 08.00-17.00 WIB).',
      category: 'Lainnya',
    ),
    FAQItem(
      question: 'Apakah KlikJasa tersedia di semua kota?',
      answer:
          'Ya, KlikJasa tersedia di seluruh kota di Indonesia.',
      category: 'Lainnya',
    ),
    FAQItem(
      question: 'Bagaimana jika ada masalah dengan jasa yang diberikan?',
      answer:
          'Jika ada masalah dengan jasa yang diberikan, Anda dapat melaporkannya melalui halaman pesanan dengan memilih "Laporkan Masalah". Tim kami akan menindaklanjuti laporan Anda dalam 24 jam.',
      category: 'Lainnya',
    ),
    FAQItem(
      question: 'Apakah KlikJasa menjamin kualitas jasa?',
      answer:
          'KlikJasa berkomitmen untuk menyediakan penyedia jasa berkualitas. Kami melakukan verifikasi dan penilaian berkala terhadap penyedia jasa. Jika Anda tidak puas, kami memiliki kebijakan pengembalian dana sesuai ketentuan.',
      category: 'Lainnya',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FAQItem> get _filteredFAQItems {
    final List<FAQItem> result = [];
    for (final item in _faqItems) {
      final bool matchesCategory = _selectedCategoryIndex == 0 || item.category == _categories[_selectedCategoryIndex];
      final bool matchesSearch = _searchQuery.isEmpty || 
          item.question.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          item.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (matchesCategory && matchesSearch) {
        result.add(item);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.bantuan),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryTabs(),
          Expanded(
            child: _filteredFAQItems.isEmpty
                ? _buildEmptyState()
                : _buildFAQList(),
          ),
          _buildContactSupport(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari pertanyaan atau kata kunci...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final bool isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFAQItems.length,
      itemBuilder: (context, index) {
        final item = _filteredFAQItems[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              item.question,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.answer),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: const Text('Membantu'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terima kasih atas umpan balik Anda!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.thumb_down_outlined, size: 16),
                    label: const Text('Tidak Membantu'),
                    onPressed: () {
                      _showFeedbackDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil ditemukan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba kata kunci lain atau pilih kategori yang berbeda',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedCategoryIndex = 0;
              });
            },
            child: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Hubungi Kami'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showContactDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Beri Kami Umpan Balik'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bantu kami meningkatkan jawaban. Apa yang kurang dari jawaban ini?'),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis umpan balik Anda di sini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.batal),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terima kasih atas umpan balik Anda!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text(AppStrings.kirim),
            ),
          ],
        );
      },
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hubungi Layanan Pelanggan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContactOption(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'support@klikjasa.com',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka aplikasi email...'),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildContactOption(
                icon: Icons.phone_outlined,
                title: 'Telepon',
                subtitle: '0800-1234-5678',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka aplikasi telepon...'),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildContactOption(
                icon: Icons.chat_outlined,
                title: 'Live Chat',
                subtitle: 'Senin-Jumat, 08.00-17.00 WIB',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur live chat akan segera tersedia'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.tutup),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
