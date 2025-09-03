// lib/core/error/exceptions.dart

/// Base exception class untuk semua custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Exception untuk error dari server/API
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.details,
  });

  factory ServerException.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return const ServerException(
          message: 'Bad Request - Permintaan tidak valid',
          code: 'BAD_REQUEST',
        );
      case 401:
        return const ServerException(
          message: 'Unauthorized - Akses tidak diizinkan',
          code: 'UNAUTHORIZED',
        );
      case 403:
        return const ServerException(
          message: 'Forbidden - Akses ditolak',
          code: 'FORBIDDEN',
        );
      case 404:
        return const ServerException(
          message: 'Not Found - Data tidak ditemukan',
          code: 'NOT_FOUND',
        );
      case 422:
        return const ServerException(
          message: 'Unprocessable Entity - Data tidak valid',
          code: 'VALIDATION_ERROR',
        );
      case 500:
        return const ServerException(
          message: 'Internal Server Error - Terjadi kesalahan pada server',
          code: 'INTERNAL_SERVER_ERROR',
        );
      default:
        return ServerException(
          message: message ?? 'Terjadi kesalahan tidak diketahui',
          code: 'UNKNOWN_SERVER_ERROR',
        );
    }
  }
}

/// Exception untuk data yang tidak ditemukan
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Exception untuk error cache/storage lokal
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Exception untuk error koneksi jaringan
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Exception untuk error validasi input
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.details, // Bisa berisi map field -> error
  }) : super(code: 'VALIDATION_ERROR');
}

/// Exception untuk error autentikasi
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code,
  });
}

/// Exception untuk error authorization/permission
class AuthorizationException extends AppException {
  const AuthorizationException({
    required super.message,
  }) : super(code: 'INSUFFICIENT_PERMISSION');
}

/// Exception untuk error parsing data
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.details,
  }) : super(code: 'PARSE_ERROR');
}

/// Exception untuk error umum/tidak terduga
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.details,
  }) : super(code: 'UNKNOWN_ERROR');
}

/// Exception untuk timeout
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code,
    super.details,
  });
}
