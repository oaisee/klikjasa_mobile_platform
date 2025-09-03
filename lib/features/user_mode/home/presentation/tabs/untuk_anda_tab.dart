import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/widgets/provider_status_banner_widget.dart';
// Import untuk banner promosi sudah ada di promotional_banner_state.dart
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/promotional_banner_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/promotional_banner_state.dart';
// import 'package:klik_jasa/features/user_mode/home/presentation/cubit/recommended_services_cubit.dart'; // Dihapus
// import 'package:klik_jasa/features/user_mode/home/presentation/cubit/recommended_services_state.dart'; // Dihapus
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_state.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/pages/services_by_category_screen.dart';
import 'package:klik_jasa/features/common/widgets/service_card_adapter.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_state.dart';
import 'package:klik_jasa/injection_container.dart' as di;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Import StaggeredGridView

/// Kelas untuk mengatur perilaku overscroll tanpa efek glow
class OverscrollWithoutGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class UntukAndaTab extends StatefulWidget {
  const UntukAndaTab({super.key});

  @override
  State<UntukAndaTab> createState() => _UntukAndaTabState();
}

class _UntukAndaTabState extends State<UntukAndaTab> {
  // State untuk mengontrol apakah kategori layanan diperluas atau tidak
  bool _isExpandedCategories = false;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CategoryCubit>(
          create: (context) => di.sl<CategoryCubit>()..getActiveCategories(),
        ),
        // BlocProvider<RecommendedServicesCubit>( // Dihapus
        //   create: (context) =>
        //       di.sl<RecommendedServicesCubit>()..fetchRecommendedServicesByLocation(),
        // ),
        BlocProvider<ServiceLocationCubit>(
          create: (context) {
            // Ambil profil user untuk mendapatkan lokasi domisili
            final supabase = Supabase.instance.client;
            final userId = supabase.auth.currentUser?.id;

            // Inisialisasi cubit
            final cubit = di.sl<ServiceLocationCubit>();

            if (userId != null) {
              // Ambil data profil user untuk mendapatkan lokasi
              supabase
                  .from('profiles')
                  .select('provinsi, kabupaten_kota')
                  .eq('id', userId)
                  .maybeSingle()
                  .then((profileData) {
                    if (profileData != null) {
                      final String? provinsi =
                          profileData['provinsi'] as String?;
                      final String? kabupatenKota =
                          profileData['kabupaten_kota'] as String?;

                      if (provinsi != null && kabupatenKota != null) {
                        // Gunakan metode baru untuk filter dengan fallback
                        cubit.fetchServicesWithLocationFallback(
                          userProvinsi: provinsi,
                          userKabupatenKota: kabupatenKota,
                        );
                      } else if (provinsi != null) {
                        // Jika hanya provinsi yang tersedia
                        cubit.fetchServicesByLocation(userProvinsi: provinsi);
                      } else {
                        // Jika tidak ada data lokasi, gunakan default
                        cubit.fetchServicesByLocation();
                      }
                    } else {
                      // Jika tidak ada profil, gunakan default
                      cubit.fetchServicesByLocation();
                    }
                  })
                  .catchError((_) {
                    // Jika error, gunakan default
                    cubit.fetchServicesByLocation();
                  });
            } else {
              // Jika tidak ada user ID, gunakan default
              cubit.fetchServicesByLocation();
            }

            return cubit;
          },
        ),
        BlocProvider<PromotionalBannerCubit>(
          create: (context) =>
              di.sl<PromotionalBannerCubit>()..startRealtimeBannerUpdates(),
        ),
      ],
      child: ScrollConfiguration(
        behavior: OverscrollWithoutGlowBehavior(),
        child: RefreshIndicator(
          // Menggunakan RefreshIndicator tanpa animasi lazy circular
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          strokeWidth: 0.0,
          onRefresh: () async {
            // Refresh data
            context.read<CategoryCubit>().getActiveCategories();
            // context.read<RecommendedServicesCubit>().fetchRecommendedServicesByLocation(); // Dihapus
            context.read<ServiceLocationCubit>().fetchServicesByLocation();
            context.read<PromotionalBannerCubit>().startRealtimeBannerUpdates();
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            key: const PageStorageKey<String>('untuk_anda'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // Banner Layanan Auto Swift
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: _buildPromotionalBanner(),
                ),
              ),
              // Kategori Layanan
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                  child: Text(
                    'Kategori Layanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              // Grid Kategori
              SliverToBoxAdapter(
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoading) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (state is CategoryLoaded) {
                      if (state.categories.isEmpty) {
                        return const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text('Tidak ada kategori tersedia'),
                          ),
                        );
                      }

                      // Bagi kategori menjadi baris-baris
                      final int itemsPerRow = 5; // Jumlah item per baris
                      final int totalRows =
                          (state.categories.length / itemsPerRow).ceil();
                      final int totalHeight =
                          100 * totalRows; // Tinggi per baris * jumlah baris

                      // Hitung jumlah item yang akan ditampilkan berdasarkan state expanded
                      final int displayedItems = _isExpandedCategories
                          ? state.categories.length
                          : (state.categories.length > 10
                                ? 10
                                : state.categories.length);

                      // Hitung tinggi container berdasarkan state expanded
                      final double containerHeight = _isExpandedCategories
                          ? (displayedItems / itemsPerRow).ceil() *
                                100.0 // Tinggi sesuai jumlah baris yang dibutuhkan
                          : (totalHeight <= 200
                                ? totalHeight.toDouble()
                                : 200.0); // Maksimal 2 baris jika tidak expanded

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            height: containerHeight,
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5, // 5 item per baris
                                    childAspectRatio:
                                        0.8, // Rasio lebar:tinggi item
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              physics:
                                  const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal
                              itemCount: displayedItems,
                              itemBuilder: (context, index) {
                                final category = state.categories[index];
                                return _buildCategoryItem(context, category);
                              },
                            ),
                          ),

                          // Tombol untuk memperluas/menciutkan daftar kategori
                          if (state.categories.length >
                              10) // Tampilkan tombol hanya jika kategori > 10
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isExpandedCategories =
                                      !_isExpandedCategories;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isExpandedCategories
                                          ? 'Ciutkan'
                                          : 'Lihat Semua Kategori',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isExpandedCategories
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    } else if (state is CategoryError) {
                      return SizedBox(
                        height: 120,
                        child: Center(child: Text('Error: ${state.message}')),
                      );
                    }
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              // Layanan Rekomendasi (Dihapus)
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              //     child: Text(
              //       'Rekomendasi Untuk Anda',
              //       style: Theme.of(context).textTheme.titleMedium?.copyWith(
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
              // ),
              // Grid Layanan Rekomendasi (Dihapus)
              // SliverPadding( // Menggunakan SliverPadding untuk padding horizontal
              //   padding: const EdgeInsets.symmetric(horizontal: 12.0),
              //   sliver: BlocBuilder<
              //     RecommendedServicesCubit,
              //     RecommendedServicesState
              //   >(
              //     builder: (context, state) {
              //       if (state is RecommendedServicesLoading) {
              //         return const SliverToBoxAdapter(
              //           child: SizedBox(
              //             height: 200,
              //             child: Center(
              //               child: CircularProgressIndicator(),
              //             ),
              //           ),
              //         );
              //       } else if (state is RecommendedServicesLoaded) {
              //         // Tampilkan pesan khusus jika tidak ada layanan di kabupaten/kota dan menggunakan fallback provinsi
              //         if (state.showEmptyLocationMessage) {
              //           return SliverToBoxAdapter(
              //             child: Container(
              //               margin: const EdgeInsets.symmetric(
              //                 vertical: 8.0,
              //               ),
              //               padding: const EdgeInsets.all(16.0),
              //               decoration: BoxDecoration(
              //                 color: Colors.amber.shade50,
              //                 borderRadius: BorderRadius.circular(12),
              //                 border: Border.all(color: Colors.amber.shade200),
              //               ),
              //               child: Column(
              //                 children: [
              //                   Row(
              //                     children: [
              //                       Icon(
              //                         Icons.info_outline,
              //                         color: Colors.amber.shade800,
              //                       ),
              //                       const SizedBox(width: 8),
              //                       Expanded(
              //                         child: Text(
              //                           'Belum ada layanan rekomendasi di kabupaten Anda',
              //                           style: TextStyle(
              //                             fontWeight: FontWeight.bold,
              //                             color: Colors.amber.shade900,
              //                           ),
              //                         ),
              //                       ),
              //                     ],
              //                   ),
              //                   const SizedBox(height: 8),
              //                   Text(
              //                     'Kami menampilkan rekomendasi layanan dari provinsi yang sama. Yuk, ajak teman di daerah Anda untuk menjadi Penyedia Jasa!',
              //                     style: TextStyle(color: Colors.amber.shade900),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           );
              //         } else if (state.services.isEmpty) {
              //           return const SliverToBoxAdapter(
              //             child: SizedBox(
              //               height: 200,
              //               child: Center(
              //                 child: Text(
              //                   'Tidak ada layanan rekomendasi tersedia di lokasi Anda',
              //                 ),
              //               ),
              //             ),
              //           );
              //         }

              //         // Menggunakan StaggeredGrid.count untuk layout grid staggered
              //         return SliverMasonryGrid.count(
              //           crossAxisCount: 2, // 2 kolom
              //           mainAxisSpacing: 4.0, // Jarak vertikal antar item
              //           crossAxisSpacing: 4.0, // Jarak horizontal antar item
              //           itemBuilder: (context, index) {
              //             final service = state.services[index];
              //             return ServiceCardAdapter.fromMap(
              //               serviceMap: service,
              //               onTap: () {
              //                 // Konversi Map ke ServiceWithLocation terlebih dahulu
              //                 try {
              //                   final serviceWithLocation = ServiceWithLocation.fromMap(service);
              //                   context.push(
              //                     '/home/service-detail',
              //                     extra: serviceWithLocation,
              //                   );
              //                 } catch (e) {
              //                   // Tampilkan pesan error jika konversi gagal
              //                   ScaffoldMessenger.of(context).showSnackBar(
              //                     const SnackBar(
              //                       content: Text('Gagal membuka detail layanan. Data tidak valid.'),
              //                       backgroundColor: Colors.red,
              //                     ),
              //                   );
              //                 }
              //               },
              //             );
              //           },
              //           childCount: state.services.length,
              //         );
              //       } else if (state is RecommendedServicesError) {
              //         return SliverToBoxAdapter(
              //           child: Center(
              //             child: Text('Error: ${state.message}'),
              //           ),
              //         );
              //       }
              //       return const SliverToBoxAdapter(
              //         child: Center(
              //           child: CircularProgressIndicator(),
              //         ),
              //       );
              //     },
              //   ),
              // ),
              // Layanan di Sekitar Anda
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: BlocBuilder<ServiceLocationCubit, ServiceLocationState>(
                    builder: (context, state) {
                      if (state is ServiceLocationLoaded) {
                        String locationText = 'Layanan di Sekitar Anda';

                        if (state.userKabupatenKota != null &&
                            state.userKabupatenKota!.isNotEmpty) {
                          locationText =
                              'Layanan di ${state.userKabupatenKota}';
                        } else if (state.userProvinsi != null &&
                            state.userProvinsi!.isNotEmpty) {
                          locationText = 'Layanan di ${state.userProvinsi}';
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              locationText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (state.services.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  // Navigasi ke halaman semua layanan di lokasi
                                  context.push(
                                    '/home/services-by-location',
                                    extra: {
                                      'services': state.services,
                                      'location':
                                          state.userKabupatenKota ??
                                          state.userProvinsi ??
                                          'Sekitar Anda',
                                    },
                                  );
                                },
                                child: const Text('Lihat Semua'),
                              ),
                          ],
                        );
                      }
                      return Text(
                        'Layanan di Sekitar Anda',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
              // Grid Layanan di Sekitar
              SliverPadding(
                // Menggunakan SliverPadding untuk padding horizontal
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                sliver: BlocBuilder<ServiceLocationCubit, ServiceLocationState>(
                  builder: (context, state) {
                    if (state is ServiceLocationLoading) {
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
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
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
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: ProviderStatusBannerWidget(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (state.services.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Belum ada layanan tersedia di lokasi Anda',
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Navigasi ke halaman pendaftaran penyedia jasa
                                      context.push(
                                        '/register-as-provider',
                                      ); // Asumsi rute ini ada
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Daftar Sebagai Penyedia Jasa',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Urutkan berdasarkan prioritas: layanan promosi di atas, lalu berdasarkan rating
                      final sortedServices = List.from(state.services)
                        ..sort((a, b) {
                          // Prioritaskan layanan promosi
                          if (a.isPromoted && !b.isPromoted) return -1;
                          if (!a.isPromoted && b.isPromoted) return 1;

                          // Jika status promosi sama, urutkan berdasarkan rating tertinggi
                          final aRating = a.averageRating ?? 0.0;
                          final bRating = b.averageRating ?? 0.0;
                          return bRating.compareTo(aRating);
                        });

                      // Menggunakan StaggeredGrid.count untuk layout grid staggered
                      return SliverMasonryGrid.count(
                        crossAxisCount: 2, // 2 kolom
                        mainAxisSpacing: 4.0, // Jarak vertikal antar item
                        crossAxisSpacing: 4.0, // Jarak horizontal antar item
                        itemBuilder: (context, index) {
                          final service = sortedServices[index];
                          return ServiceCardAdapter.fromServiceWithLocation(
                            service: service,
                            onTap: () {
                              context.push(
                                '/home/service-detail',
                                extra: service,
                              );
                            },
                          );
                        },
                        childCount: sortedServices.length,
                      );
                    } else if (state is ServiceLocationError) {
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
                                        .fetchServicesByLocation();
                                  },
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk menampilkan banner layanan dengan auto swift dan data dari Supabase secara realtime
  Widget _buildPromotionalBanner() {
    return BlocBuilder<PromotionalBannerCubit, PromotionalBannerState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo & Penawaran Spesial',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (state is PromotionalBannerLoading)
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is PromotionalBannerLoaded &&
                state.banners.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 220, // Tinggi ditambah 20 pixel dari 200
                  aspectRatio: 16 / 9,
                  viewportFraction:
                      1.0, // Diperbesar dari 0.95 untuk membuat banner lebih lebar
                  initialPage: 0,
                  enableInfiniteScroll: true,
                  reverse: false,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.2,
                  scrollDirection: Axis.horizontal,
                ),
                items: state.banners.map((banner) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () {
                          // Navigasi ke URL target jika ada
                          if (banner.targetUrl != null &&
                              banner.targetUrl!.isNotEmpty) {
                            // Implementasi navigasi ke URL target
                            if (banner.targetUrl!.startsWith('http')) {
                              // URL eksternal
                              // Bisa ditambahkan fungsi untuk membuka browser
                              AppMessageUtils.showSnackbar(
                                context: context,
                                message: 'Membuka URL: ${banner.targetUrl}',
                                type: MessageType.info,
                              );
                            } else {
                              // URL internal aplikasi
                              context.push(banner.targetUrl!);
                            }
                          } else {
                            // Tidak ada URL target
                            AppMessageUtils.showSnackbar(
                              context: context,
                              message: 'Promo dipilih',
                              type: MessageType.info,
                            );
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  banner.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              )
            else if (state is PromotionalBannerError)
              SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              // Fallback jika tidak ada banner atau terjadi kesalahan lain
              SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Tidak ada promo tersedia saat ini',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Metode untuk mendapatkan icon estetik berdasarkan nama kategori
  Widget _getModernCategoryIcon(String categoryName) {
    // Pilih icon berdasarkan nama kategori (case insensitive)
    IconData iconData;
    Color iconColor = Colors.white; // Default icon color
    Color primaryColor;
    Color secondaryColor;

    final lowercaseName = categoryName.toLowerCase();
    
    // Pemetaan kategori ke ikon yang lebih spesifik dan unik
    // Menggunakan exact match untuk kategori yang umum
    if (categoryName == 'Tukang Bangunan') {
      iconData = Icons.construction_rounded;
      primaryColor = const Color(0xFFFF9800);
      secondaryColor = const Color(0xFFFFB74D);
    } else if (categoryName == 'Transportasi') {
      iconData = Icons.directions_bus_rounded;
      primaryColor = const Color(0xFF2196F3);
      secondaryColor = const Color(0xFF64B5F6);
    } else if (categoryName == 'Teknologi & Digital') {
      iconData = Icons.computer_rounded;
      primaryColor = const Color(0xFF5C6BC0);
      secondaryColor = const Color(0xFF9FA8DA);
    } else if (categoryName == 'Taman & Pertamanan') {
      iconData = Icons.yard_rounded;
      primaryColor = const Color(0xFF4CAF50);
      secondaryColor = const Color(0xFF81C784);
    } else if (categoryName == 'Pindahan & Angkut') {
      iconData = Icons.local_shipping_rounded;
      primaryColor = const Color(0xFF795548);
      secondaryColor = const Color(0xFFA1887F);
    } else if (categoryName == 'Perbaikan & Instalasi') {
      iconData = Icons.build_rounded;
      primaryColor = const Color(0xFF607D8B);
      secondaryColor = const Color(0xFF90A4AE);
    } else if (categoryName == 'Pendidikan & Pelatihan') {
      iconData = Icons.school_rounded;
      primaryColor = const Color(0xFF66BB6A);
      secondaryColor = const Color(0xFFA5D6A7);
    } else if (categoryName == 'Otomotif (motor)') {
      iconData = Icons.two_wheeler_rounded;
      primaryColor = const Color(0xFFEF5350);
      secondaryColor = const Color(0xFFEF9A9A);
    } else if (categoryName == 'Otomotif (Mobil)') {
      iconData = Icons.directions_car_rounded;
      primaryColor = const Color(0xFF26A69A);
      secondaryColor = const Color(0xFF80CBC4);
    } else if (categoryName == 'Kecantikan & Kesehatan') {
      iconData = Icons.spa_rounded;
      primaryColor = const Color(0xFFEC407A);
      secondaryColor = const Color(0xFFF48FB1);
    } else if (categoryName == 'Kebersihan') {
      iconData = Icons.cleaning_services_rounded;
      primaryColor = const Color(0xFF4ECDC4);
      secondaryColor = const Color(0xFF7EEAE3);
    } else if (categoryName == 'Home Interior') {
      iconData = Icons.chair_rounded;
      primaryColor = const Color(0xFF8D6E63);
      secondaryColor = const Color(0xFFBCAAA4);
    } else if (categoryName == 'Home Exterior') {
      iconData = Icons.cottage_rounded;
      primaryColor = const Color(0xFF5E9FFF);
      secondaryColor = const Color(0xFF83B9FF);
    } else if (categoryName == 'Hewan Peliharaan') {
      iconData = Icons.pets_rounded;
      primaryColor = const Color(0xFFFF7043);
      secondaryColor = const Color(0xFFFFAB91);
    } else if (categoryName == 'Event & Acara') {
      iconData = Icons.celebration_rounded;
      primaryColor = const Color(0xFFEC407A);
      secondaryColor = const Color(0xFFF48FB1);
    } else if (categoryName == 'Desain & Kreatif') {
      iconData = Icons.design_services_rounded;
      primaryColor = const Color(0xFFFF7043);
      secondaryColor = const Color(0xFFFFAB91);
    } else if (categoryName == 'Administrasi & Keuangan') {
      iconData = Icons.account_balance_rounded;
      primaryColor = const Color(0xFF7986CB);
      secondaryColor = const Color(0xFF9FA8DA);
    } else if (categoryName == 'Kuliner') {
      iconData = Icons.restaurant_rounded;
      primaryColor = const Color(0xFFFF7043);
      secondaryColor = const Color(0xFFFFAB91);
    } else if (categoryName == 'Laundry') {
      iconData = Icons.local_laundry_service_rounded;
      primaryColor = const Color(0xFF4FC3F7);
      secondaryColor = const Color(0xFF81D4FA);
    } 
    // Fallback ke pencarian substring jika tidak ada exact match
    else if (lowercaseName.contains('rumah') || lowercaseName.contains('properti')) {
      iconData = Icons.villa_rounded; // Icon lebih estetik untuk properti
      primaryColor = const Color(0xFF5E9FFF);
      secondaryColor = const Color(0xFF83B9FF);
    } else if (lowercaseName.contains('kebersihan') ||
        lowercaseName.contains('bersih')) {
      iconData = Icons.cleaning_services_rounded;
      primaryColor = const Color(0xFF4ECDC4);
      secondaryColor = const Color(0xFF7EEAE3);
    } else if (lowercaseName.contains('elektronik')) {
      iconData = Icons.electrical_services_rounded;
      primaryColor = const Color(0xFFFFA726);
      secondaryColor = const Color(0xFFFFCC80);
    } else if (lowercaseName.contains('komputer') ||
        lowercaseName.contains('laptop')) {
      iconData = Icons.laptop_mac_rounded;
      primaryColor = const Color(0xFF7986CB);
      secondaryColor = const Color(0xFF9FA8DA);
    } else if (lowercaseName.contains('mobil') ||
        lowercaseName.contains('kendaraan')) {
      iconData = Icons.directions_car_filled_rounded;
      primaryColor = const Color(0xFF26A69A);
      secondaryColor = const Color(0xFF80CBC4);
    } else if (lowercaseName.contains('motor')) {
      iconData = Icons.two_wheeler_rounded;
      primaryColor = const Color(0xFFEF5350);
      secondaryColor = const Color(0xFFEF9A9A);
    } else if (lowercaseName.contains('kesehatan') ||
        lowercaseName.contains('sehat')) {
      iconData = Icons.medical_services_rounded;
      primaryColor = const Color(0xFFEC407A);
      secondaryColor = const Color(0xFFF48FB1);
    } else if (lowercaseName.contains('kecantikan') ||
        lowercaseName.contains('salon')) {
      iconData = Icons.spa_rounded;
      primaryColor = const Color(0xFFAB47BC);
      secondaryColor = const Color(0xFFCE93D8);
    } else if (lowercaseName.contains('olahraga')) {
      iconData = Icons.sports_basketball_rounded;
      primaryColor = const Color(0xFF42A5F5);
      secondaryColor = const Color(0xFF90CAF9);
    } else if (lowercaseName.contains('pendidikan') ||
        lowercaseName.contains('kursus')) {
      iconData = Icons.auto_stories_rounded;
      primaryColor = const Color(0xFF66BB6A);
      secondaryColor = const Color(0xFFA5D6A7);
    } else if (lowercaseName.contains('desain') ||
        lowercaseName.contains('grafis')) {
      iconData = Icons.palette_rounded;
      primaryColor = const Color(0xFFFF7043);
      secondaryColor = const Color(0xFFFFAB91);
    } else if (lowercaseName.contains('teknologi') ||
        lowercaseName.contains('it')) {
      iconData = Icons.code_rounded;
      primaryColor = const Color(0xFF5C6BC0);
      secondaryColor = const Color(0xFF9FA8DA);
    } else if (lowercaseName.contains('makanan') ||
        lowercaseName.contains('catering')) {
      iconData = Icons.restaurant_rounded;
      primaryColor = const Color(0xFFFF7043);
      secondaryColor = const Color(0xFFFFAB91);
    } else if (lowercaseName.contains('event') ||
        lowercaseName.contains('acara')) {
      iconData = Icons.celebration_rounded;
      primaryColor = const Color(0xFFEC407A);
      secondaryColor = const Color(0xFFF48FB1);
    } else if (lowercaseName.contains('fotografi') || lowercaseName.contains('foto')) {
      iconData = Icons.camera_alt_rounded;
      primaryColor = const Color(0xFF5C6BC0);
      secondaryColor = const Color(0xFF9FA8DA);
    } else if (lowercaseName.contains('video')) {
      iconData = Icons.videocam_rounded;
      primaryColor = const Color(0xFFE57373);
      secondaryColor = const Color(0xFFEF9A9A);
    } else if (lowercaseName.contains('hukum') || lowercaseName.contains('legal')) {
      iconData = Icons.gavel_rounded;
      primaryColor = const Color(0xFF7986CB);
      secondaryColor = const Color(0xFF9FA8DA);
    } else if (lowercaseName.contains('hiburan') || lowercaseName.contains('entertainment')) {
      iconData = Icons.music_note_rounded;
      primaryColor = const Color(0xFFBA68C8);
      secondaryColor = const Color(0xFFE1BEE7);
    } else if (lowercaseName.contains('hewan') || lowercaseName.contains('pet')) {
      iconData = Icons.pets_rounded;
      primaryColor = const Color(0xFFFF7043);
      secondaryColor = const Color(0xFFFFAB91);
    } else {
      // Default icon jika tidak ada yang cocok
      iconData = Icons.stars_rounded;
      primaryColor = const Color(0xFF5C6BC0);
      secondaryColor = const Color(0xFF9FA8DA);
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(76), // 0.3 * 255 = 76
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(iconData, size: 20, color: iconColor),
    );
  }

  Widget _buildCategoryItem(BuildContext context, ServiceCategory category) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman layanan berdasarkan kategori
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesByCategoryScreen(category: category),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gunakan modern icon
          _getModernCategoryIcon(category.name),
          const SizedBox(height: 7), // Jarak diperkecil
          // Container untuk nama kategori dengan tinggi tetap
          SizedBox(
            width: 60, // Lebar untuk teks
            height: 32, // Tinggi tetap untuk mengakomodasi dua baris teks
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black), // Ukuran font diperkecil dan warna hitam
            ),
          ),
        ],
      ),
    );
  }
}
