import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/admin_mode/data/repositories/provider_verification_repository_impl.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/admin_provider_detail_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/provider_verification/provider_verification_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProviderVerificationScreen extends StatelessWidget {
  const AdminProviderVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProviderVerificationBloc(
        repository: ProviderVerificationRepositoryImpl(
          supabase: Supabase.instance.client,
        ),
      )..add(LoadPendingVerifications()), // Langsung muat data saat BLoC dibuat
      child: Scaffold(
        // AppBar tidak diperlukan di sini karena sudah dihandle oleh AdminDashboardScreen
        // appBar: AppBar(
        //   title: const Text('Verifikasi Penyedia Jasa'),
        // ),
        body: BlocConsumer<ProviderVerificationBloc, ProviderVerificationState>(
          listener: (context, state) {
            if (state is ProviderVerificationUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              // Tidak perlu add(LoadPendingVerifications()) di sini karena sudah dihandle di BLoC setelah sukses update
            } else if (state is ProviderVerificationUpdateFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is ProviderVerificationLoading || state is ProviderVerificationUpdateInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProviderVerificationError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                ),
              );
            }
            if (state is ProviderVerificationLoaded) {
              if (state.pendingProviders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Tidak ada penyedia jasa yang menunggu verifikasi saat ini.'),
                  ),
                );
              }
              return _buildProvidersList(context, state.pendingProviders);
            }
            return const Center(child: Text('Silakan muat data penyedia.')); // State awal atau tidak dikenal
          },
        ),
      ),
    );
  }

  Widget _buildProvidersList(BuildContext context, List<UserProfile> providers) {
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(provider.fullName ?? 'Nama Tidak Tersedia'),
            onTap: () {
                  // Dapatkan instance BLoC yang ada dari context saat ini
                  final verificationBloc = BlocProvider.of<ProviderVerificationBloc>(context);
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
                },
                subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.email ?? 'Email tidak tersedia'),
                Text('ID: ${provider.id}'),
                Text('Status: ${provider.providerVerificationStatus ?? 'N/A'}'),
                if (provider.createdAt != null)
                  Text('Terdaftar: ${provider.createdAt!.toLocal().toString().substring(0,16)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Setujui',
                  onPressed: () {
                    _showConfirmationDialog(context, provider, true);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Tolak',
                  onPressed: () {
                    _showConfirmationDialog(context, provider, false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, UserProfile provider, bool approve) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(approve ? 'Setujui Penyedia?' : 'Tolak Penyedia?'),
          content: Text(
              'Apakah Anda yakin ingin ${approve ? 'menyetujui' : 'menolak'} penyedia jasa ${provider.fullName ?? provider.email}?'),
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
                  context.read<ProviderVerificationBloc>().add(ApproveProviderVerification(provider.id));
                } else {
                  context.read<ProviderVerificationBloc>().add(RejectProviderVerification(provider.id));
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
