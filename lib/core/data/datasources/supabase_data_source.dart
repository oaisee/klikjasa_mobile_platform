import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../error/exceptions.dart';

/// Base class untuk semua Supabase data sources dalam aplikasi
/// 
/// Kelas ini menyediakan fungsionalitas umum untuk berinteraksi dengan Supabase
/// dan dapat di-extend oleh data sources fitur spesifik
abstract class SupabaseDataSource {
  final SupabaseClient supabaseClient;

  SupabaseDataSource({required this.supabaseClient});
  
  /// Mendapatkan user ID saat ini dari Supabase auth
  String? get currentUserId => supabaseClient.auth.currentUser?.id;
  
  /// Memeriksa apakah user sudah terautentikasi
  bool get isAuthenticated => supabaseClient.auth.currentUser != null;
  
  /// Mendapatkan current user dari Supabase auth
  User? get currentUser => supabaseClient.auth.currentUser;
  
  /// Mendapatkan Supabase query builder untuk tabel tertentu
  SupabaseQueryBuilder table(String tableName) {
    return supabaseClient.from(tableName);
  }
  
  /// Helper method untuk menangani operasi Supabase dengan error handling yang konsisten
  Future<T> handleSupabaseOperation<T>({
    required Future<T> Function() operation,
    String? context,
  }) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e, context);
    } on AuthException catch (e) {
      throw _mapAuthException(e, context);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Tidak ada koneksi internet',
        code: 'NO_CONNECTION',
        details: e.toString(),
      );
    } on TimeoutException catch (e) {
      throw TimeoutException(
        message: 'Koneksi timeout, coba lagi nanti',
        code: 'TIMEOUT',
        details: e.toString(),
      );
    } catch (e) {
      throw ServerException(
        message: context != null 
            ? 'Gagal $context: ${e.toString()}'
            : 'Terjadi kesalahan: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Mapping PostgrestException ke custom exception
  ServerException _mapPostgrestException(PostgrestException e, String? context) {
    final statusCode = int.tryParse(e.code ?? '500') ?? 500;
    
    switch (statusCode) {
      case 400:
        return const ServerException(
          message: 'Permintaan tidak valid',
          code: 'BAD_REQUEST',
        );
      case 401:
        return const ServerException(
          message: 'Akses tidak diizinkan',
          code: 'UNAUTHORIZED',
        );
      case 403:
        return const ServerException(
          message: 'Akses ditolak',
          code: 'FORBIDDEN',
        );
      case 404:
        return const ServerException(
          message: 'Data tidak ditemukan',
          code: 'NOT_FOUND',
        );
      case 422:
        return ServerException(
          message: 'Data tidak valid: ${e.message}',
          code: 'VALIDATION_ERROR',
          details: e.details,
        );
      default:
        return ServerException(
          message: context != null 
              ? 'Gagal $context: ${e.message}'
              : e.message,
          code: 'SERVER_ERROR',
          details: e.details,
        );
    }
  }

  /// Mapping AuthException ke custom exception
  AuthenticationException _mapAuthException(AuthException e, String? context) {
    switch (e.statusCode) {
      case '400':
        return const AuthenticationException(
          message: 'Email atau password salah',
          code: 'INVALID_CREDENTIALS',
        );
      case '422':
        return const AuthenticationException(
          message: 'Data autentikasi tidak valid',
          code: 'VALIDATION_ERROR',
        );
      default:
        return AuthenticationException(
          message: context != null
              ? 'Gagal $context: ${e.message}'
              : e.message,
          code: 'AUTH_ERROR',
        );
    }
  }

  /// Helper untuk melakukan query dengan pagination
  Future<List<Map<String, dynamic>>> queryWithPagination({
    required String tableName,
    String? select,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
    Map<String, dynamic>? filters,
  }) async {
    return await handleSupabaseOperation(
      operation: () async {
        dynamic query = supabaseClient
            .from(tableName)
            .select(select ?? '*');

        // Apply filters
        if (filters != null) {
          filters.forEach((key, value) {
            query = query.eq(key, value);
          });
        }

        // Apply ordering
        if (orderBy != null) {
          query = query.order(orderBy, ascending: ascending);
        }

        // Apply pagination
        if (limit != null) {
          query = query.limit(limit);
        }
        if (offset != null) {
          query = query.range(offset, offset + (limit ?? 10) - 1);
        }

        return await query;
      },
      context: 'mengambil data dari $tableName',
    );
  }

  /// Helper untuk insert data
  Future<Map<String, dynamic>> insertData({
    required String tableName,
    required Map<String, dynamic> data,
    String? select,
  }) async {
    return await handleSupabaseOperation(
      operation: () async {
        final result = await supabaseClient
            .from(tableName)
            .insert(data)
            .select(select ?? '*')
            .single();
        return result;
      },
      context: 'menyimpan data ke $tableName',
    );
  }

  /// Helper untuk update data
  Future<Map<String, dynamic>> updateData({
    required String tableName,
    required Map<String, dynamic> data,
    required String idColumn,
    required dynamic idValue,
    String? select,
  }) async {
    return await handleSupabaseOperation(
      operation: () async {
        final result = await supabaseClient
            .from(tableName)
            .update(data)
            .eq(idColumn, idValue)
            .select(select ?? '*')
            .single();
        return result;
      },
      context: 'memperbarui data di $tableName',
    );
  }

  /// Helper untuk delete data
  Future<void> deleteData({
    required String tableName,
    required String idColumn,
    required dynamic idValue,
  }) async {
    return await handleSupabaseOperation(
      operation: () async {
        await supabaseClient
            .from(tableName)
            .delete()
            .eq(idColumn, idValue);
      },
      context: 'menghapus data dari $tableName',
    );
  }
}
