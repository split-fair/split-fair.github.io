/// Centralised image asset paths for Split Fair.
///
/// All images are generated with Adobe Firefly and dropped into
/// [assets/images/] by the developer. Each constant below maps to a
/// specific Firefly-generated PNG.  The app uses [_tryLoad] helpers so
/// missing images degrade gracefully to the built-in icon/widget fallback.
class AppImages {
  AppImages._();

  /// App logo shown on the splash screen (512 × 512, transparent BG).
  /// Firefly prompt: see firefly_prompts.md → "splash_logo"
  static const splashLogo = 'assets/images/splash_logo.png';

  /// Subtle background texture/gradient for the home screen app bar area.
  /// Firefly prompt: see firefly_prompts.md → "home_bg"
  static const homeBg = 'assets/images/home_bg.png';

  /// Decorative scale illustration overlaid in the "Scales of Fairness" card.
  /// Rendered at low opacity as a watermark behind the animated scale.
  /// Firefly prompt: see firefly_prompts.md → "scale_watermark"
  static const scaleWatermark = 'assets/images/scale_watermark.png';

  /// Hero illustration for the PDF / Saved-Configs paywall sheet.
  /// Firefly prompt: see firefly_prompts.md → "paywall_hero"
  static const paywallHero = 'assets/images/paywall_hero.png';

  /// Empty-state illustration for the Saved Configurations sheet.
  /// Firefly prompt: see firefly_prompts.md → "empty_state"
  static const emptyState = 'assets/images/empty_state.png';

  /// Full-screen background for the splash screen (9:16 gradient, #E1F5EE → white).
  static const splashBg = 'assets/images/splash_bg.png';

  // ── Onboarding hero images ────────────────────────────────────────────────
  static const heroWelcome = 'assets/images/hero_chad_split.jpg';
  static const heroTapeMeasure = 'assets/images/hero_tape_measure.jpg';
  static const heroHallway = 'assets/images/hero_hallway.jpg';
  static const heroKitchen = 'assets/images/hero_kitchen.jpg';
  static const heroResults = 'assets/images/results_highfive.png';

  /// All onboarding heroes — precached during splash to prevent checkerboard.
  static const onboardingHeroes = [
    heroWelcome,
    heroTapeMeasure,
    heroHallway,
    heroKitchen,
    heroResults,
  ];
}
