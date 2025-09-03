import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Hanya ini yang diperlukan untuk initializeDateFormatting
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/config/supabase_config.dart';
import 'package:klik_jasa/firebase_options.dart';
import 'package:klik_jasa/app.dart';
import 'package:klik_jasa/features/common/notifications/presentation/services/notification_service.dart';
import 'package:klik_jasa/injection_container.dart'
    as di; // Import service locator
import 'package:logger/logger.dart';


Future<void> main() async {
  final logger = Logger();
  WidgetsFlutterBinding.ensureInitialized(); // Cukup satu kali

  try {
    await initializeDateFormatting(
      'id_ID',
      null,
    ); // Inisialisasi untuk format tanggal Indonesia
    logger.i('Date formatting initialized for id_ID.');

    // Inisialisasi Firebase (dengan penanganan duplicate app)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('Firebase initialized successfully.');
      
      logger.i('Firebase Core initialized successfully.');
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        logger.i('Firebase already initialized, using existing instance.');
        logger.i('Firebase already initialized, using existing instance.');
      } else {
        logger.e('Firebase initialization failed: $e');
        rethrow;
      }
    }

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    logger.i('Supabase initialized successfully.');
    logger.d(
        'Current Supabase User after init: ${Supabase.instance.client.auth.currentUser?.email ?? "Not logged in"}');

    // Inisialisasi Service Locator
    await di.init();
    logger.i('Service Locator initialized successfully.');

    // Buat GlobalKey untuk ScaffoldMessenger
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
        GlobalKey<ScaffoldMessengerState>();

    // Inisialisasi NotificationService dengan GlobalKey (async)
    await NotificationService().initialize(scaffoldMessengerKey);
    logger.i('NotificationService initialized.');

    runApp(App(scaffoldMessengerKey: scaffoldMessengerKey));
  } catch (e, stackTrace) {
    logger.f(
      'FATAL: Error during app initialization',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
