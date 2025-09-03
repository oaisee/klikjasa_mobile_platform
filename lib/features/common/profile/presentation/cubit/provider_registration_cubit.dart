import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/kabupaten_kota.dart';
import 'package:klik_jasa/features/common/profile/presentation/cubit/provider_registration_state.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';

/// Cubit untuk mengelola state registrasi provider
class ProviderRegistrationCubit extends Cubit<ProviderRegistrationState> {
  final SupabaseClient _supabase;
  final ImagePicker _picker;
  final Logger _logger;

  ProviderRegistrationCubit({
    required SupabaseClient supabase,
    required ImagePicker picker,
    required Logger logger,
  }) : _supabase = supabase,
       _picker = picker,
       _logger = logger,
       super(const ProviderRegistrationState());

  /// Memuat profil pengguna saat ini
  Future<void> loadUserProfile() async {
    emit(state.copyWith(isLoadingProfile: true));

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(
          state.copyWith(
            isLoadingProfile: false,
            errorMessage: 'User tidak ditemukan',
          ),
        );
        return;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final userProfile = response;

      // Cek status provider
      String? providerStatus;
      if (userProfile['is_provider'] == true) {
        providerStatus =
            userProfile['provider_verification_status'] ?? 'pending';
      }

      emit(
        state.copyWith(
          userProfile: userProfile,
          providerStatus: providerStatus,
          isLoadingProfile: false,
        ),
      );

      _logger.i('User profile loaded successfully');
    } catch (e) {
      _logger.e('Error loading user profile: $e');
      emit(
        state.copyWith(
          isLoadingProfile: false,
          errorMessage: 'Gagal memuat profil pengguna: ${e.toString()}',
        ),
      );
    }
  }

  /// Memuat daftar kabupaten/kota berdasarkan provinsi domisili user
  Future<void> loadKabupatenKota() async {
    emit(state.copyWith(isKabupatenKotaLoading: true));

    try {
      // Ambil provinsi dari profil user jika belum diambil
      if (state.userProfile == null) {
        await loadUserProfile();
      }

      // Ambil provinsi dari profil user
      final Map<String, dynamic>? userProfile = state.userProfile;
      _logger.i('User profile data: $userProfile');
      
      final String? provinsiUser = userProfile?['provinsi'];
      _logger.i('Provinsi user dari profil: $provinsiUser');

      // Query kabupaten/kota
      final response = await _supabase
          .from('kabupaten_kota')
          .select()
          .order('nama');

      final List<dynamic> data = response as List<dynamic>;
      List<KabupatenKota> kabupatenKotaList = data
          .map((item) => KabupatenKota.fromJson(item as Map<String, dynamic>))
          .toList();

      try {
        // Jika user belum memiliki provinsi, gunakan default provinsi DKI Jakarta
        String provinsiToUse = provinsiUser ?? 'DKI JAKARTA';
        _logger.i('Menggunakan provinsi: $provinsiToUse untuk filter kabupaten');
        
        // Dapatkan ID provinsi dari nama provinsi
        final provinsiResponse = await _supabase
            .from('provinsi')
            .select('id, nama')
            .eq('nama', provinsiToUse)
            .maybeSingle();
            
        _logger.i('Provinsi response: $provinsiResponse');
        
        String? provinsiId = provinsiResponse?['id'];
        
        // Jika masih tidak ditemukan, ambil provinsi pertama dari database
        if (provinsiId == null) {
          final allProvinsiResponse = await _supabase
              .from('provinsi')
              .select('id, nama')
              .limit(1)
              .single();
          
          provinsiId = allProvinsiResponse['id'];
          provinsiToUse = allProvinsiResponse['nama'];
          _logger.i('Menggunakan provinsi default dari database: $provinsiToUse dengan ID: $provinsiId');
        }
        
        _logger.i('ID Provinsi dari nama $provinsiToUse: $provinsiId');
        
        if (provinsiId != null) {
          // Query langsung ke database dengan filter
          final filteredResponse = await _supabase
              .from('kabupaten_kota')
              .select()
              .eq('provinsi_id', provinsiId)
              .order('nama');
              
          final List<dynamic> filteredData = filteredResponse as List<dynamic>;
          kabupatenKotaList = filteredData
              .map((item) => KabupatenKota.fromJson(item as Map<String, dynamic>))
              .toList();
              
          _logger.i('Filtering kabupaten/kota for provinsi ID: $provinsiId, hasil: ${kabupatenKotaList.length} item');
        } else {
          _logger.w('Provinsi ID tidak ditemukan untuk provinsi: $provinsiToUse');
        }
      } catch (e) {
        _logger.e('Error saat filter provinsi: $e');
      }

      emit(
        state.copyWith(
          kabupatenKotaList: kabupatenKotaList,
          isKabupatenKotaLoading: false,
        ),
      );

      _logger.i(
        'Kabupaten/Kota list loaded: ${kabupatenKotaList.length} items',
      );
    } catch (e) {
      _logger.e('Error loading kabupaten/kota: $e');
      emit(
        state.copyWith(
          isKabupatenKotaLoading: false,
          errorMessage: 'Gagal memuat daftar kabupaten/kota: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengambil foto KTP dari kamera
  Future<void> pickKtpImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        await _processKtpImage(imageFile);
      }
    } catch (e) {
      _logger.e('Error picking image from camera: $e');
      emit(
        state.copyWith(
          errorMessage: 'Gagal mengambil foto dari kamera: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengambil foto KTP dari galeri
  Future<void> pickKtpImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        await _processKtpImage(imageFile);
      }
    } catch (e) {
      _logger.e('Error picking image from gallery: $e');
      emit(
        state.copyWith(
          errorMessage: 'Gagal mengambil foto dari galeri: ${e.toString()}',
        ),
      );
    }
  }

  /// Memproses dan mengkompresi gambar KTP
  Future<void> _processKtpImage(File imageFile) async {
    try {
      // Kompresi gambar untuk menghemat storage
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 70,
        minWidth: 800,
        minHeight: 600,
      );

      if (compressedImage != null) {
        final File finalImage = File(compressedImage.path);
        emit(
          state.copyWith(
            ktpImageFile: finalImage,
            imageVersion: DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        );
        _logger.i('KTP image processed successfully');
      }
    } catch (e) {
      _logger.e('Error processing KTP image: $e');
      emit(
        state.copyWith(
          errorMessage: 'Gagal memproses gambar KTP: ${e.toString()}',
        ),
      );
    }
  }

  /// Menghapus gambar KTP
  void clearKtpImage() {
    emit(state.clearKtpImage());
    _logger.i('KTP image cleared');
  }

  /// Mengubah pengaturan penggunaan alamat saat ini
  void toggleUseCurrentUserAddress(bool value) {
    emit(state.copyWith(useCurrentUserAddress: value));
  }

  /// Mengubah persetujuan syarat dan ketentuan
  void toggleAgreeToTerms(bool value) {
    emit(state.copyWith(agreeToTerms: value));
  }

  /// Memilih kabupaten/kota
  void selectKabupatenKota(KabupatenKota? kabupatenKota) {
    emit(state.copyWith(selectedKabupatenKota: kabupatenKota));
  }

  /// Submit registrasi provider
  Future<void> submitProviderRegistration({
    required String businessName,
    required String businessDescription,
    required String addressDetail,
    String businessPhone = '',
    required List<String> serviceCategories,
  }) async {
    if (!_validateSubmission()) {
      return;
    }

    emit(state.copyWith(isSubmitting: true));

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      // 1. Upload KTP image jika ada
      String? ktpUrl;
      if (state.ktpImageFile != null) {
        ktpUrl = await _uploadKtpImage(user.id);
      }

      // 2. Prepare provider details
      final providerDetails = {
        'business_name': businessName.trim(),
        'business_description': businessDescription.trim(),
        'business_phone': businessPhone.trim(),
        'service_categories': serviceCategories,
        'service_area': state.selectedKabupatenKota?.toJson(),
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // 3. Update profile dengan data provider
      final updateData = <String, dynamic>{
        'is_provider': true,
        'provider_verification_status': 'pending',
        'provider_details': providerDetails,
        'address_detail': addressDetail,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (ktpUrl != null) {
        updateData['ktp_url'] = ktpUrl;
      }

      await _supabase.from('profiles').update(updateData).eq('id', user.id);

      emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          successMessage:
              'Registrasi provider berhasil disubmit. Menunggu verifikasi admin.',
          providerStatus: 'pending',
        ),
      );

      _logger.i('Provider registration submitted successfully');
    } catch (e) {
      _logger.e('Error submitting provider registration: $e');
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Gagal submit registrasi provider: ${e.toString()}',
        ),
      );
    }
  }

  /// Upload gambar KTP ke Supabase Storage
  Future<String> _uploadKtpImage(String userId) async {
    try {
      // Gunakan format nama file yang lebih sederhana
      final fileName = 'ktp_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Gunakan bucket ktp.images sesuai permintaan
      const bucketName = 'ktp.images';
      
      _logger.i('Mencoba upload KTP ke bucket: $bucketName, path: $fileName');
      
      // Upload file ke bucket ktp.images
      await _supabase.storage
          .from(bucketName)
          .upload(fileName, state.ktpImageFile!);
      
      // Dapatkan public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
      
      _logger.i('KTP image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logger.e('Error uploading KTP image: $e');
      throw Exception('Gagal upload gambar KTP: ${e.toString()}');
    }
  }

  /// Validasi sebelum submit
  bool _validateSubmission() {
    if (!state.agreeToTerms) {
      emit(
        state.copyWith(
          errorMessage: 'Anda harus menyetujui syarat dan ketentuan',
        ),
      );
      return false;
    }

    if (state.ktpImageFile == null) {
      emit(state.copyWith(errorMessage: 'Foto KTP harus diupload'));
      return false;
    }

    if (state.selectedKabupatenKota == null) {
      emit(state.copyWith(errorMessage: 'Area layanan harus dipilih'));
      return false;
    }

    return true;
  }

  /// Reset pesan error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Reset status success
  void clearSuccess() {
    emit(state.copyWith(isSuccess: false, successMessage: null));
  }

  /// Update gambar KTP
  void updateKtpImage(File imageFile) {
    emit(
      state.copyWith(
        ktpImageFile: imageFile,
        imageVersion: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
    _logger.i('KTP image updated successfully');
  }

  /// Mengambil daftar kategori layanan dari Supabase
  Future<void> loadServiceCategories() async {
    try {
      emit(state.copyWith(isLoadingServiceCategories: true));
      
      final response = await _supabase
          .from('service_categories')
          .select('*')
          .eq('is_active', true)
          .order('name');
      
      final List<dynamic> data = response as List<dynamic>;
      final List<ServiceCategory> categories = data
          .map((item) => ServiceCategory.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _logger.i('Service categories loaded: ${categories.length} items');
      
      emit(state.copyWith(
        serviceCategories: categories,
        isLoadingServiceCategories: false,
      ));
    } catch (e) {
      _logger.e('Error loading service categories: $e');
      emit(state.copyWith(
        isLoadingServiceCategories: false,
        errorMessage: 'Gagal memuat kategori layanan: ${e.toString()}',
      ));
    }
  }
}
