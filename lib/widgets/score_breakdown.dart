import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

/// Live score breakdown card shown in the room edit sheet.
/// Updates in real time as the user tweaks features and sliders.
class ScoreBreakdown extends StatefulWidget {
  final Room room;
  const ScoreBreakdown({super.key, required this.room});
  @override
  State<ScoreBreakdown> createState() => _ScoreBreakdownState();

  /// Exposed so ResultsScreen can reuse the breakdown logic.
  static List<(String, double)> buildItems(Room room) => _ScoreBreakdownState._buildItemsFor(room);
}

class _ScoreBreakdownState extends State<ScoreBreakdown> {
  double _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _prevScore = widget.room.computeScore();
  }

  @override
  void didUpdateWidget(ScoreBreakdown old) {
    super.didUpdateWidget(old);
    _prevScore = old.room.computeScore();
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.room.computeScore();
    final items = _buildItemsFor(widget.room);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text('Score breakdown', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primaryDark)),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: _prevScore, end: score),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, val, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('${val.toStringAsFixed(0)} pts',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFB2DDD1)),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((e) => _ScoreRow(
          label: e.value.$1,
          pts: e.value.$2,
          totalScore: score,
          delay: e.key * 40,
        )),
        const SizedBox(height: 8),
        Text('Higher score = higher share of total rent',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 11, color: AppColors.primaryDark.withOpacity(0.65))),
      ]),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
  }

  static List<(String, double)> _buildItemsFor(Room room) {
    final items = <(String, double)>[];
    items.add(('${room.sqft.toInt()} sqft × 1 pt', room.sqft));
    if (room.hasPrivateBath) items.add(('Private bathroom', 40));
    if (room.hasParking) items.add(('Parking spot', 30));
    if (room.hasBalcony) items.add(('Balcony / patio', 20));
    if (room.hasWalkInCloset) items.add(('Walk-in closet', 15));
    if (room.hasAC) items.add(('A/C unit', 10));
    if (room.floorLevel > 0) {
      final bonus = (room.floorLevel * 2).clamp(0, 12).toDouble();
      items.add(('Floor ${room.floorLevel} bonus', bonus));
    }
    items.add(('Natural light (${room.naturalLightScore.toInt()}/10)', room.naturalLightScore * 3));
    items.add(('Quietness (${room.noiseScore.toInt()}/10)', room.noiseScore * 2));
    items.add(('Storage space (${room.storageScore.toInt()}/10)', room.storageScore * 1.5));
    return items;
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double pts;
  final double totalScore;
  final int delay;
  const _ScoreRow({required this.label, required this.pts, required this.totalScore, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final fraction = totalScore > 0 ? (pts / totalScore).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12, color: AppColors.primaryDark.withOpacity(0.85)))),
          Text('+${pts % 1 == 0 ? pts.toInt() : pts.toStringAsFixed(1)} pts',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        ]),
        const SizedBox(height: 3),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: fraction),
          duration: Duration(milliseconds: 500 + delay),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(children: [
              Container(height: 4, color: AppColors.primary.withOpacity(0.12)),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.6), borderRadius: BorderRadius.circular(3))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
