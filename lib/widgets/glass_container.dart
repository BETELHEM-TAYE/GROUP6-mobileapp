import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphism container widget
/// Creates a frosted glass effect with blur and semi-transparency
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;
  final double borderRadius;
  final double opacity;
  final double blurAmount;
  final Color? color;
  final BorderRadiusGeometry? customBorderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.height = 200,
    this.width = double.infinity,
    this.borderRadius = 20,
    this.opacity = 0.2,
    this.blurAmount = 10,
    this.color,
    this.customBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        customBorderRadius ?? BorderRadius.all(Radius.circular(borderRadius));

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withAlpha((opacity * 255).round()),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: Colors.white.withAlpha(77),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

