import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/ad_service.dart';
import '../models/app_state.dart';
import '../theme/app_images.dart';
import '../theme/app_theme.dart';

class PaywallSheet extends StatefulWidget {
  /// Called when the user earns a one-time PDF export via rewarded ad.
  final VoidCallback? onRewardedUnlock;

  const PaywallSheet({super.key, this.onRewardedUnlock});
  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  bool _adLoading = false;

  void _watchAd() {
    setState(() => _adLoading = true);
    AdService.showRewardedAd(
      onRewarded: () {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onRewardedUnlock?.call();
      },
      onFailed: () {
        if (!mounted) return;
        setState(() => _adLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not ready yet. Try again in a moment.')),
        );
      },
    );
  }

  void _purchase() {
    final iap = context.read<AppState>().iapService;
    if (!iap.storeAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store not available. Check your connection.')),
      );
      return;
    }
    iap.purchasePdfExport();
    if (iap.errorMessage == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening store...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(iap.errorMessage!)),
      );
    }
  }

  Future<void> _restore() async {
    final iap = context.read<AppState>().iapService;
    final wasUnlocked = iap.pdfUnlocked;
    await iap.restorePurchases();
    if (!mounted) return;
    final nowUnlocked = iap.pdfUnlocked;
    if (nowUnlocked && !wasUnlocked) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF Export restored! Enjoy.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchase found for this Apple ID.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adReady = AdService.isRewardedAdReady;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.borderMed, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 24),

        // Hero image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.accentLight, AppColors.primaryLight],
              center: Alignment.topLeft,
              radius: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppImages.paywallHero,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.picture_as_pdf_rounded, size: 48, color: AppColors.accent,
              ),
            ),
          ),
        ).animate().scale(duration: 450.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),

        // Title
        Text(
          'Export PDF',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Share a professional rent breakdown with your roommates.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // ── Option 1: Watch ad for one-time export ──────────────────
        _OptionCard(
          icon: Icons.play_circle_outline_rounded,
          iconColor: AppColors.primary,
          title: 'Watch a short video',
          subtitle: 'Export this split for free',
          trailing: _adLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.arrow_forward_rounded,
                  color: adReady ? AppColors.primary : AppColors.textTertiary,
                  size: 20,
                ),
          enabled: adReady && !_adLoading,
          onTap: _watchAd,
          highlight: true,
        ),
        const SizedBox(height: 12),

        // ── Option 2: Purchase to skip ads forever ──────────────────
        _OptionCard(
          icon: Icons.all_inclusive_rounded,
          iconColor: AppColors.accent,
          title: 'Skip ads forever',
          subtitle: 'One-time purchase \$1.99',
          trailing: const Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 20),
          enabled: true,
          onTap: _purchase,
          highlight: false,
        ),
        const SizedBox(height: 8),

        // Hint text
        if (!adReady && !_adLoading)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Ad loading... try again in a moment',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: _restore, child: const Text('Restore purchase')),
        ]),
      ]),
    );
  }
}

/// Tappable option card for the paywall.
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool enabled;
  final VoidCallback onTap;
  final bool highlight;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.enabled,
    required this.onTap,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: highlight ? AppColors.primaryLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlight ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                width: highlight ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
              trailing,
            ]),
          ),
        ),
      ),
    );
  }
}
