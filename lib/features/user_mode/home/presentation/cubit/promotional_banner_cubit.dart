import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/promotional_banner_repository.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/promotional_banner_state.dart';

class PromotionalBannerCubit extends Cubit<PromotionalBannerState> {
  final PromotionalBannerRepository _repository;
  StreamSubscription? _bannerSubscription;

  PromotionalBannerCubit({required PromotionalBannerRepository repository})
      : _repository = repository,
        super(PromotionalBannerInitial());

  Future<void> fetchActiveBanners() async {
    emit(PromotionalBannerLoading());
    try {
      final banners = await _repository.getActiveBanners();
      emit(PromotionalBannerLoaded(banners: banners));
    } catch (e) {
      emit(PromotionalBannerError(message: e.toString()));
    }
  }

  void startRealtimeBannerUpdates() {
    emit(PromotionalBannerLoading());
    try {
      _bannerSubscription?.cancel();
      _bannerSubscription = _repository.getActiveBannersStream().listen(
        (banners) {
          emit(PromotionalBannerLoaded(banners: banners));
        },
        onError: (error) {
          emit(PromotionalBannerError(message: error.toString()));
        },
      );
    } catch (e) {
      emit(PromotionalBannerError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _bannerSubscription?.cancel();
    return super.close();
  }
}
