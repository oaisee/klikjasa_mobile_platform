import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_provider_services_usecase.dart';
import 'package:klik_jasa/injection_container.dart' as di;

/// A tab that displays the services offered by a provider.
/// 
/// This tab shows a list of services that the provider has created,
/// allowing them to manage their service offerings.
class MyServicesTab extends StatefulWidget {
  const MyServicesTab({super.key});

  @override
  State<MyServicesTab> createState() => _MyServicesTabState();
}

class _MyServicesTabState extends State<MyServicesTab> {
  late GetProviderServicesUseCase _getProviderServicesUseCase;
  String? _providerId;
  bool _isLoading = false;
  List<Service> _layanan = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getProviderServicesUseCase = di.sl<GetProviderServicesUseCase>();
    _fetchProviderIdAndServices();
  }

  Future<void> _fetchProviderIdAndServices() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _providerId = authState.user.id;
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _getProviderServicesUseCase(GetProviderServicesParams(providerId: _providerId!));
        
        result.fold(
          (failure) {
            setState(() {
              _errorMessage = failure.message;
              _isLoading = false;
            });
          },
          (layananList) {
            // Mengurutkan layanan: layanan yang dipromosikan muncul terlebih dahulu
            final sortedLayanan = layananList;
            sortedLayanan.sort((a, b) {
              // Jika keduanya dipromosikan atau keduanya tidak dipromosikan, urutkan berdasarkan tanggal pembuatan (terbaru)
              if (a.isPromoted == b.isPromoted) {
                // Handle null createdAt dengan aman
                if (a.createdAt == null && b.createdAt == null) {
                  return 0;
                } else if (a.createdAt == null) {
                  return 1; // a null, b tidak null, b lebih dulu
                } else if (b.createdAt == null) {
                  return -1; // a tidak null, b null, a lebih dulu
                }
                // Keduanya tidak null
                return b.createdAt!.compareTo(a.createdAt!); // Terbaru dulu
              }
              // Jika salah satu dipromosikan, yang dipromosikan muncul lebih dulu
              return a.isPromoted ? -1 : 1;
            });
            
            setState(() {
              _layanan = sortedLayanan;
              _isLoading = false;
            });
          },
        );
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Pengguna tidak terautentikasi';
        _isLoading = false;
      });
    }
  }

  void _navigateToServiceManagement() {
    // Menggunakan GoRouter untuk navigasi ke halaman manajemen layanan
    context.pushNamed('providerServices');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Terjadi kesalahan: $_errorMessage',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba lagi untuk memuat data.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProviderIdAndServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_layanan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Anda belum menambahkan layanan apa pun.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan layanan pertama Anda untuk memulai!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToServiceManagement,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Layanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchProviderIdAndServices,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _layanan.length,
            itemBuilder: (context, index) {
              final layanan = _layanan[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to service detail/edit screen
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                // Gambar layanan atau placeholder
                                layanan.imagesUrls != null && layanan.imagesUrls!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        layanan.imagesUrls!.first,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                if (layanan.isPromoted == true)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PROMO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    layanan.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(layanan.price).replaceAll(',', '.'),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.accent),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        layanan.averageRating?.toStringAsFixed(1) ?? 'N/A',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${layanan.ratingCount ?? 0} ulasan)',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          layanan.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                layanan.isActive ? 'Aktif' : 'Tidak Aktif',
                            style: TextStyle(
                              color: layanan.isActive ? Colors.green[700] : Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: layanan.isActive ? Colors.green[100] : Colors.red[100],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigasi ke halaman edit layanan dengan data layanan yang dipilih
                                context.pushNamed(
                                  'providerAddEditService',
                                  extra: {
                                    'providerId': _providerId,
                                    'layanan': layanan,
                                  },
                                );
                              },
                              child: const Text('Ubah'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _navigateToServiceManagement,
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}