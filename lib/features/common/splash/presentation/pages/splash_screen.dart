import 'dart:async'; // Diperlukan untuk Future.delayed
import 'dart:math' as math; // Diperlukan untuk math.max
import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  double _opacityLevel = 0.0;

  @override
  void initState() {
    super.initState();
    // Memberikan sedikit delay sebelum memulai animasi fade-in
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _opacityLevel = 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan gradient putih-cyan sebagai background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFE0FFFF), // Light Cyan
              const Color(0xFFB0E0E6), // Powder Blue (cyan lebih kuat)
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                opacity: _opacityLevel,
                duration: const Duration(seconds: 1), // Durasi animasi fade-in
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/logo.png',
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Animasi teks metro untuk KlikJasa
                    MetroTextAnimation(
                      text: AppStrings.appName,
                      textStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), // Memberi jarak lebih ke progress indicator
              AnimatedOpacity(
                opacity: _opacityLevel, // Bisa juga dianimasikan atau muncul setelah delay tertentu
                duration: const Duration(seconds: 1), // Sinkronkan dengan animasi di atas
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget animasi teks metro untuk KlikJasa
class MetroTextAnimation extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const MetroTextAnimation({
    super.key,
    required this.text,
    required this.textStyle,
  });

  @override
  State<MetroTextAnimation> createState() => _MetroTextAnimationState();
}

class _MetroTextAnimationState extends State<MetroTextAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _charAnimations;
  final List<String> _characters = [];
  
  @override
  void initState() {
    super.initState();
    
    _characters.addAll(widget.text.split(''));
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Buat animasi untuk setiap karakter
    _charAnimations = List.generate(_characters.length, (index) {
      final start = index * 0.1;
      final end = math.min(start + 0.6, 1.0); // Memastikan end tidak melebihi 1.0
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
    
    // Mulai animasi setelah delay singkat
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_characters.length, (index) {
            // Efek animasi metro untuk setiap karakter
            final offset = (1.0 - _charAnimations[index].value) * 20;
            final opacity = math.max(0, _charAnimations[index].value).toDouble();
            
            return Transform.translate(
              offset: Offset(0, offset),
              child: Opacity(
                opacity: opacity,
                child: Text(
                  _characters[index],
                  style: widget.textStyle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
