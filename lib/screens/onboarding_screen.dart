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

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ─── Slide content ───────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final List<_DecorItem> decor;
  final String headline;
  final String body;
  final Color accent;
  final _ImageAnim anim;
  const _Slide({
    required this.icon,
    required this.headline,
    required this.body,
    required this.accent,
    this.decor = const [],
    this.anim = _ImageAnim.float,
  });
}

class _DecorItem {
  final IconData icon;
  final double size;
  final double dx; // -1.0 to 1.0 relative to center
  final double dy;
  final double opacity;
  const _DecorItem({required this.icon, required this.size, required this.dx, required this.dy, this.opacity = 0.55});
}

enum _ImageAnim { float, pulse, tilt, drift }

const _slides = [
  _Slide(
    icon: Icons.balance_rounded,
    decor: [
      _DecorItem(icon: Icons.home_rounded, size: 18, dx: -0.85, dy: -0.70, opacity: 0.45),
      _DecorItem(icon: Icons.people_rounded, size: 16, dx: 0.80, dy: -0.65, opacity: 0.40),
      _DecorItem(icon: Icons.check_circle_rounded, size: 14, dx: 0.75, dy: 0.72, opacity: 0.35),
    ],
    headline: 'Welcome to Split Fair',
    body: 'Finally, an app that settles the age-old question:\n"Why is Chad paying the same rent as me when his room has a window AND a closet?"\n\nSpoiler: he shouldn\'t be.',
    accent: AppColors.primary,
    anim: _ImageAnim.pulse,
  ),
  _Slide(
    icon: Icons.square_foot_rounded,
    decor: [
      _DecorItem(icon: Icons.straighten_rounded, size: 16, dx: -0.80, dy: -0.68, opacity: 0.45),
      _DecorItem(icon: Icons.calculate_rounded, size: 18, dx: 0.82, dy: -0.60, opacity: 0.40),
      _DecorItem(icon: Icons.bar_chart_rounded, size: 14, dx: -0.70, dy: 0.75, opacity: 0.35),
    ],
    headline: 'Size Matters',
    body: 'Enter each room\'s square footage and we do the math.\n\nThe person with 80 extra square feet of personal kingdom doesn\'t get to split 50/50. That\'s not splitting fairly — that\'s just splitting in Chad\'s favor.',
    accent: Color(0xFF378ADD),
    anim: _ImageAnim.drift,
  ),
  _Slide(
    icon: Icons.wb_sunny_rounded,
    decor: [
      _DecorItem(icon: Icons.bathtub_rounded, size: 17, dx: -0.82, dy: -0.65, opacity: 0.45),
      _DecorItem(icon: Icons.local_parking_rounded, size: 16, dx: 0.80, dy: -0.62, opacity: 0.40),
      _DecorItem(icon: Icons.deck_rounded, size: 14, dx: 0.72, dy: 0.70, opacity: 0.35),
    ],
    headline: 'Natural Light Tax',
    body: 'Got a room with floor-to-ceiling windows?\n\nSlide that natural light score up. The person living next to the boiler in a windowless cube deserves a discount. It\'s only fair.',
    accent: AppColors.accent,
    anim: _ImageAnim.tilt,
  ),
  _Slide(
    icon: Icons.bookmark_added_rounded,
    decor: [
      _DecorItem(icon: Icons.save_rounded, size: 16, dx: -0.80, dy: -0.68, opacity: 0.45),
      _DecorItem(icon: Icons.people_alt_rounded, size: 18, dx: 0.80, dy: -0.60, opacity: 0.40),
      _DecorItem(icon: Icons.sync_rounded, size: 14, dx: -0.68, dy: 0.72, opacity: 0.35),
    ],
    headline: 'Save Your Configs',
    body: 'Moving in with new roommates? Save your setup.\n\nBecause Tyler is joining in March, Priya is leaving in June, and you are NOT doing this math by hand again. Future you will thank present you.',
    accent: Color(0xFF7F77DD),
    anim: _ImageAnim.float,
  ),
  _Slide(
    icon: Icons.picture_as_pdf_rounded,
    decor: [
      _DecorItem(icon: Icons.gavel_rounded, size: 17, dx: -0.80, dy: -0.65, opacity: 0.45),
      _DecorItem(icon: Icons.thumb_up_rounded, size: 16, dx: 0.80, dy: -0.62, opacity: 0.40),
      _DecorItem(icon: Icons.emoji_events_rounded, size: 14, dx: 0.70, dy: 0.70, opacity: 0.35),
    ],
    headline: 'This Is Not Legal Advice',
    body: 'But it IS math. And math wins arguments.\n\nNext time someone says "just split it evenly," pull out a PDF with their name on it and a number that is not 50%.\n\nGood luck. You\'ve got this.',
    accent: AppColors.primary,
    anim: _ImageAnim.pulse,
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // ── Data collected during onboarding ──────────────────────────────────────
  final _totalRentCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _totalSqftCtrl = TextEditingController();
  int _numRooms = 2;
  final List<TextEditingController> _roomSqftCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _communalEqual = true;
  List<double> _communalPcts = [50.0, 50.0]; // per-room communal share %

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

  Future<void> _finish() async {
    await markOnboardingDone();
    if (!mounted) return;
    final state = context.read<AppState>();

    // Save rent if entered
    final rent = double.tryParse(_totalRentCtrl.text.replaceAll(',', '')) ?? 0;
    if (rent > 0) state.setTotalRent(rent);

    // Save address if entered
    final addr = _addressCtrl.text.trim();
    if (addr.isNotEmpty) state.setAddress(addr);

    // Save total sqft if entered
    final sqft = double.tryParse(_totalSqftCtrl.text) ?? 0;
    if (sqft > 0) state.setTotalAptSqft(sqft);

    // Always apply _numRooms regardless of whether sqft was entered
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
    // Update/add rooms to match _numRooms
    for (var i = 0; i < newRooms.length; i++) {
      if (i < state.rooms.length) {
        state.updateRoom(state.rooms[i].id, newRooms[i]);
      } else {
        state.addRoom();
        state.updateRoom(state.rooms.last.id, newRooms[i]);
      }
    }
    // Remove extra rooms if user chose fewer
    while (state.rooms.length > _numRooms && state.rooms.length > 2) {
      state.removeRoom(state.rooms.last.id);
    }

    // Apply custom communal shares if user opted in
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

  Widget _buildInteractiveSlide(int index) {
    switch (index) {
      case 1: // Rent + address + total sqft
        return _InteractiveSlidePage(
          icon: Icons.square_foot_rounded,
          iconColor: const Color(0xFF378ADD),
          headline: 'Size Matters',
          subhead: 'Tell us about the place you\'re splitting.',
          body: 'We\'ll use this to figure out how much is "shared" vs how much each person actually controls. That gap is where fair rent lives.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated label
              const Text('↓ Start here', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms)
                .then()
                .fadeOut(duration: 600.ms),
              const SizedBox(height: 6),
              // Total Rent — big & bold with pulsing glow
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text('\$', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _totalRentCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                        decoration: const InputDecoration(
                          hintText: '2,500',
                          hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: AppColors.border),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Text('/mo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.018, duration: 900.ms, curve: Curves.easeInOut),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Total monthly rent', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ),
              const SizedBox(height: 16),
              // Total Sqft
              TextFormField(
                controller: _totalSqftCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '1,200',
                  suffixText: 'sqft',
                  labelText: 'Total apartment size',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Address (optional)
              TextFormField(
                controller: _addressCtrl,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '123 Main St, Apt 4B',
                  labelText: 'Property address (optional)',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );

      case 2: // Num rooms
        return _InteractiveSlidePage(
          icon: Icons.bedroom_parent_rounded,
          iconColor: const Color(0xFF7F77DD),
          headline: 'How Many Rooms?',
          subhead: 'How many bedrooms are you splitting?',
          body: 'Bedrooms only — we\'re splitting rent, not staging Cribs.\n\nDon\'t count bathrooms, closets, or the "flex space" your landlord called a bedroom but is clearly a repurposed pantry.',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _numRooms > 2 ? () => _setNumRooms(_numRooms - 1) : null,
                icon: const Icon(Icons.remove_circle_rounded, size: 36),
                color: AppColors.primary,
                disabledColor: AppColors.border,
              ),
              const SizedBox(width: 24),
              Text(
                '$_numRooms',
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _numRooms < 8 ? () => _setNumRooms(_numRooms + 1) : null,
                icon: const Icon(Icons.add_circle_rounded, size: 36),
                color: AppColors.primary,
                disabledColor: AppColors.border,
              ),
            ],
          ),
        );

      case 3: // Room sqfts
        return _InteractiveSlidePage(
          icon: Icons.straighten_rounded,
          iconColor: AppColors.accent,
          headline: "Each Room's Size",
          subhead: 'Square footage of each bedroom (skip if unknown)',
          body: 'Got a tape measure? Now\'s the time.\n\nSkip any you\'re not sure about — you can fill them in later. Guessing is also fine. Chad\'s been guessing his whole life.',
          child: Column(
            children: [
              // "I don't know it" skip pill
              GestureDetector(
                onTap: _next,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textTertiary),
                      SizedBox(width: 8),
                      Text("I don't know it", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              ...List.generate(_numRooms, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _roomSqftCtrls[i],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Room ${i + 1}',
                    suffixText: 'sqft',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                ),
              )),
            ],
          ),
        );

      case 4: // Communal equal
        return _InteractiveSlidePage(
          icon: Icons.people_rounded,
          iconColor: AppColors.primary,
          headline: 'Shared Spaces',
          subhead: 'Does everyone have equal access to the living room, kitchen, and common areas?',
          body: 'If someone has claimed the kitchen or living room as their personal territory, that\'s worth factoring in.\n\nEqual access = everyone pays the same share of communal sqft.',
          child: Column(
            children: [
              _ChoiceButton(
                label: 'Yes — split equally',
                icon: Icons.check_circle_rounded,
                selected: _communalEqual,
                onTap: () => setState(() => _communalEqual = true),
              ),
              const SizedBox(height: 12),
              _ChoiceButton(
                label: "No — I'll customize per room",
                icon: Icons.tune_rounded,
                selected: !_communalEqual,
                onTap: () => setState(() => _communalEqual = false),
              ),
              if (!_communalEqual) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Drag to set each room\'s share of communal space:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...List.generate(_numRooms, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Room ${i + 1}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('${_communalPcts[i].round()}%',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                          activeTrackColor: AppColors.primary,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primaryLight,
                          inactiveTrackColor: AppColors.border,
                        ),
                        child: Slider(
                          value: _communalPcts[i].clamp(0.0, 100.0),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (v) => _setCommunalPct(i, v),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 4),
                Text(
                  'Other rooms adjust automatically to keep total at 100%',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        );

      default:
        return _SlidePage(slide: _slides[index], isActive: index == _page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip', style: TextStyle(color: AppColors.textTertiary, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, index) {
                  if (index == 0) return _SlidePage(slide: _slides[index], isActive: index == _page);
                  return _buildInteractiveSlide(index);
                },
              ),
            ),

            // Dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? slide.accent : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: slide.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: slide.accent.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _next,
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              isLast ? "Let's settle this" : 'Next',
                              key: ValueKey(isLast),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Interactive slide page ───────────────────────────────────────────────────

class _InteractiveSlidePage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String headline;
  final String subhead;
  final String? body;
  final Widget child;
  const _InteractiveSlidePage({
    required this.icon,
    required this.iconColor,
    required this.headline,
    required this.subhead,
    this.body,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: iconColor),
          ),
          const SizedBox(height: 28),
          Text(headline,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(subhead,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(body!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textTertiary, height: 1.6)),
          ],
          const SizedBox(height: 28),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Choice button (for communal slide) ──────────────────────────────────────

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.textTertiary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
            style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primaryDark : AppColors.textPrimary))),
          if (selected) const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

// ─── Individual slide page ────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final bool isActive;
  const _SlidePage({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Artwork ──────────────────────────────────────────────────────
          SizedBox(
            height: 220,
            child: _AnimatedIllustration(
              slide: slide,
              isActive: isActive,
            ),
          ),

          const SizedBox(height: 36),

          // ── Headline ─────────────────────────────────────────────────────
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 380.ms, delay: 100.ms)
              .slideY(begin: 0.12, end: 0, duration: 380.ms, delay: 100.ms),

          const SizedBox(height: 18),

          // ── Body ─────────────────────────────────────────────────────────
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 420.ms, delay: 180.ms)
              .slideY(begin: 0.10, end: 0, duration: 420.ms, delay: 180.ms),
        ],
      ),
    );
  }
}

// ─── Professional icon illustration with animation ───────────────────────────

class _AnimatedIllustration extends StatefulWidget {
  final _Slide slide;
  final bool isActive;
  const _AnimatedIllustration({required this.slide, required this.isActive});

  @override
  State<_AnimatedIllustration> createState() => _AnimatedIllustrationState();
}

class _AnimatedIllustrationState extends State<_AnimatedIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loopCtrl;
  late final Animation<double> _loopAnim;

  @override
  void initState() {
    super.initState();
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _loopAnim = CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.slide.accent;

    // Build illustration: concentric circles + main icon + floating decor icons
    Widget illustration = SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withOpacity(0.10), accent.withOpacity(0.0)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          // Mid ring
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.08),
              border: Border.all(color: accent.withOpacity(0.14), width: 1.5),
            ),
          ),
          // Inner filled circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.13),
            ),
          ),
          // Main icon
          Icon(widget.slide.icon, size: 48, color: accent),

          // Floating decorative icons
          ...widget.slide.decor.map((d) {
            return Positioned.fill(
              child: Align(
                alignment: Alignment(d.dx, d.dy),
                child: Container(
                  width: d.size + 14,
                  height: d.size + 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.10),
                    border: Border.all(color: accent.withOpacity(0.18), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(d.icon, size: d.size, color: accent.withOpacity(d.opacity)),
                ),
              ),
            );
          }),
        ],
      ),
    );

    // Continuous loop animation
    Widget looped = AnimatedBuilder(
      animation: _loopAnim,
      builder: (_, child) {
        switch (widget.slide.anim) {
          case _ImageAnim.float:
            return Transform.translate(
              offset: Offset(0, -10 * _loopAnim.value),
              child: child,
            );
          case _ImageAnim.pulse:
            final scale = 1.0 + 0.04 * _loopAnim.value;
            return Transform.scale(scale: scale, child: child);
          case _ImageAnim.tilt:
            final angle = 0.04 * (_loopAnim.value - 0.5);
            return Transform.rotate(angle: angle, child: child);
          case _ImageAnim.drift:
            return Transform.translate(
              offset: Offset(6 * (_loopAnim.value - 0.5), -8 * _loopAnim.value),
              child: child,
            );
        }
      },
      child: illustration,
    );

    // Entrance animation when slide becomes active
    return looped
        .animate(target: widget.isActive ? 1 : 0)
        .fadeIn(duration: 450.ms)
        .scale(
          begin: const Offset(0.82, 0.82),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .slideY(begin: 0.08, end: 0, duration: 400.ms);
  }
}
