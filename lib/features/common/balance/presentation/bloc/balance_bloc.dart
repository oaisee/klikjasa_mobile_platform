import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/get_user_balance_usecase.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'dart:async';

part 'balance_event.dart';
part 'balance_state.dart';

// Event internal untuk menangani perubahan status autentikasi
class _AuthUserChanged extends BalanceEvent {
  final String? userId; // Bisa null jika logout
  const _AuthUserChanged(this.userId);

  @override
  List<Object> get props {
    if (userId == null) {
      return [];
    }
    return [userId!];
  }
}

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final GetUserBalanceUsecase getUserBalanceUsecase;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;
  String? _currentUserId;

  BalanceBloc({required this.getUserBalanceUsecase, required this.authBloc}) : super(BalanceInitial()) {
    on<FetchBalanceEvent>(_onFetchBalanceEvent);
    on<_AuthUserChanged>(_onAuthUserChanged); // Tambahkan handler untuk event internal

    _authSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        add(_AuthUserChanged(_currentUserId)); // Kirim userId
        add(FetchBalanceEvent(userId: _currentUserId!)); // Tetap fetch balance
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = null;
        add(_AuthUserChanged(null)); // Kirim null untuk userId
      }
    });

    final initialAuthState = authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      _currentUserId = initialAuthState.user.id;
      add(FetchBalanceEvent(userId: _currentUserId!));
    }
  }

  Future<void> _onFetchBalanceEvent(
    FetchBalanceEvent event,
    Emitter<BalanceState> emit,
  ) async {
    emit(BalanceLoading());
    try {
      final userBalanceResult = await getUserBalanceUsecase(event.userId);
      userBalanceResult.fold(
        (failure) => emit(BalanceError(message: failure.message)),
        (userBalance) => emit(BalanceLoaded(userBalance: userBalance)),
      );
    } catch (e) {
      emit(BalanceError(message: e.toString()));
    }
  }

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<BalanceState> emit) {
    if (event.userId == null) {
      // Jika user logout (userId null), reset ke BalanceInitial
      emit(BalanceInitial());
    } else {
      // Jika user login/berubah, state loading mungkin sudah ditangani oleh FetchBalanceEvent
      // Namun, jika ada logika state lain yang spesifik saat user berubah (selain fetching), bisa ditambahkan di sini.
      // Untuk saat ini, jika userId tidak null, kita asumsikan FetchBalanceEvent akan dipanggil.
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
