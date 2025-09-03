// Menggunakan conditional import untuk platform-specific code
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/kabupaten_kota.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/features/common/profile/presentation/cubit/provider_registration_cubit.dart';
import 'package:klik_jasa/features/common/profile/presentation/cubit/provider_registration_state.dart';
import 'package:go_router/go_router.dart'; 
import 'package:klik_jasa/features/common/utils/app_message_utils.dart'; 
import 'package:klik_jasa/core/widgets/common_card.dart';
import 'package:klik_jasa/core/widgets/common_text_form_field.dart';

/// Screen untuk registrasi provider/penyedia jasa
class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  // Logger untuk debugging jika diperlukan nanti
  // final _logger = di.sl<Logger>();
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk form input
  late TextEditingController _businessNameController;
  late TextEditingController _businessDescriptionController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  
  // Variabel untuk menyimpan kategori layanan yang dipilih
  final List<String> _selectedServiceCategories = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller
    _businessNameController = TextEditingController();
    _businessDescriptionController = TextEditingController();
    _businessAddressController = TextEditingController();
    _businessPhoneController = TextEditingController();
    
    // Load data kabupaten/kota
    context.read<ProviderRegistrationCubit>().loadKabupatenKota();
    
    // Load user profile
    context.read<ProviderRegistrationCubit>().loadUserProfile();
    
    // Load service categories
    context.read<ProviderRegistrationCubit>().loadServiceCategories();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar KTP dari galeri
  Future<void> _pickKtpImage() async {
    try {
      // Gunakan Cubit untuk mengambil gambar dari galeri
      await context.read<ProviderRegistrationCubit>().pickKtpImageFromGallery();
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Gagal memilih gambar: ${e.toString()}',
          type: MessageType.error,
        );
      }
    }
  }

  // Fungsi untuk mengambil foto KTP dengan kamera
  Future<void> _takePicture() async {
    try {
      // Gunakan Cubit untuk mengambil gambar dari kamera
      await context.read<ProviderRegistrationCubit>().pickKtpImageFromCamera();
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Gagal mengambil foto: ${e.toString()}',
          type: MessageType.error,
        );
      }
    }
  }

  // Fungsi untuk crop gambar KTP

  // Submit registrasi provider
  void _handleSubmit() {
    // Validasi form terlebih dahulu
    if (_formKey.currentState!.validate()) {
      // Validasi kategori layanan
      if (_selectedServiceCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal satu kategori layanan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validasi KTP
      final state = context.read<ProviderRegistrationCubit>().state;
      if (state.ktpImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto KTP harus diupload'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validasi area layanan
      if (state.selectedKabupatenKota == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Area layanan harus dipilih'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validasi syarat dan ketentuan
      if (!state.agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus menyetujui syarat dan ketentuan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Submit form jika semua validasi berhasil
      context.read<ProviderRegistrationCubit>().submitProviderRegistration(
            businessName: _businessNameController.text.trim(),
            businessDescription: _businessDescriptionController.text.trim(),
            addressDetail: _businessAddressController.text.trim(),
            serviceCategories: _selectedServiceCategories,
          );
    } else {
      // Tampilkan snackbar jika form tidak valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua field yang wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget untuk bagian alamat
  Widget _buildAddressSection() {
    return BlocBuilder<ProviderRegistrationCubit, ProviderRegistrationState>(
      builder: (context, state) {
        return CommonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alamat Bisnis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Field alamat bisnis
              CommonTextFormField(
                controller: _businessAddressController,
                labelText: 'Alamat Bisnis',
                hintText: 'Masukkan alamat lengkap bisnis Anda',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat bisnis tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Dropdown area layanan
              _buildServiceAreaDropdown(),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk dropdown area layanan
  Widget _buildServiceAreaDropdown() {
    return BlocBuilder<ProviderRegistrationCubit, ProviderRegistrationState>(
      builder: (context, state) {
        if (state.isKabupatenKotaLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return DropdownButtonFormField<KabupatenKota>(
          decoration: const InputDecoration(
            labelText: 'Area Layanan',
            hintText: 'Pilih area layanan Anda',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isCollapsed: true,
          ),
          isExpanded: true,
          value: state.selectedKabupatenKota,
          items: state.kabupatenKotaList.map((KabupatenKota kabupatenKota) {
            return DropdownMenuItem<KabupatenKota>(
              value: kabupatenKota,
              child: Text(
                kabupatenKota.nama,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (KabupatenKota? newValue) {
            context.read<ProviderRegistrationCubit>().selectKabupatenKota(newValue);
          },
          validator: (value) {
            if (value == null) {
              return 'Area layanan harus dipilih';
            }
            return null;
          },
        );
      },
    );
  }
  
  // Widget untuk bagian upload KTP
  Widget _buildKtpUploadSection() {
    return BlocBuilder<ProviderRegistrationCubit, ProviderRegistrationState>(
      builder: (context, state) {
        return CommonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload KTP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload foto KTP Anda untuk verifikasi identitas. Pastikan foto KTP jelas dan tidak buram.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Preview KTP jika sudah ada
              if (state.ktpImageFile != null)
                Column(
                  children: [
                    Stack(
                      children: [
                        // Preview gambar KTP
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              state.ktpImageFile!,
                              fit: BoxFit.cover,
                              key: ValueKey(state.imageVersion), // Untuk refresh gambar saat berubah
                            ),
                          ),
                        ),
                        
                        // Tombol hapus gambar
                        Positioned(
                          top: 8,
                          right: 10,
                          child: InkWell(
                            onTap: () {
                              context.read<ProviderRegistrationCubit>().clearKtpImage();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Tombol upload KTP
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        onPressed: _pickKtpImage,
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Pilih dari Galeri', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Ambil Foto', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
           ) ],
          ),
        );
      },
    );
  }
  
  // Widget untuk bagian kategori layanan
  Widget _buildServiceCategoriesSection() {
    return BlocBuilder<ProviderRegistrationCubit, ProviderRegistrationState>(
      builder: (context, state) {
        if (state.isLoadingServiceCategories) {
          return const CommonCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        return CommonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Layanan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih kategori layanan yang akan Anda tawarkan (bisa lebih dari satu)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Daftar kategori layanan dengan checkbox
              state.serviceCategories.isEmpty
                  ? const Center(
                      child: Text('Tidak ada kategori layanan tersedia'),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.serviceCategories.map((category) {
                        final isSelected = _selectedServiceCategories.contains(category.name);
                        return FilterChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              if (!_selectedServiceCategories.contains(category.name)) {
                                setState(() {
                                  _selectedServiceCategories.add(category.name);
                                });
                              }
                            } else {
                              setState(() {
                                _selectedServiceCategories.remove(category.name);
                              });
                            }
                          },
                          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(51), // 0.2 * 255 = 51
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget untuk bagian informasi bisnis
  Widget _buildBusinessInfoSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Bisnis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Field nama bisnis
          CommonTextFormField(
            controller: _businessNameController,
            labelText: 'Nama Bisnis',
            hintText: 'Masukkan nama bisnis Anda',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama bisnis tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Field deskripsi bisnis
          CommonTextFormField(
            controller: _businessDescriptionController,
            labelText: 'Deskripsi Bisnis',
            hintText: 'Jelaskan tentang bisnis Anda',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Deskripsi bisnis tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Field nomor telepon bisnis
          CommonTextFormField(
            controller: _businessPhoneController,
            labelText: 'Nomor Telepon Bisnis',
            hintText: 'Masukkan nomor telepon bisnis Anda',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor telepon bisnis tidak boleh kosong';
              }
              // Validasi format nomor telepon
              if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                return 'Format nomor telepon tidak valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  // Widget untuk syarat dan ketentuan
  Widget _buildTermsAndConditions() {
    return BlocBuilder<ProviderRegistrationCubit, ProviderRegistrationState>(
      builder: (context, state) {
        return CommonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syarat dan Ketentuan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dengan mendaftar sebagai penyedia jasa, Anda menyetujui syarat dan ketentuan yang berlaku.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: state.agreeToTerms,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<ProviderRegistrationCubit>().toggleAgreeToTerms(value);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Saya menyetujui syarat dan ketentuan yang berlaku',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Tampilkan dialog syarat dan ketentuan
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Syarat dan Ketentuan'),
                      content: SingleChildScrollView(
                        child: Text(
                          AppStrings.termsAndConditions,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Baca Syarat dan Ketentuan'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget untuk header registrasi
  Widget _buildRegistrationHeader() {
    return BlocBuilder<ProviderRegistrationCubit, ProviderRegistrationState>(
      builder: (context, state) {
        // Cek status provider
        final String providerStatus = state.providerStatus ?? 'unverified';
        final bool isRegistrationDisabled = providerStatus == 'pending';
        
        return CommonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrasi Penyedia Jasa',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tampilkan status registrasi jika ada
              if (isRegistrationDisabled)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Registrasi Dalam Proses',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Registrasi Anda sedang dalam proses verifikasi oleh admin. Anda akan mendapatkan notifikasi setelah proses verifikasi selesai.',
                      ),
                    ],
                  ),
                ),
              
              if (!isRegistrationDisabled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lengkapi informasi berikut untuk mendaftar sebagai penyedia jasa.',
                    ),
                    const SizedBox(height: 16),
                    _buildRegistrationStepper(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget untuk stepper registrasi
  Widget _buildRegistrationStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepperItem(
          icon: Icons.person,
          title: 'Info Bisnis',
          isActive: true,
          isCompleted: false,
        ),
        _buildStepperConnector(isActive: true),
        _buildStepperItem(
          icon: Icons.location_on,
          title: 'Alamat',
          isActive: true,
          isCompleted: false,
        ),
        _buildStepperConnector(isActive: true),
        _buildStepperItem(
          icon: Icons.credit_card,
          title: 'KTP',
          isActive: true,
          isCompleted: false,
        ),
        _buildStepperConnector(isActive: true),
        _buildStepperItem(
          icon: Icons.check_circle,
          title: 'Selesai',
          isActive: true,
          isCompleted: false,
        ),
      ],
    );
  }
  
  // Widget untuk item stepper
  Widget _buildStepperItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  // Widget untuk connector stepper
  Widget _buildStepperConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProviderRegistrationCubit, ProviderRegistrationState>(
      listener: (context, state) {
        // Handle error message
        if (state.errorMessage != null) {
          AppMessageUtils.showSnackbar(
            context: context,
            message: state.errorMessage!,
            type: MessageType.error,
          );
          
          // Clear error message
          context.read<ProviderRegistrationCubit>().clearError();
        }
        
        // Handle success message
        if (state.isSuccess && state.successMessage != null) {
          AppMessageUtils.showSnackbar(
            context: context,
            message: state.successMessage!,
            type: MessageType.success,
          );
          
          // Clear success message
          context.read<ProviderRegistrationCubit>().clearSuccess();
          
          // Navigate back to profile screen
          context.pop();
        }
      },
      builder: (context, state) {
        // Cek status provider
        final String providerStatus = state.providerStatus ?? 'unverified';
        final bool isRegistrationDisabled = providerStatus == 'pending';
        
        // Loading state
        if (state.isLoadingProfile) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Registrasi Penyedia Jasa'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header registrasi
                  _buildRegistrationHeader(),
                  const SizedBox(height: 16),
                  
                  // Jika registrasi disabled, tampilkan pesan saja
                  if (isRegistrationDisabled)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Anda tidak dapat mengubah data registrasi saat ini karena sedang dalam proses verifikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Informasi bisnis
                        _buildBusinessInfoSection(),
                        const SizedBox(height: 16),
                        
                        // Alamat bisnis
                        _buildAddressSection(),
                        const SizedBox(height: 16),
                        
                        // Kategori layanan
                        _buildServiceCategoriesSection(),
                        const SizedBox(height: 16),
                        
                        // Upload KTP
                        _buildKtpUploadSection(),
                        const SizedBox(height: 16),
                        
                        // Syarat dan ketentuan
                        _buildTermsAndConditions(),
                        const SizedBox(height: 24),
                        
                        // Tombol submit
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.isSubmitting || !state.agreeToTerms || state.ktpImageFile == null
                                ? null
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: state.isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit Registrasi'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
         ) );
      },
    );
  }
}
