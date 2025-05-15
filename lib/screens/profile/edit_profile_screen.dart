import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  
  // Untuk penanganan gambar
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Mengisi form dengan data user saat ini
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        // Penanganan berbeda untuk web dan mobile
        if (kIsWeb) {
          // Platform web
          final imageBytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImageBytes = imageBytes;
            _profileImageFile = null;
            _profileImageName = pickedFile.name;
          });
          
          debugPrint('Foto profil dipilih (web): ${pickedFile.name}');
          debugPrint('Ukuran foto profil (web): ${imageBytes.length} bytes');
        } else {
          // Platform mobile
          final imageFile = File(pickedFile.path);
          
          // Periksa apakah file ada dan dapat dibaca
          if (await imageFile.exists()) {
            setState(() {
              _profileImageFile = imageFile;
              _profileImageBytes = null;
              _profileImageName = pickedFile.name;
            });

            debugPrint('Foto profil dipilih (mobile): ${imageFile.path}');
            debugPrint('Ukuran foto profil (mobile): ${await imageFile.length()} bytes');
          } else {
            debugPrint('File yang dipilih tidak ada: ${imageFile.path}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File gambar tidak dapat diakses'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
        
        // Tampilkan pesan sukses untuk kedua platform
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil dipilih'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saat memilih foto profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? profileImageUrl;
        
        // Upload foto profil jika ada
        if (_profileImageFile != null || _profileImageBytes != null) {
          final storageProvider = Provider.of<StorageProvider>(context, listen: false);
          
          if (kIsWeb && _profileImageBytes != null) {
            // Upload untuk web
            profileImageUrl = await storageProvider.uploadProfileImageBytes(
              _profileImageBytes!,
              _profileImageName ?? 'profile_${authProvider.user!.id}.jpg',
              authProvider.user!.id
            );
          } else if (_profileImageFile != null) {
            // Upload untuk mobile
            profileImageUrl = await storageProvider.uploadProfileImage(
              _profileImageFile!, 
              authProvider.user!.id
            );
          }
        }
        
        await authProvider.updateProfile(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          profileImageUrl: profileImageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui profil: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : _profileImageFile != null
                                  ? FileImage(_profileImageFile!) as ImageProvider
                                  : (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                      ? NetworkImage(user.profileImageUrl!) as ImageProvider
                                      : null),
                          child: (_profileImageBytes == null && _profileImageFile == null && 
                                 (user.profileImageUrl == null || user.profileImageUrl!.isEmpty))
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields
                  const Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Nama',
                    hint: 'Masukkan nama lengkap',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email',
                    hint: 'Masukkan email',
                    controller: _emailController,
                    enabled: false, // Email tidak bisa diubah
                    validator: null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Nomor Telepon',
                    hint: 'Masukkan nomor telepon',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9]{10,13}$').hasMatch(value)) {
                          return 'Nomor telepon tidak valid';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                      onPressed: _isLoading ? null : _updateProfile,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
