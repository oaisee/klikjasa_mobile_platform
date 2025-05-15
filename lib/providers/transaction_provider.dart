import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  TransactionProvider(this._transactionService);

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserTransactions(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _transactions = await _transactionService.getUserTransactions(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Transaction> processTopUp({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final transaction = await _transactionService.processTopUp(
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      // Reload transactions after top-up
      await loadUserTransactions(userId);

      _isLoading = false;
      notifyListeners();

      return transaction;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
