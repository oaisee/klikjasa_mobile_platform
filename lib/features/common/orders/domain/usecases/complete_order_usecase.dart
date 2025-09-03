import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/create_notification.dart';
import 'package:klik_jasa/features/common/orders/domain/repositories/order_repository.dart';

class CompleteOrderUseCase {
  final OrderRepository repository;
  final CreateNotification createNotification;

  CompleteOrderUseCase({
    required this.repository,
    required this.createNotification,
  });

  Future<Either<Failure, void>> call(CompleteOrderParams params) async {
    // 1. Update status pesanan menjadi completed
    final result = await repository.updateOrderStatus(
      orderId: params.orderId,
      status: 'completed',
      notes: params.notes,
    );

    return result.fold(
      (failure) => Left(failure),
      (_) async {
        // 2. Kirim notifikasi ke pengguna bahwa pesanan telah selesai
        if (params.userId != null) {
          await createNotification(CreateNotificationParams(
            recipientUserId: params.userId!,
            title: 'Pesanan Selesai',
            body: 'Pesanan Anda untuk layanan ${params.serviceTitle ?? 'Jasa'} telah selesai. Terima kasih telah menggunakan layanan kami!',
            type: 'order_completed',
            relatedEntityType: 'order',
            relatedEntityId: params.orderId.toString(),
            mode: 'user', // Notifikasi untuk user mode
          ));
        }

        // 3. Kirim notifikasi ke provider bahwa pesanan telah selesai (untuk catatan)
        if (params.providerId != null) {
          await createNotification(CreateNotificationParams(
            recipientUserId: params.providerId!,
            title: 'Pesanan Selesai',
            body: 'Pesanan untuk layanan ${params.serviceTitle ?? 'Jasa'} telah ditandai selesai.',
            type: 'order_completed',
            relatedEntityType: 'order',
            relatedEntityId: params.orderId.toString(),
            mode: 'provider', // Notifikasi untuk provider mode
          ));
        }

        return const Right(null);
      },
    );
  }
}

class CompleteOrderParams extends Equatable {
  final int orderId;
  final String? userId;
  final String? providerId;
  final String? serviceTitle;
  final String? notes;

  const CompleteOrderParams({
    required this.orderId,
    this.userId,
    this.providerId,
    this.serviceTitle,
    this.notes,
  });

  @override
  List<Object?> get props => [orderId, userId, providerId, serviceTitle, notes];
}
