import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:klik_jasa/features/common/widgets/service_card_adapter.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/pages/provider_service_management_screen.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_cubit.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_cubit.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_state.dart';
import 'package:klik_jasa/injection_container.dart' as di;
import 'package:supabase_flutter/supabase_flutter.dart';

// Import widget yang telah dipisahkan
import 'package:klik_jasa/features/user_mode/home/presentation/widgets/saldo_widget.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/widgets/notification_bell_widget.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/widgets/profile_completion_banner.dart';

// Import tab yang telah dipisahkan
import 'package:klik_jasa/features/user_mode/home/presentation/tabs/untuk_anda_tab.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/tabs/populer_tab.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/tabs/terbaru_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isSearchFocused = false;
  bool _isSearching = false;
  // Hapus GlobalKey yang tidak diperlukan untuk menghindari duplicate key error
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final SearchCubit _searchCubit;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchCubit = di.sl<SearchCubit>();
    
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
          if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
            _isSearching = false;
            _searchCubit.resetSearch();
          }
        });
      }
    });

    // Pastikan status bar berwarna sesuai dengan AppBar dan menggunakan ikon terang
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparan agar AppBar terlihat
        statusBarIconBrightness:
            Brightness.light, // Ikon status bar berwarna terang (putih)
        statusBarBrightness: Brightness.dark, // Untuk iOS
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchCubit.close(); // Close the SearchCubit to prevent memory leaks
    super.dispose();
  }

  // Metode publik untuk meminta fokus pada search field
  void requestSearchFocus() {
    if (mounted) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    }
  }

  // Method untuk handle pencarian
  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
      });
      _searchCubit.resetSearch();
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    // Gunakan SearchCubit untuk mencari layanan
    _searchCubit.searchServices(query);
  }

  // Memisahkan widget SearchBar untuk mengurangi rebuild yang tidak perlu
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSearchFocused
          ? MediaQuery.of(context).size.width - 16.0 - 56.0 - 8.0 // Lebar layar - padding kiri AppBar - lebar ikon lonceng - spasi
          : MediaQuery.of(context).size.width * 0.55, // Lebar awal
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(70), // Latar belakang AnimatedContainer
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode, // Menggunakan FocusNode
        style: const TextStyle(color: Colors.white), // Pastikan warna teks kontras
        showCursor: true,
        cursorColor: Colors.white,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          hintText: 'Cari layanan...',
          filled: true,
          fillColor: Colors.black.withAlpha(30), // Warna latar TextField
          contentPadding: const EdgeInsets.only(
            left: 12.0,
            right: 12.0,
            top: 0,
            bottom: 0,
          ), // Sesuaikan padding
          // Mengatur border agar selalu membulat
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: BorderSide(
              color: Colors.white.withAlpha(150), // Warna border saat tidak fokus
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(
              color: Colors.white,
              width: 1.5,
            ),
          ),
          hintStyle: TextStyle(
            color: Colors.white.withAlpha(180),
          ),
        ),
        onChanged: (value) {
          // Pencarian real-time saat pengguna mengetik
          _performSearch(value);
        },
        onSubmitted: _performSearch,
      ),
    );
  }
  
  // Memisahkan widget TabBar untuk mengurangi rebuild
  PreferredSizeWidget _buildTabBar() {
    return const TabBar(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      tabs: <Widget>[
        Tab(text: AppStrings.rekomendasiUntukAnda),
        Tab(text: AppStrings.layananPopuler),
        Tab(text: AppStrings.terbaru),
      ],
    );
  }
  
  // Konstanta untuk SystemUiOverlayStyle
  static const _transparentStatusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<CategoryCubit>(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _transparentStatusBarStyle,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              // Hapus key untuk menghindari duplicate GlobalKey error
              // key: _scaffoldKey,
              backgroundColor: AppColors.scaffoldBackground,
              extendBodyBehindAppBar: true, // Mengizinkan body meluas di belakang AppBar
              body: SafeArea(
                top: false, // Tidak menambahkan padding di bagian atas
                child: NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        systemOverlayStyle: _transparentStatusBarStyle,
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        titleSpacing: 16.0, // Atur spacing
                        // Kotak pencarian sebagai title dengan widget yang sudah dipisahkan
                        title: _buildSearchBar(),
                        actions: _isSearchFocused
                            ? const <Widget>[NotificationBellWidget()]
                            : const <Widget>[SaldoWidget(), NotificationBellWidget()],
                        pinned: true,
                        floating: true,
                        forceElevated: innerBoxIsScrolled,
                        bottom: _isSearching ? null : _buildTabBar(),
                      ),
                    ];
                  },
                  body: Stack(
                    children: [
                      // Tampilkan hasil pencarian atau TabBarView
                      _isSearching
                          ? BlocBuilder<SearchCubit, SearchState>(
                              bloc: _searchCubit,
                              builder: (context, state) {
                                if (state is SearchLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (state is SearchLoaded) {
                                  if (state.services.isEmpty) {
                                    return const Center(
                                      child: Text('Tidak ada layanan yang ditemukan'),
                                    );
                                  }
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: state.services.length,
                                    itemBuilder: (context, index) {
                                      final service = state.services[index];
                                      return ServiceCardAdapter.fromServiceWithLocation(
                                        service: service,
                                        onTap: () {
                                          context.pushNamed('serviceDetail', extra: {
                                            'service': service,
                                            'heroTag': 'search_${service.id}'
                                          });
                                        },
                                      );
                                    },
                                  );
                                } else if (state is SearchError) {
                                  return Center(
                                    child: Text('Error: ${state.message}'),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            )
                          : const TabBarView(
                              // Menggunakan const untuk mengurangi rebuild
                              children: <Widget>[
                                UntukAndaTab(),
                                // Tidak bisa menggunakan const untuk BlocBuilder
                                _PopulerTabWrapper(),
                                TerbaruTab(),
                              ],
                            ),
                      
                      // Lapisan semi-transparan untuk memastikan banner terlihat jelas
                      BlocBuilder<UserViewBloc, UserViewState>(
                        builder: (context, state) {
                          // Hanya tampilkan overlay jika user sudah login
                          final currentUser = Supabase.instance.client.auth.currentUser;
                          if (currentUser == null) {
                            return const SizedBox.shrink();
                          }
                          
                          return const Positioned.fill(
                            child: ProfileCompletionBanner(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Memisahkan BlocBuilder ke widget terpisah untuk mengurangi rebuild pada parent
class _PopulerTabWrapper extends StatelessWidget {
  const _PopulerTabWrapper();
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserViewBloc, UserViewState>(
      builder: (context, userViewState) {
        if (userViewState.currentViewMode == UserViewMode.penyedia &&
            userViewState.isVerifiedProvider) {
          return const ProviderServiceManagementScreen();
        } else {
          return const PopulerTab();
        }
      },
    );
  }
}
