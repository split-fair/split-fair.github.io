import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'models/ad_service.dart';
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
  await AdService.initialize();
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
        child: Image(
          image: const AssetImage(AppImages.splashLogo),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return const Icon(Icons.home_work_rounded, size: 52, color: AppColors.primary);
          },
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _resolveAndNavigate();
    }
  }

  Future<void> _resolveAndNavigate() async {
    // No visual splash — the iOS LaunchScreen (solid brand green) covers
    // load time. Precache heroes in background, then navigate immediately.
    final seen = await hasSeenOnboarding();
    for (final hero in AppImages.onboardingHeroes) {
      precacheImage(AssetImage(hero), context).catchError((_) {});
    }
    if (!mounted) return;
    context.read<AppState>().initIap();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            seen ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solid brand green — matches iOS LaunchScreen exactly.
    // No logo, no gradient, no animation. Just green until the
    // onboarding/home route fades in via pushReplacement above.
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: SizedBox.expand(),
    );
  }

  // ── DEAD CODE BELOW — kept only so _SplashLogo class still compiles ──
  // (It's referenced by the class definition above but never rendered.)
  // TODO: remove _SplashLogo class entirely in a future cleanup pass.
  Widget _legacySplashBuild(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, Colors.white],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
      ),
    );
  }
}