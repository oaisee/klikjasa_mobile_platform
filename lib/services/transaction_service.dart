import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class TransactionService {
  final SupabaseClient _supabase;

  TransactionService(this._supabase);

  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((transaction) => Transaction.fromJson(transaction))
          .toList();
    } catch (e) {
      print('Error getting user transactions: $e');
      rethrow;
    }
  }

  Future<Transaction> createTransaction({
    required String userId,
    required double amount,
    required String type,
    String? description,
    String? serviceId,
  }) async {
    try {
      final transactionData = {
        'user_id': userId,
        'amount': amount,
        'type': type,
        'status': 'pending',
        'description': description,
        'service_id': serviceId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  Future<Transaction> updateTransactionStatus({
    required String transactionId,
    required String status,
  }) async {
    try {
      final response = await _supabase
          .from('transactions')
          .update({'status': status})
          .eq('id', transactionId)
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error updating transaction status: $e');
      rethrow;
    }
  }

  Future<Transaction> processTopUp({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // 1. Create transaction record
      final transaction = await createTransaction(
        userId: userId,
        amount: amount,
        type: 'topup',
        description: 'Top up via $paymentMethod',
      );

      // 2. In a real app, we would integrate with payment gateway here
      // For demo purposes, we'll simulate a successful payment
      await Future.delayed(const Duration(seconds: 2));

      // 3. Update transaction status to success
      final updatedTransaction = await updateTransactionStatus(
        transactionId: transaction.id,
        status: 'success',
      );

      // 4. Update user balance
      await _supabase.rpc(
        'update_user_balance',
        params: {
          'user_id': userId,
          'amount': amount,
        },
      );

      return updatedTransaction;
    } catch (e) {
      print('Error processing top up: $e');
      rethrow;
    }
  }
}
