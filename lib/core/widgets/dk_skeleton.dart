import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Plain skeleton blocks — no spinners or progress lines.
class DkSkeleton {
  DkSkeleton._();

  static Widget box({
    double? width,
    required double height,
    double borderRadius = 12,
  }) {
    return _SkeletonBox(
        width: width, height: height, borderRadius: borderRadius);
  }

  static Widget customerDashboardTop(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box(height: 132, borderRadius: 14),
        const SizedBox(height: 12),
        box(height: 168, borderRadius: 16),
      ],
    );
  }

  static Widget farmDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        box(height: 28, width: 220),
        const SizedBox(height: 8),
        box(height: 14, width: 160),
        const SizedBox(height: 20),
        box(height: 14, width: 140),
        const SizedBox(height: 8),
        box(height: 180, borderRadius: 14),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: List.generate(4, (_) => box(height: 96, borderRadius: 14)),
        ),
        const SizedBox(height: 20),
        box(height: 14, width: 100),
        const SizedBox(height: 8),
        ...List.generate(
            3,
            (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: box(height: 64, borderRadius: 12),
                )),
      ],
    );
  }

  static Widget deliveryDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        box(height: 24, width: 160),
        const SizedBox(height: 8),
        box(height: 18, width: 120),
        const SizedBox(height: 12),
        box(height: 48, borderRadius: 12),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: List.generate(4, (_) => box(height: 88, borderRadius: 14)),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: box(height: 72, borderRadius: 14)),
            const SizedBox(width: 12),
            Expanded(child: box(height: 72, borderRadius: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: box(height: 72, borderRadius: 14)),
            const SizedBox(width: 12),
            Expanded(child: box(height: 72, borderRadius: 14)),
          ],
        ),
      ],
    );
  }

  static Widget supplierStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: List.generate(4, (_) => box(height: 96, borderRadius: 14)),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    this.width,
    required this.height,
    required this.borderRadius,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dk = Dk.of(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = 0.14 + (_pulse.value * 0.1);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(dk.muted.withValues(alpha: 0.12),
                dk.muted.withValues(alpha: t), _pulse.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
