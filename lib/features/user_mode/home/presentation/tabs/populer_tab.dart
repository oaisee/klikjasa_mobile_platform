import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/widgets/provider_status_banner_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/injection_container.dart' as di;
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_state.dart';
import 'package:klik_jasa/features/common/widgets/service_card_adapter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'
    as staggered; // Import staggered_grid_view
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart'; // Pastikan ini diimpor jika belum

/// Widget tab 'Populer' yang menampilkan layanan populer berdasarkan lokasi pengguna.
class PopulerTab extends StatelessWidget {
  const PopulerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServiceLocationCubit>(
      create: (context) {
        // Mengambil profil pengguna untuk mendapatkan lokasi domisili.
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;

        // Inisialisasi cubit ServiceLocationCubit.
        final cubit = di.sl<ServiceLocationCubit>();

        if (userId != null) {
          // Mengambil data profil pengguna untuk mendapatkan informasi lokasi.
          supabase
              .from('profiles')
              .select('provinsi, kabupaten_kota')
              .eq('id', userId)
              .maybeSingle()
              .then((profileData) {
                if (profileData != null) {
                  final String? provinsi = profileData['provinsi'] as String?;
                  final String? kabupatenKota =
                      profileData['kabupaten_kota'] as String?;

                  if (provinsi != null && kabupatenKota != null) {
                    // Menggunakan metode baru untuk memfilter layanan dengan fallback ke provinsi.
                    cubit.fetchServicesWithLocationFallback(
                      userProvinsi: provinsi,
                      userKabupatenKota: kabupatenKota,
                    );
                  } else if (provinsi != null) {
                    // Jika hanya provinsi yang tersedia, ambil layanan berdasarkan provinsi.
                    cubit.fetchServicesByLocation(userProvinsi: provinsi);
                  } else {
                    // Jika tidak ada data lokasi, gunakan prioritas promosi.
                    cubit.fetchServicesWithPromotionPriority();
                  }
                } else {
                  // Jika tidak ada profil pengguna, gunakan prioritas promosi.
                  cubit.fetchServicesWithPromotionPriority();
                }
              })
              .catchError((_) {
                // Jika terjadi kesalahan saat mengambil profil, gunakan prioritas promosi.
                cubit.fetchServicesWithPromotionPriority();
              });
        } else {
          // Jika tidak ada ID pengguna, gunakan prioritas promosi.
          cubit.fetchServicesWithPromotionPriority();
        }

        return cubit;
      },
      child: CustomScrollView(
        key: const PageStorageKey<String>('populer'),
        slivers: <Widget>[
          // BlocBuilder untuk mengelola state layanan populer.
          BlocBuilder<ServiceLocationCubit, ServiceLocationState>(
            builder: (context, state) {
              if (state is ServiceLocationLoading) {
                // Menampilkan indikator loading saat data sedang dimuat.
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              } else if (state is ServiceLocationLoaded) {
                // Menampilkan pesan khusus jika tidak ada layanan di kabupaten/kota dan menggunakan fallback provinsi.
                if (state.showEmptyLocationMessage) {
                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Banner pesan bahwa layanan di daerah belum tersedia.
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Layanan penyedia jasa di daerah anda belum tersedia nih...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Yuk,Segera mendaftar sebagai Penyedia Jasa untuk menjadi yang Pertama, dan dapatkan Penghasilan tak terbatas bersama KlikJasa!',
                                style: TextStyle(color: Colors.amber.shade900),
                              ),
                              const SizedBox(height: 12),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: ProviderStatusBannerWidget(),
                              ),
                            ],
                          ),
                        ),
                        // Judul untuk layanan provinsi (fallback).
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            16.0,
                            16.0,
                            8.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Layanan Populer di ${state.userProvinsi ?? ""}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Menampilkan grid layanan provinsi (fallback).
                        _buildServiceGrid(
                          context,
                          state.services,
                          'Tidak ada layanan populer tersedia di provinsi Anda',
                        ),
                      ],
                    ),
                  );
                }

                // Menampilkan lokasi layanan jika tidak menggunakan fallback provinsi.
                if (!state.isProvinceLevel &&
                    state.userKabupatenKota != null &&
                    state.userKabupatenKota!.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indikator lokasi untuk kabupaten/kota.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            6.0,
                            16.0,
                            2.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Layanan Populer di ${state.userKabupatenKota}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Menampilkan grid layanan untuk kabupaten/kota.
                        _buildServiceGrid(
                          context,
                          state.services,
                          'Tidak ada layanan populer tersedia di lokasi Anda',
                        ),
                      ],
                    ),
                  );
                }

                // Tampilan default jika tidak ada indikator lokasi khusus.
                // MEMPERBAIKI: Membungkus _buildServiceGrid dengan SliverToBoxAdapter.
                return SliverToBoxAdapter(
                  child: _buildServiceGrid(
                    context,
                    state.services,
                    'Tidak ada layanan populer tersedia',
                  ),
                );
              } else if (state is ServiceLocationError) {
                // Menampilkan pesan error dan tombol coba lagi.
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ServiceLocationCubit>()
                                  .fetchServicesWithPromotionPriority();
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Menampilkan indikator loading default jika state tidak dikenali.
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Widget pembantu untuk membangun tampilan grid layanan.
  /// Mengurutkan layanan berdasarkan prioritas promosi dan rating, lalu menampilkannya dalam grid.
  Widget _buildServiceGrid(
    BuildContext context,
    List<ServiceWithLocation> services,
    String emptyMessage,
  ) {
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Center(
          child: Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    // Urutkan berdasarkan prioritas: layanan promosi di atas, lalu berdasarkan rating.
    final sortedServices = List<ServiceWithLocation>.from(services)
      ..sort((a, b) {
        // Prioritaskan layanan promosi.
        if (a.isPromoted && !b.isPromoted) return -1;
        if (!a.isPromoted && b.isPromoted) return 1;

        // Jika status promosi sama, urutkan berdasarkan rating tertinggi.
        final aRating = a.averageRating;
        final bRating = b.averageRating;
        return bRating.compareTo(aRating);
      });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: staggered.MasonryGridView.count(
        crossAxisCount: 2, // 2 kolom.
        mainAxisSpacing: 4.0, // Jarak vertikal antar item.
        crossAxisSpacing: 4.0, // Jarak horizontal antar item.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedServices.length,
        itemBuilder: (BuildContext context, int index) {
          final service = sortedServices[index];
          // Menghitung lebar item (2 kolom dengan spacing).
          // Menggunakan MediaQuery.of(context).size.width untuk mendapatkan lebar layar.
          final screenWidth = MediaQuery.of(context).size.width;
          // 24 = padding horizontal total (12 kiri + 12 kanan) dari Wrap.
          // 8 = spacing horizontal antar item.
          // Jadi, (screenWidth - 24 - 8) / 2 = (screenWidth - 32) / 2.
          // Namun, karena padding Wrap adalah 12.0 di setiap sisi, total padding horizontal adalah 24.0.
          // Spacing antar item adalah 8.0.
          // Jadi, total ruang horizontal yang diambil oleh padding dan spacing adalah 24 + 8 = 32.
          // Lebar yang tersisa dibagi 2 untuk dua kolom.
          final itemWidth = (screenWidth - 32) / 2;

          return SizedBox(
            width: itemWidth,
            child: ServiceCardAdapter.fromServiceWithLocation(
              service: service,
              onTap: () {
                context.push('/home/service-detail', extra: service);
              },
            ),
          );
        },
      ),
    );
  }
}
