import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';

/// State dasar untuk Services Bloc.
abstract class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object?> get props => [];
}

/// State awal ketika tidak ada operasi yang sedang berlangsung.
class ServicesInitial extends ServicesState {}

/// State ketika sedang memuat data.
class ServicesLoading extends ServicesState {}

/// State ketika operasi berhasil memuat daftar layanan.
class ServicesLoaded extends ServicesState {
  final List<Service> layanan;

  const ServicesLoaded({required this.layanan});

  @override
  List<Object> get props => [layanan];
}

/// State ketika operasi berhasil memuat detail layanan.
class LayananDetailLoaded extends ServicesState {
  final Service layanan;

  const LayananDetailLoaded({required this.layanan});

  @override
  List<Object> get props => [layanan];
}

/// State ketika operasi berhasil menambahkan layanan.
class LayananAdded extends ServicesState {
  final Service layanan;

  const LayananAdded({required this.layanan});

  @override
  List<Object> get props => [layanan];
}

/// State ketika operasi berhasil mengupdate layanan.
class LayananUpdated extends ServicesState {
  final Service layanan;

  const LayananUpdated({required this.layanan});

  @override
  List<Object> get props => [layanan];
}

/// State ketika operasi berhasil menghapus layanan.
class LayananDeleted extends ServicesState {
  final String layananId;

  const LayananDeleted({required this.layananId});

  @override
  List<Object> get props => [layananId];
}

/// State ketika operasi gagal.
class ServicesError extends ServicesState {
  final String message;

  const ServicesError({required this.message});

  @override
  List<Object> get props => [message];
}