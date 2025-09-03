import 'dart:math';
import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget untuk menampilkan loading indicator
/// 
/// Widget ini menyediakan berbagai jenis loading indicator
/// yang dapat digunakan di seluruh aplikasi.
class LoadingWidget extends StatelessWidget {
  /// Pesan yang ditampilkan di bawah loading indicator
  final String? message;
  
  /// Ukuran loading indicator
  final double size;
  
  /// Warna loading indicator
  final Color? color;
  
  /// Tipe loading indicator
  final LoadingType type;

  /// Konstruktor untuk LoadingWidget
  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
    this.type = LoadingType.circular,
  });

  /// Factory constructor untuk loading circular
  factory LoadingWidget.circular({
    Key? key,
    String? message,
    double size = 40.0,
    Color? color,
  }) {
    return LoadingWidget(
      key: key,
      message: message,
      size: size,
      color: color,
      type: LoadingType.circular,
    );
  }

  /// Factory constructor untuk loading linear
  factory LoadingWidget.linear({
    Key? key,
    String? message,
    Color? color,
  }) {
    return LoadingWidget(
      key: key,
      message: message,
      color: color,
      type: LoadingType.linear,
    );
  }

  /// Factory constructor untuk loading dots
  factory LoadingWidget.dots({
    Key? key,
    String? message,
    double size = 40.0,
    Color? color,
  }) {
    return LoadingWidget(
      key: key,
      message: message,
      size: size,
      color: color,
      type: LoadingType.dots,
    );
  }

  /// Factory constructor untuk loading overlay (fullscreen)
  factory LoadingWidget.overlay({
    Key? key,
    String? message,
    Color? backgroundColor,
  }) {
    return LoadingWidget(
      key: key,
      message: message,
      type: LoadingType.overlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? AppColors.primary;
    
    Widget loadingIndicator;
    
    switch (type) {
      case LoadingType.circular:
        loadingIndicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
            strokeWidth: 3,
          ),
        );
        break;
        
      case LoadingType.linear:
        loadingIndicator = LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          backgroundColor: loadingColor.withValues(alpha: 0.2),
        );
        break;
        
      case LoadingType.dots:
        loadingIndicator = DotsLoadingIndicator(
          size: size,
          color: loadingColor,
        );
        break;
        
      case LoadingType.overlay:
        return Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
                      strokeWidth: 3,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
    }
    
    if (message != null && type != LoadingType.overlay) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingIndicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    return loadingIndicator;
  }
}

/// Custom dots loading indicator
class DotsLoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  
  const DotsLoadingIndicator({
    super.key,
    required this.size,
    required this.color,
  });
  
  @override
  State<DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size / 4,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
              final scale = (sin(animationValue * pi) * 0.5 + 0.5).clamp(0.3, 1.0);
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size / 6,
                  height: widget.size / 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Enum untuk tipe loading
enum LoadingType {
  circular,
  linear,
  dots,
  overlay,
}