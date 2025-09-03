import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/get_provider_orders_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/update_order_status_usecase.dart';
import 'package:logger/logger.dart';

part 'provider_orders_event.dart';
part 'provider_orders_state.dart';

class ProviderOrdersBloc extends Bloc<ProviderOrdersEvent, ProviderOrdersState> {
  final Logger _logger = Logger();
  final GetProviderOrdersUseCase _getProviderOrdersUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;

  ProviderOrdersBloc({
    required GetProviderOrdersUseCase getProviderOrdersUseCase,
    required UpdateOrderStatusUseCase updateOrderStatusUseCase,
  })  : _getProviderOrdersUseCase = getProviderOrdersUseCase,
        _updateOrderStatusUseCase = updateOrderStatusUseCase,
        super(ProviderOrdersInitial()) {
    on<FetchAllProviderOrders>(_onFetchAllProviderOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
  }

  Future<void> _onFetchAllProviderOrders(
    FetchAllProviderOrders event,
    Emitter<ProviderOrdersState> emit,
  ) async {
    _logger.d('Memulai fetch semua pesanan provider ${event.providerId}');
    emit(ProviderOrdersLoading());
    try {
      // Status untuk tab Aktif
      final activeStatuses = [
        'pending_confirmation',
        'accepted_by_provider',
        'in_progress',
      ];
      
      // Status untuk tab Selesai
      final completedStatuses = [
        'completed_by_provider',
        'completed_by_provider',
      ];
      
      // Status untuk tab Dibatalkan (semua jenis pembatalan dan penolakan)
      final cancelledStatuses = [
        'cancelled_by_user',
        'cancelled_by_provider',
        'rejected_by_provider',
        'cancelled', // untuk kompatibilitas dengan data lama
        'rejected',  // untuk kompatibilitas dengan data lama
      ];
      
      // Gabungkan semua status yang perlu diambil
      final statusesToFetch = [
        ...activeStatuses,
        ...completedStatuses,
        ...cancelledStatuses,
      ];

      _logger.d('Akan mengambil pesanan dengan status: $statusesToFetch');

      // Mengambil semua data secara paralel
      final results = await Future.wait(statusesToFetch.map((status) {
        _logger.d('Mengambil pesanan dengan status: $status');
        return _getProviderOrdersUseCase(
          GetProviderOrdersParams(providerId: event.providerId, status: status),
        );
      }));

      final Map<String, List<Order>> allOrders = {};
      bool hasError = false;
      String errorMessage = '';
      _logger.d('Jumlah hasil query: ${results.length}');

      for (int i = 0; i < results.length; i++) {
        results[i].fold(
          (failure) {
            hasError = true;
            errorMessage = failure.message;
            _logger.e('Error saat mengambil pesanan dengan status ${statusesToFetch[i]}: ${failure.message}');
          },
          (orders) {
            allOrders[statusesToFetch[i]] = orders;
            _logger.d('Berhasil mengambil ${orders.length} pesanan dengan status ${statusesToFetch[i]}');
            if (statusesToFetch[i] == 'pending_confirmation' && orders.isNotEmpty) {
              _logger.d('Contoh data pesanan pending_confirmation pertama: ${orders.first}');
            }
          },
        );
        if (hasError) break;
      }

      if (hasError) {
        emit(ProviderOrdersError(message: errorMessage));
      } else {
        emit(ProviderOrdersLoaded(allOrders: allOrders));
      }
    } catch (e) {
      emit(ProviderOrdersError(message: e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<ProviderOrdersState> emit,
  ) async {
    // Simpan state sebelumnya untuk recovery jika terjadi error
    final previousState = state;
    Map<String, List<Order>>? previousOrders;
    
    if (previousState is ProviderOrdersLoaded) {
      previousOrders = previousState.allOrders;
    }
    
    try {
      // Emit loading state untuk UI feedback
      if (state is ProviderOrdersLoaded) {
        emit(ProviderOrdersUpdating(
          allOrders: (state as ProviderOrdersLoaded).allOrders,
          orderId: event.orderId,
        ));
      }
      
      // Mengkonversi string status ke enum OrderStatus
      final statusEnum = parseOrderStatus(event.newStatus);
      
      // Validasi status enum - jika unknown, tampilkan error
      if (statusEnum == OrderStatus.unknown) {
        throw Exception('Status pesanan tidak valid: ${event.newStatus}');
      }
      
      // Log untuk debugging
      _logger.i('Updating order ${event.orderId} status to: ${event.newStatus} (enum: $statusEnum)');

      final result = await _updateOrderStatusUseCase(
        UpdateOrderStatusParams(
          orderId: event.orderId.toString(),
          newStatus: statusEnum,
        ),
      );

      result.fold(
        (failure) {
          // Jika gagal, emit error dengan pesan yang lebih jelas dan informatif
          String errorMessage = 'Gagal memuat pesanan provider: ${failure.message}';
          
          // Deteksi error saldo tidak cukup
          if (failure.message.toLowerCase().contains('saldo tidak mencukupi') || 
              failure.message.toLowerCase().contains('saldo tidak cukup')) {
            errorMessage = 'INSUFFICIENT_BALANCE:${failure.message}';
            _logger.w('Error saldo tidak cukup: ${failure.message}');
          } else {
            _logger.e('Error updating order status: $errorMessage');
          }
          
          emit(ProviderOrdersError(message: errorMessage));
          
          // Kembali ke state sebelumnya
          if (previousOrders != null) {
            emit(ProviderOrdersLoaded(allOrders: previousOrders));
          }
        },
        (updatedOrder) {
          // Jika berhasil, refresh semua data
          _logger.i('Successfully updated order ${event.orderId} status to ${event.newStatus}');
          add(FetchAllProviderOrders(providerId: event.providerId));
        },
      );
    } catch (e) {
      // Tangani exception yang tidak terduga dengan pesan yang lebih jelas
      String errorMessage = 'Error: Gagal memperbarui status pesanan: ${e.toString()}';
      
      // Deteksi error saldo tidak cukup
      if (e.toString().toLowerCase().contains('saldo tidak mencukupi') || 
          e.toString().toLowerCase().contains('saldo tidak cukup')) {
        errorMessage = 'INSUFFICIENT_BALANCE:${e.toString()}';
        _logger.w('Error saldo tidak cukup: ${e.toString()}');
      } else {
        _logger.e('Exception in _onUpdateOrderStatus: $errorMessage', error: e, stackTrace: StackTrace.current);
      }
      
      emit(ProviderOrdersError(message: errorMessage));
      
      // Kembali ke state sebelumnya jika ada
      if (previousOrders != null) {
        emit(ProviderOrdersLoaded(allOrders: previousOrders));
      }
    }
  }
}

