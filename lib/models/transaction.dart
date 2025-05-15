class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'topup', 'payment', 'refund', 'commission'
  final String status; // 'pending', 'success', 'failed'
  final String? description;
  final String? serviceId;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    this.serviceId,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] is int 
          ? (json['amount'] as int).toDouble() 
          : json['amount'] as double,
      type: json['type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      serviceId: json['service_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'description': description,
      'service_id': serviceId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
