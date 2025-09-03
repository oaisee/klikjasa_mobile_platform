import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/cubit/admin_drawer_state.dart';

/// Cubit untuk mengelola state drawer pada halaman admin
class AdminDrawerCubit extends Cubit<AdminDrawerState> {
  AdminDrawerCubit() : super(const AdminDrawerClosed());

  /// Membuka drawer
  void openDrawer() {
    emit(const AdminDrawerOpened());
  }

  /// Menutup drawer
  void closeDrawer() {
    emit(const AdminDrawerClosed());
  }

  /// Toggle status drawer
  void toggleDrawer() {
    if (state is AdminDrawerOpened) {
      closeDrawer();
    } else {
      openDrawer();
    }
  }

  /// Mendapatkan status drawer (apakah terbuka atau tidak)
  bool isDrawerOpen() {
    return state is AdminDrawerOpened;
  }
}
