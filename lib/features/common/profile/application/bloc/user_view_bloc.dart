import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/balance_realtime_subscription.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';
import 'user_view_mode.dart';
export 'user_view_mode.dart'; // Ekspor UserViewMode agar tersedia

part 'user_view_event.dart';
part 'user_view_state.dart';

class UserViewBloc extends Bloc<UserViewEvent, UserViewState> {
  final Logger _logger = Logger();
  final AuthBloc _authBloc;
  final SupabaseClient _supabaseClient;
  StreamSubscription<AuthState>? _authSubscription;
  
  // Subscription untuk pembaruan saldo secara real-time
  late final BalanceRealtimeSubscription _balanceSubscription;
  StreamSubscription<UserBalanceEntity>? _balanceStreamSubscription;

  UserViewBloc({
    required AuthBloc authBloc,
    required SupabaseClient supabaseClient,
  })  : _authBloc = authBloc,
        _supabaseClient = supabaseClient,
        super(const UserViewState()) {
    // Inisialisasi subscription saldo real-time
    _balanceSubscription = BalanceRealtimeSubscription(supabaseClient: supabaseClient);
    on<UserViewInitialize>(_onUserViewInitialize);
    on<_UserProviderStatusUpdated>(_onUserProviderStatusUpdated);
    on<UserViewSwitchModeRequested>(_onUserViewSwitchModeRequested);
    on<UserViewReset>(_onUserViewReset);
    on<UserViewUpdateBalance>(_onUserViewUpdateBalance);
    on<UserViewUpdateBalanceRealtime>(_onUserViewUpdateBalanceRealtime);

    _authSubscription = _authBloc.stream.listen((AuthState authState) {
      if (authState is AuthAuthenticated) {
        // Gunakan nilai role langsung dari database yang sudah diambil oleh repository
        add(UserViewInitialize(userId: authState.user.id, userRole: authState.user.role));
        
        // Mulai subscription saldo real-time saat user terautentikasi
        _startBalanceSubscription(authState.user.id);
      } else if (authState is AuthUnauthenticated) {
        add(UserViewReset());
        
        // Hentikan subscription saldo saat logout
        _stopBalanceSubscription();
      }
    });

    // Handle initial auth state if already authenticated when UserViewBloc is created
    final initialAuthState = _authBloc.state;
    if (initialAuthState is AuthAuthenticated) {
      // Gunakan nilai role langsung dari database yang sudah diambil oleh repository
      add(UserViewInitialize(userId: initialAuthState.user.id, userRole: initialAuthState.user.role));
      
      // Mulai subscription saldo real-time jika user sudah terautentikasi saat bloc dibuat
      _startBalanceSubscription(initialAuthState.user.id);
    }
  }

  Future<void> _onUserViewInitialize(
    UserViewInitialize event,
    Emitter<UserViewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, userRole: event.userRole, clearProviderStatus: true, clearFullName: true, clearAvatarUrl: true)); // Clear previous data
    try {
      // Ambil data profil dari tabel profiles (tanpa saldo)
      final profileResponse = await _supabaseClient
          .from('profiles')
          .select('provider_verification_status, full_name, avatar_url') // Tidak mengambil saldo dari profiles
          .eq('id', event.userId)
          .maybeSingle(); // Use maybeSingle to handle null case gracefully

      String? providerStatus;
      String? fullName;
      String? avatarUrl;
      double saldo = 0.0; // Inisialisasi dengan nilai default
      
      if (profileResponse != null && profileResponse.isNotEmpty) {
        providerStatus = profileResponse['provider_verification_status'] is String ? profileResponse['provider_verification_status'] as String : null;
        fullName = profileResponse['full_name'] is String ? profileResponse['full_name'] as String : null;
        avatarUrl = profileResponse['avatar_url'] is String ? profileResponse['avatar_url'] as String : null;
      }
      
      // Ambil saldo dari tabel user_balances (sumber data saldo yang benar)
      try {
        final balanceResponse = await _supabaseClient
            .from('user_balances')
            .select('balance')
            .eq('user_id', event.userId)
            .maybeSingle();
        
        if (balanceResponse != null && balanceResponse['balance'] != null) {
          if (balanceResponse['balance'] is num) {
            saldo = (balanceResponse['balance'] as num).toDouble();
          } else if (balanceResponse['balance'] is String) {
            saldo = double.tryParse(balanceResponse['balance'].toString()) ?? 0.0;
          }
          _logger.i('UserViewBloc: Saldo dari user_balances untuk ${event.userId}: $saldo');
        } else {
          _logger.w('UserViewBloc: Saldo tidak ditemukan di user_balances untuk ${event.userId}');
          // Set saldo default ke 0.0 jika tidak ditemukan di database
          saldo = 0.0;
          _logger.i('UserViewBloc: Menggunakan saldo default 0.0 untuk ${event.userId}');
        }
      } catch (balanceError) {
        _logger.e('UserViewBloc: Error mengambil saldo dari user_balances', error: balanceError);
        // Set saldo default ke 0.0 jika terjadi error saat mengambil dari database
        saldo = 0.0;
        _logger.i('UserViewBloc: Menggunakan saldo default 0.0 karena error untuk ${event.userId}');
      }
      
      add(_UserProviderStatusUpdated(providerStatus: providerStatus, fullName: fullName, avatarUrl: avatarUrl, saldo: saldo));
    } catch (e) {
      _logger.e('UserViewBloc: Error mengambil data profil', error: e);
      // Emit state with error or keep previous state but stop loading
      add(const _UserProviderStatusUpdated(providerStatus: null, fullName: null, avatarUrl: null, saldo: 0.0)); // Indicate error
    }
  }

  void _onUserProviderStatusUpdated(
    _UserProviderStatusUpdated event,
    Emitter<UserViewState> emit,
  ) {
    
    final bool isVerifiedProvider = event.providerStatus == 'verified';
    final bool isPendingVerification = event.providerStatus == 'pending';

    UserViewMode determinedInitialMode;
    // state.userRole diisi dari AuthBloc melalui UserViewInitialize event
    // Gunakan nilai role dari database: 'penyedia_jasa' atau 'pengguna_jasa'
    if (state.userRole == 'penyedia_jasa') {
        determinedInitialMode = UserViewMode.penyedia;
    } else if (state.userRole == 'pengguna_jasa' || state.userRole == 'user') {
        determinedInitialMode = UserViewMode.pengguna;
    } else {
        // Default jika peran tidak dikenali atau null, aman untuk mode pengguna
        _logger.w('UserViewBloc: Role tidak dikenali: ${state.userRole}, menggunakan mode pengguna sebagai default');
        determinedInitialMode = UserViewMode.pengguna;
    }
    
    

    emit(state.copyWith(
      providerStatus: event.providerStatus,
      isVerifiedProvider: isVerifiedProvider,
      isPendingVerification: isPendingVerification,
      currentViewMode: determinedInitialMode, // Gunakan mode awal berbasis peran
      fullName: event.fullName,
      avatarUrl: event.avatarUrl,
      saldo: event.saldo, // Tambahkan saldo ke state
      isLoading: false,
    ));
  }

  void _onUserViewSwitchModeRequested(
    UserViewSwitchModeRequested event,
    Emitter<UserViewState> emit,
  ) {
    // Allow switching to provider mode only if verified
    if (event.requestedMode == UserViewMode.penyedia && !state.isVerifiedProvider) {
      // Optionally, emit state with an error message or just ignore
      return;
    }
    
    emit(state.copyWith(currentViewMode: event.requestedMode));
  }

  void _onUserViewReset(
    UserViewReset event,
    Emitter<UserViewState> emit,
  ) {
    
    emit(const UserViewState().copyWith(clearProviderStatus: true, clearUserRole: true, clearFullName: true, clearAvatarUrl: true, clearSaldo: true)); // Reset to initial default state and ensure clearance
  }

  Future<void> _onUserViewUpdateBalance(
    UserViewUpdateBalance event,
    Emitter<UserViewState> emit,
  ) async {
    try {
      // Ambil saldo terbaru dari tabel user_balances (sumber data saldo yang benar)
      final response = await _supabaseClient
          .from('user_balances')
          .select('balance')
          .eq('user_id', event.userId)
          .maybeSingle();
      
      if (response != null && response.containsKey('balance')) {
        double updatedSaldo = 0.0;
        if (response['balance'] is num) {
          updatedSaldo = (response['balance'] as num).toDouble();
        } else if (response['balance'] is String) {
          updatedSaldo = double.tryParse(response['balance'].toString()) ?? 0.0;
        }
        
        _logger.i('UserViewBloc: Saldo diperbarui untuk ${event.userId}: $updatedSaldo');
        
        // Update state dengan saldo baru
        emit(state.copyWith(saldo: updatedSaldo));
      } else {
        _logger.w('UserViewBloc: Saldo tidak ditemukan di user_balances untuk ${event.userId}');
        // Set saldo default ke 0.0 jika tidak ditemukan di database
        _logger.i('UserViewBloc: Menggunakan saldo default 0.0 untuk ${event.userId}');
        emit(state.copyWith(saldo: 0.0));
      }
    } catch (e) {
      // Tangani error jika terjadi
      _logger.e('UserViewBloc: Error saat memperbarui saldo', error: e);
      // Set saldo default ke 0.0 jika terjadi error
      _logger.i('UserViewBloc: Menggunakan saldo default 0.0 karena error untuk ${event.userId}');
      emit(state.copyWith(saldo: 0.0));
    }
  }
  
  // Metode publik untuk memperbarui saldo secara real-time
  void refreshBalance(String userId) {
    add(UserViewUpdateBalance(userId: userId));
  }
  
  // Handler untuk event pembaruan saldo secara real-time dari subscription
  void _onUserViewUpdateBalanceRealtime(
    UserViewUpdateBalanceRealtime event,
    Emitter<UserViewState> emit,
  ) {
    // Pastikan saldo tidak pernah null
    final double safeBalance = event.newBalance;
    _logger.i('UserViewBloc: Memperbarui saldo dari real-time subscription: $safeBalance');
    emit(state.copyWith(saldo: safeBalance));
  }

  // Metode untuk memulai subscription saldo real-time
  void _startBalanceSubscription(String userId) {
    _logger.i('UserViewBloc: Memulai subscription saldo real-time untuk user $userId');
    
    // Hentikan subscription sebelumnya jika ada
    _stopBalanceSubscription();
    
    // Mulai subscription baru
    _balanceSubscription.subscribeToUserBalance(userId);
    
    // Dengarkan perubahan saldo secara real-time
    _balanceStreamSubscription = _balanceSubscription.balanceStream.listen((updatedBalance) {
      _logger.i('UserViewBloc: Menerima update saldo real-time: ${updatedBalance.balance}');
      // Gunakan event untuk update saldo, bukan emit langsung
      add(UserViewUpdateBalanceRealtime(updatedBalance.balance));
    });
  }
  
  // Metode untuk menghentikan subscription saldo real-time
  void _stopBalanceSubscription() {
    _logger.i('UserViewBloc: Menghentikan subscription saldo real-time');
    _balanceStreamSubscription?.cancel();
    _balanceStreamSubscription = null;
    _balanceSubscription.unsubscribe();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _stopBalanceSubscription();
    _balanceSubscription.dispose();
    return super.close();
  }
}
