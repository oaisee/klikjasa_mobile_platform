import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_promoted_services.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_services_by_highest_rating.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_services_by_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_services_with_promotion_priority.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_state.dart';

class ServiceLocationCubit extends Cubit<ServiceLocationState> {
  final GetServicesByLocation getServicesByLocation;
  final GetPromotedServices getPromotedServices;
  final GetServicesByHighestRating getServicesByHighestRating;
  final GetServicesWithPromotionPriority getServicesWithPromotionPriority;
  // Tambahkan repository untuk akses ke stream realtime
  final ServiceRepository serviceRepository;

  int _page = 0;
  static const int _limit = 10;
  
  // Menyimpan stream subscriptions
  final List<StreamSubscription> _streamSubscriptions = [];
  
  // Menambahkan cache untuk mengurangi pemanggilan API berulang
  static final Map<String, List<dynamic>> _serviceCache = {};
  static DateTime _lastCacheTime = DateTime.now();
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Fungsi untuk memeriksa apakah cache masih valid
  bool _isCacheValid() {
    return DateTime.now().difference(_lastCacheTime) < _cacheDuration;
  }
  
  // Fungsi untuk menyimpan data ke cache
  void _saveToCache(String key, List<dynamic> data) {
    _serviceCache[key] = data;
    _lastCacheTime = DateTime.now();
  }
  
  // Fungsi untuk mendapatkan data dari cache
  List<dynamic>? _getFromCache(String key) {
    if (_serviceCache.containsKey(key) && _isCacheValid()) {
      return _serviceCache[key];
    }
    return null;
  }
  
  // Fungsi untuk membersihkan cache
  void clearCache() {
    _serviceCache.clear();
    _lastCacheTime = DateTime.now();
  }

  ServiceLocationCubit({
    required this.getServicesByLocation,
    required this.getPromotedServices,
    required this.getServicesByHighestRating,
    required this.getServicesWithPromotionPriority,
    required this.serviceRepository,
  }) : super(ServiceLocationInitial()) {
    // Bersihkan subscriptions sebelumnya jika ada
    _cleanupSubscriptions();
  }
  
  // Metode untuk menangani subscription stream
  void _cleanupSubscriptions() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
  }
  
  @override
  Future<void> close() {
    _cleanupSubscriptions();
    serviceRepository.dispose();
    return super.close();
  }

  // Variabel untuk pagination
  // Mendapatkan layanan berdasarkan lokasi dengan metode realtime
  // Set initialLoad=true untuk pertama kali memanggil fungsi ini
  // dan gunakan initialLoad=false untuk hanya memulai subscription tanpa loading state
  Future<void> fetchServicesByLocation({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    bool refresh = false,
    bool initialLoad = true,
  }) async {
    if (refresh) {
      _page = 0;
      emit(ServiceLocationLoading());
    } else {
      // Jika sudah mencapai maksimum atau sedang loading, jangan fetch lagi
      if (state is ServiceLocationLoaded) {
        final currentState = state as ServiceLocationLoaded;
        if (currentState.hasReachedMax) return;
      } else if (state is ServiceLocationLoading) {
        return;
      }
    }

    final offset = refresh ? 0 : _page * _limit;

    final params = ServiceLocationParams(
      userProvinsi: userProvinsi,
      userKabupatenKota: userKabupatenKota,
      userKecamatan: userKecamatan,
      userDesaKelurahan: userDesaKelurahan,
      limit: _limit,
      offset: offset,
    );

    final result = await getServicesByLocation(params);

    if (isClosed) return;
    
    // Mulai subscription realtime untuk lokasi yang sama
    _startLocationStreamSubscription(
      userProvinsi: userProvinsi,
      userKabupatenKota: userKabupatenKota,
      userKecamatan: userKecamatan,
      userDesaKelurahan: userDesaKelurahan,
    );

    result.fold(
      (failure) => emit(ServiceLocationError(message: failure.message)),
      (services) {
        _page++;
        if (state is ServiceLocationLoaded && !refresh) {
          final currentState = state as ServiceLocationLoaded;
          emit(
            currentState.copyWith(
              services: [...currentState.services, ...services],
              hasReachedMax: services.length < _limit,
              userProvinsi: userProvinsi,
              userKabupatenKota: userKabupatenKota,
              userKecamatan: userKecamatan,
              userDesaKelurahan: userDesaKelurahan,
            ),
          );
        } else {
          emit(
            ServiceLocationLoaded(
              services: services,
              hasReachedMax: services.length < _limit,
              userProvinsi: userProvinsi,
              userKabupatenKota: userKabupatenKota,
              userKecamatan: userKecamatan,
              userDesaKelurahan: userDesaKelurahan,
            ),
          );
        }
      },
    );
  }

  // Mendapatkan layanan yang dipromosikan dengan dukungan realtime
  Future<void> fetchPromotedServices({bool refresh = false, bool initialLoad = true}) async {
    if (refresh) {
      emit(initialLoad ? ServiceLocationLoading() : state);
      _page = 0;
    } else {
      if (state is ServiceLocationLoaded) {
        final currentState = state as ServiceLocationLoaded;
        if (currentState.hasReachedMax) return;
      } else if (state is! ServiceLocationLoading && initialLoad) {
        emit(ServiceLocationLoading());
      }
    }

    final offset = refresh ? 0 : _page * _limit;
    final params = PaginationParams(limit: _limit, offset: offset);

    final result = await getPromotedServices(params);
    
    // Mulai subscription realtime untuk layanan promosi
    _startPromotedServicesStreamSubscription();

    result.fold(
      (failure) {
        emit(ServiceLocationError(message: failure.message));
      },(services) {
        _page++;
        if (state is PromotedServicesLoaded && !refresh) {
          final currentState = state as PromotedServicesLoaded;
          emit(
            currentState.copyWith(
              services: [...currentState.services, ...services],
              hasReachedMax: services.length < _limit,
            ),
          );
        } else {
          // Urutkan layanan berdasarkan promosi dan rating
          final sortedServices = _sortServicesByPromotionAndRating(services);
          emit(
            PromotedServicesLoaded(
              services: sortedServices,
              hasReachedMax: services.length < _limit,
            ),
          );
        }
      },
    );
  }

  // Mendapatkan layanan dengan rating tertinggi dengan dukungan realtime
  Future<void> fetchServicesByHighestRating({bool refresh = false, bool initialLoad = true}) async {
    if (refresh) {
      emit(initialLoad ? ServiceLocationLoading() : state);
      _page = 0;
    } else {
      if (state is ServiceLocationLoaded) {
        final currentState = state as ServiceLocationLoaded;
        if (currentState.hasReachedMax) return;
      } else if (state is! ServiceLocationLoading && initialLoad) {
        emit(ServiceLocationLoading());
      }
    }

    final offset = refresh ? 0 : _page * _limit;
    final params = PaginationParams(limit: _limit, offset: offset);

    final result = await getServicesByHighestRating(params);
    
    // Mulai subscription realtime untuk layanan rating tertinggi
    _startHighestRatingServicesStreamSubscription();

    result.fold(
      (failure) {
        emit(ServiceLocationError(message: failure.message));
      },(services) {
        _page++;
        if (state is HighestRatedServicesLoaded && !refresh) {
          final currentState = state as HighestRatedServicesLoaded;
          emit(
            currentState.copyWith(
              services: [...currentState.services, ...services],
              hasReachedMax: services.length < _limit,
            ),
          );
        } else {
          emit(
            HighestRatedServicesLoaded(
              services: services,
              hasReachedMax: services.length < _limit,
            ),
          );
        }
      },
    );
  }

  // Mendapatkan layanan dengan prioritas promosi (algoritma baru)
  Future<void> fetchServicesWithPromotionPriority({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    bool refresh = false,
  }) async {
    // Buat cache key berdasarkan parameter lokasi
    final String cacheKey = 'priority_services_${userProvinsi ?? ""}_${userKabupatenKota ?? ""}_${userKecamatan ?? ""}_${userDesaKelurahan ?? ""}';
    
    // Jika refresh diminta, hapus cache untuk key ini
    if (refresh) {
      _page = 0;
      emit(ServiceLocationLoading());
      _serviceCache.remove(cacheKey);
    } else {
      // Jika sudah mencapai maksimum atau sedang loading, jangan fetch lagi
      if (state is ServiceLocationLoaded) {
        final currentState = state as ServiceLocationLoaded;
        if (currentState.hasReachedMax) return;
      } else if (state is ServiceLocationLoading) {
        return;
      }
      
      // Cek cache terlebih dahulu
      final cachedData = _getFromCache(cacheKey);
      if (cachedData != null) {
        emit(
          ServiceLocationLoaded(
            services: cachedData.cast(),
            hasReachedMax: true, // Anggap sudah mencapai max karena menggunakan cache
            userProvinsi: userProvinsi,
            userKabupatenKota: userKabupatenKota,
            userKecamatan: userKecamatan,
            userDesaKelurahan: userDesaKelurahan,
          ),
        );
        return;
      }
    }

    final params = ServicePriorityParams(
      userProvinsi: userProvinsi,
      userKabupatenKota: userKabupatenKota,
      userKecamatan: userKecamatan,
      userDesaKelurahan: userDesaKelurahan,
      promotedLimit: 5,
      regularLimit: 10,
      locationLimit: 10,
      totalLimit: 20,
    );

    final result = await getServicesWithPromotionPriority(params);

    if (isClosed) return;

    result.fold(
      (failure) => emit(ServiceLocationError(message: failure.message)),
      (services) {
        _page++;
        // Simpan data ke cache
        _saveToCache(cacheKey, services);
        
        emit(
          ServiceLocationLoaded(
            services: services,
            hasReachedMax: services.length < params.totalLimit,
            userProvinsi: userProvinsi,
            userKabupatenKota: userKabupatenKota,
            userKecamatan: userKecamatan,
            userDesaKelurahan: userDesaKelurahan,
          ),
        );
      },
    );
  }
  
  // Mendapatkan layanan dengan filter lokasi Kabupaten/Kota dan fallback ke Provinsi
  Future<void> fetchServicesWithLocationFallback({
    required String userProvinsi,
    required String userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    bool refresh = false,
  }) async {
    if (refresh) {
      _page = 0;
      emit(ServiceLocationLoading());
      // Hapus cache untuk kedua level filter (kabupaten dan provinsi)
      _serviceCache.remove('location_kabupaten_${userKabupatenKota}_$userProvinsi');
      _serviceCache.remove('location_provinsi_$userProvinsi');
    } else if (state is ServiceLocationLoading) {
      return;
    }
    
    // Cek cache untuk kabupaten/kota terlebih dahulu
    final String kabupatenCacheKey = 'location_kabupaten_${userKabupatenKota}_$userProvinsi';
    final cachedKabupatenData = _getFromCache(kabupatenCacheKey);
    
    if (cachedKabupatenData != null) {
      final bool isEmpty = cachedKabupatenData.isEmpty;
      if (!isEmpty) {
        // Jika ada data di cache untuk kabupaten/kota, gunakan itu
        emit(
          ServiceLocationLoaded(
            services: cachedKabupatenData.cast(),
            hasReachedMax: true,
            userProvinsi: userProvinsi,
            userKabupatenKota: userKabupatenKota,
            isProvinceLevel: false,
            showEmptyLocationMessage: false,
          ),
        );
      } else {
        // Jika cache kabupaten kosong, cek cache provinsi
        final String provinsiCacheKey = 'location_provinsi_$userProvinsi';
        final cachedProvinsiData = _getFromCache(provinsiCacheKey);
        
        if (cachedProvinsiData != null) {
          emit(
            ServiceLocationLoaded(
              services: cachedProvinsiData.cast(),
              hasReachedMax: true,
              userProvinsi: userProvinsi,
              userKabupatenKota: userKabupatenKota,
              isProvinceLevel: true,
              showEmptyLocationMessage: true,
            ),
          );
        } else {
          // Jika tidak ada cache provinsi, lakukan query
          await _fetchProvinsiServicesAsFallback(userProvinsi, userKabupatenKota);
        }
      }
      return;
    }
    
    // Jika tidak ada cache, lakukan query untuk kabupaten/kota
    final kabupatenParams = ServiceLocationParams(
      userProvinsi: userProvinsi,
      userKabupatenKota: userKabupatenKota,
      userKecamatan: userKecamatan,
      userDesaKelurahan: userDesaKelurahan,
      limit: 20, // Ambil lebih banyak untuk kabupaten/kota
      offset: 0,
    );
    
    final kabupatenResult = await getServicesByLocation(kabupatenParams);
    
    if (isClosed) return;
    
    await kabupatenResult.fold(
      (failure) async {
        // Jika gagal query kabupaten, langsung fallback ke provinsi
        await _fetchProvinsiServicesAsFallback(userProvinsi, userKabupatenKota);
      },
      (services) async {
        // Simpan hasil ke cache
        _saveToCache(kabupatenCacheKey, services);
        
        if (services.isEmpty) {
          // Jika tidak ada layanan di kabupaten/kota, fallback ke provinsi
          await _fetchProvinsiServicesAsFallback(userProvinsi, userKabupatenKota);
        } else {
          // Jika ada layanan di kabupaten/kota, tampilkan
          emit(
            ServiceLocationLoaded(
              services: services,
              hasReachedMax: services.length < kabupatenParams.limit,
              userProvinsi: userProvinsi,
              userKabupatenKota: userKabupatenKota,
              userKecamatan: userKecamatan,
              userDesaKelurahan: userDesaKelurahan,
              isProvinceLevel: false,
              showEmptyLocationMessage: false,
            ),
          );
        }
      },
    );
  }
  
  // Helper method untuk fetch layanan provinsi sebagai fallback
  Future<void> _fetchProvinsiServicesAsFallback(String userProvinsi, String userKabupatenKota) async {
    final String provinsiCacheKey = 'location_provinsi_$userProvinsi';
    final cachedProvinsiData = _getFromCache(provinsiCacheKey);
    
    if (cachedProvinsiData != null) {
      emit(
        ServiceLocationLoaded(
          services: cachedProvinsiData.cast(),
          hasReachedMax: true,
          userProvinsi: userProvinsi,
          userKabupatenKota: userKabupatenKota,
          isProvinceLevel: true,
          showEmptyLocationMessage: true,
        ),
      );
      return;
    }
    
    final provinsiParams = ServiceLocationParams(
      userProvinsi: userProvinsi,
      userKabupatenKota: null, // Tidak filter berdasarkan kabupaten
      limit: 20,
      offset: 0,
    );
    
    final provinsiResult = await getServicesByLocation(provinsiParams);
    
    if (isClosed) return;
    provinsiResult.fold(
      (failure) {
        emit(ServiceLocationError(message: failure.message));
      },
      (services) {
        // Simpan hasil ke cache
        _saveToCache(provinsiCacheKey, services);
        
        emit(
          ServiceLocationLoaded(
            services: services,
            hasReachedMax: services.length < provinsiParams.limit,
            userProvinsi: userProvinsi,
            userKabupatenKota: userKabupatenKota,
            isProvinceLevel: true,
            showEmptyLocationMessage: true, // Tampilkan pesan bahwa tidak ada layanan di kabupaten/kota
          ),
        );
        
        // Mulai subscription realtime untuk provinsi sebagai fallback
        _startLocationStreamSubscription(
          userProvinsi: userProvinsi,
          userKabupatenKota: null, // Kosongkan kabupaten kota untuk mendapatkan layanan provinsi
        );
      },
    );
  }
  
  // Fungsi untuk memulai subscription stream data layanan berdasarkan lokasi
  // Fungsi untuk memulai subscription stream data layanan berdasarkan lokasi
  void _startLocationStreamSubscription({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
  }) {
    try {
      // Batalkan subscription lama jika ada
      _cleanupSubscriptions();
      
      // Mulai subscription baru
      final subscription = serviceRepository
          .getServicesByLocationStream(
            userProvinsi: userProvinsi,
            userKabupatenKota: userKabupatenKota,
            userKecamatan: userKecamatan,
            userDesaKelurahan: userDesaKelurahan,
          )
          .listen((result) {
            if (isClosed) return;
            
            result.fold(
              (failure) {
                debugPrint('Error on location stream: ${failure.message}');
                // Tidak perlu emit error disini, karena bisa mengganggu UI
              },
              (services) {
                // Update state tanpa mengubah parameter lokasi
                if (state is ServiceLocationLoaded) {
                  final currentState = state as ServiceLocationLoaded;
                  
                  // Update cache jika ada
                  final String cacheKey = userKabupatenKota != null
                      ? 'location_kabupaten_${userProvinsi}_$userKabupatenKota'
                      : 'location_provinsi_$userProvinsi';
                      
                  // Urutkan layanan berdasarkan promosi dan rating sebelum disimpan ke cache
                  final sortedServices = _sortServicesByPromotionAndRating(services);
                  
                  _saveToCache(cacheKey, sortedServices);
                  
                  emit(currentState.copyWith(
                    services: sortedServices,
                    hasReachedMax: services.length < _limit,
                    isRealtimeUpdate: true,
                  ));
                }
              },
            );
          });
      
      _streamSubscriptions.add(subscription);
    } catch (e) {
      debugPrint('Error setting up location stream: $e');
    }
  }
  
  // Fungsi untuk memulai subscription stream data layanan promosi
  void _startPromotedServicesStreamSubscription() {
    try {
      final subscription = serviceRepository
          .getPromotedServicesStream()
          .listen((result) {
            if (isClosed) return;
            
            result.fold(
              (failure) {
                debugPrint('Error on promoted services stream: ${failure.message}');
              },
              (services) {
                if (state is ServiceLocationLoaded) {
                  final currentState = state as ServiceLocationLoaded;
                  
                  // Hanya update state jika tab promosi yang aktif
                  // Periksa properti state untuk menentukan tab aktif
                  if (!currentState.isProvinceLevel && currentState.userProvinsi == null) {
                    // Update cache
                // Urutkan layanan berdasarkan promosi dan rating
                final sortedServices = _sortServicesByPromotionAndRating(services);
                
                _saveToCache('promoted_services', sortedServices);
                
                emit(currentState.copyWith(
                  services: sortedServices,
                      hasReachedMax: services.length < _limit,
                      isRealtimeUpdate: true,
                    ));
                  }
                }
              },
            );
          });
      
      _streamSubscriptions.add(subscription);
    } catch (e) {
      debugPrint('Error setting up promoted services stream: $e');
    }
  }
  
  // Fungsi untuk memulai subscription stream data layanan dengan rating tertinggi
  void _startHighestRatingServicesStreamSubscription() {
    try {
      final subscription = serviceRepository
          .getServicesByHighestRatingStream()
          .listen((result) {
            if (isClosed) return;
            
            result.fold(
              (failure) {
                debugPrint('Error on highest rating services stream: ${failure.message}');
              },
              (services) {
                if (state is ServiceLocationLoaded) {
                  final currentState = state as ServiceLocationLoaded;
                  
                  // Hanya update state jika tab rating tertinggi yang aktif
                  if (currentState.userProvinsi == null) {
                    // Update cache
                    _saveToCache('highest_rating_services', services);
                    
                    // Urutkan layanan berdasarkan promosi dan rating
                    final sortedServices = _sortServicesByPromotionAndRating(services);
                    
                    emit(currentState.copyWith(
                      services: sortedServices,
                      hasReachedMax: services.length < _limit,
                      isRealtimeUpdate: true,
                    ));
                  }
                }
              },
            );
          });
      
      _streamSubscriptions.add(subscription);
    } catch (e) {
      debugPrint('Error setting up highest rating services stream: $e');
    }
  }
  
  /// Mengurutkan layanan berdasarkan prioritas promosi dan rating
  /// 1. Layanan promosi di urutan teratas
  /// 2. Di antara layanan promosi, urutkan berdasarkan rating tertinggi
  /// 3. Layanan non-promosi di bawah, diurutkan berdasarkan rating tertinggi
  List<ServiceWithLocation> _sortServicesByPromotionAndRating(List<dynamic> services) {
    // Buat salinan list untuk menghindari mutasi list asli
    final List<ServiceWithLocation> typedServices = services.cast<ServiceWithLocation>();
    
    // Urutkan berdasarkan promosi (true di atas) dan rating (tertinggi di atas)
    typedServices.sort((a, b) {
      // Jika salah satu dipromosikan dan yang lain tidak
      if (a.isPromoted == true && b.isPromoted != true) return -1;
      if (a.isPromoted != true && b.isPromoted == true) return 1;
      
      // Jika keduanya dipromosikan atau keduanya tidak dipromosikan,
      // urutkan berdasarkan rating
      return b.averageRating.compareTo(a.averageRating);
    });
    
    return typedServices;
  }
}
