import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/room.dart';
import '../theme/app_images.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'room_edit_sheet.dart';
import 'results_screen.dart';
import 'saved_configs_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, state),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildRentInput(context, state),
                    const SizedBox(height: 12),
                    _buildAddressInput(context, state),
                    const SizedBox(height: 12),
                    _CommunalSpaceCard(state: state),
                    const SizedBox(height: 24),
                    _buildRoomsList(context, state),
                    const SizedBox(height: 16),
                    _buildAddRoomButton(context, state),
                    const SizedBox(height: 24),
                    _buildCalculateButton(context, state),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppState state) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      pinned: true,
      expandedHeight: 180,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 6),
        // Firefly home_bg shows as a subtle background behind the app bar text.
        // A gradient fade-to-white at the bottom keeps the title always legible.
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImages.homeBg,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.surface),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.surface],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
          ],
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split Fair', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            Text('Fair rent for every room', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => showModalBottomSheet(
            context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
            builder: (_) => ChangeNotifierProvider.value(value: state, child: const SavedConfigsSheet()),
          ),
          icon: Badge(
            isLabelVisible: state.savedConfigs.isNotEmpty,
            label: Text('${state.savedConfigs.length}'),
            child: const Icon(Icons.bookmark_rounded, size: 22),
          ),
          tooltip: 'Saved configs',
        ),
        IconButton(onPressed: () => _showResetDialog(context, state), icon: const Icon(Icons.refresh_rounded, size: 22)),
        IconButton(onPressed: () => _showAbout(context), icon: const Icon(Icons.info_outline_rounded, size: 22), tooltip: 'About'),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildRentInput(BuildContext context, AppState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(label: 'Total monthly rent'),
      const SizedBox(height: 8),
      Hero(
        tag: 'total_rent_amount',
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: CurrencyField(value: state.totalRent, label: 'Monthly total', onChanged: state.setTotalRent),
          ),
        ),
      ),
    ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAddressInput(BuildContext context, AppState state) {
    return _AddressField(
      initialValue: state.address,
      onChanged: state.setAddress,
      suggestions: state.recentAddresses,
    ).animate().fadeIn(duration: 300.ms, delay: 25.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildRoomsList(BuildContext context, AppState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
        label: '${state.rooms.length} rooms',
        trailing: IconButton(
          onPressed: () => _showScoringExplainer(context),
          icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textTertiary),
          tooltip: 'How scoring works',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ),
      const SizedBox(height: 8),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.rooms.length,
        onReorder: state.reorderRooms,
        proxyDecorator: (child, idx, anim) => Material(elevation: 8, borderRadius: BorderRadius.circular(16), child: child),
        itemBuilder: (context, i) {
          final room = state.rooms[i];
          final color = AppColors.roomColors[i % AppColors.roomColors.length];
          final canDelete = state.rooms.length > 2;
          return KeyedSubtree(
            key: ValueKey(room.id),
            child: _SwipeDeleteWrapper(
              enabled: canDelete,
              onDelete: () => state.removeRoom(room.id),
              child: _RoomTile(
                room: room, color: color, index: i,
                onEdit: () => _openRoomEdit(context, state, room.id),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.swipe_left_rounded, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text('Swipe to remove  ·  Hold & drag to reorder',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, color: AppColors.textTertiary)),
      ]),
    ]);
  }

  Widget _buildAddRoomButton(BuildContext context, AppState state) {
    return OutlinedButton.icon(
      onPressed: () {
        state.addRoom();
        HapticFeedback.lightImpact();
      },
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Add another room'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildCalculateButton(BuildContext context, AppState state) {
    final isReady = state.rooms.length >= 2 && state.totalRent > 0;
    final btn = ElevatedButton(
      onPressed: isReady
          ? () {
              FocusScope.of(context).unfocus();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const ResultsScreen(),
                  transitionDuration: const Duration(milliseconds: 420),
                  reverseTransitionDuration: const Duration(milliseconds: 350),
                  transitionsBuilder: (_, animation, __, child) {
                    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                            .animate(curved),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            }
          : null,
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.calculate_rounded, size: 20),
        SizedBox(width: 8),
        Text('Calculate fair split'),
      ]),
    );

    if (isReady) {
      return btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 2200.ms, color: Colors.white.withOpacity(0.18), angle: 30)
          .animate()  // chained: run once on build
          .fadeIn(duration: 400.ms, delay: 150.ms)
          .slideY(begin: 0.05, end: 0);
    }
    return btn
        .animate()
        .fadeIn(duration: 400.ms, delay: 150.ms)
        .slideY(begin: 0.05, end: 0);
  }

  void _showScoringExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const _ScoringExplainerSheet(),
    );
  }

  void _openRoomEdit(BuildContext context, AppState state, String roomId) {
    final room = state.rooms.firstWhere((r) => r.id == roomId);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => RoomEditSheet(
        room: room,
        onSave: (updated) => state.updateRoom(roomId, updated),
        onSaveAllCommunal: (shares) => state.updateAllCommunalShares(shares),
        communalEnabled: state.communalEnabled,
        communalSqft: state.communalSqft,
        allRooms: state.rooms,
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.balance_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text('Split Fair'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Version ${info.version} (${info.buildNumber})',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          const Text('Fair rent splitting — weighted by room size, features, and quality.', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('© 2025 Split Fair', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppState state) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Reset everything?'),
      content: const Text('This will clear all rooms and start fresh.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { state.reset(); Navigator.pop(ctx); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(80, 40)),
          child: const Text('Reset'),
        ),
      ],
    ));
  }
}

// ─── Scoring Explainer Sheet ─────────────────────────────────────────────────

class _ScoringExplainerSheet extends StatelessWidget {
  const _ScoringExplainerSheet();

  static const _rows = [
    ('Square footage', '1 pt per sqft'),
    ('Private bathroom', '+40 pts'),
    ('Parking spot', '+30 pts'),
    ('Balcony / patio', '+20 pts'),
    ('Walk-in closet', '+15 pts'),
    ('A/C unit', '+10 pts'),
    ('Floor bonus', '+2 pts/floor (max +12)'),
    ('Natural light (1–10)', '×3 pts each'),
    ('Quietness (1–10)', '×2 pts each'),
    ('Storage space (1–10)', '×1.5 pts each'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderMed, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calculate_rounded, size: 18, color: AppColors.primary)),
          const SizedBox(width: 12),
          Text('How scoring works', style: Theme.of(context).textTheme.titleLarge),
        ]),
        const SizedBox(height: 8),
        Text('Each room earns points based on size and features. Your share of rent = your room\'s points ÷ total points.',
          style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: _rows.asMap().entries.map((e) {
            final isLast = e.key == _rows.length - 1;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  Expanded(child: Text(e.value.$1, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14))),
                  Text(e.value.$2, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                ]),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ]);
          }).toList()),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: Text('Example: 180 sqft + private bath = 180 + 40 = 220 pts. If total is 400 pts, this room pays 55% of rent.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark, fontSize: 13)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text('Got it'),
        ),
      ]),
    );
  }
}

class _AddressField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final List<String> suggestions;
  const _AddressField({required this.initialValue, required this.onChanged, required this.suggestions});
  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.initialValue); }

  @override
  void didUpdateWidget(_AddressField old) {
    super.didUpdateWidget(old);
    // Sync field if state was reset externally (e.g. reset button)
    if (widget.initialValue != old.initialValue && widget.initialValue != _ctrl.text) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _ctrl,
      focusNode: _focus,
      optionsBuilder: (value) {
        if (value.text.isEmpty || widget.suggestions.isEmpty) return const Iterable<String>.empty();
        final q = value.text.toLowerCase();
        return widget.suggestions.where((s) => s.toLowerCase().contains(q));
      },
      onSelected: (s) { _ctrl.text = s; widget.onChanged(s); },
      fieldViewBuilder: (_, ctrl, focusNode, __) => TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        keyboardType: TextInputType.streetAddress,
        textCapitalization: TextCapitalization.words,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Property address (optional)',
          hintText: 'e.g. 123 Main St, Apt 4B',
          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
        ),
        onChanged: widget.onChanged,
      ),
      optionsViewBuilder: (_, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final s = options.elementAt(i);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history_rounded, size: 16, color: AppColors.textTertiary),
                  title: Text(s, style: const TextStyle(fontSize: 14)),
                  onTap: () => onSelected(s),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Communal Space Card ─────────────────────────────────────────────────────

class _CommunalSpaceCard extends StatefulWidget {
  final AppState state;
  const _CommunalSpaceCard({required this.state});
  @override
  State<_CommunalSpaceCard> createState() => _CommunalSpaceCardState();
}

class _CommunalSpaceCardState extends State<_CommunalSpaceCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final v = widget.state.totalAptSqft;
    _ctrl = TextEditingController(text: v > 0 ? v.toInt().toString() : '');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final enabled = state.communalEnabled;
    final communal = state.communalSqft;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: enabled ? AppColors.primary.withOpacity(0.3) : AppColors.border),
        ),
        child: Column(
          children: [
            // Toggle row
            InkWell(
              onTap: () => state.setCommunalEnabled(!enabled),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: enabled ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.house_rounded, size: 18,
                      color: enabled ? Colors.white : AppColors.textTertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Itemize communal space', style: Theme.of(context).textTheme.titleMedium),
                      Text('Assign each room\'s access in the room editor',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                    ]),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: state.setCommunalEnabled,
                    activeColor: AppColors.primary,
                  ),
                ]),
              ),
            ),
            // Expanded content when enabled
            if (enabled) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextFormField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total apartment sqft',
                      hintText: 'e.g. 1200',
                      suffixText: 'sqft',
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      state.setTotalAptSqft(parsed ?? 0);
                    },
                  ),
                  if (communal > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${communal.toInt()} sqft shared space. If access isn\'t equal, adjust roommate access in the room editor.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ),
                      ]),
                    ),
                  ] else if (state.totalAptSqft > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Total sqft must be greater than the sum of all rooms.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12, color: AppColors.error),
                    ),
                  ],
                ]),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 35.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─── Swipe-to-delete wrapper ──────────────────────────────────────────────────

class _SwipeDeleteWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool enabled;
  const _SwipeDeleteWrapper({
    required this.child,
    required this.onDelete,
    this.enabled = true,
  });

  @override
  State<_SwipeDeleteWrapper> createState() => _SwipeDeleteWrapperState();
}

class _SwipeDeleteWrapperState extends State<_SwipeDeleteWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  double _offsetX = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (mounted) setState(() => _offsetX = _anim.value);
      });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) => _anim.stop();

  void _onDragUpdate(DragUpdateDetails d) {
    if (!widget.enabled) return;
    setState(() => _offsetX = (_offsetX + d.delta.dx).clamp(-400.0, 12.0));
  }

  void _onDragEnd(DragEndDetails d) async {
    if (!widget.enabled) return;
    final width = MediaQuery.of(context).size.width;
    final pastThreshold = -_offsetX > width * 0.35;
    final fastFling = d.velocity.pixelsPerSecond.dx < -700;

    if (pastThreshold || fastFling) {
      HapticFeedback.mediumImpact();
      _anim.animateTo(
        -(width + 60),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeIn,
      ).then((_) => widget.onDelete());
    } else {
      final sim = SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 380, damping: 32),
        _offsetX,
        0.0,
        d.velocity.pixelsPerSecond.dx,
      );
      _anim.animateWith(sim);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final progress = (-_offsetX / width).clamp(0.0, 1.0);
    final rotation = -progress * 0.055;
    final scale = 1.0 - progress * 0.028;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: widget.enabled ? _onDragStart : null,
      onHorizontalDragUpdate: widget.enabled ? _onDragUpdate : null,
      onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
      child: Stack(clipBehavior: Clip.none, children: [
        // ── Gradient delete background ─────────────────────────────────────
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    AppColors.error.withValues(alpha: (progress * 0.55).clamp(0.0, 0.55)),
                    AppColors.error.withValues(alpha: (progress * 1.0).clamp(0.0, 1.0)),
                  ],
                  stops: [
                    (0.45 - progress * 0.2).clamp(0.0, 1.0),
                    (0.72 - progress * 0.1).clamp(0.0, 1.0),
                    1.0,
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 22),
                  child: Opacity(
                    opacity: (progress * 2.2).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: (progress * 1.6).clamp(0.0, 1.0),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                          SizedBox(height: 3),
                          Text('Remove',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Card with Tinder-style transform ──────────────────────────────
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(_offsetX, 0.0)
            ..rotateZ(rotation)
            ..scale(scale),
          child: widget.child,
        ),
      ]),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final Room room;
  final Color color;
  final int index;
  final VoidCallback onEdit;
  const _RoomTile({super.key, required this.room, required this.color, required this.index, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit, borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(room.tenant.isNotEmpty ? room.tenant[0].toUpperCase() : '?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(room.tenant, style: Theme.of(context).textTheme.titleMedium),
                Row(children: [
                  Text(room.name, style: Theme.of(context).textTheme.bodyMedium),
                  const Text(' · '),
                  Text('${room.sqft.toInt()} sqft', style: Theme.of(context).textTheme.bodyMedium),
                  if (room.hasPrivateBath) ...[const Text(' · '), const Icon(Icons.bathtub_rounded, size: 12, color: AppColors.textTertiary)],
                ]),
              ])),
            ]),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
      begin: const Offset(0.94, 0.94),
      end: const Offset(1.0, 1.0),
      duration: 380.ms,
      curve: Curves.elasticOut,
    );
  }
}
