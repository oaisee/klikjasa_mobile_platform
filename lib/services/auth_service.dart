import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<AppUser?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', authUser.id)
          .single();

      return AppUser.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) throw Exception('User not found');

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    try {
      // 1. Daftarkan user di Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) throw Exception('User not found');
      
      try {
        // 2. Coba buat profil user di tabel users
        // Cek struktur tabel terlebih dahulu
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'role': 'pengguna_jasa',
            'created_at': DateTime.now().toIso8601String(),
            // Kolom saldo dihapus karena tidak ada di tabel
          });
        } catch (insertError) {
          print('Error inserting user: $insertError');
          // Coba dengan struktur minimal jika masih error
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
          });
        }
      } catch (profileError) {
        print('Error creating user profile: $profileError');
        // Jika gagal membuat profil, cek apakah profil sudah ada
        final existingProfile = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
            
        if (existingProfile == null) {
          // Jika tidak ada profil, throw error
          throw Exception('Gagal membuat profil pengguna');
        }
        // Jika profil sudah ada, lanjutkan proses
      }

      // 3. Return AppUser object
      // Buat objek AppUser dengan nilai default
      return AppUser(
        id: response.user!.id,
        email: email,
        name: name,
        role: 'pengguna_jasa',
        saldo: 0, // Default saldo = 0 di aplikasi meskipun kolom tidak ada di database
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
