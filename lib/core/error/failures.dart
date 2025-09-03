// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

/// Base class untuk semua failure dalam aplikasi
/// 
/// Failure merepresentasikan kegagalan dalam business logic layer
/// dan digunakan untuk mengembalikan error dari use cases
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() {
    return 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Failure untuk error dari server/API
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory ServerFailure.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return const ServerFailure(
          message: 'Permintaan tidak valid',
          code: 'BAD_REQUEST',
        );
      case 401:
        return const ServerFailure(
          message: 'Sesi telah berakhir, silakan login kembali',
          code: 'UNAUTHORIZED',
        );
      case 403:
        return const ServerFailure(
          message: 'Anda tidak memiliki akses untuk melakukan tindakan ini',
          code: 'FORBIDDEN',
        );
      case 404:
        return const ServerFailure(
          message: 'Data yang dicari tidak ditemukan',
          code: 'NOT_FOUND',
        );
      case 422:
        return const ServerFailure(
          message: 'Data yang dikirim tidak valid',
          code: 'VALIDATION_ERROR',
        );
      case 500:
        return const ServerFailure(
          message: 'Terjadi kesalahan pada server',
          code: 'INTERNAL_SERVER_ERROR',
        );
      default:
        return ServerFailure(
          message: message ?? 'Terjadi kesalahan tidak diketahui',
          code: 'UNKNOWN',
        );
    }
  }
}

/// Failure untuk error cache/storage lokal
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory CacheFailure.notFound() {
    return const CacheFailure(
      message: 'Data tidak ditemukan di penyimpanan lokal',
      code: 'CACHE_NOT_FOUND',
    );
  }

  factory CacheFailure.writeError() {
    return const CacheFailure(
      message: 'Gagal menyimpan data ke penyimpanan lokal',
      code: 'CACHE_WRITE_ERROR',
    );
  }
}

/// Failure untuk data yang tidak ditemukan
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Failure untuk error koneksi jaringan
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      message: 'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Koneksi timeout. Periksa koneksi internet Anda',
      code: 'TIMEOUT',
    );
  }

  factory NetworkFailure.requestCancelled() {
    return const NetworkFailure(
      message: 'Permintaan dibatalkan',
      code: 'REQUEST_CANCELLED',
    );
  }
}

/// Failure untuk error validasi input
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory ValidationFailure.required(String fieldName) {
    return ValidationFailure(
      message: '$fieldName wajib diisi',
      code: 'FIELD_REQUIRED',
      details: fieldName,
    );
  }

  factory ValidationFailure.invalidFormat(String fieldName) {
    return ValidationFailure(
      message: 'Format $fieldName tidak valid',
      code: 'INVALID_FORMAT',
      details: fieldName,
    );
  }

  factory ValidationFailure.minLength(String fieldName, int minLength) {
    return ValidationFailure(
      message: '$fieldName minimal $minLength karakter',
      code: 'MIN_LENGTH',
      details: {'field': fieldName, 'minLength': minLength},
    );
  }
}

/// Failure untuk error autentikasi
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory AuthenticationFailure.invalidCredentials() {
    return const AuthenticationFailure(
      message: 'Email atau password salah',
      code: 'INVALID_CREDENTIALS',
    );
  }

  factory AuthenticationFailure.userNotFound() {
    return const AuthenticationFailure(
      message: 'Akun tidak ditemukan',
      code: 'USER_NOT_FOUND',
    );
  }

  factory AuthenticationFailure.sessionExpired() {
    return const AuthenticationFailure(
      message: 'Sesi telah berakhir, silakan login kembali',
      code: 'SESSION_EXPIRED',
    );
  }
}

/// Failure untuk error authorization/permission
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory AuthorizationFailure.accessDenied() {
    return const AuthorizationFailure(
      message: 'Anda tidak memiliki akses untuk melakukan tindakan ini',
      code: 'ACCESS_DENIED',
    );
  }

  factory AuthorizationFailure.insufficientPermissions() {
    return const AuthorizationFailure(
      message: 'Izin tidak mencukupi untuk mengakses fitur ini',
      code: 'INSUFFICIENT_PERMISSIONS',
    );
  }
}

/// Failure untuk error parsing data
class ParseFailure extends Failure {
  const ParseFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory ParseFailure.invalidJson() {
    return const ParseFailure(
      message: 'Format data tidak valid',
      code: 'INVALID_JSON',
    );
  }

  factory ParseFailure.missingField(String fieldName) {
    return ParseFailure(
      message: 'Field $fieldName tidak ditemukan dalam data',
      code: 'MISSING_FIELD',
      details: fieldName,
    );
  }
}

/// Failure untuk error umum/tidak terduga
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.details,
  });

  factory UnknownFailure.unexpected([String? message]) {
    return UnknownFailure(
      message: message ?? 'Terjadi kesalahan yang tidak terduga',
      code: 'UNKNOWN_ERROR',
    );
  }
}
