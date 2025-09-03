import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';
import 'package:klik_jasa/core/utils/logger.dart'; // Import logger untuk logging yang lebih baik

abstract class UserBalanceRemoteDataSource {
  Future<UserBalanceEntity> getUserBalance(String userId);
  Future<UserBalanceEntity> updateUserBalance(
    String userId,
    double newBalance, {
    String? description,
  });
  Future<bool> deductBalance(
    String userId,
    double amount,
    String description,
    String transactionType,
  );
  Future<bool> addBalance(
    String userId,
    double amount,
    String description,
    String transactionType,
  );
}

class UserBalanceRemoteDataSourceImpl implements UserBalanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  UserBalanceRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserBalanceEntity> getUserBalance(String userId) async {
    try {
      logger.i('UserBalanceDataSource: Mengambil saldo untuk user $userId');
      final response = await supabaseClient
          .from('user_balances')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // Menggunakan maybeSingle untuk menangani kasus tidak ada data

      if (response == null) {
        logger.w(
          'UserBalanceDataSource: Saldo tidak ditemukan untuk user $userId, mengembalikan saldo 0',
        );
        // Jika saldo tidak ditemukan, buat entri baru dengan saldo 0
        final newBalanceEntity = UserBalanceEntity(
          userId: userId,
          balance: 0.0,
          lastUpdated: DateTime.now(),
        );

        // Buat entri baru di database
        await supabaseClient.from('user_balances').insert({
          'user_id': userId,
          'balance': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Tidak lagi melakukan update ke field saldo di profiles
        // Hanya menggunakan tabel user_balances sebagai sumber data saldo yang valid

        logger.i(
          'UserBalanceDataSource: Berhasil membuat entri saldo baru untuk user $userId',
        );
        return newBalanceEntity;
      }

      final balanceEntity = UserBalanceEntity.fromJson(response);
      logger.i(
        'UserBalanceDataSource: Saldo user $userId adalah ${balanceEntity.balance}',
      );
      return balanceEntity;
    } on PostgrestException catch (e) {
      logger.e(
        'UserBalanceDataSource: PostgrestException saat mengambil saldo: ${e.message}',
      );
      throw Exception(
        'Gagal mengambil saldo pengguna dari Supabase: ${e.message}',
      );
    } catch (e) {
      logger.e('UserBalanceDataSource: Error saat mengambil saldo: $e');
      throw Exception('Terjadi kesalahan saat mengambil saldo pengguna: $e');
    }
  }

  @override
  Future<UserBalanceEntity> updateUserBalance(
    String userId,
    double newBalance, {
    String? description,
  }) async {
    try {
      logger.i(
        'UserBalanceDataSource: Memperbarui saldo user $userId menjadi $newBalance',
      );
      if (description != null) {
        logger.i('UserBalanceDataSource: Deskripsi: $description');
      }

      // Mulai transaksi dengan menggunakan RPC (Remote Procedure Call)
      // Catatan: Ini bukan transaksi database sebenarnya, tapi pendekatan untuk memastikan konsistensi
      bool updateSuccess = false;

      // 1. Update saldo di user_balances
      try {
        final userBalanceResponse =
            await supabaseClient.from('user_balances').upsert({
              'user_id': userId,
              'balance': newBalance,
              'updated_at': DateTime.now().toIso8601String(),
            }).select();

        if (userBalanceResponse.isNotEmpty) {
          updateSuccess = true;
          logger.i(
            'UserBalanceDataSource: Berhasil update saldo di user_balances',
          );
        } else {
          logger.w(
            'UserBalanceDataSource: Tidak ada respons dari update user_balances',
          );
        }
      } catch (e) {
        logger.e('UserBalanceDataSource: Gagal update user_balances: $e');
        throw Exception('Gagal memperbarui saldo di user_balances: $e');
      }

      // Tidak lagi melakukan sinkronisasi ke tabel profiles
      // Hanya menggunakan tabel user_balances sebagai sumber data saldo yang valid
      if (updateSuccess) {
        logger.i(
          'UserBalanceDataSource: Update saldo berhasil di user_balances, tidak perlu sinkronisasi ke profiles',
        );
      }

      // 3. Tidak mencatat transaksi di sini karena sudah dicatat di addBalance/deductBalance
      // dengan transaction_type dan amount yang benar
      if (description != null) {
        logger.i(
          'UserBalanceDataSource: Update saldo dengan deskripsi: $description',
        );
        logger.i(
          'UserBalanceDataSource: Transaksi akan dicatat oleh fungsi pemanggil dengan tipe yang sesuai',
        );
      }

      // 4. Ambil data terbaru untuk dikembalikan
      final response = await supabaseClient
          .from('user_balances')
          .select()
          .eq('user_id', userId)
          .single();

      final result = UserBalanceEntity.fromJson(response);
      logger.i(
        'UserBalanceDataSource: Saldo terbaru user $userId adalah ${result.balance}',
      );
      return result;
    } on PostgrestException catch (e) {
      logger.e(
        'UserBalanceDataSource: PostgrestException saat update saldo: ${e.message}',
      );
      throw Exception(
        'Gagal memperbarui saldo pengguna di Supabase: ${e.message}',
      );
    } catch (e) {
      logger.e('UserBalanceDataSource: Error saat update saldo: $e');
      throw Exception('Terjadi kesalahan saat memperbarui saldo pengguna: $e');
    }
  }

  @override
  Future<bool> deductBalance(
    String userId,
    double amount,
    String description,
    String transactionType,
  ) async {
    try {
      logger.i(
        'UserBalanceDataSource: Mengurangi saldo user $userId sebesar $amount',
      );
      logger.i('UserBalanceDataSource: Deskripsi: $description');

      final currentBalance = await getUserBalance(userId);

      // Validasi saldo cukup
      if (currentBalance.balance < amount) {
        logger.w(
          'UserBalanceDataSource: Saldo tidak cukup. Saldo: ${currentBalance.balance}, Jumlah: $amount',
        );
        throw Exception('Saldo tidak mencukupi untuk melakukan transaksi ini');
      }

      final newBalance = currentBalance.balance - amount;
      logger.i('UserBalanceDataSource: Saldo baru akan menjadi $newBalance');

      // TIDAK memanggil updateUserBalance karena trigger database akan mengupdate saldo otomatis
      // berdasarkan transaksi yang dicatat di bawah
      logger.i('UserBalanceDataSource: Saldo akan diupdate otomatis oleh trigger database');

      // Catat transaksi pengurangan saldo
      try {
        // Validasi transactionType tidak null atau kosong
        if (transactionType.isEmpty) {
          logger.e(
            'UserBalanceDataSource: transactionType kosong, menggunakan default fee_deduction_user',
          );
          transactionType = 'DEDUCTION';
        }

        // Konversi transaction type ke format yang benar untuk database
        String dbTransactionType;
        switch (transactionType.toUpperCase()) {
          case 'CHECKOUT_FEE':
            dbTransactionType = 'checkout_fee';
            break;
          case 'PLATFORM_FEE':
            dbTransactionType = 'platform_fee';
            break;
          case 'DEDUCTION':
            dbTransactionType = 'fee_deduction_user';
            break;
          case 'PROMOTION_FEE':
            dbTransactionType = 'fee_deduction_user';
            break;
          default:
            dbTransactionType = 'fee_deduction_user'; // Default fallback
        }

        logger.i(
          'UserBalanceDataSource: Menggunakan transaction_type: $dbTransactionType untuk database',
        );

        await supabaseClient.from('transactions').insert({
          'user_id': userId,
          'transaction_type': dbTransactionType,
          'amount':
              amount, // Nilai positif - trigger akan mengurangi berdasarkan transaction_type
          'description': description,
          'transaction_date': DateTime.now().toIso8601String(),
          'status': 'completed',
        });
        logger.i(
          'UserBalanceDataSource: Berhasil mencatat transaksi pengurangan saldo',
        );
      } catch (e) {
        logger.e(
          'UserBalanceDataSource: Gagal mencatat transaksi pengurangan: $e',
        );
        // Tidak throw exception di sini, karena update utama sudah berhasil
      }

      return true;
    } on PostgrestException catch (e) {
      logger.e(
        'UserBalanceDataSource: PostgrestException saat mengurangi saldo: ${e.message}',
      );
      throw Exception(
        'Gagal mengurangi saldo pengguna di Supabase: ${e.message}',
      );
    } catch (e) {
      logger.e('UserBalanceDataSource: Error saat mengurangi saldo: $e');
      throw Exception('Terjadi kesalahan saat mengurangi saldo pengguna: $e');
    }
  }

  @override
  Future<bool> addBalance(
    String userId,
    double amount,
    String description,
    String transactionType,
  ) async {
    try {
      logger.i(
        'UserBalanceDataSource: Menambah saldo user $userId sebesar $amount',
      );
      logger.i('UserBalanceDataSource: Deskripsi: $description');

      final currentBalance = await getUserBalance(userId);
      final newBalance = currentBalance.balance + amount;
      logger.i('UserBalanceDataSource: Saldo baru akan menjadi $newBalance');

      // TIDAK memanggil updateUserBalance karena trigger database akan mengupdate saldo otomatis
      // berdasarkan transaksi yang dicatat di bawah
      logger.i('UserBalanceDataSource: Saldo akan diupdate otomatis oleh trigger database');

      // Catat transaksi penambahan saldo
      try {
        // Validasi transactionType tidak null atau kosong
        if (transactionType.isEmpty) {
          logger.e(
            'UserBalanceDataSource: transactionType kosong, menggunakan default TOP_UP',
          );
          transactionType = 'TOP_UP';
        }

        // Konversi transaction type ke format yang benar untuk database
        String dbTransactionType;
        switch (transactionType.toUpperCase()) {
          case 'TOP_UP':
            dbTransactionType = 'top_up';
            break;
          case 'TOPUP':
            dbTransactionType = 'topup';
            break;
          case 'REFUND':
            dbTransactionType = 'refund';
            break;
          case 'ADJUSTMENT':
            dbTransactionType = 'adjustment';
            break;
          default:
            dbTransactionType = 'top_up'; // Default fallback untuk penambahan
        }

        logger.i(
          'UserBalanceDataSource: Menggunakan transaction_type: $dbTransactionType untuk database',
        );

        await supabaseClient.from('transactions').insert({
          'user_id': userId,
          'transaction_type': dbTransactionType,
          'amount': amount, // Nilai positif untuk penambahan
          'description': description,
          'transaction_date': DateTime.now().toIso8601String(),
          'status': 'completed',
        });
        logger.i(
          'UserBalanceDataSource: Berhasil mencatat transaksi penambahan saldo',
        );
      } catch (e) {
        logger.e(
          'UserBalanceDataSource: Gagal mencatat transaksi penambahan: $e',
        );
        // Tidak throw exception di sini, karena update utama sudah berhasil
      }

      return true;
    } on PostgrestException catch (e) {
      logger.e(
        'UserBalanceDataSource: PostgrestException saat menambah saldo: ${e.message}',
      );
      throw Exception(
        'Gagal menambah saldo pengguna di Supabase: ${e.message}',
      );
    } catch (e) {
      logger.e('UserBalanceDataSource: Error saat menambah saldo: $e');
      throw Exception('Terjadi kesalahan saat menambah saldo pengguna: $e');
    }
  }
}
