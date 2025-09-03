import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';
import '../../domain/entities/promotional_banner.dart';

class AddEditBannerScreen extends StatefulWidget {
  final PromotionalBanner? banner;

  const AddEditBannerScreen({super.key, this.banner});

  @override
  State<AddEditBannerScreen> createState() => _AddEditBannerScreenState();
}

class _AddEditBannerScreenState extends State<AddEditBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _targetUrlController;
  late TextEditingController _sortOrderController;
  bool _isActive = true;
  XFile? _selectedImage;
  String? _networkImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title);
    _targetUrlController = TextEditingController(text: widget.banner?.targetUrl);
    _sortOrderController = TextEditingController(text: widget.banner?.sortOrder.toString() ?? '0');
    _isActive = widget.banner?.isActive ?? true;
    _networkImageUrl = widget.banner?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _networkImageUrl = null; // Hapus network image jika gambar baru dipilih
        });
      }
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

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final String filePath = 'public/promotional_banners/$fileName';
      
      await _supabase.storage
          .from('banners') // Nama bucket di Supabase Storage
          .upload(filePath, File(imageFile.path), fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
      
      // Mendapatkan URL publik dari gambar yang diunggah
      final String publicUrl = _supabase.storage.from('banners').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Gagal mengunggah gambar: ${e.toString()}',
          type: MessageType.error,
        );
      }
      return null;
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    String? imageUrl = _networkImageUrl; // Gunakan network image jika ada dan tidak ada gambar baru

    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return; // Gagal upload gambar, jangan lanjutkan
      }
    }

    if (imageUrl == null) {
        if (mounted) {
            AppMessageUtils.showSnackbar(
               context: context,
               message: 'Gambar banner wajib diisi.',
               type: MessageType.error,
             );
        }
        setState(() {_isLoading = false;});
        return;
    }

    final bannerData = {
      'title': _titleController.text.trim(),
      'target_url': _targetUrlController.text.trim(),
      'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
      'is_active': _isActive,
      'image_url': imageUrl,
      'uploaded_by': _supabase.auth.currentUser?.id, // Mencatat admin yang mengunggah
    };

    try {
      if (widget.banner == null) {
        // Tambah banner baru
        await _supabase.from('promotional_banners').insert(bannerData);
      } else {
        // Edit banner yang ada
        await _supabase.from('promotional_banners').update(bannerData).match({'id': widget.banner!.id});
      }
      if (mounted) {
        AppMessageUtils.showSnackbar(
           context: context,
           message: 'Banner berhasil disimpan!',
           type: MessageType.success,
         );
        Navigator.of(context).pop(true); // Kembali dan kirim sinyal untuk refresh
      }
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
           context: context,
           message: 'Gagal menyimpan banner: ${e.toString()}',
           type: MessageType.error,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banner == null ? 'Tambah Banner Baru' : 'Edit Banner'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Preview Gambar dan Tombol Pilih Gambar
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _selectedImage != null
                            ? Image.file(File(_selectedImage!.path), fit: BoxFit.contain)
                            : _networkImageUrl != null
                                ? Image.network(_networkImageUrl!, fit: BoxFit.contain, 
                                  errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey))
                                : const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_search),
                      label: Text(_selectedImage != null || _networkImageUrl != null ? 'Ganti Gambar' : 'Pilih Gambar Banner'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Rekomendasi: JPG/PNG, rasio 16:9 atau 3:1 (misal 1200x675 atau 1200x400), maks 1-2MB.',
                       style: TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Judul Banner (Opsional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetUrlController,
                      decoration: const InputDecoration(labelText: 'URL Tujuan (Opsional, contoh: /layanan/123 atau https://...)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sortOrderController,
                      decoration: const InputDecoration(labelText: 'Urutan Tampil (Angka, kecil duluan)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Urutan tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Aktifkan Banner Ini?'),
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppColors.accent,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveBanner,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Simpan Banner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
