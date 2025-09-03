import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';
import 'dart:async';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/usecases/get_provider_summary_data_usecase.dart';
import 'package:logger/logger.dart';

part 'provider_summary_event.dart';
part 'provider_summary_state.dart';

class ProviderSummaryBloc extends Bloc<ProviderSummaryEvent, ProviderSummaryState> {
  final Logger _logger = Logger();
  final WatchProviderSummaryDataUseCase _watchProviderSummaryDataUseCase;
  StreamSubscription? _summarySubscription;

  ProviderSummaryBloc(
    this._watchProviderSummaryDataUseCase,
  ) : super(ProviderSummaryInitial()) {
    on<SubscribeToProviderSummary>(_onSubscribeToProviderSummary);
    on<RefreshProviderSummary>(_onRefreshProviderSummary);
    on<_ProviderSummaryUpdated>(_onProviderSummaryUpdated);
    on<_ProviderSummaryFailed>(_onProviderSummaryFailed);
  }

  Future<void> _onSubscribeToProviderSummary(
    SubscribeToProviderSummary event,
    Emitter<ProviderSummaryState> emit,
  ) async {
    _logger.i('Berlangganan ke provider summary dengan ID: ${event.providerId}');

    if (event.providerId.isEmpty) {
      _logger.e('Provider ID kosong');
      emit(const ProviderSummaryError(message: 'Provider ID tidak boleh kosong'));
      return;
    }

    emit(ProviderSummaryLoading(providerId: event.providerId));
    await _summarySubscription?.cancel();

    try {
      _summarySubscription = _watchProviderSummaryDataUseCase(
        GetProviderSummaryDataParams(providerId: event.providerId),
      ).listen(
        (either) => either.fold(
          (failure) {
            _logger.e('Gagal mendapatkan data: ${failure.message}');
            add(_ProviderSummaryFailed(failure.message, providerId: event.providerId));
          },
          (summaryData) {
            _logger.d('Data berhasil dimuat: $summaryData');
            add(_ProviderSummaryUpdated(summaryData, providerId: event.providerId));
          },
        ),
        onError: (error) {
          _logger.e('Error pada stream', error: error, stackTrace: StackTrace.current);
          add(_ProviderSummaryFailed('Terjadi kesalahan: ${error.toString()}',
              providerId: event.providerId));
        },
      );
    } catch (e) {
      _logger.e('Error saat setup subscription', error: e, stackTrace: StackTrace.current);
      emit(ProviderSummaryError(
          message: 'Gagal berlangganan data: ${e.toString()}',
          providerId: event.providerId));
    }
  }

  Future<void> _onRefreshProviderSummary(
    RefreshProviderSummary event,
    Emitter<ProviderSummaryState> emit,
  ) async {
    final providerId = event.providerId ?? state.providerId;
    _logger.i('Refresh data provider summary dengan ID: $providerId');

    try {
      if (providerId == null || providerId.isEmpty) {
        _logger.e('Provider ID kosong saat refresh');
        if (state is! ProviderSummaryLoaded) {
          emit(const ProviderSummaryError(message: 'Provider ID tidak boleh kosong'));
        }
        return;
      }

      final result = await _watchProviderSummaryDataUseCase(
        GetProviderSummaryDataParams(providerId: providerId),
      ).first;

      result.fold(
        (failure) {
          _logger.e('Gagal refresh data: ${failure.message}');
          if (state is! ProviderSummaryLoaded) {
            emit(ProviderSummaryError(
                message: failure.message, providerId: providerId));
          }
        },
        (summaryData) {
          _logger.i('Data berhasil di-refresh: $summaryData');
          emit(ProviderSummaryLoaded(
              summaryData: summaryData, providerId: providerId));
        },
      );
    } catch (e) {
      _logger.e('Error saat refresh', error: e, stackTrace: StackTrace.current);
      if (state is! ProviderSummaryLoaded) {
        emit(ProviderSummaryError(
            message: 'Gagal memuat data: ${e.toString()}', providerId: providerId));
      }
    } finally {
      if (event.completer?.isCompleted == false) {
        event.completer!.complete();
      }
    }
  }

  void _onProviderSummaryUpdated(
      _ProviderSummaryUpdated event, Emitter<ProviderSummaryState> emit) {
    emit(ProviderSummaryLoaded(
      summaryData: event.summaryData,
      providerId: event.providerId,
    ));
  }

  void _onProviderSummaryFailed(
      _ProviderSummaryFailed event, Emitter<ProviderSummaryState> emit) {
    emit(ProviderSummaryError(
      message: event.message,
      providerId: event.providerId,
    ));
  }

  @override
  Future<void> close() {
    _summarySubscription?.cancel();
    return super.close();
  }
}