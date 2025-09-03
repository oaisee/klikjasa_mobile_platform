import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/theme/app_theme.dart'; 
import 'package:klik_jasa/routes/app_router.dart'; 
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:klik_jasa/features/common/balance/presentation/bloc/balance_bloc.dart';
import 'package:klik_jasa/features/common/theme/application/theme_bloc.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_cubit.dart';
import 'package:klik_jasa/injection_container.dart' as di;

class App extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const App({super.key, required this.scaffoldMessengerKey});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(),
        ),
        BlocProvider<UserViewBloc>(
          create: (context) => UserViewBloc(
            authBloc: context.read<AuthBloc>(),
            supabaseClient: di.sl(),
          ),
        ),
        BlocProvider<BalanceBloc>(
          create: (context) => BalanceBloc(
            getUserBalanceUsecase: di.sl(),
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<SearchCubit>(
          create: (context) => di.sl<SearchCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final appRouter = AppRouter(
            context.read<AuthBloc>(),
            context.read<UserViewBloc>(),
          );
          return MaterialApp.router(
            title: 'KlikJasa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode == AppThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: appRouter.router,
            scaffoldMessengerKey: scaffoldMessengerKey,
          );
        },
      ),
    );
  }
}
