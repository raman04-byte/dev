import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphism helper class for creating Apple-style frosted glass effects
class Glassmorphism {
  /// Creates a frosted glass container with blur effect
  static Widget container({
    required Widget child,
    double blur = 10,
    double opacity = 0.15,
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow:
            boxShadow ??
            [
              const BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 20,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: (color ?? AppColors.white).withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border:
                  border ??
                  Border.all(color: AppColors.white.withOpacity(0.2), width: 1),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a frosted glass card
  static Widget card({
    required Widget child,
    double blur = 10,
    double opacity = 0.6,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.systemGray5.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  /// Creates a frosted glass bottom navigation bar
  static Widget bottomBar({
    required Widget child,
    double blur = 20,
    double opacity = 0.8,
    double height = 90,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(opacity),
            border: const Border(
              top: BorderSide(color: AppColors.systemGray5, width: 0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Creates a frosted glass app bar
  static PreferredSizeWidget appBar({
    Widget? title,
    List<Widget>? actions,
    Widget? leading,
    double blur = 20,
    double opacity = 0.8,
    bool centerTitle = true,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: AppBar(
            title: title,
            actions: actions,
            leading: leading,
            centerTitle: centerTitle,
            backgroundColor: AppColors.white.withOpacity(opacity),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: const Border(
              bottom: BorderSide(color: AppColors.systemGray5, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates a frosted glass button
  static Widget button({
    required Widget child,
    required VoidCallback onPressed,
    double blur = 10,
    double opacity = 0.2,
    Color? color,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: (color ?? AppColors.primaryBlue).withOpacity(opacity),
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                border: Border.all(
                  color: (color ?? AppColors.primaryBlue).withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Creates a frosted glass dialog
  static Widget dialog({
    required Widget child,
    double blur = 30,
    double opacity = 0.9,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.systemGray5.withOpacity(0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  /// Creates a subtle gradient background
  static BoxDecoration gradientBackground({
    List<Color>? colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors:
            colors ??
            [
              AppColors.systemGray6,
              AppColors.white,
              AppColors.systemGray6.withOpacity(0.5),
            ],
      ),
    );
  }

  /// Creates a shimmer effect for loading states
  static ShaderMask shimmer({
    required Widget child,
    Color baseColor = AppColors.systemGray5,
    Color highlightColor = AppColors.white,
  }) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
