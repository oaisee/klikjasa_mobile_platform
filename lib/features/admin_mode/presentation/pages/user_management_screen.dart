import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/user_management_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/provider_verification/provider_verification_bloc.dart';
import 'package:klik_jasa/features/admin_mode/data/repositories/provider_verification_repository_impl.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/admin_provider_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedRole = 'all';

  // Daftar role yang tersedia (akan diisi dari data)
  final List<Map<String, String>> _availableRoles = [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'user', 'label': 'Pengguna'},
    {'value': 'provider', 'label': 'Penyedia'},
    {'value': 'admin', 'label': 'Admin'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Memuat data pengguna saat inisialisasi
    context.read<UserManagementBloc>().add(FetchUserProfiles());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Reset filter saat tab berubah
        _selectedRole = 'all';
        _searchQuery = '';
      });

      final userManagementBloc = BlocProvider.of<UserManagementBloc>(context);

      // Muat data sesuai tab yang dipilih
      switch (_tabController.index) {
        case 0: // Tab Pengguna
          // Muat data pengguna biasa (is_provider = false)
          userManagementBloc.add(const FetchUserProfilesByType(false));
          break;
        case 1: // Tab Penyedia
          // Muat data penyedia jasa (is_provider = true)
          userManagementBloc.add(const FetchUserProfilesByType(true));
          break;
        case 2: // Tab Verifikasi
          // Muat data verifikasi penyedia
          final verificationBloc = BlocProvider.of<ProviderVerificationBloc>(
            context,
          );
          verificationBloc.add(LoadPendingVerifications());
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AppBar dikelola oleh AdminDashboardScreen karena ini adalah child dari ShellRoute
    return BlocProvider<ProviderVerificationBloc>(
      create: (context) => ProviderVerificationBloc(
        repository: ProviderVerificationRepositoryImpl(
          supabase: Supabase.instance.client,
        ),
      )..add(LoadPendingVerifications()),
      child: BlocListener<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is ResetPasswordInProgress) {
            // Tampilkan loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Sedang mereset password...'),
                  ],
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is ResetPasswordSuccess) {
            // Tampilkan pesan sukses
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password berhasil direset menjadi "Password123!". Pengguna dapat login dengan password default tersebut.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            // Refresh data pengguna
            context.read<UserManagementBloc>().add(
              const FetchUserProfilesByType(false),
            );
          } else if (state is ResetPasswordFailure) {
            // Tampilkan pesan error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mereset password: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Scaffold(
          // Tidak perlu AppBar di sini karena sudah ada di AdminDashboardScreen (ShellRoute)
          body: Column(
            children: [
              _buildTabBar(),
              _buildFilterControls(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Pengguna
                    _buildAllUsersTab(),
                    // Tab 2: Penyedia
                    _buildProviderUsersTab(),
                    // Tab 3: Verifikasi
                    _buildProviderVerificationContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    // Gunakan BlocSelector untuk efisiensi, hanya rebuild saat jumlah berubah
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, userState) {
        int totalUsers = 0;
        int totalProviders = 0;

        if (userState is UserManagementLoaded) {
          // Hitung jumlah pengguna biasa (bukan admin)
          totalUsers = userState.userProfiles
              .where((user) => user.role != 'admin')
              .length;

          // Hitung jumlah penyedia jasa yang sudah terverifikasi
          totalProviders = userState.userProfiles
              .where(
                (user) =>
                    user.role != 'admin' &&
                    (user.providerVerificationStatus == 'verified' ||
                        user.providerVerificationStatus == 'Terverifikasi'),
              )
              .length;
        }

        // Gunakan BlocBuilder terpisah untuk ProviderVerificationBloc
        // untuk mendapatkan jumlah verifikasi yang akurat
        return BlocBuilder<ProviderVerificationBloc, ProviderVerificationState>(
          builder: (context, verificationState) {
            int totalPendingVerification = 0;

            // Ambil jumlah pending verifikasi dari state ProviderVerificationBloc
            if (verificationState is ProviderVerificationLoaded) {
              totalPendingVerification =
                  verificationState.pendingProviders.length;
            }

            return Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                isScrollable: true,
                tabs: [
                  Tab(child: Text('Pengguna ($totalUsers)')),
                  Tab(child: Text('Penyedia ($totalProviders)')),
                  Tab(child: Text('Verifikasi ($totalPendingVerification)')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterControls() {
    // Gunakan layout yang responsif berdasarkan ukuran layar
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Cek apakah kita berada di tab Penyedia Jasa atau tidak
    final bool showRoleFilter = _tabController.index == 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isSmallScreen
          // Layout vertikal untuk layar kecil
          ? Column(
              children: [
                // Kolom pencarian selalu ditampilkan
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari pengguna...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                // Dropdown filter role hanya ditampilkan di tab Semua Pengguna
                if (showRoleFilter) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filter Role',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedRole,
                    isExpanded: true,
                    items: _availableRoles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role['value'],
                            child: Text(role['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ],
              ],
            )
          // Layout horizontal untuk layar besar
          : Row(
              children: [
                // Kolom pencarian selalu ditampilkan
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari pengguna...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Dropdown filter role hanya ditampilkan di tab Semua Pengguna
                showRoleFilter
                    ? Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Filter Role',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value: _selectedRole,
                          isExpanded: true,
                          items: _availableRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role['value'],
                                  child: Text(role['label']!),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      )
                    // Spacer untuk menjaga layout tetap seimbang pada tab lain
                    : const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
    );
  }

  Widget _buildAllUsersTab() {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is UserManagementLoaded) {
          // Filter pencarian saja, karena filter is_provider sudah dilakukan di database
          final filteredUsers = state.userProfiles
              .where(
                (user) =>
                    _searchQuery.isEmpty ||
                    (user.fullName?.toLowerCase().contains(_searchQuery) ??
                        false) ||
                    (user.email?.toLowerCase().contains(_searchQuery) ?? false),
              )
              .toList();

          if (filteredUsers.isEmpty) {
            return const Center(
              child: Text('Tidak ada data pengguna yang sesuai.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Gunakan event baru untuk mengambil data pengguna biasa
              context.read<UserManagementBloc>().add(
                const FetchUserProfilesByType(false),
              );
            },
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final UserProfile user = filteredUsers[index];
                return _buildUserListItem(user);
              },
            ),
          );
        }
        if (state is UserManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Gagal memuat pengguna: ${state.message}'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Gunakan event baru untuk mengambil data pengguna biasa
                    context.read<UserManagementBloc>().add(
                      const FetchUserProfilesByType(false),
                    );
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Silakan muat data pengguna.'));
      },
    );
  }

  Widget _buildProviderUsersTab() {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is UserManagementLoaded) {
          // Filter pencarian saja, karena filter is_provider sudah dilakukan di database
          final filteredProviders = state.userProfiles
              .where(
                (user) =>
                    _searchQuery.isEmpty ||
                    (user.fullName?.toLowerCase().contains(_searchQuery) ??
                        false) ||
                    (user.email?.toLowerCase().contains(_searchQuery) ?? false),
              )
              .toList();

          if (filteredProviders.isEmpty) {
            return const Center(
              child: Text('Tidak ada data penyedia jasa yang sesuai.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Gunakan event baru untuk mengambil data penyedia jasa
              context.read<UserManagementBloc>().add(
                const FetchUserProfilesByType(true),
              );
            },
            child: ListView.builder(
              itemCount: filteredProviders.length,
              itemBuilder: (context, index) {
                final UserProfile provider = filteredProviders[index];
                return _buildProviderListItem(provider);
              },
            ),
          );
        }
        if (state is UserManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Gagal memuat penyedia jasa: ${state.message}'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Gunakan event baru untuk mengambil data penyedia jasa
                    context.read<UserManagementBloc>().add(
                      const FetchUserProfilesByType(true),
                    );
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Silakan muat data penyedia jasa.'));
      },
    );
  }

  // Metode _buildProviderVerificationTab sudah didefinisikan di atas

  Widget _buildProviderVerificationContent() {
    return BlocConsumer<ProviderVerificationBloc, ProviderVerificationState>(
      listener: (context, state) {
        if (state is ProviderVerificationUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProviderVerificationUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is ProviderVerificationLoading ||
            state is ProviderVerificationUpdateInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProviderVerificationError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProviderVerificationBloc>().add(
                        LoadPendingVerifications(),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is ProviderVerificationLoaded) {
          if (state.pendingProviders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tidak ada penyedia jasa yang menunggu verifikasi saat ini.',
                ),
              ),
            );
          }

          final filteredProviders = state.pendingProviders
              .where(
                (provider) =>
                    _searchQuery.isEmpty ||
                    (provider.fullName?.toLowerCase().contains(_searchQuery) ??
                        false) ||
                    (provider.email?.toLowerCase().contains(_searchQuery) ??
                        false),
              )
              .toList();

          if (filteredProviders.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada penyedia jasa yang sesuai dengan pencarian.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProviderVerificationBloc>().add(
                LoadPendingVerifications(),
              );
            },
            child: ListView.builder(
              itemCount: filteredProviders.length,
              itemBuilder: (context, index) {
                final provider = filteredProviders[index];
                return _buildVerificationListItem(provider);
              },
            ),
          );
        }
        return const Center(child: Text('Silakan muat data penyedia.'));
      },
    );
  }

  Widget _buildUserListItem(UserProfile user) {
    // Menentukan warna status pengguna
    Color statusColor = Colors.green;
    String statusText = 'Aktif';

    if (user.userStatus == 'blocked') {
      statusColor = Colors.red;
      statusText = 'Diblokir';
    } else if (user.userStatus == 'inactive') {
      statusColor = Colors.grey;
      statusText = 'Nonaktif';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user.email?.substring(0, 1).toUpperCase() ??
                user.fullName?.substring(0, 1).toUpperCase() ??
                '?',
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName ?? user.email ?? 'Pengguna tidak dikenal',
              ),
            ),
            if (user.userStatus != 'active')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${user.role ?? 'N/A'}'),
            Text('ID: ${user.id.substring(0, 8)}...'),
            Text(
              'Joined: ${user.createdAt != null ? '${user.createdAt!.toLocal().year}-${user.createdAt!.toLocal().month}-${user.createdAt!.toLocal().day}' : 'N/A'}',
            ),
          ],
        ),
        onTap: () {
          _showUserDetailDialog(user);
        },
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildProviderListItem(UserProfile provider) {
    final verificationStatus = provider.providerVerificationStatus ?? 'unknown';
    Color statusColor;

    switch (verificationStatus) {
      case 'verified':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            provider.email?.substring(0, 1).toUpperCase() ??
                provider.fullName?.substring(0, 1).toUpperCase() ??
                '?',
          ),
        ),
        title: Text(
          provider.fullName ?? provider.email ?? 'Penyedia tidak dikenal',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${provider.email ?? 'N/A'}'),
            Row(
              children: [
                Text('Status: '),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51), // 0.2 * 255 = 51
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getVerificationStatusText(verificationStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Joined: ${provider.createdAt != null ? '${provider.createdAt!.toLocal().year}-${provider.createdAt!.toLocal().month}-${provider.createdAt!.toLocal().day}' : 'N/A'}',
            ),
          ],
        ),
        onTap: () {
          _navigateToProviderDetail(provider);
        },
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildVerificationListItem(UserProfile provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(provider.fullName ?? 'Nama Tidak Tersedia'),
        onTap: () {
          _navigateToProviderDetail(provider);
        },
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.email ?? 'Email tidak tersedia'),
            Text('ID: ${provider.id}'),
            Text('Status: ${provider.providerVerificationStatus ?? 'N/A'}'),
            if (provider.createdAt != null)
              Text(
                'Terdaftar: ${provider.createdAt!.toLocal().toString().substring(0, 16)}',
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Setujui',
              onPressed: () {
                _showConfirmationDialog(provider, true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Tolak',
              onPressed: () {
                _showConfirmationDialog(provider, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailDialog(UserProfile user) {
    // Status pengguna saat ini
    String currentStatus = user.userStatus ?? 'active';
    String statusText = '';
    Color statusColor = Colors.green;

    // Menentukan teks dan warna status
    if (currentStatus == 'blocked') {
      statusText = 'Diblokir';
      statusColor = Colors.red;
    } else if (currentStatus == 'inactive') {
      statusText = 'Nonaktif';
      statusColor = Colors.grey;
    } else {
      statusText = 'Aktif';
      statusColor = Colors.green;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.fullName ?? user.email ?? 'Detail Pengguna'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID:', user.id),
                _buildDetailRow('Email:', user.email ?? 'N/A'),
                _buildDetailRow('Nama:', user.fullName ?? 'N/A'),
                _buildDetailRow('Role:', user.role ?? 'N/A'),
                _buildDetailRow('Telepon:', user.phoneNumber ?? 'N/A'),
                _buildDetailRow(
                  'Terdaftar:',
                  user.createdAt != null
                      ? user.createdAt!.toLocal().toString().substring(0, 16)
                      : 'N/A',
                ),
                if (user.role == 'provider')
                  _buildDetailRow(
                    'Status Verifikasi:',
                    _getVerificationStatusText(
                      user.providerVerificationStatus ?? 'unknown',
                    ),
                  ),
                // Menampilkan status pengguna
                Row(
                  children: [
                    const Text(
                      'Status Pengguna: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (user.role == 'provider')
              TextButton(
                child: const Text('Lihat Detail Penyedia'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToProviderDetail(user);
                },
              ),
            // Tombol untuk reset password pengguna
            TextButton(
              child: const Text(
                'Reset Password',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                _showResetPasswordConfirmation(user);
              },
            ),
            // Tombol untuk mengubah status pengguna
            if (currentStatus == 'active')
              TextButton(
                child: const Text(
                  'Blokir Pengguna',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  _updateUserStatus(user, 'blocked');
                  Navigator.of(context).pop();
                },
              ),
            if (currentStatus == 'active')
              TextButton(
                child: const Text(
                  'Nonaktifkan',
                  style: TextStyle(color: Colors.orange),
                ),
                onPressed: () {
                  _updateUserStatus(user, 'inactive');
                  Navigator.of(context).pop();
                },
              ),
            if (currentStatus != 'active')
              TextButton(
                child: const Text(
                  'Aktifkan Kembali',
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  _updateUserStatus(user, 'active');
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showResetPasswordConfirmation(UserProfile user) {
    // Simpan context saat ini yang memiliki akses ke UserManagementBloc
    final outerContext = context;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Reset Password'),
          content: Text(
            'Anda yakin ingin mereset password untuk pengguna ${user.fullName ?? user.email ?? 'ini'}? '
            'Pengguna akan diminta untuk membuat password baru saat login berikutnya.',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Reset Password',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                // Tutup dialog konfirmasi
                Navigator.of(dialogContext).pop();
                // Tutup dialog detail pengguna
                Navigator.of(dialogContext).pop();
                // Panggil event reset password menggunakan context luar
                outerContext.read<UserManagementBloc>().add(
                  ResetUserPassword(user.id),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToProviderDetail(UserProfile provider) {
    // Coba dapatkan instance BLoC yang ada dari context saat ini
    // Gunakan try-catch untuk menangani kasus ketika bloc tidak tersedia
    try {
      final verificationBloc = BlocProvider.of<ProviderVerificationBloc>(
        context,
        listen: false,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          // Gunakan BlocProvider.value untuk menyediakan BLoC yang ada ke route baru
          builder: (newContext) => BlocProvider.value(
            value: verificationBloc,
            child: AdminProviderDetailScreen(userProfile: provider),
          ),
        ),
      );
    } catch (e) {
      // Jika bloc tidak tersedia, buat instance baru
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (newContext) => BlocProvider(
            create: (_) => ProviderVerificationBloc(
              repository: ProviderVerificationRepositoryImpl(
                supabase: Supabase.instance.client,
              ),
            ),
            child: AdminProviderDetailScreen(userProfile: provider),
          ),
        ),
      );
    }
  }

  // Metode untuk mengubah status pengguna (aktif/nonaktif/blokir)
  void _updateUserStatus(UserProfile user, String newStatus) {
    // Tampilkan loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memperbarui status pengguna...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Gunakan Supabase untuk update status pengguna
      Supabase.instance.client
          .from('profiles')
          .update({'user_status': newStatus})
          .eq('id', user.id)
          .then((response) {
            if (response.error != null) {
              // Tampilkan error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Gagal memperbarui status: ${response.error!.message}',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              // Tampilkan sukses
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Status pengguna berhasil diperbarui menjadi $newStatus',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Refresh data pengguna dengan mengirim event ke bloc
              if (mounted) {
                context.read<UserManagementBloc>().add(FetchUserProfiles());
              }
            }
          });
    } catch (e) {
      // Tangani error yang mungkin terjadi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showConfirmationDialog(UserProfile provider, bool approve) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(approve ? 'Setujui Penyedia?' : 'Tolak Penyedia?'),
          content: Text(
            'Apakah Anda yakin ingin ${approve ? 'menyetujui' : 'menolak'} penyedia jasa ${provider.fullName ?? provider.email}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(approve ? 'Setujui' : 'Tolak'),
              onPressed: () {
                if (approve) {
                  context.read<ProviderVerificationBloc>().add(
                    ApproveProviderVerification(provider.id),
                  );
                } else {
                  context.read<ProviderVerificationBloc>().add(
                    RejectProviderVerification(provider.id),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getVerificationStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Tidak Diketahui';
    }
  }
}
