import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_state.dart';
import '../models/pdf_service.dart';
import '../models/split_result.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/scale_animation.dart';
import '../widgets/score_breakdown.dart';
import 'paywall_sheet.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final results = state.results;
      if (results.isEmpty) return const Scaffold(body: Center(child: Text('No data')));
      final total = state.totalRent;
      return Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        appBar: AppBar(
          title: const Text('Fair split'),
          actions: [
            IconButton(onPressed: () => _shareText(context, results, total), icon: const Icon(Icons.ios_share_rounded, size: 22)),
            IconButton(onPressed: () => _exportPdf(context, state, results), icon: const Icon(Icons.picture_as_pdf_rounded, size: 22)),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TotalHeader(total: total, count: results.length),
            const SizedBox(height: 16),
            _ScaleCard(results: results)
              .animate().fadeIn(duration: 450.ms, delay: 80.ms).slideY(begin: 0.04, end: 0),
            const SizedBox(height: 20),
            const SectionHeader(label: 'Each person pays'),
            const SizedBox(height: 8),
            ...results.asMap().entries.map((e) {
              final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AmountCard(name: e.value.room.name, tenant: e.value.room.tenant, amount: e.value.amount, percentage: e.value.percentage, color: color, rank: e.key + 1)
                  .animate().fadeIn(duration: 300.ms, delay: (e.key * 60).ms).slideX(begin: 0.05, end: 0),
              );
            }),
            const SizedBox(height: 20),
            // For 3+ rooms the donut is already shown in _ScaleCard; only show here for 2-person
            if (results.length <= 2) ...[
              _DonutCard(results: results, total: total),
              const SizedBox(height: 20),
            ],
            _BreakdownCard(results: results),
            const SizedBox(height: 20),
            _WhyCard(results: results),
            const SizedBox(height: 20),
            _ShareCard(results: results, total: total, onShareText: () => _shareText(context, results, total), onCopyText: () => _copyToClipboard(context, results, total), onExportPdf: () => _exportPdf(context, state, results), isUnlocked: state.iapUnlocked),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  String _buildShareText(List<SplitResult> results, double total) {
    final lines = results.map((r) => '${r.room.tenant} (${r.room.name}): \$${r.amount.toStringAsFixed(2)} (${(r.percentage * 100).toStringAsFixed(1)}%)').join('\n');
    return 'Fair Rent Split — Total \$${total.toStringAsFixed(2)}\n\n$lines\n\nCalculated with Split Fair';
  }

  void _shareText(BuildContext context, List<SplitResult> results, double total) {
    SharePlus.instance.share(ShareParams(
      text: _buildShareText(results, total),
      subject: 'Fair rent split breakdown',
    ));
  }

  void _copyToClipboard(BuildContext context, List<SplitResult> results, double total) {
    Clipboard.setData(ClipboardData(text: _buildShareText(results, total)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _exportPdf(BuildContext context, AppState state, List<SplitResult> results) async {
    if (state.iapUnlocked) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      try {
        final bytes = await PdfService.generateSplitPdf(
          results: results,
          totalRent: state.totalRent,
          address: state.address.isNotEmpty ? state.address : null,
        );
        await Printing.sharePdf(bytes: bytes, filename: 'split_fair_rent.pdf');
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    } else {
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(value: state, child: const PaywallSheet()));
    }
  }
}

class _TotalHeader extends StatelessWidget {
  final double total;
  final int count;
  const _TotalHeader({required this.total, required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total monthly rent', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 6),
        Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Split across $count rooms', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8))),
      ]),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1));
  }
}

class _BreakdownCard extends StatelessWidget {
  final List<SplitResult> results;
  const _BreakdownCard({required this.results});
  @override
  Widget build(BuildContext context) {
    final maxFraction = results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Visual breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...results.asMap().entries.map((e) {
          final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
          return BarChartRow(label: e.value.room.tenant, fraction: e.value.percentage / maxFraction, color: color, valueLabel: '${(e.value.percentage * 100).toStringAsFixed(0)}%');
        }),
      ]),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

class _ShareCard extends StatelessWidget {
  final List<SplitResult> results;
  final double total;
  final VoidCallback onShareText;
  final VoidCallback onCopyText;
  final VoidCallback onExportPdf;
  final bool isUnlocked;
  const _ShareCard({required this.results, required this.total, required this.onShareText, required this.onCopyText, required this.onExportPdf, required this.isUnlocked});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Share with roommates', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Send the breakdown so everyone sees the math.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: onShareText,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: onCopyText,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          )),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onExportPdf,
            icon: Icon(isUnlocked ? Icons.picture_as_pdf_rounded : Icons.lock_rounded, size: 18),
            label: Text(isUnlocked ? 'Export PDF' : 'Export PDF  —  \$1.99'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: isUnlocked ? AppColors.primary : AppColors.accent, foregroundColor: Colors.white),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

// ─── Donut chart card ────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  final List<SplitResult> results;
  final double total;
  const _DonutCard({required this.results, required this.total});

  @override
  Widget build(BuildContext context) {
    final slices = results.asMap().entries.map((e) {
      final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
      return (color, e.value.percentage, e.value.room.tenant);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Rent split at a glance', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
            child: const Text('Weighted by room score', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Donut ring — no built-in legend
            DonutChart(
              slices: slices,
              centerLabel: '\$${total.toStringAsFixed(0)}',
              centerSub: 'total',
              showLegend: false,
              size: 148,
            ),
            const SizedBox(width: 20),
            // Custom legend: ● Name   $X/mo   X%
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: results.asMap().entries.map((e) {
                  final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      Container(
                        width: 11, height: 11,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.room.tenant,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(
                          '\$${e.value.amount.toStringAsFixed(0)}/mo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                        ),
                        Text(
                          '${(e.value.percentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ]),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms, delay: 180.ms);
  }
}

// ─── Why these numbers? card ─────────────────────────────────────────────────

class _WhyCard extends StatelessWidget {
  final List<SplitResult> results;
  const _WhyCard({required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Why these numbers?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Tap any room to see its full score.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        ...results.asMap().entries.map((e) {
          final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
          final room = e.value.room;
          // Condensed: sqft pts | feature pts | quality pts
          final sqftPts = room.sqft;
          final qualityPts = (room.naturalLightScore * 3) + (room.noiseScore * 2) + (room.storageScore * 1.5);
          final bonusPts = e.value.score - sqftPts - qualityPts;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (e.key > 0) const Divider(height: 20),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderMed, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(room.tenant, style: Theme.of(context).textTheme.titleMedium),
                    ]),
                    const SizedBox(height: 16),
                    ScoreBreakdown(room: room),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(room.tenant, style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    Text('${e.value.score.toStringAsFixed(0)} pts total',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    _PtChip('${sqftPts.toStringAsFixed(0)} sqft', AppColors.textTertiary),
                    const SizedBox(width: 6),
                    if (bonusPts > 0) ...[_PtChip('+${bonusPts.toStringAsFixed(0)} features', AppColors.primary), const SizedBox(width: 6)],
                    _PtChip('+${qualityPts.toStringAsFixed(0)} quality', AppColors.accent),
                  ]),
                ]),
              ),
            ),
          ]);
        }),
      ]),
    ).animate().fadeIn(duration: 400.ms, delay: 260.ms);
  }
}

// ─── Scale of Fairness card ───────────────────────────────────────────────────

class _ScaleCard extends StatelessWidget {
  final List<SplitResult> results;
  const _ScaleCard({required this.results});

  @override
  Widget build(BuildContext context) {
    // 3+ rooms: show the combined donut chart instead of the balance scale
    if (results.length > 2) {
      final total = results.fold(0.0, (s, r) => s + r.amount);
      return _DonutCard(results: results, total: total);
    }

    final sorted = [...results]..sort((a, b) => b.amount.compareTo(a.amount));
    final left = sorted.first;
    final right = sorted.last;
    final leftIdx = results.indexOf(left);
    final rightIdx = results.indexOf(right);
    final leftColor = AppColors.roomColors[leftIdx % AppColors.roomColors.length];
    final rightColor = AppColors.roomColors[rightIdx % AppColors.roomColors.length];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Scales of fairness', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
              child: const Text('Balanced by room score', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 2),
          Text('The heavier side pays more — weighted by room value.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          JudicialScaleWidget(
            leftPercentage: left.percentage,
            rightPercentage: right.percentage,
            leftLabel: left.room.tenant,
            rightLabel: right.room.tenant,
            leftAmount: left.amount,
            rightAmount: right.amount,
            leftColor: leftColor,
            rightColor: rightColor,
          ),
        ],
      ),
    );
  }
}


class _PtChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PtChip(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}
