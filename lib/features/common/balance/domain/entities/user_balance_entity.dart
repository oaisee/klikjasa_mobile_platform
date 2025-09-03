import 'package:equatable/equatable.dart';

class UserBalanceEntity extends Equatable {
  final String userId;
  final double balance;
  final DateTime lastUpdated;

  const UserBalanceEntity({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [userId, balance, lastUpdated];

  factory UserBalanceEntity.fromJson(Map<String, dynamic> json) {
    return UserBalanceEntity(
      userId:
          json['user_id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : 0.0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'balance': balance,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
