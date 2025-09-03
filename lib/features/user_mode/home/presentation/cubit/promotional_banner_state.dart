import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/promotional_banner.dart';

abstract class PromotionalBannerState extends Equatable {
  const PromotionalBannerState();

  @override
  List<Object?> get props => [];
}

class PromotionalBannerInitial extends PromotionalBannerState {}

class PromotionalBannerLoading extends PromotionalBannerState {}

class PromotionalBannerLoaded extends PromotionalBannerState {
  final List<PromotionalBanner> banners;

  const PromotionalBannerLoaded({required this.banners});

  @override
  List<Object?> get props => [banners];
}

class PromotionalBannerError extends PromotionalBannerState {
  final String message;

  const PromotionalBannerError({required this.message});

  @override
  List<Object?> get props => [message];
}
