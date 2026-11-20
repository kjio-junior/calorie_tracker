import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../data/ai_service.dart';
import '../../state/ai_coach_controller.dart';
import '../../state/connectivity_controller.dart';

class AiCard extends StatefulWidget {
  const AiCard({super.key});

  @override
  State<AiCard> createState() => _AiCardState();
}

class _AiCardState extends State<AiCard> {
  final _key = TextEditingController();
  late final TextEditingController _model;
  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final ai = context.read<AiCoachController>();
    _model = TextEditingController(text: ai.modelFor(ai.provider));
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _selectProvider(AiProvider p) async {
    final ai = context.read<AiCoachController>();
    await ai.setProvider(p);
    _key.clear();
    _model.text = ai.modelFor(p);
  }

  Future<void> _save() async {
    final ai = context.read<AiCoachController>();
    final p = ai.provider;
    setState(() => _busy = true);
    try {
      if (_key.text.trim().isNotEmpty) {
        await ai.saveKey(p, _key.text);
        _key.clear();
      }
      await ai.setModel(p, _model.text);
      _model.text = ai.modelFor(p);
      _snack('Saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final ai = context.read<AiCoachController>();
    setState(() => _busy = true);
    try {
      await _save();
      final err = await ai.testConnection();
      _snack(err ?? 'Connected. The AI answered.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiCoachController>();
    final online = context.watch<ConnectivityController>().isOnline;
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final p = ai.provider;
    final keyUrl = p == AiProvider.gemini
        ? 'aistudio.google.com/app/apikey'
        : 'console.groq.com/keys';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI coach',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!online) const OfflineBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Uses a free API key you create yourself. The key is stored in '
            'secure storage on this phone only.',
            style: text.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final provider in AiProvider.values)
                ChoiceChip(
                  label: Text(provider.label),
                  selected: p == provider,
                  onSelected: (_) => _selectProvider(provider),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Get a free key at $keyUrl',
            style: text.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _key,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: ai.hasKey(p)
                  ? '${p.label} key saved. Paste a new one to replace it'
                  : 'Paste your ${p.label} API key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show' : 'Hide',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Model',
              helperText:
                  'Default: ${p.defaultModel}. Change it if the provider '
                  'retires this model.',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: (_busy || !online || !ai.hasKey(p) && _key.text.trim().isEmpty)
                      ? null
                      : _test,
                  child: const Text('Test'),
                ),
              ),
              if (ai.hasKey(p)) ...[
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Remove saved key',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _busy ? null : () => ai.removeKey(p),
                ),
              ],
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 10),
          Text(
            'When you tap Generate on the dashboard, today\'s totals, weight '
            'trend and activity are sent to ${p.label}. Your name, age and '
            'sex are never sent. AI food logging sends only the food '
            'description and weight you type.',
            style: text.labelSmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
