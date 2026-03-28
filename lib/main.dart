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
  @override
  void initState() {
    super.initState();
    _navigate();
  }
  Future<void> _navigate() async {
    // Run splash delay and first-launch check in parallel.
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 600)),
      hasSeenOnboarding(),
    ]);
    if (!mounted) return;
    // Kick off IAP initialisation in the background — doesn't block navigation.
    context.read<AppState>().initIap();
    final seenOnboarding = false; // TODO: restore → results[1] as bool;
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
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Image.asset(
            AppImages.splashBg,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.primaryLight),
          ),
          // Centered content
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