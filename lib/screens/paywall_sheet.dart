import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_images.dart';
import '../theme/app_theme.dart';

class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});
  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  void _purchase() {
    final iap = context.read<AppState>().iapService;
    if (!iap.storeAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store not available. Check your connection.')),
      );
      return;
    }
    iap.purchasePdfExport();
    // Only pop if the product was found — otherwise stay open so user sees the error
    if (iap.errorMessage == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening store…')),
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
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderMed, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 28),
        // Firefly paywall hero with gradient backdrop for visual impact.
        Container(
          width: 140,
          height: 140,
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
              errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.accent),
            ),
          ),
        ).animate().scale(duration: 450.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text('Unlock PDF Export', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Get a beautiful, shareable PDF of your rent split.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ...[('Printable PDF with all room details', Icons.print_rounded), ('Professional layout', Icons.home_work_rounded), ('One-time purchase, yours forever', Icons.all_inclusive_rounded)].map((f) =>
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)), child: Icon(f.$2, size: 16, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(f.$1, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15))),
          ]))),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _purchase,
          child: const Text('Unlock for \$1.99'),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe later')),
          const SizedBox(width: 8),
          TextButton(onPressed: _restore, child: const Text('Restore')),
        ]),
      ]),
    );
  }
}