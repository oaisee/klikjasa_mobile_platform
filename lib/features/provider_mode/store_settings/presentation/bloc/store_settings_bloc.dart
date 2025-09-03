import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/usecases/get_store_settings_usecase.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/usecases/update_store_settings_usecase.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/usecases/update_store_status_usecase.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/presentation/bloc/store_settings_event.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/presentation/bloc/store_settings_state.dart';

class StoreSettingsBloc extends Bloc<StoreSettingsEvent, StoreSettingsState> {
  final GetStoreSettingsUseCase getStoreSettings;
  final UpdateStoreSettingsUseCase updateStoreSettings;
  final UpdateStoreStatusUseCase updateStoreStatus;

  StoreSettingsEntity? _currentSettings;

  StoreSettingsBloc({
    required this.getStoreSettings,
    required this.updateStoreSettings,
    required this.updateStoreStatus,
  }) : super(StoreSettingsInitial()) {
    on<GetStoreSettingsEvent>(_onGetStoreSettings);
    on<UpdateStoreSettingsEvent>(_onUpdateStoreSettings);
    on<UpdateStoreStatusEvent>(_onUpdateStoreStatus);
    on<UpdateOperationalHoursEvent>(_onUpdateOperationalHours);
    on<UpdateServiceRadiusEvent>(_onUpdateServiceRadius);
    on<UpdateStoreLocationEvent>(_onUpdateStoreLocation);
    on<UpdateAutoAcceptOrdersEvent>(_onUpdateAutoAcceptOrders);
    on<UpdateShowDistanceEvent>(_onUpdateShowDistance);
    on<UpdateReceiveNotificationsEvent>(_onUpdateReceiveNotifications);
  }

  Future<void> _onGetStoreSettings(
      GetStoreSettingsEvent event, Emitter<StoreSettingsState> emit) async {
    emit(StoreSettingsLoading());
    
    final result = await getStoreSettings(event.providerId);
    
    result.fold(
      (failure) => emit(StoreSettingsError(message: failure.message)),
      (settings) {
        _currentSettings = settings;
        emit(StoreSettingsLoaded(settings: settings));
      },
    );
  }

  Future<void> _onUpdateStoreSettings(
      UpdateStoreSettingsEvent event, Emitter<StoreSettingsState> emit) async {
    emit(StoreSettingsUpdating());
    
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: event.settings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = event.settings;
        emit(const StoreSettingsUpdateSuccess(message: 'Pengaturan toko berhasil disimpan'));
        emit(StoreSettingsLoaded(settings: event.settings));
      },
    );
  }

  Future<void> _onUpdateStoreStatus(
      UpdateStoreStatusEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    final result = await updateStoreStatus(UpdateStoreStatusParams(
      providerId: event.providerId,
      isActive: event.isActive,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        final updatedSettings = _currentSettings!.copyWith(isStoreActive: event.isActive);
        _currentSettings = updatedSettings;
        
        final statusMessage = event.isActive 
            ? 'Toko berhasil diaktifkan'
            : 'Toko berhasil dinonaktifkan';
        
        emit(StoreSettingsUpdateSuccess(message: statusMessage));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }

  Future<void> _onUpdateOperationalHours(
      UpdateOperationalHoursEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    // Buat salinan dari jam operasional saat ini
    final Map<String, OperationalHourEntity> updatedHours = 
        Map.from(_currentSettings!.operationalHours);
    
    // Perbarui jam operasional untuk hari tertentu
    updatedHours[event.day] = event.hours;
    
    // Buat pengaturan toko yang diperbarui
    final updatedSettings = _currentSettings!.copyWith(operationalHours: updatedHours);
    
    // Simpan pengaturan yang diperbarui
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: updatedSettings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = updatedSettings;
        emit(const StoreSettingsUpdateSuccess(message: 'Jam operasional berhasil diperbarui'));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }

  Future<void> _onUpdateServiceRadius(
      UpdateServiceRadiusEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    // Buat pengaturan toko yang diperbarui
    final updatedSettings = _currentSettings!.copyWith(serviceRadius: event.radius);
    
    // Simpan pengaturan yang diperbarui
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: updatedSettings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = updatedSettings;
        emit(const StoreSettingsUpdateSuccess(message: 'Radius layanan berhasil diperbarui'));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }

  Future<void> _onUpdateStoreLocation(
      UpdateStoreLocationEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    // Buat pengaturan toko yang diperbarui
    final updatedSettings = _currentSettings!.copyWith(
      storeAddress: event.address,
      latitude: event.latitude,
      longitude: event.longitude,
    );
    
    // Simpan pengaturan yang diperbarui
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: updatedSettings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = updatedSettings;
        emit(const StoreSettingsUpdateSuccess(message: 'Lokasi toko berhasil diperbarui'));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }

  Future<void> _onUpdateAutoAcceptOrders(
      UpdateAutoAcceptOrdersEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    // Buat pengaturan toko yang diperbarui
    final updatedSettings = _currentSettings!.copyWith(autoAcceptOrders: event.autoAccept);
    
    // Simpan pengaturan yang diperbarui
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: updatedSettings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = updatedSettings;
        
        final statusMessage = event.autoAccept 
            ? 'Auto-accept pesanan diaktifkan'
            : 'Auto-accept pesanan dinonaktifkan';
        
        emit(StoreSettingsUpdateSuccess(message: statusMessage));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }

  Future<void> _onUpdateShowDistance(
      UpdateShowDistanceEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    // Buat pengaturan toko yang diperbarui
    final updatedSettings = _currentSettings!.copyWith(showDistance: event.showDistance);
    
    // Simpan pengaturan yang diperbarui
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: updatedSettings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = updatedSettings;
        
        final statusMessage = event.showDistance 
            ? 'Tampilkan jarak pelanggan diaktifkan'
            : 'Tampilkan jarak pelanggan dinonaktifkan';
        
        emit(StoreSettingsUpdateSuccess(message: statusMessage));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }

  Future<void> _onUpdateReceiveNotifications(
      UpdateReceiveNotificationsEvent event, Emitter<StoreSettingsState> emit) async {
    if (_currentSettings == null) {
      emit(const StoreSettingsUpdateError(message: 'Data toko belum dimuat'));
      return;
    }
    
    emit(StoreSettingsUpdating());
    
    // Buat pengaturan toko yang diperbarui
    final updatedSettings = _currentSettings!.copyWith(receiveNotifications: event.receiveNotifications);
    
    // Simpan pengaturan yang diperbarui
    final result = await updateStoreSettings(UpdateStoreSettingsParams(
      providerId: event.providerId,
      settings: updatedSettings,
    ));
    
    result.fold(
      (failure) => emit(StoreSettingsUpdateError(message: failure.message)),
      (success) {
        _currentSettings = updatedSettings;
        
        final statusMessage = event.receiveNotifications 
            ? 'Notifikasi pesanan diaktifkan'
            : 'Notifikasi pesanan dinonaktifkan';
        
        emit(StoreSettingsUpdateSuccess(message: statusMessage));
        emit(StoreSettingsLoaded(settings: updatedSettings));
      },
    );
  }
}
