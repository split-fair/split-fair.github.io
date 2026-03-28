import 'dart:math';
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

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().autoSaveResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final results = state.results;
      if (results.isEmpty) return const Scaffold(body: Center(child: Text('No data')));
      final total = state.totalRent;
      return Stack(
        children: [
          Scaffold(
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
                // ── SUMMARY card with donut + scale icon center ──────────
                _SummaryCard(results: results, total: total),
                const SizedBox(height: 24),

                // ── EACH PERSON PAYS ─────────────────────────────────────
                const SectionHeader(label: 'Each person pays'),
                const SizedBox(height: 8),
                ...results.asMap().entries.map((e) {
                  final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StitchAmountCard(
                      result: e.value,
                      color: color,
                      total: total,
                    ).animate()
                        .fadeIn(duration: 300.ms, delay: (e.key * 60).ms)
                        .slideX(begin: 0.05, end: 0),
                  );
                }),
                const SizedBox(height: 20),

                // ── Visual breakdown bar chart ───────────────────────────
                _BreakdownCard(results: results),
                const SizedBox(height: 20),

                // ── Why these numbers? ───────────────────────────────────
                _WhyCard(results: results),
                const SizedBox(height: 20),

                // ── Share section ────────────────────────────────────────
                _ShareCard(
                  results: results,
                  total: total,
                  onShareText: () => _shareText(context, results, total),
                  onCopyText: () => _copyToClipboard(context, results, total),
                  onExportPdf: () => _exportPdf(context, state, results),
                  isUnlocked: state.iapUnlocked,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const Positioned.fill(child: _ConfettiBurst()),
        ],
      );
    });
  }

  String _buildShareText(List<SplitResult> results, double total) {
    final lines = results.map((r) => '${r.room.tenant} (${r.room.name}): \$${r.amount.toStringAsFixed(2)} (${(r.percentage * 100).toStringAsFixed(1)}%)').join('\n');
    return 'Fair Rent Split — Total \$${total.toStringAsFixed(2)}\n\n$lines\n\nCalculated with Split Fair';
  }

  void _shareText(BuildContext context, List<SplitResult> results, double total) {
    Share.share(_buildShareText(results, total), subject: 'Fair rent split breakdown');
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

// ─── SUMMARY CARD: green header + donut with scale icon center ─────────────

class _SummaryCard extends StatefulWidget {
  final List<SplitResult> results;
  final double total;
  const _SummaryCard({required this.results, required this.total});
  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final slices = widget.results.asMap().entries.map((e) {
      final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
      return (color, e.value.percentage, e.value.room.tenant);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Green gradient header ──────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SUMMARY',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                color: Colors.white.withOpacity(0.7),
              )),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final displayed = widget.total * _anim.value;
                return _RollingHeaderText(
                  text: '\$${displayed.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1),
                );
              },
            ),
            const SizedBox(height: 2),
            Text('/month',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text('${widget.results.length} rooms total · Optimized balance',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
          ]),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),

        // ── Donut chart with scale icon center ────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut ring with scale icon in center
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (context, progress, _) {
                    return CustomPaint(
                      painter: _DonutPainter(slices: slices, progress: progress),
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.balance_rounded, size: 26, color: AppColors.primary),
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 450.ms, delay: 100.ms),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.results.asMap().entries.map((e) {
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
        ),

        // ── Balance scale for 2 rooms ─────────────────────────────────
        if (widget.results.length == 2) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _buildBalanceScale(),
          ),
        ] else
          const SizedBox(height: 16),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildBalanceScale() {
    final sorted = [...widget.results]..sort((a, b) => b.amount.compareTo(a.amount));
    final left = sorted.first;
    final right = sorted.last;
    final leftIdx = widget.results.indexOf(left);
    final rightIdx = widget.results.indexOf(right);
    final leftColor = AppColors.roomColors[leftIdx % AppColors.roomColors.length];
    final rightColor = AppColors.roomColors[rightIdx % AppColors.roomColors.length];

    return Column(children: [
      const Divider(),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
        child: const Text('Balanced by room score', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(height: 8),
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
    ]);
  }
}

/// Rolling text for the header (white colored digits)
class _RollingHeaderText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _RollingHeaderText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: text.split('').asMap().entries.map((e) {
        final isDigit = RegExp(r'\d').hasMatch(e.value);
        return ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 130),
            transitionBuilder: (child, anim) {
              if (!isDigit) return child;
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: Text(e.value, key: ValueKey('h_${e.key}_${e.value}'), style: style),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Stitch-style amount card: colored left border, dollar + percentage ─────

class _StitchAmountCard extends StatefulWidget {
  final SplitResult result;
  final Color color;
  final double total;
  const _StitchAmountCard({required this.result, required this.color, required this.total});
  @override
  State<_StitchAmountCard> createState() => _StitchAmountCardState();
}

class _StitchAmountCardState extends State<_StitchAmountCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final room = widget.result.room;
    final pctLabel = '${(widget.result.percentage * 100).toStringAsFixed(0)}%';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(children: [
          // 4px colored left accent
          Container(width: 4, color: widget.color),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    room.tenant.isNotEmpty ? room.tenant[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: widget.color),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + room label
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(room.tenant, style: Theme.of(context).textTheme.titleMedium),
                    Text(room.name, style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                ),
                // Dollar amount + percentage badge
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) {
                      final displayed = widget.result.amount * _anim.value;
                      return Text(
                        '\$${displayed.toStringAsFixed(2)}/mo',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: widget.color,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(pctLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.color)),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Visual breakdown bar chart ─────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final List<SplitResult> results;
  const _BreakdownCard({required this.results});
  @override
  Widget build(BuildContext context) {
    final maxFraction = results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
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

// ─── Share card ──────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
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

// ─── Why these numbers? card ─────────────────────────────────────────────────

class _WhyCard extends StatelessWidget {
  final List<SplitResult> results;
  const _WhyCard({required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Why these numbers?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Tap any room to see its full score.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        ...results.asMap().entries.map((e) {
          final color = AppColors.roomColors[e.key % AppColors.roomColors.length];
          final room = e.value.room;
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

// ─── Donut painter (reused from common_widgets but local for the summary) ───

class _DonutPainter extends CustomPainter {
  final List<(Color, double, String)> slices;
  final double progress;
  const _DonutPainter({required this.slices, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 26.0;
    const gapAngle = 0.04;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    for (final slice in slices) {
      final sweep = slice.$2 * 2 * pi * progress - gapAngle;
      if (sweep <= 0) continue;
      paint.color = slice.$1;
      canvas.drawArc(rect, startAngle + gapAngle / 2, sweep, false, paint);
      startAngle += slice.$2 * 2 * pi * progress;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─── Confetti burst ──────────────────────────────────────────────────────────

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst();
  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(55, (_) => _Particle(_rand));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          if (_ctrl.value >= 1.0) return const SizedBox.shrink();
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _ctrl.value),
            size: MediaQuery.of(context).size,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double rotSpeed;
  final bool isCircle;

  _Particle(Random r)
      : x = r.nextDouble(),
        vx = (r.nextDouble() - 0.5) * 0.6,
        vy = 0.3 + r.nextDouble() * 0.7,
        size = 5 + r.nextDouble() * 7,
        color = [
          const Color(0xFF00694C),
          const Color(0xFF855400),
          const Color(0xFF378ADD),
          const Color(0xFFD4537E),
          const Color(0xFFEA4335),
          Colors.white,
        ][r.nextInt(6)],
        rotation = r.nextDouble() * 2 * pi,
        rotSpeed = (r.nextDouble() - 0.5) * 8,
        isCircle = r.nextBool();
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  const _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = progress;
      final px = (p.x + p.vx * t) * size.width;
      final py = (-0.15 + p.vy * t * t * 1.8) * size.height;
      if (py > size.height) continue;

      final opacity = (1.0 - (t * 1.2).clamp(0.0, 1.0)).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + p.rotSpeed * t);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
