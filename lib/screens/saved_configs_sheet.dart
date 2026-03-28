import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class SavedConfigsSheet extends StatefulWidget {
  const SavedConfigsSheet({super.key});
  @override
  State<SavedConfigsSheet> createState() => _SavedConfigsSheetState();
}

class _SavedConfigsSheetState extends State<SavedConfigsSheet> {
  final _nameCtrl = TextEditingController();
  bool _nameInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill config name with address on first open; don't override user edits.
    if (!_nameInitialized) {
      _nameInitialized = true;
      final address = context.read<AppState>().address;
      if (address.isNotEmpty) _nameCtrl.text = address;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _save(AppState state) {
    if (!state.iapConfigsUnlocked) { _showPaywall(state); return; }
    if (state.savedConfigs.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 10 saved configs')));
      return;
    }
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : 'Config ${state.savedConfigs.length + 1}';
    state.saveCurrentConfig(name);
    _nameCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" saved!')));
  }

  void _load(AppState state, String id, String name) {
    state.loadConfig(id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded "$name"')));
  }

  void _delete(AppState state, String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete config?'),
      content: Text('Remove "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { state.deleteConfig(id); Navigator.pop(ctx); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(80, 40)),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showPaywall(AppState state) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.bookmark_rounded, size: 18, color: AppColors.accent)),
        const SizedBox(width: 12),
        const Expanded(child: Text('Unlock Saved Configs')),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Save up to 10 room configurations and switch between them instantly.'),
        const SizedBox(height: 12),
        ...[
          'Save for different apartments you\'re considering',
          'Compare "Room A gets master" vs "Room B gets master"',
          'Load any setup in one tap',
        ].map((f) => Padding(padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
          ]))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Maybe later')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); _simulatePurchase(state); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, minimumSize: const Size(120, 40)),
          child: const Text('Unlock \$1.99'),
        ),
      ],
    ));
  }

  void _simulatePurchase(AppState state) {
    state.iapService.purchaseSavedConfigs();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening store…')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final configs = state.savedConfigs;
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Let the sheet size itself; scroll handles overflow
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderMed, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),

              // Header
              Row(children: [
                const Icon(Icons.bookmark_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Text('Saved Configurations', style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 4),
              Text('Save and switch between different room setups.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),

              // Save row
              Row(children: [
                Expanded(child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: state.iapConfigsUnlocked ? 'Name this config...' : 'Unlock to save configs',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  enabled: state.iapConfigsUnlocked,
                )),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _save(state),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor: state.iapConfigsUnlocked ? AppColors.primary : AppColors.accent,
                  ),
                  child: Text(state.iapConfigsUnlocked ? 'Save' : '\$1.99'),
                ),
              ]),

              // Configs list or empty state
              if (configs.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: configs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = configs[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
                        ),
                        title: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text('${c.rooms.length} rooms · \$${c.totalRent.toStringAsFixed(0)}/mo', style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          TextButton(onPressed: () => _load(state, c.id, c.name), child: const Text('Load')),
                          IconButton(onPressed: () => _delete(state, c.id, c.name), icon: Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.error)),
                        ]),
                      ).animate().fadeIn(duration: 200.ms, delay: (i * 40).ms);
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 28),
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Clean icon illustration — no image dependency
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      const Icon(Icons.folder_open_rounded, size: 44, color: AppColors.primary),
                      Positioned(
                        right: 12, top: 12,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOut),
                  const SizedBox(height: 12),
                  Text('No saved configs yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                  ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Save your current setup to quickly reload it later.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 300.ms, delay: 180.ms),
                ])),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),
      );
    });
  }
}
      