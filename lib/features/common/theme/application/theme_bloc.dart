import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.initial()) {
    on<ThemeChanged>(_onThemeChanged);
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkModeEnabled') ?? false;
    add(ThemeChanged(isDarkMode: isDarkMode));
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    final newThemeMode = event.isDarkMode ? AppThemeMode.dark : AppThemeMode.light;
    emit(state.copyWith(themeMode: newThemeMode));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', event.isDarkMode);
  }
}
