import 'package:flutter/material.dart';

import 'app_brand.dart';
import '../theme/app_theme.dart';

enum BrandLogoVariant { full, compact, mono, onDark, onLight }

/// Reusable Doodh Wala logo (Bullet + rear cans mark).
///
/// Mark is PNG; wordmark is Flutter [Text] so it stays crisp at any size.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.full,
    this.height = 40,
    this.showTagline = false,
    this.color,
  });

  final BrandLogoVariant variant;
  final double height;
  final bool showTagline;
  final Color? color;

  bool get _markOnly =>
      variant == BrandLogoVariant.compact || variant == BrandLogoVariant.mono;

  String get _markAsset {
    switch (variant) {
      case BrandLogoVariant.mono:
        return AppBrand.logoMono;
      case BrandLogoVariant.onDark:
        return AppBrand.logoMarkOnDark;
      case BrandLogoVariant.compact:
      case BrandLogoVariant.full:
      case BrandLogoVariant.onLight:
        return AppBrand.logoCompact;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mark = Image.asset(
      _markAsset,
      height: height,
      width: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: AppBrand.name,
    );
    if (color != null) {
      mark = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcATop),
        child: mark,
      );
    }

    if (_markOnly) return mark;

    final onDark = variant == BrandLogoVariant.onDark;
    final titleColor = onDark ? Colors.white : AppColors.leafDark;
    final taglineColor =
        onDark ? Colors.white.withValues(alpha: 0.85) : AppColors.muted;
    final titleSize = (height * 0.42).clamp(18.0, 34.0);
    final taglineSize = (height * 0.18).clamp(11.0, 14.0);

    return Semantics(
      label: AppBrand.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              SizedBox(width: height * 0.2),
              Text(
                AppBrand.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
          if (showTagline) ...[
            SizedBox(height: height * 0.08),
            Text(
              AppBrand.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: taglineSize,
                color: taglineColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
