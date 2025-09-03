import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/profile/presentation/bloc/region/region_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_event.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_state.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/pages/add_edit_layanan_screen.dart';
import 'package:klik_jasa/injection_container.dart' as sl;

/// Screen untuk menampilkan detail layanan.
class LayananDetailScreen extends StatefulWidget {
  final String layananId;

  const LayananDetailScreen({super.key, required this.layananId});

  @override
  State<LayananDetailScreen> createState() => _LayananDetailScreenState();
}

class _LayananDetailScreenState extends State<LayananDetailScreen> {
  late ServicesBloc _servicesBloc;

  @override
  void initState() {
    super.initState();
    _servicesBloc = sl.sl<ServicesBloc>();
    _loadLayananDetail();
  }

  void _loadLayananDetail() {
    _servicesBloc.add(LoadLayananDetail(layananId: widget.layananId));
  }

  Future<void> _confirmDelete(Service layanan) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text('Apakah Anda yakin ingin menghapus layanan "${layanan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      _servicesBloc.add(DeleteLayanan(layananId: layanan.id));
    }
  }

  Future<void> _navigateToEditScreen(Service layanan) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<RegionBloc>(
              create: (context) => sl.sl<RegionBloc>(),
            ),
            BlocProvider<ServicesBloc>(
              create: (context) => sl.sl<ServicesBloc>(),
            ),
          ],
          child: AddEditLayananScreen(
            service: layanan,
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      _loadLayananDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _servicesBloc,
      child: BlocConsumer<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is LayananUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.layanan.isPromoted
                      ? 'Promosi layanan "${state.layanan.title}" telah diaktifkan. Biaya Rp 1.000/hari akan dipotong dari saldo Anda.'
                      : 'Promosi layanan "${state.layanan.title}" telah dinonaktifkan.',
                ),
                backgroundColor: state.layanan.isPromoted ? Colors.amber[700] : Colors.grey[600],
              ),
            );
          } else if (state is ServicesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LayananDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Layanan berhasil dihapus')),
            );
            Navigator.of(context).pop(true); // Kembali ke halaman sebelumnya
            return Container(); // Placeholder sementara karena akan navigasi keluar
          } else if (state is ServicesLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is LayananDetailLoaded) {
            final layanan = state.layanan;
            return _buildDetailScreen(context, layanan);
          } else if (state is ServicesError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detail Layanan')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLayananDetail,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: Text('Memuat detail layanan...')),
          );
        },
      ),
    );
  }

  Widget _buildDetailScreen(BuildContext context, Service layanan) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Layanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditScreen(layanan),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(layanan),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar layanan
            _buildImageGallery(layanan),

            // Informasi layanan
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dan status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          layanan.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Switch(
                        value: layanan.isActive,
                        onChanged: (value) {
                          context.read<ServicesBloc>().add(
                                SetLayananActive(
                                  layananId: layanan.id,
                                  isActive: value,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Harga
                  Text(
                    layanan.formattedPrice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        (layanan.averageRating ?? 0) > 0
                            ? '${layanan.averageRating!.toStringAsFixed(1)} (${layanan.ratingCount ?? 0} ulasan)'
                            : 'Belum ada ulasan',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    layanan.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Status Promosi
                  const Text(
                    'Status Promosi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          layanan.isPromoted
                              ? 'Layanan ini sedang dipromosikan'
                              : 'Layanan ini tidak dipromosikan',
                          style: TextStyle(
                            color: layanan.isPromoted ? Colors.amber[700] : Colors.grey[600],
                            fontWeight: layanan.isPromoted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Switch(
                        value: layanan.isPromoted,
                        activeColor: Colors.amber[700],
                        onChanged: layanan.isActive
                            ? (value) {
                                // Dapatkan AuthBloc dari parent widget
                                final authBloc = BlocProvider.of<AuthBloc>(context, listen: false);
                                final authState = authBloc.state;
                                if (authState is AuthAuthenticated) {
                                  context.read<ServicesBloc>().add(
                                        ToggleLayananPromosi(
                                          layananId: layanan.id,
                                          providerId: authState.user.id,
                                          serviceTitle: layanan.title,
                                          isPromoted: value,
                                        ),
                                      );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Anda harus login untuk mengaktifkan promosi'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                  if (layanan.isPromoted && layanan.promotionStartDate != null && layanan.promotionEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mulai: ${_formatDate(layanan.promotionStartDate!)}'),
                            const SizedBox(height: 4),
                            Text('Berakhir: ${_formatDate(layanan.promotionEndDate!)}'),
                            const SizedBox(height: 4),
                            const Text('Biaya: Rp 1.000/hari'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Informasi tambahan
                  const Text(
                    'Informasi Tambahan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem('Kategori', layanan.categoryName ?? 'Tidak ada kategori'),
                  _buildInfoItem('Dibuat pada', layanan.createdAt != null ? _formatDate(layanan.createdAt!) : 'Tidak tersedia'),
                  _buildInfoItem('Diperbarui pada', layanan.updatedAt != null ? _formatDate(layanan.updatedAt!) : 'Tidak tersedia'),
                  _buildInfoItem('ID Layanan', layanan.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(Service layanan) {
    if (layanan.imagesUrls?.isEmpty ?? true) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(child: Text('Tidak ada gambar')),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: layanan.imagesUrls?.length ?? 0,
        itemBuilder: (context, index) {
          return Image.network(
            layanan.imagesUrls?[index] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.error)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}