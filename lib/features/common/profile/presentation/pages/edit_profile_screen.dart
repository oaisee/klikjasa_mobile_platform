import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

// Import untuk RegionBloc dan dependensinya
import '../bloc/region/region_bloc.dart';
import '../../domain/entities/provinsi.dart';
import '../../domain/entities/kabupaten_kota.dart';
import '../../domain/entities/kecamatan.dart';
import '../../domain/entities/desa_kelurahan.dart';
import 'package:logger/logger.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with WidgetsBindingObserver {
  File? _selectedImageFile;
  bool _isUploadingImage = false;
  final _logger = Logger();
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Loading state untuk data profil utama
  bool _isLoadingUserData = true;
  String? _userId;
  String? _avatarUrl;

  // Variabel untuk menyimpan nama wilayah dari database
  String? _savedProvinceName;
  String? _savedKabupatenKotaName;
  String? _savedKecamatanName;
  String? _savedDesaKelurahanName;

  // Variabel untuk data dan pilihan dropdown
  Provinsi? _selectedProvinsi;
  List<KabupatenKota> _kabupatenKotaList = [];
  KabupatenKota? _selectedKabupatenKota;
  List<Kecamatan> _kecamatanList = [];
  Kecamatan? _selectedKecamatan;
  List<DesaKelurahan> _desaKelurahanList = [];
  DesaKelurahan? _selectedDesaKelurahan;

  // Loading state untuk setiap level wilayah
  bool _isKabupatenKotaLoading = false;
  bool _isKecamatanLoading = false;
  bool _isDesaKelurahanLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _retrieveLostImageData(); // Panggil untuk memulihkan gambar jika ada yang hilang
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _emailController.text = Supabase.instance.client.auth.currentUser?.email ?? '';
    _loadUserData();
    // Memuat data provinsi saat inisialisasi
    context.read<RegionBloc>().add(FetchProvinces());
  }

  Future<void> _loadUserData() async {
    _logger.i('_loadUserData CALLED for user ID: $_userId');
    if (!mounted) return;
    setState(() => _isLoadingUserData = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select(
            'full_name, provinsi, kabupaten_kota, kecamatan, desa_kelurahan, avatar_url, phone_number, address_detail, postal_code',
          )
          .eq('id', _userId!)
          .single();

      _logger.i('Data loaded from Supabase: $response');

      if (mounted) {
        _fullNameController.text = response['full_name'] is String ? response['full_name'] as String : '';
        _avatarUrl = response['avatar_url'] is String ? response['avatar_url'] as String : null;
        _phoneController.text = response['phone_number'] is String ? response['phone_number'] as String : '';
        _addressController.text = response['address_detail'] is String ? response['address_detail'] as String : '';
        _postalCodeController.text = response['postal_code'] is String ? response['postal_code'] as String : '';
        _savedProvinceName = response['provinsi'] is String ? response['provinsi'] as String : null;
        _savedKabupatenKotaName = response['kabupaten_kota'] is String ? response['kabupaten_kota'] as String : null;
        _savedKecamatanName = response['kecamatan'] is String ? response['kecamatan'] as String : null;
        _savedDesaKelurahanName = response['desa_kelurahan'] is String ? response['desa_kelurahan'] as String : null;
        // Pre-seleksi akan dilakukan di BlocListener setelah data masing-masing level dimuat
        _logger.i('User data controllers updated. FullName: ${_fullNameController.text}, SavedProvince: $_savedProvinceName');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.errorTerjadiKesalahan}: ${error.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageSourceOptions,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!)
                      : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? NetworkImage(_avatarUrl!)
                          : null) as ImageProvider?,
                  child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _selectedImageFile == null
                      ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceOptions() async {
    if (_isUploadingImage || _isLoadingUserData) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploadingImage || _isLoadingUserData) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source, // Menggunakan parameter source
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _logger.i('Image picked from $source: ${pickedFile.path}');
        });
      } else {
        _logger.i('No image selected from $source.');
      }
    } catch (e, stackTrace) {
      _logger.e('Error picking image from $source. Detail: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar dari $source: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _uploadAvatar(File imageFile) async {
    if (_userId == null) {
      _logger.e('User ID is null, cannot upload avatar.');
      return null;
    }
    if(mounted) setState(() => _isUploadingImage = true);
    try {
      final fileExtension = p.extension(imageFile.path).toLowerCase();
      final filePath = '$_userId/avatar${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      _logger.i('Uploading avatar to Supabase Storage: $filePath');

      await Supabase.instance.client.storage
          .from('avatars') 
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      _logger.i('Avatar uploaded successfully.');

      final publicUrlResponse = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      _logger.i('Public URL for avatar: $publicUrlResponse');
      return publicUrlResponse;

    } catch (e, stackTrace) {
      _logger.e('Error uploading avatar. Detail: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah avatar: ${e.toString()}')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    _logger.i('_saveProfile function CALLED.');
    if (!_formKey.currentState!.validate()) {
      _logger.w('Form validation FAILED. Aborting save.');
      return;
    }
    _logger.i('Form validation PASSED.');
    if (!mounted) return;

    if(mounted) setState(() => _isLoadingUserData = true);

    String? newAvatarUrl;
    if (_selectedImageFile != null) {
      newAvatarUrl = await _uploadAvatar(_selectedImageFile!);
      if (newAvatarUrl == null && mounted) {
        _logger.w('Avatar upload failed. Other profile data might still be saved.');
        // Optionally, you could prevent saving other data if avatar upload is critical
        // For now, we'll allow other data to be saved.
      }
    }

    try {
      final updates = {
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address_detail': _addressController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'provinsi': _selectedProvinsi?.nama,
        'kabupaten_kota': _selectedKabupatenKota?.nama,
        'kecamatan': _selectedKecamatan?.nama,
        'desa_kelurahan': _selectedDesaKelurahan?.nama,
        // 'avatar_url': _avatarUrl, // Hanya jika ada perubahan avatar
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newAvatarUrl != null) {
        updates['avatar_url'] = newAvatarUrl;
      }

      _logger.i('Attempting to save profile with data: $updates');
      _logger.d('User ID for update: $_userId');

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', _userId!); // Pastikan _userId tidak null dan benar

      _logger.i('Profile update call to Supabase successful.');

    if (mounted) {
      if (newAvatarUrl != null) { 
        setState(() {
          _avatarUrl = newAvatarUrl;
          _selectedImageFile = null; 
        });
      }
      _savedProvinceName = _selectedProvinsi?.nama;
      _savedKabupatenKotaName = _selectedKabupatenKota?.nama;
      _savedKecamatanName = _selectedKecamatan?.nama;
      _savedDesaKelurahanName = _selectedDesaKelurahan?.nama;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }  
    } catch (e) {
      _logger.e('Error saving profile: $e');
      String errorMessage = AppStrings.errorGagalMemperbaruiProfil;
      if (e is PostgrestException) {
        _logger.e('PostgrestException details: code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
        if (e.code == '23505' && e.message.contains('profiles_phone_number_key')) {
          errorMessage = 'Nomor telepon ini sudah digunakan. Silakan gunakan nomor lain.';
        } else {
          errorMessage = '${AppStrings.errorGagalMemperbaruiProfil}: ${e.message}';
        }
      } else {
        errorMessage = '${AppStrings.errorGagalMemperbaruiProfil}: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false); // Stop loading after saving
      }
    }
  }

  Widget _buildDisabledDropdown(String label, String hint) {
    final textTheme = Theme.of(context).textTheme;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondaryLight.withAlpha(179),
        ),
        filled: true,
        fillColor: AppColors.lightGrey.withAlpha(77),
        prefixIcon: Icon(
          Icons.location_city_outlined,
          color: AppColors.textSecondaryLight.withAlpha(179),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(
        hint,
        style: textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondaryLight.withAlpha(179),
        ),
      ),
      items: const [],
      onChanged: null,
      disabledHint: Text(
        hint,
        style: textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondaryLight.withAlpha(179),
        ),
      ),
      isExpanded: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose(); // Memastikan postal code controller di-dispose
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil data gambar yang hilang
  Future<void> _retrieveLostImageData() async {
    final LostDataResponse response = await ImagePicker().retrieveLostData();
    if (response.isEmpty) {
      _logger.i('Tidak ada data gambar yang hilang.');
      return;
    }
    if (response.file != null) {
      _logger.i('Data gambar yang hilang berhasil dipulihkan: ${response.file!.path}');
      setState(() {
        _selectedImageFile = File(response.file!.path);
        // Jika Anda memiliki logika untuk langsung mengunggah setelah memilih, panggil di sini
        // atau setidaknya perbarui UI untuk menunjukkan gambar yang dipilih.
      });
    } else {
      _logger.e('Data gambar yang hilang ditemukan, tetapi ada error: ${response.exception?.message}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.i('AppLifecycleState changed to: $state');
    // Anda bisa menambahkan logika spesifik di sini jika diperlukan
    // misalnya, jika state == AppLifecycleState.resumed setelah kembali dari kamera,
    // Anda bisa mencoba memastikan state halaman tetap terjaga.
  }

  @override
  Widget build(BuildContext context) {
    // Ensure RegionBloc is provided if it's used directly in this widget's tree for UI elements
    // If it's only for events like in initState, it might not need to be here.
    // However, if dropdowns depend on BlocBuilder/BlocSelector from RegionBloc, it's necessary.
    // For now, assuming it's correctly provided higher up or as needed.

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(AppStrings.ubahProfil),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 1.0,
      ),
      body: BlocListener<RegionBloc, RegionState>(
          listener: (context, state) {
            // ---> MULAI KODE TAMBAHAN UNTUK LOGGING <---
            _logger.i('LISTENER: RegionBloc state received: ${state.runtimeType}');

            if (state is RegionInitial) {
              _logger.i('LISTENER: State is RegionInitial.');
            } else if (state is RegionLoading) { 
              String loadingType = "N/A";
              try {
                loadingType = (state as dynamic).type?.toString() ?? "N/A";
              } catch (e) { /* Properti 'type' tidak ada atau error lain */ }
              _logger.i('LISTENER: State is RegionLoading. Type: $loadingType');
            } else if (state is ProvincesLoaded) {
              _logger.i('LISTENER: State is ProvincesLoaded with ${state.provinces.length} items. First item: ${state.provinces.isNotEmpty ? state.provinces.first.nama : "N/A"}');
            } else if (state is KabupatenKotaLoading) {
              String provId = "N/A";
              try {
                provId = (state as dynamic).provinsiId?.toString() ?? "N/A";
              } catch (e) { /* Properti 'provinsiId' tidak ada */ }
              _logger.i('LISTENER: State is KabupatenKotaLoading for province ID: $provId');
            } else if (state is KabupatenKotaLoaded) {
              _logger.i('LISTENER: State is KabupatenKotaLoaded with ${state.kabupatenKotaList.length} items. First item: ${state.kabupatenKotaList.isNotEmpty ? state.kabupatenKotaList.first.nama : "N/A"}');
            } else if (state is KecamatanLoading) {
              String kabId = "N/A";
              try {
                kabId = (state as dynamic).kabupatenKotaId?.toString() ?? "N/A";
              } catch (e) { /* Properti 'kabupatenKotaId' tidak ada */ }
              _logger.i('LISTENER: State is KecamatanLoading for kabkota ID: $kabId');
            } else if (state is KecamatanLoaded) {
              _logger.i('LISTENER: State is KecamatanLoaded with ${state.kecamatanList.length} items. First item: ${state.kecamatanList.isNotEmpty ? state.kecamatanList.first.nama : "N/A"}');
            } else if (state is DesaKelurahanLoading) {
              String kecId = "N/A";
              try {
                kecId = (state as dynamic).kecamatanId?.toString() ?? "N/A";
              } catch (e) { /* Properti 'kecamatanId' tidak ada */ }
              _logger.i('LISTENER: State is DesaKelurahanLoading for kecamatan ID: $kecId');
            } else if (state is DesaKelurahanLoaded) {
              _logger.i('LISTENER: State is DesaKelurahanLoaded with ${state.desaKelurahanList.length} items. First item: ${state.desaKelurahanList.isNotEmpty ? state.desaKelurahanList.first.nama : "N/A"}');
            } else if (state is RegionError) {
              String errorType = "N/A";
              try {
                errorType = (state as dynamic).type?.toString() ?? "N/A";
              } catch (e) { /* Properti 'type' tidak ada */ }
              _logger.e('LISTENER: State is RegionError. Message: ${state.message}. Type: $errorType');
            }
            // ---> AKHIR KODE TAMBAHAN UNTUK LOGGING <---

            // Logika untuk Provinsi
            if (state is ProvincesLoaded) {
              // Hanya set selectedProvinsi jika belum terpilih atau jika _savedProvinceName tidak null
              // dan _selectedProvinsi belum sesuai dengan _savedProvinceName
              if (_savedProvinceName != null &&
                  (_selectedProvinsi == null ||
                      _selectedProvinsi!.nama != _savedProvinceName)) {
                try {
                  final savedProv = state.provinces.firstWhere(
                    (p) =>
                        p.nama.toLowerCase() ==
                        _savedProvinceName!.toLowerCase(),
                  );
                  if (mounted) {
                    setState(() {
                      _selectedProvinsi = savedProv;
                      // Setelah provinsi terpilih, langsung fetch kabupaten/kota jika _savedKabupatenKotaName ada
                      if (_savedKabupatenKotaName != null) {
                        context.read<RegionBloc>().add(
                          FetchKabupatenKota(_selectedProvinsi!.id),
                        );
                      }
                    });
                  }
                } catch (e) {
                  _logger.i(
                    'Provinsi tersimpan "$_savedProvinceName" tidak ditemukan di daftar provinces yang dimuat. Mungkin data lama atau salah ketik.',
                  );
                  // Jika savedProv tidak ditemukan, _selectedProvinsi tetap null atau gunakan default (misal: yang pertama)
                }
              }
            } else if (state is RegionError &&
                state.message.contains('provinces')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memuat provinsi: ${state.message}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }

            // Logika untuk Kabupaten/Kota
            if (state is KabupatenKotaLoading) {
              if (mounted) setState(() => _isKabupatenKotaLoading = true);
            } else if (state is KabupatenKotaLoaded) {
              if (mounted) {
                setState(() {
                  _kabupatenKotaList = state.kabupatenKotaList;
                  _isKabupatenKotaLoading = false;

                  // Hanya set selectedKabupatenKota jika belum terpilih atau jika _savedKabupatenKotaName tidak null
                  // dan _selectedKabupatenKota belum sesuai dengan _savedKabupatenKotaName
                  if (_savedKabupatenKotaName != null &&
                      (_selectedKabupatenKota == null ||
                          _selectedKabupatenKota!.nama !=
                              _savedKabupatenKotaName)) {
                    try {
                      _selectedKabupatenKota = state.kabupatenKotaList
                          .firstWhere(
                            (kab) =>
                                kab.nama.toLowerCase() ==
                                _savedKabupatenKotaName!.toLowerCase(),
                          );
                      if (_savedKecamatanName != null) {
                        context.read<RegionBloc>().add(
                          FetchKecamatan(_selectedKabupatenKota!.id),
                        );
                      }
                    } catch (e) {
                      _logger.i(
                        'Kabupaten/Kota tersimpan "$_savedKabupatenKotaName" tidak ditemukan di daftar untuk provinsi terpilih. Mungkin data lama atau salah ketik.',
                      );
                    }
                  } else if (_selectedKabupatenKota != null &&
                      !_kabupatenKotaList.contains(_selectedKabupatenKota)) {
                    // Ini kasus saat provinsi diubah, dan kabupaten/kota yang terpilih sebelumnya tidak ada di daftar baru
                    _selectedKabupatenKota = null;
                    _kecamatanList = [];
                    _selectedKecamatan = null;
                    _desaKelurahanList = [];
                    _selectedDesaKelurahan = null;
                  }
                });
              }
            } else if (state is RegionError &&
                state.message.contains('kabupaten_kota')) {
              if (mounted) setState(() => _isKabupatenKotaLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal memuat kabupaten/kota: ${state.message}',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }

            // Logika untuk Kecamatan
            if (state is KecamatanLoading) {
              if (mounted) setState(() => _isKecamatanLoading = true);
            } else if (state is KecamatanLoaded) {
              if (mounted) {
                setState(() {
                  _kecamatanList = state.kecamatanList;
                  _isKecamatanLoading = false;

                  if (_savedKecamatanName != null &&
                      (_selectedKecamatan == null ||
                          _selectedKecamatan!.nama != _savedKecamatanName)) {
                    try {
                      _selectedKecamatan = state.kecamatanList.firstWhere(
                        (kec) =>
                            kec.nama.toLowerCase() ==
                            _savedKecamatanName!.toLowerCase(),
                      );
                      if (_savedDesaKelurahanName != null) {
                        context.read<RegionBloc>().add(
                          FetchDesaKelurahan(_selectedKecamatan!.id),
                        );
                      }
                    } catch (e) {
                      _logger.i(
                        'Kecamatan tersimpan "$_savedKecamatanName" tidak ditemukan di daftar untuk kabupaten/kota terpilih. Mungkin data lama atau salah ketik.',
                      );
                    }
                  } else if (_selectedKecamatan != null &&
                      !_kecamatanList.contains(_selectedKecamatan)) {
                    _selectedKecamatan = null;
                    _desaKelurahanList = [];
                    _selectedDesaKelurahan = null;
                  }
                });
              }
            } else if (state is RegionError &&
                state.message.contains('kecamatan')) {
              if (mounted) setState(() => _isKecamatanLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memuat kecamatan: ${state.message}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }

            // Logika untuk Desa/Kelurahan
            if (state is DesaKelurahanLoading) {
              if (mounted) setState(() => _isDesaKelurahanLoading = true);
            } else if (state is DesaKelurahanLoaded) {
              if (mounted) {
                setState(() {
                  _desaKelurahanList = state.desaKelurahanList;
                  _isDesaKelurahanLoading = false;

                  if (_savedDesaKelurahanName != null &&
                      (_selectedDesaKelurahan == null ||
                          _selectedDesaKelurahan!.nama !=
                              _savedDesaKelurahanName)) {
                    try {
                      _selectedDesaKelurahan = state.desaKelurahanList
                          .firstWhere(
                            (desa) =>
                                desa.nama.toLowerCase() ==
                                _savedDesaKelurahanName!.toLowerCase(),
                          );
                    } catch (e) {
                      _logger.i(
                        'Desa/Kelurahan tersimpan "$_savedDesaKelurahanName" tidak ditemukan di daftar untuk kecamatan terpilih. Mungkin data lama atau salah ketik.',
                      );
                    }
                  } else if (_selectedDesaKelurahan != null &&
                      !_desaKelurahanList.contains(_selectedDesaKelurahan)) {
                    _selectedDesaKelurahan = null;
                  }
                });
              }
            } else if (state is RegionError &&
                state.message.contains('desa_kelurahan')) {
              if (mounted) setState(() => _isDesaKelurahanLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal memuat desa/kelurahan: ${state.message}',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          child: Builder(
            builder: (context) {
              if (_isLoadingUserData && _userId != null) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0), // Consistent padding for SingleChildScrollView
                child: Padding(
                  padding: const EdgeInsets.all(0), // Reset inner padding if outer is already set
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                      _buildAvatarPicker(),
                      const SizedBox(height: 24.0),

                      // Nama Lengkap
                      TextFormField(
                        controller: _fullNameController,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.namaPengguna,
                          labelStyle: textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.lightGrey.withAlpha(128),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Nama lengkap tidak boleh kosong.'
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // Email (Read-only)
                      TextFormField(
                        controller: _emailController,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.email,
                          labelStyle: textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          filled: true,
                          fillColor: AppColors.lightGrey.withAlpha(77),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.accent.withAlpha(128),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Nomor Telepon
                      TextFormField(
                        controller: _phoneController,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: AppStrings.nomorTelepon,
                          labelStyle: textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.lightGrey.withAlpha(128),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Nomor telepon tidak boleh kosong.'
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // Dropdown Provinsi
                      BlocBuilder<RegionBloc, RegionState>(
                        builder: (context, regionState) {
                          _logger.i("State Provinsi BlocBuilder: ${regionState.runtimeType}, Data: $regionState");
                          Widget dropdownContent;
                          if (regionState is RegionInitial ||
                              regionState is RegionLoading) {
                            dropdownContent = Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
                              ),
                            );
                          } else if (regionState is ProvincesLoaded) {
                            dropdownContent = DropdownButtonFormField<Provinsi>(
                              decoration: InputDecoration(
                                labelText: 'Provinsi',
                                labelStyle: textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                                filled: true,
                                fillColor: AppColors.backgroundLight,
                                prefixIcon: const Icon(
                                  Icons.map_outlined,
                                  color: AppColors.textSecondaryLight,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: AppColors.lightGrey,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: AppColors.lightGrey.withAlpha(128),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              value: _selectedProvinsi,
                              hint: Text(
                                'Pilih Provinsi',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              isExpanded: true,
                              items: regionState.provinces
                                  .map(
                                    (Provinsi p) => DropdownMenuItem<Provinsi>(
                                      value: p,
                                      child: Text(
                                        p.nama,
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (Provinsi? newValue) {
                                if (mounted) {
                                  setState(() {
                                    _selectedProvinsi = newValue;
                                    _selectedKabupatenKota = null;
                                    _kabupatenKotaList = [];
                                    _selectedKecamatan = null;
                                    _kecamatanList = [];
                                    _selectedDesaKelurahan = null;
                                    _desaKelurahanList = [];
                                    if (newValue != null) {
                                      context.read<RegionBloc>().add(
                                        FetchKabupatenKota(newValue.id),
                                      );
                                    }
                                  });
                                }
                              },
                              validator: (value) => value == null
                                  ? 'Provinsi tidak boleh kosong'
                                  : null,
                              dropdownColor: AppColors.backgroundLight,
                            );
                          } else if (regionState is RegionError &&
                              regionState.message.contains('provinces')) {
                            dropdownContent = Text(
                              'Gagal memuat provinsi: ${regionState.message}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                            );
                          } else {
                            dropdownContent =
                                const SizedBox.shrink(); // Default fallback
                          }
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              // Key harus unik untuk setiap state dan nilainya agar AnimatedSwitcher berfungsi
                              key: ValueKey(
                                '${regionState.runtimeType.toString()}-${_selectedProvinsi?.id ?? 'no_prov'}',
                              ),
                              child: dropdownContent,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Dropdown Kabupaten/Kota
                      if (_selectedProvinsi != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isKabupatenKotaLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Memuat kabupaten/kota...',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_kabupatenKotaList.isNotEmpty ||
                                _selectedKabupatenKota !=
                                    null) // Tampilkan dropdown jika ada list atau sudah ada yang terpilih
                              DropdownButtonFormField<KabupatenKota>(
                                decoration: InputDecoration(
                                  labelText: 'Kabupaten/Kota',
                                  labelStyle: textTheme.labelLarge?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                  prefixIcon: const Icon(
                                    Icons.location_city_outlined,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.lightGrey.withAlpha(128),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                value: _selectedKabupatenKota,
                                hint: Text(
                                  'Pilih Kabupaten/Kota',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textHintLight,
                                  ),
                                ),
                                isExpanded: true,
                                items: _kabupatenKotaList.map((kabKota) {
                                  return DropdownMenuItem<KabupatenKota>(
                                    value: kabKota,
                                    child: Text(
                                      kabKota.nama,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (KabupatenKota? newValue) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedKabupatenKota = newValue;
                                      _selectedKecamatan = null;
                                      _kecamatanList = [];
                                      _selectedDesaKelurahan = null;
                                      _desaKelurahanList = [];
                                      if (newValue != null) {
                                        context.read<RegionBloc>().add(
                                          FetchKecamatan(newValue.id),
                                        );
                                      }
                                    });
                                  }
                                },
                                validator: (value) =>
                                    _selectedProvinsi != null && value == null
                                    ? 'Kabupaten/Kota tidak boleh kosong'
                                    : null,
                                dropdownColor: AppColors.backgroundLight,
                              )
                            else if (!_isKabupatenKotaLoading &&
                                _selectedProvinsi != null &&
                                _kabupatenKotaList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: Text(
                                  'Tidak ada data kabupaten/kota untuk provinsi ini.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16.0),
                          ],
                        )
                      else
                        _buildDisabledDropdown(
                          'Kabupaten/Kota',
                          'Pilih Provinsi terlebih dahulu',
                        ),
                      const SizedBox(height: 16.0),

                      // Dropdown Kecamatan
                      if (_selectedKabupatenKota != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isKecamatanLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Memuat kecamatan...',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_kecamatanList.isNotEmpty ||
                                _selectedKecamatan != null)
                              DropdownButtonFormField<Kecamatan>(
                                decoration: InputDecoration(
                                  labelText: 'Kecamatan',
                                  labelStyle: textTheme.labelLarge?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                  prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.lightGrey.withAlpha(128),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                value: _selectedKecamatan,
                                hint: Text(
                                  'Pilih Kecamatan',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textHintLight,
                                  ),
                                ),
                                isExpanded: true,
                                items: _kecamatanList.map((kecamatan) {
                                  return DropdownMenuItem<Kecamatan>(
                                    value: kecamatan,
                                    child: Text(
                                      kecamatan.nama,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Kecamatan? newValue) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedKecamatan = newValue;
                                      _selectedDesaKelurahan = null;
                                      _desaKelurahanList = [];
                                      if (newValue != null) {
                                        context.read<RegionBloc>().add(
                                          FetchDesaKelurahan(newValue.id),
                                        );
                                      }
                                    });
                                  }
                                },
                                validator: (value) =>
                                    _selectedKabupatenKota != null &&
                                        value == null
                                    ? 'Kecamatan tidak boleh kosong'
                                    : null,
                                dropdownColor: AppColors.backgroundLight,
                              )
                            else if (!_isKecamatanLoading &&
                                _selectedKabupatenKota != null &&
                                _kecamatanList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: Text(
                                  'Tidak ada data kecamatan untuk kabupaten/kota ini.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16.0),
                          ],
                        )
                      else
                        _buildDisabledDropdown(
                          'Kecamatan',
                          'Pilih Kabupaten/Kota terlebih dahulu',
                        ),
                      const SizedBox(height: 16.0),

                      // Dropdown Desa/Kelurahan
                      if (_selectedKecamatan != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isDesaKelurahanLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Memuat desa/kelurahan...',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_desaKelurahanList.isNotEmpty ||
                                _selectedDesaKelurahan != null)
                              DropdownButtonFormField<DesaKelurahan>(
                                decoration: InputDecoration(
                                  labelText: 'Desa/Kelurahan',
                                  labelStyle: textTheme.labelLarge?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                  prefixIcon: const Icon(
                                    Icons.home_outlined,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.lightGrey.withAlpha(128),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                value: _selectedDesaKelurahan,
                                hint: Text(
                                  'Pilih Desa/Kelurahan',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textHintLight,
                                  ),
                                ),
                                isExpanded: true,
                                items: _desaKelurahanList.map((desaKelurahan) {
                                  return DropdownMenuItem<DesaKelurahan>(
                                    value: desaKelurahan,
                                    child: Text(
                                      desaKelurahan.nama,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (DesaKelurahan? newValue) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedDesaKelurahan = newValue;
                                    });
                                  }
                                },
                                validator: (value) =>
                                    _selectedKecamatan != null && value == null
                                    ? 'Desa/Kelurahan tidak boleh kosong'
                                    : null,
                                dropdownColor: AppColors.backgroundLight,
                              )
                            else if (!_isDesaKelurahanLoading &&
                                _selectedKecamatan != null &&
                                _desaKelurahanList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: Text(
                                  'Tidak ada data desa/kelurahan untuk kecamatan ini.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16.0),
                          ],
                        )
                      else
                        _buildDisabledDropdown(
                          'Desa/Kelurahan',
                          'Pilih Kecamatan terlebih dahulu',
                        ),
                      const SizedBox(height: 16.0),
                      
                      // Alamat Lengkap
                      TextFormField(
                        controller: _addressController,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppStrings.alamatLengkap,
                          labelStyle: textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.lightGrey.withAlpha(128),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                          hintText: 'Tambahkan detail lainnya seperti patokan, RT/RW, dll.',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Alamat lengkap tidak boleh kosong.'
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // Kode Pos
                      TextFormField(
                        controller: _postalCodeController,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppStrings.kodePos,
                          labelStyle: textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          prefixIcon: const Icon(
                            Icons.markunread_mailbox_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: AppColors.lightGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.lightGrey.withAlpha(128),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          return (value == null || value.trim().isEmpty)
                            ? 'Kode Pos tidak boleh kosong.'
                            : null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Tombol Simpan
                      ElevatedButton(
                        onPressed: _isLoadingUserData ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoadingUserData
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : Text(
                                AppStrings.simpanPerubahan,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
            );
          }, // Menutup fungsi builder, diikuti koma
        ),   // Menutup widget Builder, diikuti koma
      ),     // Menutup widget BlocListener, diikuti koma

  );         // Menutup widget Scaffold & statement return
}            // Menutup metode build
}            // Menutup kelas _EditProfileScreenState
