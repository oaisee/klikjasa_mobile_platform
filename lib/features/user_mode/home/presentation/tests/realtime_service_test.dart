import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';

/// File ini untuk membantu pengujian fungsionalitas realtime streaming layanan
/// Penggunaan:
/// 1. Jalankan aplikasi di device/emulator
/// 2. Buka halaman beranda dan pilih tab "Untuk Anda"
/// 3. Buka terminal atau aplikasi Supabase Studio dan lakukan perubahan data di tabel services
/// 4. Perhatikan UI beranda, data seharusnya diperbarui secara otomatis tanpa loading spinner
/// 
/// Catatan validasi:
/// - Ketika data berubah di tabel services, UI harus memperbarui data tanpa loading spinner
/// - Perubahan pada data promosi layanan harus terlihat pada tab Populer
/// - Perubahan pada rating layanan harus terlihat pada tab rating tertinggi
/// - Perubahan lokasi layanan harus terlihat pada tab lokasi (Untuk Anda)
/// 
/// Cara pengujian via Supabase SQL Editor:
/// 1. UPDATE services SET title = 'Layanan Baru - [timestamp]' WHERE id = [id_layanan]
/// 2. UPDATE services SET rating = 5.0 WHERE id = [id_layanan]
/// 3. UPDATE services SET promotion_start_date = NOW(), promotion_end_date = NOW() + INTERVAL '7 days' WHERE id = [id_layanan]

/// Kelas helper untuk memantau perubahan state ServiceLocationCubit
class ServiceRealtimeMonitor extends StatelessWidget {
  const ServiceRealtimeMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceLocationCubit, ServiceLocationState>(
      listener: (context, state) {
        if (state is ServiceLocationLoaded && state.isRealtimeUpdate) {
          AppMessageUtils.showSnackbar(
            context: context,
            message: 'Data layanan diperbarui secara realtime! ${DateTime.now()}',
            type: MessageType.success,
            duration: const Duration(seconds: 3),
          );
        }
      },
      child: const SizedBox.shrink(),
    );
  }
}

/// Metode untuk menguji koneksi realtime manual menggunakan Supabase client
Future<void> testRealtimeConnection(SupabaseClient supabase) async {
  try {
    final channel = supabase.channel('public:services');
    channel
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'services',
            callback: (payload) {
              debugPrint('Realtime change detected: ${payload.toString()}');
              debugPrint('Event type: ${payload.eventType}');
              debugPrint('Data: ${payload.newRecord}');
              // Di sini dapat ditambahkan notifikasi visual saat perubahan terdeteksi
            })
        .subscribe();

    debugPrint('Realtime subscription aktif dan mendengarkan perubahan...');
  } catch (e) {
    debugPrint('Error koneksi realtime: $e');
  }
}
