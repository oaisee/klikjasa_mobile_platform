import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:klik_jasa/injection_container.dart';

// Core imports
import 'package:klik_jasa/core/constants/app_colors.dart';

// Common features imports
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';

// Provider mode imports
import 'package:klik_jasa/features/provider_mode/dashboard/application/blocs/provider_summary_bloc/provider_summary_bloc.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/presentation/widgets/tabs/provider_summary_tab.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/presentation/widgets/balance_widget.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/presentation/widgets/notification_bell_widget.dart';


/// A consolidated dashboard screen for service providers.
///
/// This screen displays a tabbed interface with summary information,
/// incoming orders, and provider services.
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _providerProfile;
  bool _isLoadingProfile = true;
  
  @override
  void initState() {
    super.initState();
    
    // Pastikan status bar berwarna sesuai dengan AppBar dan menggunakan ikon terang
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparan agar AppBar terlihat
      statusBarIconBrightness: Brightness.light, // Ikon status bar berwarna terang (putih)
      statusBarBrightness: Brightness.dark, // Untuk iOS
    ));
    
    // Ambil data profil penyedia saat inisialisasi
    _fetchProviderProfile();
  }
  
  Future<void> _fetchProviderProfile() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingProfile = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }
      
      // Ambil data profil dari tabel profiles
      final profileData = await _supabase
          .from('profiles')
          .select('full_name, avatar_url, provider_verification_status')
          .eq('id', userId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _providerProfile = profileData;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        debugPrint('Error fetching provider profile: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProviderSummaryBloc>(
          create: (context) {
            final bloc = sl<ProviderSummaryBloc>();
            final supabaseClient = sl<SupabaseClient>();
            final String? providerId = supabaseClient.auth.currentUser?.id;
            if (providerId != null) {
              bloc.add(SubscribeToProviderSummary(providerId: providerId));
            } else {
              debugPrint(
                '[ProviderDashboardScreen] Provider ID is null. Cannot fetch summary data.',
              );
            }
            return bloc;
          },
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Transparan agar warna AppBar terlihat
          statusBarIconBrightness: Brightness.light, // Ikon status bar berwarna terang
          statusBarBrightness: Brightness.dark, // Untuk iOS
        ),
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      elevation: 0,
                      backgroundColor: AppColors.accent,
                      floating: true,
                      pinned: true,
                      snap: false,
                      centerTitle: false,
                      title: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          if (authState is AuthAuthenticated) {
                            final UserEntity user = authState.user;
                            
                            // Gunakan data dari _providerProfile jika tersedia, atau fallback ke user dari authState
                            final String? displayName = _isLoadingProfile
                                ? 'Memuat...'
                                : (_providerProfile != null && _providerProfile!['full_name'] != null && _providerProfile!['full_name'].toString().isNotEmpty
                                    ? _providerProfile!['full_name']
                                    : (user.fullName?.isNotEmpty == true
                                        ? user.fullName
                                        : (user.email?.isNotEmpty == true
                                            ? user.email
                                            : 'Dasbor Penyedia')));
                            
                            // Gunakan avatar dari _providerProfile jika tersedia, atau fallback ke user.avatarUrl
                            final String? avatarUrl = _providerProfile != null && _providerProfile!['avatar_url'] != null && _providerProfile!['avatar_url'].toString().isNotEmpty
                                ? _providerProfile!['avatar_url']
                                : user.avatarUrl;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white.withAlpha(50),
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty)
                                      ? Icon(
                                          Icons.person_outline,
                                          size: 20,
                                          color: Colors.white.withAlpha(200),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    displayName ?? 'Dasbor Penyedia',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }
                          // Fallback UI if state is not AuthAuthenticated
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white.withAlpha(50),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Dasbor Penyedia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      actions: const <Widget>[
                        BalanceWidget(),
                        NotificationBellWidget(),
                        SizedBox(width: 8),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(4.0),
                        child: Container(
                          color: Colors.white.withAlpha(51), // Menggunakan withAlpha sebagai pengganti withOpacity
                          height: 1.0,
                        ),
                      ),
                    ),
                  ];
                },
            body: const ProviderSummaryTab(),
          ),
        ), // Tutup Scaffold
      ),
    ); // Tutup AnnotatedRegion
  }
}
