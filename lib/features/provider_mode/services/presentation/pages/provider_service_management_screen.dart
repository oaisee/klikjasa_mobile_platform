import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/core/constants/app_colors.dart'; // Untuk warna tema
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_provider_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/delete_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/toggle_service_promotion_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/toggle_service_active_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/injection_container.dart' as sl;


class ProviderServiceManagementScreen extends StatefulWidget {
  static const String routeName = '/provider-service-management';
  const ProviderServiceManagementScreen({super.key});

  @override
  State<ProviderServiceManagementScreen> createState() =>
      _ProviderServiceManagementScreenState();
}

class _ProviderServiceManagementScreenState
    extends State<ProviderServiceManagementScreen> {
  List<Service> _layanan = [];
  bool _isLoading = true;
  String? _errorMessage;

  late final GetProviderLayananUseCase _getProviderLayananUseCase;
  late final DeleteLayananUseCase _deleteLayananUseCase;
  late final ToggleServiceActiveUseCase _toggleServiceActiveUseCase;

  @override
  void initState() {
    super.initState();
    _getProviderLayananUseCase = sl.sl<GetProviderLayananUseCase>();
    _deleteLayananUseCase = sl.sl<DeleteLayananUseCase>();
    _toggleServiceActiveUseCase = sl.sl<ToggleServiceActiveUseCase>();
    _fetchLayananPenyedia();
  }

  Future<void> _fetchLayananPenyedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authState = context.read<AuthBloc>().state;
    String providerId = '';

    if (authState is AuthAuthenticated) {
      providerId = authState.user.id;
    }

    if (providerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tidak dapat mengambil ID penyedia. Pastikan Anda sudah login.';
        });
      }
      return;
    }

    final result = await _getProviderLayananUseCase(GetProviderLayananParams(providerId: providerId));

    if (mounted) {
      setState(() {
        result.fold(
          (failure) {
            _errorMessage = failure.message;
          },
          (layananList) {
            _layanan = layananList;
          },
        );
        _isLoading = false;
      });
    }
  }

  void _tambahLayanan() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    final contextRef = context;
    final result = await contextRef.pushNamed<bool>(
      'addEditLayanan',
      extra: {
        'providerId': authState.user.id,
      },
    );

    if (result == true && mounted) {
      _fetchLayananPenyedia();
    }
  }

  void _editLayanan(Service layanan) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    final contextRef = context;
    final result = await contextRef.pushNamed<bool>(
      'addEditLayanan',
      extra: {
        'providerId': authState.user.id,
        'layanan': layanan,
      },
    );

    if (result == true && mounted) {
      _fetchLayananPenyedia();
    }
  }

  void _toggleLayananActive(Service layanan) async {
    setState(() {
      _isLoading = true;
    });

    final result = await _toggleServiceActiveUseCase(
      ToggleServiceActiveParams(serviceId: layanan.id),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengubah status layanan: ${failure.message}')),
          );
        },
        (updatedService) {
          final statusText = updatedService.isActive ? 'aktif' : 'nonaktif';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Layanan berhasil diubah menjadi $statusText')),
          );
          _fetchLayananPenyedia();
        },
      );
    }
  }

  void _hapusLayanan(Service layanan) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus layanan "${layanan.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Hapus', style: TextStyle(color: Colors.red[700])),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final result = await _deleteLayananUseCase(
                  DeleteLayananParams(layananId: layanan.id),
                );

                if (mounted) {
                  result.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menghapus layanan: ${failure.message}')),
                      );
                    },
                    (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Layanan berhasil dihapus.')),
                      );
                      _fetchLayananPenyedia();
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _togglePromosi(Service layanan, bool value) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                value ? Icons.campaign : Icons.campaign_outlined,
                color: value ? Colors.amber[700] : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(value ? 'Aktifkan Promosi' : 'Nonaktifkan Promosi', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layanan: "${layanan.title}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (value) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Informasi Biaya Promosi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• Biaya: Rp 1.000 per hari'),
                      const Text('• Layanan akan muncul di urutan teratas'),
                      const Text('• Promosi dapat dinonaktifkan kapan saja'),
                      const Text('• Saldo akan dipotong otomatis setiap hari'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pastikan saldo Anda mencukupi untuk biaya promosi harian.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Promosi layanan akan dinonaktifkan dan tidak akan dikenakan biaya lagi.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: value ? Colors.amber[700] : Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(value ? 'Aktifkan Promosi' : 'Nonaktifkan'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  setState(() {
                    _isLoading = true;
                  });

                  final authState = context.read<AuthBloc>().state;
                  String providerId = '';

                  if (authState is AuthAuthenticated) {
                    providerId = authState.user.id;

                    final toggleServicePromotionUsecase = sl.sl<ToggleServicePromotionUsecase>();

                    final result = await toggleServicePromotionUsecase(
                      serviceId: layanan.id,
                      providerId: providerId,
                      isPromoted: value,
                      serviceTitle: layanan.title,
                    );

                    result.fold(
                      (failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal ${value ? 'mengaktifkan' : 'menonaktifkan'} promosi: ${failure.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      (updatedService) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Promosi layanan "${layanan.title}" telah diaktifkan. Biaya Rp 1.000/hari akan dipotong dari saldo Anda.'
                                  : 'Promosi layanan "${layanan.title}" telah dinonaktifkan.',
                            ),
                            backgroundColor: value ? Colors.amber[700] : Colors.grey[600],
                          ),
                        );

                        _fetchLayananPenyedia();
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anda harus login untuk mengaktifkan promosi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Terjadi kesalahan: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 48),
              const SizedBox(height: 12),
              Text(
                'Terjadi kesalahan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red[700], fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
                onPressed: _fetchLayananPenyedia,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_layanan.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_business_outlined, size: 40, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada layanan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan layanan pertama Anda dengan mengklik tombol + di bawah',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                label: Text('Tambah Layanan', style: TextStyle(color: AppColors.primary)),
                onPressed: _tambahLayanan,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _layanan.length,
      itemBuilder: (context, index) {
        final layanan = _layanan[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: layanan.imagesUrls != null && layanan.imagesUrls!.isNotEmpty
                          ? Image.network(
                              layanan.imagesUrls!.first,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.image, color: Colors.grey[400], size: 30),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layanan.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${NumberFormat('#,##0', 'id_ID').format(layanan.price).replaceAll(',', '.')} / ${layanan.priceUnit}',
                            style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  layanan.locationText ?? 'Tidak ada lokasi',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPromotionStatusWidget(layanan),
                    Row(
                      children: [
                        // Tombol toggle aktif/nonaktif
                        IconButton(
                          icon: Icon(
                            layanan.isActive ? Icons.toggle_on : Icons.toggle_off,
                            color: layanan.isActive ? Colors.green[700] : Colors.grey[400],
                            size: 24,
                          ),
                          onPressed: () => _toggleLayananActive(layanan),
                          tooltip: layanan.isActive ? 'Nonaktifkan Layanan' : 'Aktifkan Layanan',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                          onPressed: () => _editLayanan(layanan),
                          tooltip: 'Edit Layanan',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                          onPressed: () => _hapusLayanan(layanan),
                          tooltip: 'Hapus Layanan',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromotionStatusWidget(Service layanan) {
    final status = layanan.promotionStatus;
    String text;
    Color color;
    bool isActive = status == PromotionStatus.active || status == PromotionStatus.scheduled;

    switch (status) {
      case PromotionStatus.active:
        text = 'Promosi Aktif';
        color = Colors.green[700]!;
        break;
      case PromotionStatus.scheduled:
        text = 'Terjadwal';
        color = Colors.blue[700]!;
        break;
      case PromotionStatus.ended:
        text = 'Promosi Berakhir';
        color = Colors.grey[600]!;
        break;
      case PromotionStatus.none:
        text = 'Promosikan';
        color = Colors.grey[600]!;
        break;
    }

    return InkWell(
      onTap: () => _editLayanan(layanan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: isActive,
                onChanged: layanan.isActive && status != PromotionStatus.ended
                    ? (bool value) => _togglePromosi(layanan, value)
                    : null,
                activeColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaCard() {
    if (_layanan.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promosikan Layanan!', 
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                SizedBox(height: 2),
                Text('Jangkau lebih banyak pelanggan.', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTambahLayananButton() {
    return FloatingActionButton(
      onPressed: _tambahLayanan,
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Layanan'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
                  children: [
                    Expanded(
                      child: _buildServiceList(),
                    ),
                    _buildCtaCard(),
                  ],
                ),
      floatingActionButton: _buildTambahLayananButton(),
    );
  }
}
