import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';

/// Event dasar untuk Services Bloc.
abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memuat daftar layanan provider.
class LoadProviderLayanan extends ServicesEvent {
  final String providerId;
  final bool? isActive;

  const LoadProviderLayanan({
    required this.providerId,
    this.isActive,
  });

  @override
  List<Object?> get props => [providerId, isActive];
}

/// Event untuk menambahkan layanan baru.
class AddLayanan extends ServicesEvent {
  final Service layanan;

  const AddLayanan({required this.layanan});

  @override
  List<Object> get props => [layanan];
}

/// Event untuk memperbarui layanan yang sudah ada.
class UpdateLayanan extends ServicesEvent {
  final Service layanan;

  const UpdateLayanan({required this.layanan});

  @override
  List<Object> get props => [layanan];
}

/// Event untuk menghapus layanan.
class DeleteLayanan extends ServicesEvent {
  final String layananId;

  const DeleteLayanan({required this.layananId});

  @override
  List<Object> get props => [layananId];
}

/// Event untuk memuat detail layanan.
class LoadLayananDetail extends ServicesEvent {
  final String layananId;

  const LoadLayananDetail({required this.layananId});

  @override
  List<Object> get props => [layananId];
}

/// Event untuk mengatur status aktif layanan.
class SetLayananActive extends ServicesEvent {
  final String layananId;
  final bool isActive;

  const SetLayananActive({
    required this.layananId,
    required this.isActive,
  });

  @override
  List<Object> get props => [layananId, isActive];
}

/// Event untuk mengatur status promosi layanan.
class ToggleLayananPromosi extends ServicesEvent {
  final String layananId;
  final String providerId;
  final String serviceTitle;
  final bool isPromoted;
  final DateTime? promotionStartDate;
  final DateTime? promotionEndDate;

  const ToggleLayananPromosi({
    required this.layananId,
    required this.providerId,
    required this.serviceTitle,
    required this.isPromoted,
    this.promotionStartDate,
    this.promotionEndDate,
  });

  @override
  List<Object?> get props => [layananId, providerId, serviceTitle, isPromoted, promotionStartDate, promotionEndDate];
}