import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/colors.dart';
import 'constants/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/auth_service.dart';
import 'services/service_service.dart';
import 'services/storage_service.dart';
import 'services/transaction_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/services/service_list_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.apiUrl,
    anonKey: SupabaseConfig.apiKey,
  );

  final supabase = Supabase.instance.client;
  final authService = AuthService(supabase);
  final serviceService = ServiceService(supabase);
  final storageService = StorageService(supabase);
  final transactionService = TransactionService(supabase);

  runApp(
    MyApp(
      authService: authService,
      serviceService: serviceService,
      storageService: storageService,
      transactionService: transactionService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ServiceService serviceService;
  final StorageService storageService;
  final TransactionService transactionService;

  const MyApp({
    super.key,
    required this.authService,
    required this.serviceService,
    required this.storageService,
    required this.transactionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(serviceService),
        ),
        ChangeNotifierProvider(
          create: (_) => StorageProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(transactionService),
        ),
      ],
      child: MaterialApp(
        title: 'KlikJasa',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MyHomePage(),
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('KlikJasa', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal logout, silakan coba lagi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          ServiceListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Layanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
