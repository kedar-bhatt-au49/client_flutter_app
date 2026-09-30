import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Animated numeric counter for dashboard stats.
class AnimatedCounter extends StatefulWidget {
  final int value;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextStyle? style;
  final bool animate;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.animate = true,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animation = IntTween(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        var display = '${_animation.value}';
        if (display.length > 3) {
          // Compact formatting for large numbers
          final val = _animation.value;
          if (val >= 100000) {
            display = '${(val / 100000).toStringAsFixed(val % 100000 == 0 ? 0 : 1)}L';
          } else if (val >= 1000) {
            display = '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}K';
          }
        }
        return Text(
          '${widget.prefix}$display${widget.suffix}',
          style: widget.style ??
              GSTextStyles.displayMedium.copyWith(
                color: GSColors.navy900,
                fontWeight: FontWeight.w800,
              ),
        );
      },
    );
  }
}
