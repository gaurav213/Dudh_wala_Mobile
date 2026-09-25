import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/branding/app_brand.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = ref.read(authControllerProvider);
      if (!auth.initialized) {
        await ref.read(authControllerProvider.notifier).bootstrap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.milkWhite,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.milkWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.milkWhite,
        body: SizedBox.expand(
          child: Center(
            // Exact logo_splash — small, no re-crop / radius change.
            child: Image.asset(
              AppBrand.splashLogo,
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: AppBrand.name,
            ),
          ),
        ),
      ),
    );
  }
}
