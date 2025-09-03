import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';
import 'package:klik_jasa/features/common/services/domain/utils/category_icon_mapper.dart';
import 'package:logger/logger.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger();
  List<ServiceCategory> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Controller untuk form tambah/edit kategori
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // State untuk pemilihan icon
  String? _selectedIconName;
  String _selectedIconCategory = 'Lainnya'; // Default kategori icon

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategories();
    // Perbarui ikon kategori yang sudah ada
    _updateExistingCategoryIcons();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data saat aplikasi kembali aktif
    if (state == AppLifecycleState.resumed) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Memeriksa apakah nama kategori sudah ada di database
  Future<bool> _isCategoryNameUnique(String name, {int? excludeId}) async {
    try {
      var query = _supabaseClient
          .from('service_categories')
          .select('id')
          .eq('name', name);
      
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }
      
      final result = await query;
      return result.isEmpty;
    } catch (e) {
      _logger.e('Error checking category name uniqueness', error: e);
      return false;
    }
  }

  /// Method ini tidak lagi diperlukan karena kita menggunakan Material Icons
  /// Ikon akan di-generate secara dinamis berdasarkan nama kategori
  Future<void> _updateExistingCategoryIcons() async {
    _logger.i('Menggunakan Material Icons, tidak perlu update ikon');
  }

  // Mendapatkan warna cerah dan modern untuk setiap kategori
  Color _getCategoryColor(String categoryName) {
    final String nameLower = categoryName.toLowerCase();
    
    // Warna cerah dan modern yang lebih menarik
    if (nameLower.contains('kebersihan') || nameLower.contains('bersih')) {
      return const Color(0xFF00B4D8); // Biru cerah
    } else if (nameLower.contains('perbaikan') || nameLower.contains('repair')) {
      return const Color(0xFFF77F00); // Oranye cerah
    } else if (nameLower.contains('transportasi') || nameLower.contains('transport')) {
      return const Color(0xFFEF476F); // Merah muda cerah
    } else if (nameLower.contains('kesehatan') || nameLower.contains('health')) {
      return const Color(0xFFF72585); // Merah muda tua
    } else if (nameLower.contains('kecantikan') || nameLower.contains('beauty')) {
      return const Color(0xFFB5179E); // Ungu muda
    } else if (nameLower.contains('pendidikan') || 
               nameLower.contains('education') || 
               nameLower.contains('pelatihan')) {
      return const Color(0xFFF9C74F); // Kuning cerah
    } else if (nameLower.contains('teknologi') || nameLower.contains('tech')) {
      return const Color(0xFF4CC9F0); // Biru muda cerah
    } else if (nameLower.contains('kuliner') || nameLower.contains('food')) {
      return const Color(0xFFF94144); // Merah cerah
    } else if (nameLower.contains('olahraga') || nameLower.contains('sport')) {
      return const Color(0xFF43AA8B); // Hijau toska
    } else if (nameLower.contains('hiburan') || nameLower.contains('entertainment')) {
      return const Color(0xFF7209B7); // Ungu cerah
    } else if (nameLower.contains('acara') || nameLower.contains('event')) {
      return const Color(0xFFF8961E); // Oranye kekuningan
    } else {
      // Generate warna deterministik berdasarkan nama kategori
      final hash = categoryName.codeUnits.fold(0, (a, b) => a + b);
      final colors = [
        const Color(0xFF00B4D8), // Biru cerah
        const Color(0xFFF77F00), // Oranye cerah
        const Color(0xFFEF476F), // Merah muda cerah
        const Color(0xFFF72585), // Merah muda tua
        const Color(0xFFB5179E), // Ungu muda
        const Color(0xFF4CC9F0), // Biru muda cerah
        const Color(0xFF43AA8B), // Hijau toska
        const Color(0xFF7209B7), // Ungu cerah
      ];
      return colors[hash % colors.length];
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _supabaseClient
          .from('service_categories')
          .select()
          .order('name', ascending: true);

      _categories = data.map((item) => ServiceCategory.fromJson(item)).toList();
    } catch (e) {
      _errorMessage = 'Gagal mengambil data kategori: ${e.toString()}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
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

  /// Validasi kategori sebelum toggle status
  Future<void> _toggleCategoryStatusWithValidation(
    ServiceCategory category,
    bool newStatus,
  ) async {
    try {
      // Validasi bahwa kategori masih ada di database
      final existingCategory = await _supabaseClient
          .from('service_categories')
          .select('id')
          .eq('id', category.id)
          .maybeSingle();
      
      if (existingCategory == null) {
        // Kategori tidak ditemukan, refresh data dan tampilkan pesan
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kategori tidak ditemukan. Data telah diperbarui.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Kategori masih ada, lanjutkan toggle status
      await _toggleCategoryStatus(category, newStatus);
      
    } catch (e) {
      _logger.e('Error saat validasi kategori untuk toggle status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCategoryStatus(
    ServiceCategory category,
    bool newStatus,
  ) async {
    try {
      await _supabaseClient
          .from('service_categories')
          .update({'is_active': newStatus})
          .eq('id', category.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status kategori berhasil diperbarui.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCategories(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status kategori: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Validasi kategori sebelum edit
  Future<void> _editCategoryWithValidation(ServiceCategory category) async {
    try {
      // Validasi bahwa kategori masih ada di database
      final existingCategory = await _supabaseClient
          .from('service_categories')
          .select('*')
          .eq('id', category.id)
          .maybeSingle();
      
      if (existingCategory == null) {
        // Kategori tidak ditemukan, refresh data dan tampilkan pesan
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kategori tidak ditemukan. Data telah diperbarui.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Kategori masih ada, buka dialog edit dengan data terbaru
      final updatedCategory = ServiceCategory.fromJson(existingCategory);
      if (mounted) {
        _showCategoryFormDialog(category: updatedCategory);
      }
      
    } catch (e) {
      _logger.e('Error saat validasi kategori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Validasi kategori sebelum delete
  Future<void> _deleteCategoryWithValidation(ServiceCategory category) async {
    try {
      // Validasi bahwa kategori masih ada di database
      final existingCategory = await _supabaseClient
          .from('service_categories')
          .select('id')
          .eq('id', category.id)
          .maybeSingle();
      
      if (existingCategory == null) {
        // Kategori tidak ditemukan, refresh data dan tampilkan pesan
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kategori tidak ditemukan. Data telah diperbarui.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Kategori masih ada, lanjutkan delete
      await _deleteCategory(category.id);
      
    } catch (e) {
      _logger.e('Error saat validasi kategori untuk delete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(int categoryId) async {
    try {
      // Periksa apakah kategori digunakan oleh layanan
      final servicesUsingCategory = await _supabaseClient
          .from('services')
          .select('id')
          .eq('category_id', categoryId);

      if (servicesUsingCategory.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kategori ini sedang digunakan oleh layanan dan tidak dapat dihapus.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Jika tidak digunakan, hapus kategori
      await _supabaseClient
          .from('service_categories')
          .delete()
          .eq('id', categoryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCategories(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kategori: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCategory(String name, String description, String? iconName) async {
    try {
      await _supabaseClient.from('service_categories').insert({
        'name': name,
        'description': description,
        'is_active': true,
        'icon_name': iconName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCategories(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan kategori: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCategory(int categoryId, String name, String description, String? iconName) async {
    try {
      await _supabaseClient.from('service_categories').update({
        'name': name,
        'description': description,
        'icon_name': iconName,
      }).eq('id', categoryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCategories(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui kategori: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCategoryFormDialog({ServiceCategory? category}) async {
    // Reset controller atau isi dengan data kategori jika mengedit
    
    // Gunakan nilai dari kategori yang ada jika sedang edit
    // Jika tidak, gunakan nilai default
    _nameController.text = category?.name ?? '';
    _descriptionController.text = category?.description ?? '';
    _selectedIconName = category?.iconName;
    _selectedIconCategory = 'Lainnya'; // Default kategori icon

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Mendapatkan daftar kategori icon
          final iconCategories = CategoryIconMapper.getIconCategories();
          // Mendapatkan daftar icon berdasarkan kategori yang dipilih
          final iconsByCategory = CategoryIconMapper.getIconsByCategory(_selectedIconCategory);
          
          // Mendapatkan icon yang dipilih
          final selectedIcon = _selectedIconName != null
              ? CategoryIconMapper.getCategoryIconByName(_selectedIconName!)
              : null;
          
          return AlertDialog(
            title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kategori *',
                      hintText: 'Masukkan nama kategori',
                    ),
                  ),
                  // Tampilkan field deskripsi
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Masukkan deskripsi kategori',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Icon Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Dropdown untuk memilih kategori icon
                  DropdownButtonFormField<String>(
                    value: _selectedIconCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Icon',
                      border: OutlineInputBorder(),
                    ),
                    items: iconCategories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedIconCategory = value;
                          // Reset icon yang dipilih
                          _selectedIconName = null;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Grid untuk memilih icon
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: iconsByCategory.length,
                      itemBuilder: (context, index) {
                        final icon = iconsByCategory[index];
                        final isSelected = _selectedIconName == icon.name;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIconName = icon.name;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor.withAlpha(51) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Tooltip(
                              message: icon.label,
                              child: Icon(
                                icon.icon,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preview icon yang dipilih
                  if (selectedIcon != null)
                    Row(
                      children: [
                        Icon(
                          selectedIcon.icon,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Icon dipilih: ${selectedIcon.label}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Belum ada icon yang dipilih',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  // Validasi input
                  if (_nameController.text.trim().isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama kategori tidak boleh kosong'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Simpan context sebelum operasi async
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  
                  // Validasi nama kategori unik
                  final isUnique = await _isCategoryNameUnique(
                    _nameController.text.trim(),
                    excludeId: category?.id,
                  );

                  if (!isUnique) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Nama kategori sudah digunakan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Proses simpan atau update
                  if (category == null) {
                    // Tambah kategori baru
                    await _addCategory(
                      _nameController.text.trim(),
                      _descriptionController.text.trim(),
                      _selectedIconName,
                    );
                  } else {
                    // Update kategori yang ada
                    await _updateCategory(
                      category.id,
                      _nameController.text.trim(),
                      _descriptionController.text.trim(),
                      _selectedIconName,
                    );
                  }

                  if (mounted) {
                    navigator.pop();
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryFormDialog(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildCategoryList(),
    );
  }

  Widget _buildCategoryList() {
    if (_errorMessage != null && _categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCategories,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(
              child: Text(
                'Belum ada kategori. Tambahkan kategori pertama!',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final iconData = CategoryIconMapper.getIconData(category.name, iconName: category.iconName);
          final color = _getCategoryColor(category.name);
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withAlpha(51),
                child: Icon(iconData, color: color),
              ),
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.description != null && category.description!.isNotEmpty)
                    Text(category.description!),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${category.isActive ? "Aktif" : "Tidak Aktif"}',
                    style: TextStyle(
                      color: category.isActive ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: category.isActive,
                  onChanged: (newValue) => _toggleCategoryStatusWithValidation(category, newValue),
                  activeColor: Colors.green,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editCategoryWithValidation(category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Konfirmasi'),
                        content: const Text(
                          'Apakah Anda yakin ingin menghapus kategori ini?\n'
                          'Kategori yang digunakan oleh layanan tidak dapat dihapus.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteCategoryWithValidation(category);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            isThreeLine: category.description != null && category.description!.isNotEmpty,
          ),
        );
        },
      ),
    );
  }
}
