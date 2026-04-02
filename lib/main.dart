import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_images.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SplitFairApp());
}

class SplitFairApp extends StatelessWidget {
  const SplitFairApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Split Fair',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child!,
          ),
        ),
        home: const _Splash(),
      ),
    );
  }
}

/// Loads [AppImages.splashLogo] when it exists; falls back to the icon widget.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, Color(0xFFE8F8F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          AppImages.splashLogo,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.home_work_rounded, size: 52, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  bool _started = false;
  bool _splashReady = false; // true once splash images are decoded

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _precacheAndNavigate();
    }
  }

  Future<void> _precacheAndNavigate() async {
    // Phase 1: Decode splash images so the splash screen itself never shows
    // a checkerboard. This completes before we show any Image.asset widgets.
    await Future.wait([
      precacheImage(const AssetImage(AppImages.splashBg), context).catchError((_) {}),
      precacheImage(const AssetImage(AppImages.splashLogo), context).catchError((_) {}),
    ]);
    if (!mounted) return;
    setState(() => _splashReady = true);

    // Phase 2: Precache onboarding heroes + minimum display time in parallel.
    final results = await Future.wait([
      for (final hero in AppImages.onboardingHeroes)
        precacheImage(AssetImage(hero), context).catchError((_) {}),
      Future.delayed(const Duration(milliseconds: 600)),
      hasSeenOnboarding(),
    ]);
    if (!mounted) return;
    context.read<AppState>().initIap();
    final seenOnboarding = false; // TEMP: force onboarding for testing — restore: results.last as bool
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            seenOnboarding ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solid colour until splash images are decoded — no checkerboard possible.
    if (!_splashReady) {
      return const Scaffold(backgroundColor: AppColors.primaryLight);
    }
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppImages.splashBg,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.primaryLight),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _SplashLogo()
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut, begin: const Offset(0.6, 0.6))
                  .fadeIn(duration: 400.ms),
                const SizedBox(height: 28),
                Text('Split Fair',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ))
                  .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.12, end: 0),
                const SizedBox(height: 6),
                Text('Fair rent for every room',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ))
                  .animate().fadeIn(duration: 400.ms, delay: 320.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}