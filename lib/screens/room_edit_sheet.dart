import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/score_breakdown.dart';

class RoomEditSheet extends StatefulWidget {
  final Room room;
  final ValueChanged<Room> onSave;
  /// Called on save with the full {roomId -> sharePct} map for ALL rooms,
  /// so the app can redistribute communal shares atomically.
  final ValueChanged<Map<String, double>>? onSaveAllCommunal;
  final bool communalEnabled;
  final double communalSqft;
  final List<Room> allRooms;
  final double totalAptSqft;
  final ValueChanged<double>? onSetTotalAptSqft;
  const RoomEditSheet({
    super.key,
    required this.room,
    required this.onSave,
    this.onSaveAllCommunal,
    this.communalEnabled = false,
    this.communalSqft = 0,
    this.allRooms = const [],
    this.totalAptSqft = 0,
    this.onSetTotalAptSqft,
  });
  @override
  State<RoomEditSheet> createState() => _RoomEditSheetState();
}

class _RoomEditSheetState extends State<RoomEditSheet> {
  late Room _room;
  late TextEditingController _nameCtrl;
  late TextEditingController _tenantCtrl;
  late TextEditingController _sqftCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _aptSqftCtrl;
  late double _communalSharePct;
  late bool _communalEquallyTreated;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _nameCtrl = TextEditingController(text: _room.name);
    _tenantCtrl = TextEditingController(text: _room.tenant);
    _sqftCtrl = TextEditingController(text: _room.sqft.toInt().toString());
    _floorCtrl = TextEditingController(text: _room.floorLevel > 0 ? _room.floorLevel.toString() : '');
    final _equalShare = widget.allRooms.isEmpty ? 50.0 : 100.0 / widget.allRooms.length;
    _communalSharePct = widget.room.communalSharePct ?? _equalShare;
    _communalEquallyTreated = widget.room.communalSharePct == null;
    _aptSqftCtrl = TextEditingController(
      text: widget.totalAptSqft > 0 ? widget.totalAptSqft.toInt().toString() : '',
    );
  }

  /// Sqft this room gets at its current slider value.
  double get _communalSqftPreview {
    if (!widget.communalEnabled || widget.communalSqft <= 0 || widget.allRooms.isEmpty) return 0;
    return (_communalSharePct / 100.0) * widget.communalSqft;
  }

  /// Equal share per room (used as the saved default when no explicit pct is set).
  double get _equalShare => widget.allRooms.isEmpty ? 50.0 : 100.0 / widget.allRooms.length;

  /// Compute how much each OTHER room keeps after this room claims _communalSharePct.
  /// Redistribution is proportional to each room's saved value, so rooms with larger
  /// saved shares absorb a larger fraction of any change — preserving relative ratios.
  double _computedShareForOther(Room other) {
    final otherRooms = widget.allRooms.where((r) => r.id != widget.room.id).toList();
    if (otherRooms.isEmpty) return 0;

    // Sum of other rooms' saved shares (their baseline)
    final sumSaved = otherRooms.fold(0.0, (s, r) => s + (r.communalSharePct ?? _equalShare));

    // Total remaining budget for all other rooms
    final remaining = (100.0 - _communalSharePct).clamp(0.0, 100.0);

    if (sumSaved <= 0) return remaining / otherRooms.length;

    // Distribute proportionally: each other room gets (its saved ratio × remaining)
    final savedOther = other.communalSharePct ?? _equalShare;
    return (savedOther / sumSaved) * remaining;
  }

  double _computedSqftForOther(Room other) {
    if (widget.communalSqft <= 0) return 0;
    return (_computedShareForOther(other) / 100.0) * widget.communalSqft;
  }

  /// Full share map to persist across ALL rooms atomically on save.
  Map<String, double> get _fullShareMap {
    final map = <String, double>{};
    for (final r in widget.allRooms) {
      map[r.id] = r.id == widget.room.id ? _communalSharePct : _computedShareForOther(r);
    }
    return map;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _tenantCtrl.dispose(); _sqftCtrl.dispose(); _floorCtrl.dispose(); _aptSqftCtrl.dispose(); super.dispose(); }

  void _showCommunalInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Communal Space'),
        content: const Text(
          'Communal spaces are areas in the home other than the bedrooms — living room, kitchen, bathrooms, etc. Uncheck this if a roommate has more or less access to the home than others, then adjust sliders accordingly.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
      ),
    );
  }

  void _save() {
    final parsedSqft = double.tryParse(_sqftCtrl.text) ?? _room.sqft;
    if (parsedSqft < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room must be at least 50 sqft.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final updatedRoom = _room.copyWith(
      name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : _room.name,
      tenant: _tenantCtrl.text.trim().isNotEmpty ? _tenantCtrl.text.trim() : _room.tenant,
      sqft: parsedSqft,
      floorLevel: int.tryParse(_floorCtrl.text) ?? 0,
      communalSharePct: _communalEquallyTreated ? null : _communalSharePct,
    );
    widget.onSave(updatedRoom);
    // Fire adaptive redistribution for all rooms
    if (widget.communalEnabled && widget.onSaveAllCommunal != null) {
      widget.onSaveAllCommunal!(_fullShareMap);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderMed, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Text('Edit room', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            const SizedBox(width: 4),
            ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40), padding: const EdgeInsets.symmetric(horizontal: 20)), child: const Text('Save')),
          ]),
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(label: 'Basics'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _tenantCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Tenant name'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _nameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Room label'))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(controller: _sqftCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Square footage', hintText: 'min 50', suffixText: 'sqft'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _floorCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Floor #', hintText: 'e.g. 3', suffixText: 'floor'))),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(label: 'Features'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FeatureChip(label: 'Private bath', icon: Icons.bathtub_rounded, selected: _room.hasPrivateBath, bonus: '+40 pts', onTap: () => setState(() { _room = _room.copyWith(hasPrivateBath: !_room.hasPrivateBath); })),
                FeatureChip(label: 'Parking spot', icon: Icons.directions_car_rounded, selected: _room.hasParking, bonus: '+30 pts', onTap: () => setState(() { _room = _room.copyWith(hasParking: !_room.hasParking); })),
                FeatureChip(label: 'Balcony / patio', icon: Icons.deck_rounded, selected: _room.hasBalcony, bonus: '+20 pts', onTap: () => setState(() { _room = _room.copyWith(hasBalcony: !_room.hasBalcony); })),
                FeatureChip(label: 'Walk-in closet', icon: Icons.checkroom_rounded, selected: _room.hasWalkInCloset, bonus: '+15 pts', onTap: () => setState(() { _room = _room.copyWith(hasWalkInCloset: !_room.hasWalkInCloset); })),
                FeatureChip(label: 'A/C unit', icon: Icons.ac_unit_rounded, selected: _room.hasAC, bonus: '+10 pts', onTap: () => setState(() { _room = _room.copyWith(hasAC: !_room.hasAC); })),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(label: 'Room quality'),
              const SizedBox(height: 12),
              LabeledSlider(label: 'Natural light', value: _room.naturalLightScore, divisions: 10, format: (v) => v.toInt() < 4 ? 'Dim' : v.toInt() < 7 ? 'Good' : 'Bright', onChanged: (v) => setState(() { _room = _room.copyWith(naturalLightScore: v); })),
              const SizedBox(height: 4),
              LabeledSlider(label: 'Quietness', value: _room.noiseScore, divisions: 10, format: (v) => v.toInt() < 4 ? 'Noisy' : v.toInt() < 7 ? 'Moderate' : 'Quiet', onChanged: (v) => setState(() { _room = _room.copyWith(noiseScore: v); })),
              const SizedBox(height: 4),
              LabeledSlider(label: 'Storage space', value: _room.storageScore, divisions: 10, format: (v) => v.toInt() < 4 ? 'Minimal' : v.toInt() < 7 ? 'Average' : 'Plenty', onChanged: (v) => setState(() { _room = _room.copyWith(storageScore: v); })),
              if (widget.allRooms.length > 1) ...[
                const SizedBox(height: 24),
                SectionHeader(
                  label: 'Communal space',
                  trailing: GestureDetector(
                    onTap: _showCommunalInfo,
                    child: const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                // Checkbox: treated equally
                InkWell(
                  onTap: () => setState(() => _communalEquallyTreated = !_communalEquallyTreated),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(children: [
                    Checkbox(
                      value: _communalEquallyTreated,
                      onChanged: (v) => setState(() => _communalEquallyTreated = v ?? true),
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Communal space treated equally',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
                // Custom communal slider (shown when unchecked)
                if (!_communalEquallyTreated) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _communalSharePct = _equalShare),
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('Reset to equal'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  // Total apt sqft input if not set
                  if (widget.totalAptSqft <= 0) ...[
                    TextFormField(
                      controller: _aptSqftCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Total apartment sqft',
                        hintText: 'e.g. 1200 — needed to calculate communal sqft',
                        suffixText: 'sqft',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null && parsed > 0) widget.onSetTotalAptSqft?.call(parsed);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          thumbColor: AppColors.primary,
                          inactiveTrackColor: AppColors.primary.withOpacity(0.18),
                          overlayColor: AppColors.primary.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _communalSharePct.clamp(0.0, 100.0),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (v) => setState(() => _communalSharePct = v),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...widget.allRooms.map((r) {
                        final isThis = r.id == widget.room.id;
                        final pct   = isThis ? _communalSharePct : _computedShareForOther(r);
                        final sqft  = isThis ? _communalSqftPreview : _computedSqftForOther(r);
                        final label = isThis
                            ? (r.name.isNotEmpty ? r.name : 'This room')
                            : (r.name.isNotEmpty ? r.name : 'Other room');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: isThis ? AppColors.primary : AppColors.primary.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: isThis ? FontWeight.w700 : FontWeight.w400,
                                  color: isThis ? AppColors.primaryDark : AppColors.primaryDark.withOpacity(0.7),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct / 100.0,
                                  minHeight: 5,
                                  backgroundColor: AppColors.primary.withOpacity(0.12),
                                  color: isThis ? AppColors.primary : AppColors.primary.withOpacity(0.4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: widget.communalSqft > 0 ? 90 : 50,
                              child: Text(
                                widget.communalSqft > 0
                                    ? '${pct.toStringAsFixed(1)}%  ·  ${sqft.toStringAsFixed(0)} sqft'
                                    : '${pct.toStringAsFixed(1)}%',
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: isThis ? FontWeight.w700 : FontWeight.w400,
                                  color: isThis ? AppColors.primaryDark : AppColors.primaryDark.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ]),
                        );
                      }),
                      const SizedBox(height: 10),
                      Text(
                        widget.communalSqft > 0
                            ? 'Equal share: ${(100.0 / widget.allRooms.length).toStringAsFixed(1)}% each  ·  ${(widget.communalSqft / widget.allRooms.length).toStringAsFixed(0)} sqft each'
                            : 'Equal share: ${(100.0 / widget.allRooms.length).toStringAsFixed(1)}% each',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11, color: AppColors.primaryDark.withOpacity(0.45)),
                      ),
                    ]),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              ScoreBreakdown(room: _room),
            ]).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03, end: 0),
          ),
        ),
      ]),
    );
  }
}