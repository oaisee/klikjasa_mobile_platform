import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/kabupaten_kota.dart';
import 'package:klik_jasa/features/common/profile/presentation/bloc/region/region_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_event.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_state.dart';
import 'package:klik_jasa/core/utils/thousand_separator_input_formatter.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';

/// Screen untuk menambah atau mengedit layanan.
class AddEditLayananScreen extends StatefulWidget {
  final Service? service; // Jika null, berarti tambah layanan baru

  const AddEditLayananScreen({super.key, this.service});

  @override
  State<AddEditLayananScreen> createState() => _AddEditLayananScreenState();
}

class _AddEditLayananScreenState extends State<AddEditLayananScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceAreaDropdownKey = GlobalKey<FormFieldState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // Variabel untuk menyimpan data form
  final List<File> _imageFiles = [];
  List<String> _imagesUrls = [];
  bool _isPromoted = false;
  DateTime? _promotionStartDate;
  DateTime? _promotionEndDate;

  // Variabel untuk dropdown area layanan
  List<KabupatenKota> _kabupatenKotaList = [];
  final List<KabupatenKota> _selectedServiceAreas = [];
  String? _providerDomicileKabupatenKotaId;
  String? _providerDomicileKabupatenKotaName; // Untuk menyimpan nama domisili

  // Variabel untuk kategori
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isFetchingCategories = true;

  // Variabel untuk status loading
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    developer.log('AddEditLayananScreen initState');
    // Pindahkan _loadProviderProvince ke atas agar daftar kabupaten/kota
    // tersedia sebelum _initializeControllers dipanggil.
    _loadProviderProvince();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // Inisialisasi controller dengan data service jika dalam mode edit
  void _initializeControllers() {
    if (widget.service != null) {
      _nameController.text = widget.service!.title;
      _descriptionController.text = widget.service!.description;

      // Format harga dengan pemisah ribuan
      final priceFormatter = NumberFormat('#,##0', 'id_ID');
      _priceController.text = priceFormatter
          .format(widget.service!.price)
          .replaceAll(',', '.');

      _selectedCategoryId = widget.service!.categoryId.toString();

      if (widget.service!.imagesUrls != null) {
        _imagesUrls = List<String>.from(widget.service!.imagesUrls!);
      }

      // Inisialisasi data promosi jika ada
      if (widget.service!.isPromoted) {
        _isPromoted = true;
        _promotionStartDate = widget.service!.promotionStartDate;
        _promotionEndDate = widget.service!.promotionEndDate;

        if (_promotionStartDate != null) {
          _startDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(_promotionStartDate!);
        }

        if (_promotionEndDate != null) {
          _endDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(_promotionEndDate!);
        }
      }

      // Panggil _loadServiceAreas setelah controller lain diinisialisasi
      _loadServiceAreas();
    }
  }

  /// Fungsi untuk memuat area layanan berdasarkan ID
  ///
  /// Fungsi ini memuat area layanan berdasarkan ID yang tersimpan di service (mode edit)
  /// atau berdasarkan kabupaten_kota_id dari profil user (mode tambah).
  ///
  /// Jika tidak ada area layanan yang dipilih, fungsi ini akan memilih kabupaten/kota
  /// dari profil user sebagai area layanan default.
  void _loadServiceAreas() {
    // Hapus daftar area terpilih sebelumnya untuk memastikan data bersih
    _selectedServiceAreas.clear();

    // 1. Atur domisili provider sebagai area layanan default
    if (_providerDomicileKabupatenKotaName != null &&
        _kabupatenKotaList.isNotEmpty) {
      try {
        final domicileArea = _kabupatenKotaList.firstWhere(
          (area) =>
              area.nama.toLowerCase() ==
              _providerDomicileKabupatenKotaName!.toLowerCase(),
        );
        setState(() {
          _providerDomicileKabupatenKotaId = domicileArea.id;
          if (!_selectedServiceAreas.any(
            (area) => area.id == domicileArea.id,
          )) {
            _selectedServiceAreas.insert(
              0,
              domicileArea,
            ); // Selalu di posisi pertama
          }
        });
      } catch (e) {
        developer.log(
          'Domisili "$_providerDomicileKabupatenKotaName" tidak ditemukan di daftar kabupaten/kota saat ini.',
        );
      }
    }

    // 2. Jika dalam mode edit, muat area layanan yang sudah ada dari location_text
    if (widget.service != null &&
        widget.service!.locationText != null &&
        _kabupatenKotaList.isNotEmpty) {
      final areaNames = widget.service!.locationText!
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .toList();
      final existingAreas = _kabupatenKotaList
          .where((area) => areaNames.contains(area.nama.toLowerCase()))
          .toList();

      setState(() {
        for (var area in existingAreas) {
          if (!_selectedServiceAreas.any((sa) => sa.id == area.id)) {
            _selectedServiceAreas.add(area);
          }
        }
      });
    }
  }

  /// Memuat data provinsi dan kabupaten/kota provider dari Supabase dan memicu event RegionBloc
  /// untuk mengambil data kabupaten/kota berdasarkan provinsi tersebut.
  ///
  /// Fungsi ini mengambil provinsi_id dan kabupaten_kota_id dari profil provider yang sedang login,
  /// kemudian mengirimkan event FetchKabupatenKota ke RegionBloc untuk memuat
  /// data kabupaten/kota yang akan ditampilkan di dropdown area layanan.
  ///
  /// Kabupaten/kota provider akan digunakan sebagai area layanan default untuk memastikan
  /// sinkronisasi antara alamat provider dan area layanan yang ditawarkan.
  // Variabel _cachedProvinsiId sudah didefinisikan di atas

  Future<void> _loadProviderProvince() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        developer.log('User tidak ditemukan, tidak dapat memuat provinsi.');
        return;
      }

      developer.log('Memulai _loadProviderProvince untuk user: ${user.id}');
      final profileResponse = await supabase
          .from('profiles')
          .select('provinsi, kabupaten_kota')
          .eq('id', user.id)
          .single();

      final provinsiName = profileResponse['provinsi']?.toString();
      final kabupatenKotaName = profileResponse['kabupaten_kota']?.toString();

      // Simpan nama kabupaten/kota dari profil untuk dijadikan default nanti
      if (kabupatenKotaName != null) {
        setState(() {
          _providerDomicileKabupatenKotaName = kabupatenKotaName;
        });
      }

      if (provinsiName == null || provinsiName.isEmpty) {
        developer.log('Nama provinsi tidak ditemukan di profil.');
        if (mounted) {
          AppMessageUtils.showSnackbar(
            context: context,
            message: 'Data provinsi di profil Anda kosong.',
            type: MessageType.error,
          );
        }
        return;
      }

      // 1. Ambil semua data provinsi untuk menemukan ID berdasarkan nama
      final provincesResponse = await supabase
          .from('provinsi')
          .select('id, nama');
      final provincesList = (provincesResponse as List)
          .cast<Map<String, dynamic>>();
      final matchedProvince = provincesList.firstWhere(
        (p) => p['nama'].toString().toLowerCase() == provinsiName.toLowerCase(),
        orElse: () => <String, dynamic>{}, // Return an empty map if not found
      );

      if (matchedProvince.isEmpty) {
        developer.log(
          'Provinsi "$provinsiName" tidak ditemukan dalam database.',
        );
        return;
      }

      final provinsiId = matchedProvince['id'].toString();
      developer.log('Provinsi "$provinsiName" cocok dengan ID: $provinsiId');

      // 2. Kirim event untuk mengambil kabupaten/kota berdasarkan ID provinsi yang ditemukan
      if (mounted) {
        context.read<RegionBloc>().add(FetchKabupatenKota(provinsiId));
        // Setelah mengambil daftar kabupaten/kota, panggil initializeControllers
        // untuk memastikan data layanan (termasuk area) dimuat dengan benar.
        _initializeControllers();
      }
    } catch (e) {
      developer.log('Error dalam _loadProviderProvince: $e');
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Gagal memuat data domisili: ${e.toString()}',
          type: MessageType.error,
        );
      }
    }
  }

  // Fungsi untuk menambahkan gambar
  Future<void> _addImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _imageFiles.add(File(file.path!));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Error memilih gambar: ${e.toString()}',
          type: MessageType.error,
        );
      }
    }
  }

  // Fungsi untuk menghapus gambar
  void _removeImage(int index) {
    setState(() {
      if (index < _imageFiles.length) {
        _imageFiles.removeAt(index);
      } else {
        final urlIndex = index - _imageFiles.length;
        if (urlIndex < _imagesUrls.length) {
          _imagesUrls.removeAt(urlIndex);
        }
      }
    });
  }

  // Fungsi untuk mengambil daftar kategori dari API
  Future<void> _fetchCategories() async {
    setState(() {
      _isFetchingCategories = true;
    });

    try {
      final supabase = Supabase.instance.client;
      developer.log('Mengambil kategori dari tabel service_categories');
      final response = await supabase
          .from('service_categories')
          .select('id, name')
          .eq('is_active', true);
      developer.log('Response kategori: $response');

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _isFetchingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Error mengambil kategori: ${e.toString()}',
          type: MessageType.error,
        );
        setState(() {
          _isFetchingCategories = false;
        });
      }
    }
  }

  // Fungsi untuk submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedServiceAreas.isEmpty) {
        AppMessageUtils.showSnackbar(
           context: context,
           message: 'Pilih minimal satu area layanan',
           type: MessageType.error,
         );
         return;
      }

      // Simpan referensi ke bloc sebelum operasi asinkron
      final servicesBloc = context.read<ServicesBloc>();

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Upload gambar ke storage jika ada
        final List<String> imageUrls = List<String>.from(_imagesUrls);

        if (_imageFiles.isNotEmpty) {
          final supabase = Supabase.instance.client;
          final user = supabase.auth.currentUser;

          for (final file in _imageFiles) {
            final fileName =
                '${user!.id}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
            final storageResponse = await supabase.storage
                .from('service.images')
                .upload(fileName, file);

            if (storageResponse.isNotEmpty) {
              final imageUrl = supabase.storage
                  .from('service.images')
                  .getPublicUrl(fileName);
              imageUrls.add(imageUrl);
            }
          }
        }

        // Buat atau update service
        // Buat atau update service dengan data terbaru dari state
        final service = Service(
          id: widget.service?.id ?? '00000000-0000-0000-0000-000000000000',
          title: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text.replaceAll('.', '')),
          priceUnit: 'per layanan', // Menambahkan nilai default
          locationText: _selectedServiceAreas
              .map((area) => area.nama)
              .join(', '), // Menggunakan nama area, sesuai skema DB
          providerId: Supabase.instance.client.auth.currentUser!.id,
          categoryId: _selectedCategoryId != null
              ? int.parse(_selectedCategoryId!)
              : 0, // Default ke 0 jika tidak ada kategori yang dipilih
          imagesUrls: imageUrls,
          isActive:
              widget.service?.isActive ??
              true, // Pertahankan status aktif yang ada atau default ke true
          isPromoted: _isPromoted, // Ambil nilai terbaru dari state
          promotionStartDate: _isPromoted
              ? _promotionStartDate
              : null, // Ambil nilai terbaru dari state
          promotionEndDate: _isPromoted
              ? _promotionEndDate
              : null, // Ambil nilai terbaru dari state
        );

        if (widget.service == null) {
          // Tambah layanan baru
          if (mounted) {
            servicesBloc.add(AddLayanan(layanan: service));
          }
        } else {
          // Update layanan yang ada
          if (mounted) {
            servicesBloc.add(UpdateLayanan(layanan: service));
          }
        }
      } catch (e) {
        if (mounted) {
          AppMessageUtils.showSnackbar(
            context: context,
            message: 'Error menyimpan layanan: ${e.toString()}',
            type: MessageType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Tambah Layanan' : 'Edit Layanan'),
      ),
      body: BlocListener<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is LayananAdded || state is LayananUpdated) {
            AppMessageUtils.showSnackbar(
              context: context,
              message: 'Layanan berhasil disimpan',
              type: MessageType.success,
            );
            Navigator.of(context).pop(true);
          } else if (state is ServicesError) {
            final errorMessage = state.message;
            AppMessageUtils.showSnackbar(
              context: context,
              message: 'Error: $errorMessage',
              type: MessageType.error,
            );
            setState(() {
              _isSubmitting = false;
            });
          }
        },
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                      const SizedBox(height: 16),
                      _buildPriceField(),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),
                      _buildServiceAreaSection(),
                      const SizedBox(height: 16),
                      _buildPromotionSection(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Layanan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Tombol tambah gambar
              InkWell(
                onTap: _addImage,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40),
                      SizedBox(height: 8),
                      Text('Tambah Foto'),
                    ],
                  ),
                ),
              ),

              // Daftar gambar yang sudah dipilih
              ..._imageFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return _buildImageItem(file: file, index: index);
              }),

              // Daftar gambar yang sudah diupload sebelumnya (untuk edit)
              ..._imagesUrls.asMap().entries.map((entry) {
                final index = entry.key + _imageFiles.length;
                final url = entry.value;
                return _buildImageItem(url: url, index: index);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem({File? file, String? url, required int index}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: file != null
                  ? FileImage(file) as ImageProvider
                  : NetworkImage(url!),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 8,
          child: InkWell(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nama Layanan',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama layanan tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Deskripsi',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Deskripsi tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Harga',
        border: OutlineInputBorder(),
        prefixText: 'Rp ',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        ThousandSeparatorInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Harga tidak boleh kosong';
        }
        final harga = value.replaceAll('.', '');
        if (double.tryParse(harga) == null) {
          return 'Harga harus berupa angka';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _isFetchingCategories
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                value: _selectedCategoryId,
                hint: const Text('Pilih Kategori'),
                isExpanded: true,
                items: _categories.map((category) {
                  // Konversi id kategori dari int ke String
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori harus dipilih';
                  }
                  return null;
                },
              ),
      ],
    );
  }

  Widget _buildServiceAreaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Area Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        BlocConsumer<RegionBloc, RegionState>(
          listener: (context, state) {
            if (state is KabupatenKotaLoaded) {
              setState(() {
                _kabupatenKotaList = state.kabupatenKotaList;
                _loadServiceAreas();
              });
            } else if (state is RegionError) {
              AppMessageUtils.showSnackbar(
                context: context,
                message: 'Gagal memuat data area: ${state.message}',
                type: MessageType.error,
              );
            }
          },
          builder: (context, state) {
            if (state is RegionLoading && _kabupatenKotaList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_kabupatenKotaList.isEmpty) {
              return const Text(
                'Tidak ada data kabupaten/kota. Pastikan profil provinsi Anda sudah benar.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<KabupatenKota>(
                  key: _serviceAreaDropdownKey,
                  isExpanded: true,
                  value: null,
                  hint: const Text('Tambah Area Layanan...'),
                  items: _kabupatenKotaList
                      .where(
                        (kab) => !_selectedServiceAreas.any(
                          (selected) => selected.id == kab.id,
                        ),
                      )
                      .map<DropdownMenuItem<KabupatenKota>>((
                        KabupatenKota kabupaten,
                      ) {
                        return DropdownMenuItem<KabupatenKota>(
                          value: kabupaten,
                          child: Text(kabupaten.nama),
                        );
                      })
                      .toList(),
                  onChanged: (KabupatenKota? newValue) {
                    if (newValue != null) {
                      setState(() {
                        if (!_selectedServiceAreas.any(
                          (area) => area.id == newValue.id,
                        )) {
                          _selectedServiceAreas.add(newValue);
                          // Reset dropdown untuk kembali ke hint text dan menghindari error
                          _serviceAreaDropdownKey.currentState?.reset();
                        }
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSelectedAreasDisplay(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedAreasDisplay() {
    if (_selectedServiceAreas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _selectedServiceAreas.map((area) {
        final isDomicile = area.id == _providerDomicileKabupatenKotaId;

        return Chip(
          label: Text(area.nama),
          // Domisili tidak bisa dihapus
          onDeleted: isDomicile
              ? null
              : () {
                  setState(() {
                    _selectedServiceAreas.removeWhere(
                      (item) => item.id == area.id,
                    );
                  });
                },
          // Beri warna berbeda untuk domisili
          backgroundColor: isDomicile
              ? Colors.blue.shade100
              : Colors.grey.shade200,
          deleteIconColor: isDomicile ? Colors.grey.shade500 : null,
          labelStyle: TextStyle(
            fontWeight: isDomicile ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPromotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isPromoted,
              onChanged: (value) {
                setState(() {
                  _isPromoted = value ?? false;
                  if (!_isPromoted) {
                    _promotionStartDate = null;
                    _promotionEndDate = null;
                    _startDateController.clear();
                    _endDateController.clear();
                  }
                });
              },
            ),
            const Text('Promosikan Layanan'),
          ],
        ),
        if (_isPromoted) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Mulai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _promotionStartDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );

                    if (picked != null) {
                      setState(() {
                        _promotionStartDate = picked;
                        _startDateController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                      });
                    }
                  },
                  validator: _isPromoted
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal mulai harus diisi';
                          }
                          return null;
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Selesai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    if (_promotionStartDate == null) {
                      AppMessageUtils.showSnackbar(
                        context: context,
                        message: 'Pilih tanggal mulai terlebih dahulu',
                        type: MessageType.warning,
                      );
                      return;
                    }

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _promotionEndDate ??
                          _promotionStartDate!.add(const Duration(days: 1)),
                      firstDate: _promotionStartDate!,
                      lastDate: _promotionStartDate!.add(
                        const Duration(days: 365),
                      ),
                    );

                    if (picked != null) {
                      setState(() {
                        _promotionEndDate = picked;
                        _endDateController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                      });
                    }
                  },
                  validator: _isPromoted
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal selesai harus diisi';
                          }
                          return null;
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.service == null ? 'Tambah Layanan' : 'Simpan Perubahan',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
