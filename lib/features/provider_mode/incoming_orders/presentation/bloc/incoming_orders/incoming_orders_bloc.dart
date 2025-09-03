import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/get_incoming_orders_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/update_order_status_usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/create_notification.dart';

part 'incoming_orders_event.dart';
part 'incoming_orders_state.dart';

class IncomingOrdersBloc extends Bloc<IncomingOrdersEvent, IncomingOrdersState> {
  final GetIncomingOrdersUseCase _getIncomingOrdersUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;
  final CreateNotification _createNotificationUseCase;

  IncomingOrdersBloc(
    this._getIncomingOrdersUseCase,
    this._updateOrderStatusUseCase,
    this._createNotificationUseCase,
  ) : super(IncomingOrdersInitial()) {
    on<FetchIncomingOrders>(_onFetchIncomingOrders);
    on<AcceptIncomingOrder>(_onAcceptIncomingOrder);
    on<DeclineIncomingOrder>(_onDeclineIncomingOrder);
  }

  Future<void> _onFetchIncomingOrders(
    FetchIncomingOrders event,
    Emitter<IncomingOrdersState> emit,
  ) async {
    emit(IncomingOrdersLoading());
    try {
      final result = await _getIncomingOrdersUseCase(
        GetIncomingOrdersParams(providerId: event.providerId),
      );

      result.fold(
        (failure) => emit(IncomingOrdersError(message: failure.message)),
        (orders) => emit(IncomingOrdersLoaded(orders: orders)),
      );
    } catch (e) {
      emit(IncomingOrdersError(message: e.toString()));
    }
  }

  Future<void> _onAcceptIncomingOrder(
    AcceptIncomingOrder event,
    Emitter<IncomingOrdersState> emit,
  ) async {
    emit(IncomingOrderAcceptLoading(orderId: event.orderId));
    try {
      final result = await _updateOrderStatusUseCase(
        UpdateOrderStatusParams(
          orderId: event.orderId,
          newStatus: OrderStatus.confirmed, // Status diubah menjadi diterima
          providerNotes: event.notes,
        ),
      );

      result.fold(
        (failure) => emit(IncomingOrderAcceptFailure(orderId: event.orderId, message: failure.message)),
        (order) async {
          emit(IncomingOrderAcceptSuccess(order: order));
          
          // Kirim notifikasi ke pengguna bahwa pesanan telah diterima
          await _createNotificationUseCase(CreateNotificationParams(
            recipientUserId: order.userId,
            title: 'Pesanan Diterima',
            body: 'Pesanan Anda untuk layanan ${order.serviceTitle ?? 'Jasa'} telah diterima oleh penyedia jasa.',
            type: 'order_update',
            relatedEntityType: 'order',
            relatedEntityId: order.id.toString(),
            mode: 'user' // Notifikasi untuk user mode
          ));
          
          // Setelah berhasil, muat ulang daftar pesanan masuk
          add(FetchIncomingOrders(providerId: event.providerId));
        },
      );
    } catch (e) {
      emit(IncomingOrderAcceptFailure(orderId: event.orderId, message: e.toString()));
    }
  }

  Future<void> _onDeclineIncomingOrder(
    DeclineIncomingOrder event,
    Emitter<IncomingOrdersState> emit,
  ) async {
    emit(IncomingOrderDeclineLoading(orderId: event.orderId));
    try {
      final result = await _updateOrderStatusUseCase(
        UpdateOrderStatusParams(
          orderId: event.orderId,
          newStatus: OrderStatus.rejected, // Status diubah menjadi ditolak
          cancellationReason: event.reason,
        ),
      );

      result.fold(
        (failure) => emit(IncomingOrderDeclineFailure(orderId: event.orderId, message: failure.message)),
        (order) async {
          emit(IncomingOrderDeclineSuccess(order: order));
          
          // Kirim notifikasi ke pengguna bahwa pesanan telah ditolak
          final String alasan = event.reason.isNotEmpty ? event.reason : 'Tidak tersedia';
          await _createNotificationUseCase(CreateNotificationParams(
            recipientUserId: order.userId,
            title: 'Pesanan Ditolak',
            body: 'Maaf, pesanan Anda untuk layanan ${order.serviceTitle ?? 'Jasa'} ditolak oleh penyedia jasa. Alasan: $alasan',
            type: 'order_update',
            relatedEntityType: 'order',
            relatedEntityId: order.id.toString(),
            mode: 'user' // Notifikasi untuk user mode
          ));
          
          // Setelah berhasil, muat ulang daftar pesanan masuk
          add(FetchIncomingOrders(providerId: event.providerId));
        },
      );
    } catch (e) {
      emit(IncomingOrderDeclineFailure(orderId: event.orderId, message: e.toString()));
    }
  }
}
