import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../services/region_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedCityId;
  String? _selectedCityName;
  String? _selectedDistrictId;
  String? _selectedDistrictName;
  String? _selectedVillageId;
  String? _selectedVillageName;
  bool _isLoading = false;
  bool _isLoadingProvinces = true;
  bool _isLoadingCities = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingVillages = false;
  
  // For image handling
  File? _ktpImageFile;
  Uint8List? _ktpImageBytes;
  String? _ktpImageName;
  final _imagePicker = ImagePicker();
  
  // Data for regions
  List<RegionModel> _provinces = [];
  List<RegionModel> _cities = [];
  List<RegionModel> _districts = [];
  List<RegionModel> _villages = [];

  @override
  void initState() {
    super.initState();
    // Clear cache to ensure fresh data
    RegionService.clearCache().then((_) {
      _loadProvinces();
    });
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });

    try {
      _provinces = await RegionService.getProvinces();
      
      if (_provinces.isEmpty) {
        // If API returns empty list, try direct fetch as fallback
        final response = await http.get(Uri.parse('https://www.emsifa.com/api-wilayah-indonesia/api/provinces.json'));
        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          _provinces = data.map((json) => RegionModel.fromJson(json)).toList();
        }
      }
      
      setState(() {
        _isLoadingProvinces = false;
      });
      
      // Debug print to check data
      debugPrint('Loaded ${_provinces.length} provinces');
      if (_provinces.isNotEmpty) {
        debugPrint('First province: ${_provinces.first.name}');
      }
    } catch (e) {
      debugPrint('Error loading provinces: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data provinsi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingProvinces = false;
      });
    }
  }

  Future<void> _loadCities(String provinceId) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCityId = null;
      _selectedCityName = null;
      _districts = [];
      _selectedDistrictId = null;
      _selectedDistrictName = null;
    });

    try {
      _cities = await RegionService.getCities(provinceId);
      
      if (_cities.isEmpty) {
        // If API returns empty list, try direct fetch as fallback
        final response = await http.get(Uri.parse('https://www.emsifa.com/api-wilayah-indonesia/api/regencies/${provinceId}.json'));
        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          _cities = data.map((json) => RegionModel.fromJson(json)).toList();
        }
      }
      
      setState(() {
        _isLoadingCities = false;
      });
      
      // Debug print to check data
      debugPrint('Loaded ${_cities.length} cities for province $provinceId');
      if (_cities.isNotEmpty) {
        debugPrint('First city: ${_cities.first.name} (${RegionService.formatRegionName(_cities.first.name)})');
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data kota/kabupaten: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrictId = null;
      _selectedDistrictName = null;
      _villages = [];
      _selectedVillageId = null;
      _selectedVillageName = null;
    });

    try {
      _districts = await RegionService.getDistricts(cityId);
      
      if (_districts.isEmpty) {
        // If API returns empty list, try direct fetch as fallback
        final response = await http.get(Uri.parse('https://www.emsifa.com/api-wilayah-indonesia/api/districts/${cityId}.json'));
        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          _districts = data.map((json) => RegionModel.fromJson(json)).toList();
        }
      }
      
      setState(() {
        _isLoadingDistricts = false;
      });
      
      // Debug print to check data
      debugPrint('Loaded ${_districts.length} districts for city $cityId');
      if (_districts.isNotEmpty) {
        debugPrint('First district: ${_districts.first.name}');
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data kecamatan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }
  
  Future<void> _loadVillages(String districtId) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      _selectedVillageId = null;
      _selectedVillageName = null;
    });

    try {
      _villages = await RegionService.getVillages(districtId);
      
      if (_villages.isEmpty) {
        // If API returns empty list, try direct fetch as fallback
        final response = await http.get(Uri.parse('https://www.emsifa.com/api-wilayah-indonesia/api/villages/${districtId}.json'));
        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          _villages = data.map((json) => RegionModel.fromJson(json)).toList();
        }
      }
      
      setState(() {
        _isLoadingVillages = false;
      });
      
      // Debug print to check data
      debugPrint('Loaded ${_villages.length} villages for district $districtId');
      if (_villages.isNotEmpty) {
        debugPrint('First village: ${_villages.first.name}');
      }
    } catch (e) {
      debugPrint('Error loading villages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data desa/kelurahan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingVillages = false;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProvinceId == null || _selectedCityId == null || _selectedDistrictId == null || _selectedVillageId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih provinsi, kota, dan kecamatan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_ktpImageFile == null && _ktpImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan unggah foto KTP Anda'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final storageProvider = Provider.of<StorageProvider>(context, listen: false);
        
        // Membuat alamat lengkap
        final fullAddress = '${_addressController.text}, $_selectedVillageName, $_selectedDistrictName, $_selectedCityName, $_selectedProvinceName';
        
        // Upload KTP image
        String? ktpImageUrl;
        try {
          if (_ktpImageFile != null || _ktpImageBytes != null) {
            ktpImageUrl = await storageProvider.uploadKtpImage(
              _ktpImageFile, 
              _ktpImageBytes,
              _ktpImageName,
              authProvider.user!.id
            );
            
            debugPrint('KTP berhasil diupload: $ktpImageUrl');
          } else {
            debugPrint('Tidak ada file KTP yang dipilih');
          }
        } catch (uploadError) {
          debugPrint('Error saat mengupload KTP: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengupload KTP: ${uploadError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Lanjutkan proses pendaftaran meskipun upload KTP gagal
          // User dapat mencoba lagi nanti
        }
        
        try {
          await authProvider.registerAsProvider(
            phoneNumber: _phoneController.text,
            address: fullAddress,
            ktpImageUrl: ktpImageUrl,
          );
          
          debugPrint('Pendaftaran penyedia jasa berhasil dikirim');
        } catch (registerError) {
          debugPrint('Error saat mendaftar sebagai penyedia jasa: $registerError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mendaftar: ${registerError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; // Keluar dari fungsi jika pendaftaran gagal
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil dikirim! Menunggu verifikasi admin.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mendaftar: ${e.toString()}'),
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

  Future<void> _uploadKTP() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        // Handle differently for web and mobile
        if (kIsWeb) {
          // Web platform
          try {
            final imageBytes = await pickedFile.readAsBytes();
            setState(() {
              _ktpImageBytes = imageBytes;
              _ktpImageFile = null;
              _ktpImageName = pickedFile.name;
            });
            
            debugPrint('Foto KTP dipilih (web): ${pickedFile.name}');
            debugPrint('Ukuran foto KTP (web): ${imageBytes.length} bytes');
          } catch (webError) {
            debugPrint('Error saat membaca file di web: $webError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membaca file: ${webError.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          // Mobile platform
          try {
            final imageFile = File(pickedFile.path);
            
            // Check if file exists and is readable
            if (await imageFile.exists()) {
              setState(() {
                _ktpImageFile = imageFile;
                _ktpImageBytes = null;
                _ktpImageName = pickedFile.name;
              });

              debugPrint('Foto KTP dipilih (mobile): ${imageFile.path}');
              debugPrint('Ukuran foto KTP (mobile): ${await imageFile.length()} bytes');
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
          } catch (mobileError) {
            debugPrint('Error saat membaca file di mobile: $mobileError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membaca file: ${mobileError.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
        
        // Show success message for both platforms
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto KTP berhasil dipilih'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saat memilih foto KTP: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Penyedia Jasa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Untuk menjadi penyedia jasa, Anda perlu melengkapi data diri dan mengunggah foto KTP. Data Anda akan diverifikasi oleh admin dalam 1-2 hari kerja.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              const Text(
                'Data Diri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nomor WhatsApp',
                hint: 'Contoh: 08123456789',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor WhatsApp tidak boleh kosong';
                  }
                  if (!RegExp(r'^[0-9]{10,13}$').hasMatch(value)) {
                    return 'Format nomor WhatsApp tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Alamat
              const Text(
                'Alamat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Provinsi
              _isLoadingProvinces
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Provinsi',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedProvinceId,
                    items: _provinces.map((RegionModel province) {
                      return DropdownMenuItem<String>(
                        value: province.id,
                        child: Text(province.name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        final selectedProvince = _provinces.firstWhere((p) => p.id == newValue);
                        setState(() {
                          _selectedProvinceId = newValue;
                          _selectedProvinceName = selectedProvince.name;
                        });
                        _loadCities(newValue);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih provinsi';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),
              
              // Kota/Kabupaten
              _isLoadingCities
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Kota/Kabupaten',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCityId,
                    items: _cities.map((RegionModel city) {
                      // Format city name to remove prefixes like "Kabupaten"
                      String formattedName = RegionService.formatRegionName(city.name);
                      return DropdownMenuItem<String>(
                        value: city.id,
                        child: Text(formattedName),
                      );
                    }).toList(),
                    onChanged: _cities.isEmpty
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            final selectedCity = _cities.firstWhere((c) => c.id == newValue);
                            String formattedName = RegionService.formatRegionName(selectedCity.name);
                            setState(() {
                              _selectedCityId = newValue;
                              _selectedCityName = formattedName;
                            });
                            _loadDistricts(newValue);
                          }
                        },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih kota/kabupaten';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),
              
              // Kecamatan
              _isLoadingDistricts
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Kecamatan',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDistrictId,
                    items: _districts.map((RegionModel district) {
                      return DropdownMenuItem<String>(
                        value: district.id,
                        child: Text(district.name),
                      );
                    }).toList(),
                    onChanged: _districts.isEmpty
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            final selectedDistrict = _districts.firstWhere((d) => d.id == newValue);
                            setState(() {
                              _selectedDistrictId = newValue;
                              _selectedDistrictName = selectedDistrict.name;
                            });
                            _loadVillages(newValue);
                          }
                        },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih kecamatan';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),
              
              // Desa/Kelurahan
              _isLoadingVillages
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Desa/Kelurahan',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedVillageId,
                    items: _villages.map((RegionModel village) {
                      return DropdownMenuItem<String>(
                        value: village.id,
                        child: Text(RegionService.formatRegionName(village.name)),
                      );
                    }).toList(),
                    onChanged: _villages.isEmpty
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            final selectedVillage = _villages.firstWhere((v) => v.id == newValue);
                            setState(() {
                              _selectedVillageId = newValue;
                              _selectedVillageName = RegionService.formatRegionName(selectedVillage.name);
                            });
                          }
                        },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih desa/kelurahan';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),
              
              // Alamat Lengkap
              CustomTextField(
                label: 'Alamat Lengkap',
                hint: 'Contoh: Jl. Merdeka No. 123, RT 01/RW 02',
                controller: _addressController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Upload KTP
              const Text(
                'Foto KTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unggah foto KTP Anda',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _uploadKTP,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Pilih Foto KTP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _ktpImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _ktpImageBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Error loading KTP image bytes: $error');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                                        const SizedBox(height: 8),
                                        const Text('Gagal memuat gambar', textAlign: TextAlign.center),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : _ktpImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _ktpImageFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading KTP image file: $error');
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                                            const SizedBox(height: 8),
                                            const Text('Gagal memuat gambar', textAlign: TextAlign.center),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                          : const Center(
                              child: Text(
                                'Pratinjau KTP',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Mengirim...' : 'Kirim Pendaftaran',
                  onPressed: _isLoading ? null : _submitRegistration,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
