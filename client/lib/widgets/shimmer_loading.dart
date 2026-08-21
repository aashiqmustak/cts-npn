import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shimmer Skeleton Animation Component
class BentoShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BentoShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<BentoShimmer> createState() => _BentoShimmerState();
}

class _BentoShimmerState extends State<BentoShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE6F8F6), // subtle surgical teal shimmer hint
                Color(0xFFE2E8F0),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
              begin: Alignment(-1.0 + (_controller.value * 2.0), -0.3),
              end: Alignment(1.0 + (_controller.value * 2.0), 0.3),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer Skeleton for an entire Bento Card
class BentoCardSkeleton extends StatelessWidget {
  final double height;

  const BentoCardSkeleton({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.metallicBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              BentoShimmer(width: 140, height: 18, borderRadius: 8),
              BentoShimmer(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const BentoShimmer(width: 220, height: 12, borderRadius: 6),
          const SizedBox(height: 24),
          const Expanded(
            child: BentoShimmer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
            ),
          ),
        ],
      ),
    );
  }
}
