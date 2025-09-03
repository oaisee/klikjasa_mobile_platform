// lib/features/common/profile/domain/usecases/get_provinces_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/provinsi.dart';
import '../repositories/region_repository.dart';

class GetProvincesUseCase {
  final RegionRepository repository;

  GetProvincesUseCase(this.repository);

  Future<Either<Failure, List<Provinsi>>> call() async {
    debugPrint('GetProvincesUseCase called, forwarding to repository');
    return await repository.getProvinces();
  }
}
