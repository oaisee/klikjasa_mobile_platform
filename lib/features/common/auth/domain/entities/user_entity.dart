import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? address;
  final bool isProvider;
  final String? providerStatus;
  final String role;
  final double? saldo;

  const UserEntity({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.address,
    this.isProvider = false,
    this.providerStatus,
    this.role = 'user',
    this.saldo,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        phoneNumber,
        address,
        isProvider,
        providerStatus,
        role,
        saldo,
      ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? address,
    bool? isProvider,
    String? providerStatus,
    String? role,
    double? saldo,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      isProvider: isProvider ?? this.isProvider,
      providerStatus: providerStatus ?? this.providerStatus,
      role: role ?? this.role,
      saldo: saldo ?? this.saldo,
    );
  }

  bool get isProfileComplete {
    return fullName != null &&
        fullName!.isNotEmpty &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty;
  }
}
