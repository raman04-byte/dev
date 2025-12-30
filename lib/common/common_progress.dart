import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CommonProgressIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const CommonProgressIndicator({
    super.key,
    this.size = 200.0,
    this.color,
    this.message,
  });

  @override
  State<CommonProgressIndicator> createState() =>
      _CommonProgressIndicatorState();
}

class _CommonProgressIndicatorState extends State<CommonProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int maxSeeds;
  int _currentSeeds = 0;

  @override
  void initState() {
    super.initState();
    // Use fewer seeds for small indicators to maintain clarity
    maxSeeds = widget.size < 50 ? 80 : 150;
    _currentSeeds = maxSeeds ~/ 2;

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(() {
            setState(() {
              _currentSeeds = (1 + _animationController.value * (maxSeeds - 1))
                  .round();
            });
          })
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: SunflowerWidget(
            _currentSeeds,
            maxSeeds: maxSeeds,
            color: widget.color ?? AppColors.primaryBlue,
            dotSize: widget.size < 50 ? 4.0 : 6.0,
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}

class SunflowerWidget extends StatelessWidget {
  static const tau = math.pi * 2;
  static const scaleFactor = 1 / 25;
  static final phi = (math.sqrt(5) + 1) / 2;
  static final rng = math.Random();

  final int seeds;
  final int maxSeeds;
  final Color color;
  final double dotSize;

  const SunflowerWidget(
    this.seeds, {
    super.key,
    required this.maxSeeds,
    required this.color,
    this.dotSize = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final seedWidgets = <Widget>[];

    for (var i = 0; i < seeds; i++) {
      final theta = i * tau / phi;
      final r = math.sqrt(i) * scaleFactor;

      seedWidgets.add(
        AnimatedAlign(
          key: ValueKey<int>(i),
          duration: Duration(milliseconds: rng.nextInt(300) + 200),
          curve: Curves.easeInOut,
          alignment: Alignment(r * math.cos(theta), -1 * r * math.sin(theta)),
          child: Dot(lit: true, color: color, size: dotSize),
        ),
      );
    }

    for (var j = seeds; j < maxSeeds; j++) {
      final x = math.cos(tau * j / (maxSeeds - 1)) * 0.9;
      final y = math.sin(tau * j / (maxSeeds - 1)) * 0.9;

      seedWidgets.add(
        AnimatedAlign(
          key: ValueKey<int>(j),
          duration: Duration(milliseconds: rng.nextInt(300) + 200),
          curve: Curves.easeInOut,
          alignment: Alignment(x, y),
          child: Dot(lit: false, color: color, size: dotSize),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        height: 400, // Internal coordinate space
        width: 400,
        child: Stack(children: seedWidgets),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final double size;
  final double radius;
  final bool lit;
  final Color color;

  const Dot({
    super.key,
    required this.lit,
    required this.color,
    this.size = 6.0,
    this.radius = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: lit ? color : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: size / 2,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: SizedBox(height: size, width: size),
    );
  }
}
