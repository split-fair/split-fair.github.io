import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_state.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

const _kOnboardingDone = 'onboarding_done_v1';

// Stitch design system colors
const _stitchGreen = Color(0xFF00694C);
const _stitchCream = Color(0xFFFAF7F2);
const _stitchAmber = Color(0xFF855400);

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _SlideData {
  final String heroImage;
  final String? categoryLabel;
  final IconData icon;
  final String headline;
  final String body;
  const _SlideData({
    required this.heroImage,
    this.categoryLabel,
    required this.icon,
    required this.headline,
    required this.body,
  });
}

const _slides = [
  // 0 — Welcome (static)
  _SlideData(
    heroImage: 'assets/images/hero_chad_split.jpg',
    categoryLabel: 'WELCOME',
    icon: Icons.balance_rounded,
    headline: 'Welcome to Split Fair',
    body: 'Finally, an app that settles the age-old question:\n"Why is Chad paying the same rent as me when his room has a window AND a closet?"\n\nSpoiler: he shouldn\'t be.',
  ),
  // 1 — Size Matters (interactive: rent, sqft, address)
  _SlideData(
    heroImage: 'assets/images/hero_tape_measure.jpg',
    categoryLabel: 'DIMENSIONS',
    icon: Icons.square_foot_rounded,
    headline: 'Size Matters',
    body: 'Tell us about the place you\'re splitting.',
  ),
  // 2 — How Many Rooms (interactive)
  _SlideData(
    heroImage: 'assets/images/hero_hallway.jpg',
    categoryLabel: 'CAPACITY',
    icon: Icons.bedroom_parent_rounded,
    headline: 'How Many Rooms?',
    body: 'Bedrooms only — we\'re splitting rent, not staging Cribs.',
  ),
  // 3 — Shared Spaces (interactive)
  _SlideData(
    heroImage: 'assets/images/hero_kitchen.jpg',
    categoryLabel: 'COMMON AREAS',
    icon: Icons.people_rounded,
    headline: 'Shared Spaces',
    body: 'Does everyone have equal access to the living room, kitchen, and common areas?',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _totalRentCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _totalSqftCtrl = TextEditingController();
  int _numRooms = 2;
  final List<TextEditingController> _roomSqftCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _communalEqual = true;
  List<double> _communalPcts = [50.0, 50.0];

  void _setNumRooms(int n) {
    setState(() {
      _numRooms = n;
      while (_roomSqftCtrls.length < n) _roomSqftCtrls.add(TextEditingController());
      while (_roomSqftCtrls.length > n) _roomSqftCtrls.removeLast().dispose();
      _communalPcts = List.generate(n, (_) => 100.0 / n);
    });
  }

  void _setCommunalPct(int roomIndex, double value) {
    setState(() {
      _communalPcts[roomIndex] = value;
      final remaining = (100.0 - value).clamp(0.0, 100.0);
      final others = _numRooms - 1;
      for (var i = 0; i < _numRooms; i++) {
        if (i != roomIndex) _communalPcts[i] = others > 0 ? remaining / others : 0;
      }
    });
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _skip() async {
    await markOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (!mounted) return;
    final state = context.read<AppState>();

    final rent = double.tryParse(_totalRentCtrl.text.replaceAll(',', '')) ?? 0;
    if (rent > 0) state.setTotalRent(rent);

    final addr = _addressCtrl.text.trim();
    if (addr.isNotEmpty) state.setAddress(addr);

    final sqft = double.tryParse(_totalSqftCtrl.text) ?? 0;
    if (sqft > 0) state.setTotalAptSqft(sqft);

    final uuid = const Uuid();
    final roomSqfts = _roomSqftCtrls.map((c) => double.tryParse(c.text) ?? 0).toList();
    final newRooms = List.generate(_numRooms, (i) {
      final s = i < roomSqfts.length ? roomSqfts[i] : 0.0;
      return Room(
        id: uuid.v4(),
        name: 'Room ${i + 1}',
        tenant: 'Roommate ${i + 1}',
        sqft: s > 0 ? s : 150,
      );
    });
    for (var i = 0; i < newRooms.length; i++) {
      if (i < state.rooms.length) {
        state.updateRoom(state.rooms[i].id, newRooms[i]);
      } else {
        state.addRoom();
        state.updateRoom(state.rooms.last.id, newRooms[i]);
      }
    }
    while (state.rooms.length > _numRooms && state.rooms.length > 2) {
      state.removeRoom(state.rooms.last.id);
    }

    if (!_communalEqual) {
      final idToSharePct = <String, double>{};
      for (var i = 0; i < state.rooms.length && i < _communalPcts.length; i++) {
        idToSharePct[state.rooms[i].id] = _communalPcts[i];
      }
      state.updateAllCommunalShares(idToSharePct);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _totalRentCtrl.dispose();
    _addressCtrl.dispose();
    _totalSqftCtrl.dispose();
    for (final c in _roomSqftCtrls) c.dispose();
    super.dispose();
  }

  // ── Build interactive content for each slide ──────────────────────────────

  Widget? _buildInteractiveContent(int index) {
    switch (index) {
      case 1: // Size Matters
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL MONTHLY RENT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: _stitchAmber)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _stitchCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _stitchGreen, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text('\$', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _stitchGreen)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _totalRentCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [],
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: const InputDecoration.collapsed(
                        hintText: '2,500',
                        hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppColors.border),
                      ),
                    ),
                  ),
                  const Text('/mo', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL SIZE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: _stitchAmber)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _totalSqftCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        autofillHints: const [],
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '1,200 sqft',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _stitchGreen, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: _stitchAmber)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressCtrl,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [],
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Apt 4B',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _stitchGreen, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );

      case 2: // How Many Rooms
        return Column(
          children: [
            Text(
              "Don't count the \"flex space\" your landlord called a bedroom.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleButton(
                  icon: Icons.remove,
                  onTap: _numRooms > 2 ? () => _setNumRooms(_numRooms - 1) : null,
                ),
                const SizedBox(width: 32),
                Text(
                  '$_numRooms',
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: _stitchGreen),
                ),
                const SizedBox(width: 32),
                _CircleButton(
                  icon: Icons.add,
                  onTap: _numRooms < 8 ? () => _setNumRooms(_numRooms + 1) : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );

      case 3: // Shared Spaces
        return Column(
          children: [
            _ChoiceChip(
              label: 'Yes — split equally',
              icon: Icons.check_circle_rounded,
              selected: _communalEqual,
              onTap: () => setState(() => _communalEqual = true),
            ),
            const SizedBox(height: 10),
            _ChoiceChip(
              label: "No — I'll customize per room",
              icon: Icons.tune_rounded,
              selected: !_communalEqual,
              onTap: () => setState(() => _communalEqual = false),
            ),
            if (!_communalEqual) ...[
              const SizedBox(height: 16),
              ...List.generate(_numRooms, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Room ${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${_communalPcts[i].round()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _stitchGreen)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: _stitchGreen,
                        thumbColor: _stitchGreen,
                        inactiveTrackColor: AppColors.border,
                      ),
                      child: Slider(
                        value: _communalPcts[i].clamp(0.0, 100.0),
                        min: 0, max: 100, divisions: 20,
                        onChanged: (v) => _setCommunalPct(i, v),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 16),
          ],
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: _stitchCream,
      resizeToAvoidBottomInset: true,
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _page = i),
        itemCount: _slides.length,
        itemBuilder: (_, index) {
          final slide = _slides[index];
          final isActive = index == _page;
          final interactiveContent = _buildInteractiveContent(index);
          // Static slides (welcome) show more photo
          final hasInteraction = interactiveContent != null;

          return _StitchSlide(
            data: slide,
            isActive: isActive,
            interactiveContent: interactiveContent,
            onSkip: _skip,
            onNext: _next,
            isLast: isLast,
            currentPage: _page,
            totalPages: _slides.length,
            initialCardSize: hasInteraction ? 0.52 : 0.38,
          );
        },
      ),
    );
  }
}

// ── Stitch-style slide: hero photo + draggable white card ────────────────────

class _StitchSlide extends StatelessWidget {
  final _SlideData data;
  final bool isActive;
  final Widget? interactiveContent;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool isLast;
  final int currentPage;
  final int totalPages;
  final double initialCardSize;

  const _StitchSlide({
    required this.data,
    required this.isActive,
    this.interactiveContent,
    required this.onSkip,
    required this.onNext,
    required this.isLast,
    required this.currentPage,
    required this.totalPages,
    this.initialCardSize = 0.52,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── Hero photo — fills entire background ──────────────────────
        Positioned.fill(
          child: Image.asset(
            data.heroImage,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // ── Skip button ───────────────────────────────────────────────
        Positioned(
          top: topPad + 8,
          right: 16,
          child: GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ),

        // ── Category label ────────────────────────────────────────────
        if (data.categoryLabel != null)
          Positioned(
            top: topPad + 12,
            left: 0, right: 60,
            child: Center(
              child: Text(
                data.categoryLabel!,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),

        // ── Scrollable white card from bottom ─────────────────────────
        DraggableScrollableSheet(
          initialChildSize: initialCardSize,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Icon badge
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _stitchGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, size: 24, color: _stitchGreen),
                  )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms),

                  const SizedBox(height: 12),

                  // Headline
                  Text(
                    data.headline,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
                  )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(duration: 350.ms, delay: 50.ms),

                  const SizedBox(height: 8),

                  // Body
                  Text(
                    data.body,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(duration: 400.ms, delay: 100.ms),

                  // Interactive content
                  if (interactiveContent != null) ...[
                    const SizedBox(height: 16),
                    interactiveContent!,
                  ],

                  const SizedBox(height: 24),

                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages, (i) {
                      final active = i == currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? _stitchGreen : const Color(0xFFD5D0C8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Next button (inside the scrollable card)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _stitchGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? "Let's settle this" : 'Next',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? _stitchCream : AppColors.border.withValues(alpha: 0.3),
          border: Border.all(color: enabled ? AppColors.border : AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 22, color: enabled ? AppColors.textPrimary : AppColors.border),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _stitchGreen.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _stitchGreen : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? _stitchGreen : AppColors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
            style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? _stitchGreen : AppColors.textPrimary))),
          if (selected) const Icon(Icons.check_rounded, color: _stitchGreen, size: 18),
        ]),
      ),
    );
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      