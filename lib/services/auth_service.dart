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

  Future<AppUser> updateProfile({
    required String userId, 
    required String name, 
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      print('Updating profile for user: $userId');
      print('Name: $name');
      print('Phone: $phoneNumber');
      print('Profile Image URL: $profileImageUrl');
      
      // Periksa struktur tabel users terlebih dahulu
      final tableInfo = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
          
      print('User table structure: ${tableInfo.keys.toList()}');
      
      // Buat map untuk update dengan nama kolom yang benar
      final updateData = <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Tambahkan field opsional jika ada dengan nama kolom yang benar
      if (phoneNumber != null) {
        if (tableInfo.containsKey('phone_number')) {
          updateData['phone_number'] = phoneNumber;
        } else if (tableInfo.containsKey('phoneNumber')) {
          updateData['phoneNumber'] = phoneNumber;
        } else {
          // Default
          updateData['phone'] = phoneNumber;
        }
      }
      
      if (profileImageUrl != null) {
        if (tableInfo.containsKey('profile_image_url')) {
          updateData['profile_image_url'] = profileImageUrl;
        } else if (tableInfo.containsKey('profileImageUrl')) {
          updateData['profileImageUrl'] = profileImageUrl;
        } else if (tableInfo.containsKey('avatar_url')) {
          updateData['avatar_url'] = profileImageUrl;
        } else {
          // Default
          updateData['profile_url'] = profileImageUrl;
        }
      }
      
      print('Update data: $updateData');
      
      // Update user profile in users table
      final response = await _supabase.from('users')
          .update(updateData)
          .eq('id', userId);
          
      print('Update response: $response');

      // Fetch updated user data
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
          
      print('Updated user data: $userData');

      return AppUser.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      print('Error updating profile: $e');
      // Tampilkan error detail untuk debugging
      if (e is PostgrestException) {
        print('PostgrestException details:');
        print('Message: ${e.message}');
        print('Code: ${e.code}');
        print('Details: ${e.details}');
        print('Hint: ${e.hint}');
      }
      rethrow;
    }
  }

  // Mendapatkan nama kolom yang benar di tabel provider_verifications
  Future<Map<String, String>> _getProviderVerificationColumns() async {
    try {
      // Coba dapatkan struktur tabel dengan cara yang berbeda
      final result = await _supabase.rpc('get_table_columns', params: {'table_name': 'provider_verifications'});
      print('Table columns from RPC: $result');
      
      // Jika RPC gagal, gunakan pendekatan alternatif
      if (result == null) {
        // Coba buat verifikasi dummy untuk mengetahui struktur tabel
        try {
          final dummyData = {
            'user_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
            'status': 'dummy',
          };
          
          await _supabase.from('provider_verifications').insert(dummyData);
          print('Created dummy verification to detect schema');
        } catch (e) {
          print('Error creating dummy verification: $e');
        }
      }
      
      // Coba dapatkan data dari tabel
      final tableData = await _supabase
          .from('provider_verifications')
          .select()
          .limit(1)
          .maybeSingle();
          
      print('Provider verification table data: $tableData');
      
      // Mapping untuk nama kolom yang mungkin berbeda
      final Map<String, String> columnMapping = {
        'user_id': 'user_id',
        'phone': 'phone',
        'phone_number': 'phone_number',
        'phoneNumber': 'phoneNumber',
        'address': 'address',
        'ktp_url': 'ktp_url',
        'ktp_image_url': 'ktp_image_url',
        'ktpImageUrl': 'ktpImageUrl',
        'ktp_image': 'ktp_image',
        'status': 'status',
      };
      
      // Jika ada data, gunakan untuk mendeteksi kolom yang ada
      if (tableData != null) {
        final keys = tableData.keys.toList();
        print('Detected columns: $keys');
        
        // Update mapping berdasarkan kolom yang terdeteksi
        for (final expectedCol in columnMapping.keys.toList()) {
          bool found = false;
          for (final actualCol in keys) {
            if (actualCol.toLowerCase() == expectedCol.toLowerCase() ||
                actualCol.replaceAll('_', '') == expectedCol.replaceAll('_', '')) {
              columnMapping[expectedCol] = actualCol;
              found = true;
              break;
            }
          }
          if (!found) {
            // Hapus mapping untuk kolom yang tidak ada
            columnMapping.remove(expectedCol);
          }
        }
      }
      
      print('Final column mapping: $columnMapping');
      return columnMapping;
    } catch (e) {
      print('Error detecting provider verification columns: $e');
      // Default mapping jika gagal mendeteksi
      return {
        'user_id': 'user_id',
        'phone': 'phone',
        'address': 'address',
        'ktp_url': 'ktp_url',
        'status': 'status',
      };
    }
  }
  
  Future<void> registerAsProvider({required String userId, required String phoneNumber, required String address, String? ktpImageUrl}) async {
    try {
      // Dapatkan mapping kolom yang benar
      final columnMapping = await _getProviderVerificationColumns();
      print('Using column mapping: $columnMapping');
      
      // Periksa apakah sudah ada verifikasi yang pending untuk user ini
      final existingVerification = await _supabase
          .from('provider_verifications')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();
      
      // Buat map data untuk insert/update dengan nama kolom yang benar
      final Map<String, dynamic> verificationData = {
        'user_id': userId,
        'status': 'pending', // pending, approved, rejected
      };
      
      // Tambahkan nomor telepon dengan nama kolom yang benar
      if (columnMapping.containsKey('phone_number')) {
        verificationData[columnMapping['phone_number']!] = phoneNumber;
      } else if (columnMapping.containsKey('phoneNumber')) {
        verificationData[columnMapping['phoneNumber']!] = phoneNumber;
      } else if (columnMapping.containsKey('phone')) {
        verificationData[columnMapping['phone']!] = phoneNumber;
      } else {
        // Jika tidak ada kolom untuk nomor telepon, simpan di data tambahan
        verificationData['data'] = {'phone': phoneNumber};
        print('Warning: No phone column found, storing in data JSON field');
      }
      
      // Tambahkan alamat dengan nama kolom yang benar
      if (columnMapping.containsKey('address')) {
        verificationData[columnMapping['address']!] = address;
      } else {
        // Jika tidak ada kolom untuk alamat, simpan di data tambahan
        if (verificationData.containsKey('data')) {
          (verificationData['data'] as Map<String, dynamic>)['address'] = address;
        } else {
          verificationData['data'] = {'address': address};
        }
        print('Warning: No address column found, storing in data JSON field');
      }
      
      // Tambahkan KTP image URL jika ada dengan nama kolom yang benar
      if (ktpImageUrl != null) {
        if (columnMapping.containsKey('ktp_image_url')) {
          verificationData[columnMapping['ktp_image_url']!] = ktpImageUrl;
        } else if (columnMapping.containsKey('ktpImageUrl')) {
          verificationData[columnMapping['ktpImageUrl']!] = ktpImageUrl;
        } else if (columnMapping.containsKey('ktp_url')) {
          verificationData[columnMapping['ktp_url']!] = ktpImageUrl;
        } else if (columnMapping.containsKey('ktp_image')) {
          verificationData[columnMapping['ktp_image']!] = ktpImageUrl;
        } else {
          // Jika tidak ada kolom untuk KTP, simpan di data tambahan
          if (verificationData.containsKey('data')) {
            (verificationData['data'] as Map<String, dynamic>)['ktp_url'] = ktpImageUrl;
          } else {
            verificationData['data'] = {'ktp_url': ktpImageUrl};
          }
          print('Warning: No KTP image column found, storing in data JSON field');
        }
      }
      
      // Coba simpan data ke Supabase
      try {
        if (existingVerification != null) {
          // Update verifikasi yang ada
          verificationData['updated_at'] = DateTime.now().toIso8601String();
          
          await _supabase
              .from('provider_verifications')
              .update(verificationData)
              .eq('user_id', userId)
              .eq('status', 'pending');
              
          print('Updated existing provider verification for user: $userId');
        } else {
          // Buat permintaan verifikasi penyedia baru
          verificationData['created_at'] = DateTime.now().toIso8601String();
          
          await _supabase
              .from('provider_verifications')
              .insert(verificationData);
          
          print('Created new provider verification for user: $userId');
        }
      } catch (insertError) {
        print('Error saving provider verification: $insertError');
        
        // Jika gagal, coba dengan minimal data yang diperlukan
        final minimalData = {
          'user_id': userId,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        };
        
        await _supabase
            .from('provider_verifications')
            .insert(minimalData);
            
        print('Created provider verification with minimal data');
      }
      
      // Update role user menjadi pending_provider jika belum
      try {
        final userData = await _supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .single();
            
        if (userData['role'] == 'pengguna_jasa') {
          await _supabase
              .from('users')
              .update({
                'role': 'pending_provider',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', userId);
              
          print('Updated user role to pending_provider for user: $userId');
        }
      } catch (roleError) {
        print('Error updating user role: $roleError');
        // Lanjutkan meskipun gagal update role
      }
    } catch (e) {
      print('Error registering as provider: $e');
      // Tampilkan error detail untuk debugging
      if (e is PostgrestException) {
        print('PostgrestException details:');
        print('Message: ${e.message}');
        print('Code: ${e.code}');
        print('Details: ${e.details}');
        print('Hint: ${e.hint}');
      }
      rethrow;
    }
  }
}
