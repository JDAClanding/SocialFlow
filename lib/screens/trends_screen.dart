library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class TrendsScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const TrendsScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final s = AppState.instance;
  final hookCtrl = TextEditingController();
  bool scanning = false;
  String? scanError;

  // Scan results survive leaving and re-entering the step (per product).
  static Map<String, List<Map<String, String>>> _cache = {};
  static String _cacheFor = '';
  Map<String, List<Map<String, String>>> get results =>
      _cacheFor == s.brand.product ? _cache : const {};

  static const catLabel = {
    'trends': '🔥 Trends',
    'memes': '😂 Memes & culture',
    'ugc': '🤳 UGC formats',
  };

  @override
  void dispose() {
    hookCtrl.dispose();
    super.dispose();
  }

  String trendKey(String cat, Map<String, String> it) => '$cat|${it['title']}';

  void toggleHook(String h) => setState(() {
        if (!s.hooks.remove(h)) s.hooks.add(h);
        s.save();
      });

  void toggleTrend(String key) => setState(() {
        if (!s.trends.remove(key)) s.trends.add(key);
        s.save();
      });

  void setAllTrends(String cat, List<Map<String, String>> items, bool on) =>
      setState(() {
        for (final it in items) {
          final k = trendKey(cat, it);
          if (on && !s.trends.contains(k)) s.trends.add(k);
          if (!on) s.trends.remove(k);
        }
        s.save();
      });

  void setAllHooks(List<String> hooks, bool on) => setState(() {
        for (final h in hooks) {
          if (on && !s.hooks.contains(h)) s.hooks.add(h);
          if (!on) s.hooks.remove(h);
        }
        s.save();
      });

  void addCustomHook() {
    final h = hookCtrl.text.trim();
    if (h.isEmpty) return toast(context, 'Type a hook first');
    if (s.hooks.contains(h)) return toast(context, 'Already in your hooks');
    setState(() {
      s.hooks.add(h);
      hookCtrl.clear();
      s.save();
    });
  }

  Future<void> scan() async {
    setState(() {
      scanning = true;
      scanError = null;
    });
    final base = s.brand.product.isEmpty ? 'food' : '${s.brand.product} brand';
    final d = await Api.suggest(base, ['trends', 'memes', 'ugc']);
    if (!mounted) return;
    setState(() => scanning = false);
    if (d['error'] != null) {
      setState(() => scanError = d['error'].toString());
      return;
    }
    final cats = <String, List<Map<String, String>>>{};
    (d['categories'] as Map?)?.forEach((k, v) {
      cats[k.toString()] = (v as List)
          .map((e) => {
                'title': (e['title'] ?? '').toString(),
                'snippet': (e['snippet'] ?? '').toString(),
                'url': (e['url'] ?? '').toString(),
              })
          .where((e) => e['title']!.isNotEmpty)
          .toList();
    });
    setState(() {
      _cache = cats;
      _cacheFor = s.brand.product;
    });
  }

  Widget _heading(String text, {Widget? trailing}) => Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
          ),
          if (trailing != null) trailing,
        ],
      );

  Widget _textLink(String label, VoidCallback onTap,
          {Color color = C.accent}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hooks = hooksFor(s.brand.product);
    final customHooks = s.hooks.where((h) => !hooks.contains(h)).toList();
    final product = s.brand.product.isEmpty ? 'your category' : s.brand.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 4 · TRENDS & HOOKS',
          title: 'What\'s working right now',
          lead: 'Pulled live from the web for $product'
              '${s.competitors.isNotEmpty ? ' and your competitors' : ''} — categorized. '
              'Tap trends and hooks to add them to your playbook.',
        ),
        _summaryBar(),
        SplitView(
          left: [_trendsCard()],
          right: [
            _hooksCard(hooks, customHooks, product),
            if (s.trends.isNotEmpty || s.hooks.isNotEmpty) _playbook(),
          ],
        ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }

  Widget _trendsCard() => SfCard(
        glow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('⚡ Live trends'),
            const SizedBox(height: 8),
            Row(
              children: [
                SfButton(results.isEmpty ? 'Scan now' : '↻ Rescan',
                    onPressed: scanning ? null : scan),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                      'Searches TikTok/IG trends, memes & UGC formats for your category',
                      style: TextStyle(fontSize: 12, color: C.soft)),
                ),
              ],
            ),
            if (scanning)
              const Thinking('Scanning live trends for your category…'),
            if (scanError != null) ErrText(scanError!),
            for (final cat in results.entries)
              if (cat.value.isNotEmpty) ..._trendGroup(cat.key, cat.value),
          ],
        ),
      );

  Widget _hooksCard(
          List<String> hooks, List<String> customHooks, String product) =>
      SfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading(
              '🎣 Hook bank — tap your favorites',
              trailing: _textLink(
                  hooks.every(s.hooks.contains) ? 'Clear' : 'Select all',
                  () => setAllHooks(hooks, !hooks.every(s.hooks.contains))),
            ),
            const SizedBox(height: 4),
            Text(
                'Opening lines for the first 2 seconds, picked for $product. Selected hooks rotate into your calendar captions.',
                style: const TextStyle(fontSize: 12, color: C.soft)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in [...hooks, ...customHooks]) _hookChip(h),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hookCtrl,
                    decoration: sfInput(
                        'Write your own hook, e.g. “Wait for the pour…”'),
                    onSubmitted: (_) => addCustomHook(),
                  ),
                ),
                const SizedBox(width: 8),
                SfButton('+ Add', alt: true, onPressed: addCustomHook),
              ],
            ),
          ],
        ),
      );

  Widget _summaryBar() {
    final t = s.trends.length, h = s.hooks.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: C.cream, borderRadius: BorderRadius.circular(13)),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
              '📌 Playbook:  $t trend${t == 1 ? '' : 's'}  ·  $h hook${h == 1 ? '' : 's'} selected',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
          if (t == 0 && h == 0)
            const Text('Pick at least a few hooks — they power your captions.',
                style: TextStyle(fontSize: 12, color: C.soft)),
        ],
      ),
    );
  }

  List<Widget> _trendGroup(String cat, List<Map<String, String>> items) {
    final picked =
        items.where((it) => s.trends.contains(trendKey(cat, it))).length;
    final all = picked == items.length;
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Text(
                '${catLabel[cat] ?? cat}${picked > 0 ? '  ·  $picked selected' : ''}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
          ),
          _textLink(all ? 'Clear' : 'Select all',
              () => setAllTrends(cat, items, !all)),
        ],
      ),
      const SizedBox(height: 6),
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Stack(
            children: [
              SelCard(
                title: it['title']!,
                snippet: it['snippet']!,
                selected: s.trends.contains(trendKey(cat, it)),
                onTap: () => toggleTrend(trendKey(cat, it)),
              ),
              if (it['url']!.isNotEmpty)
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: _textLink(
                      'source ↗', () => launchUrl(Uri.parse(it['url']!))),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _hookChip(String h) {
    final on = s.hooks.contains(h);
    return InkWell(
      onTap: () => toggleHook(h),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? C.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? C.brand : C.line, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? Icons.check : Icons.add,
                size: 14, color: on ? Colors.white : C.accent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(h,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : C.brand)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playbook() {
    Widget row(
            String title, String tag, Color tagColor, VoidCallback onRemove) =>
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          decoration: BoxDecoration(
              color: C.cream, borderRadius: BorderRadius.circular(11)),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
              ),
              Pill(tag, color: tagColor),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16, color: C.rose),
                onPressed: onRemove,
              ),
            ],
          ),
        );

    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            '📌 Your playbook (${s.trends.length + s.hooks.length})',
            trailing: _textLink(
                'Clear all',
                () => setState(() {
                      s.trends.clear();
                      s.hooks.clear();
                      s.save();
                    }),
                color: C.rose),
          ),
          if (s.hooks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Hooks (${s.hooks.length})',
                style: const TextStyle(
                    fontSize: 12, color: C.soft, fontWeight: FontWeight.w700)),
            for (final h in List.of(s.hooks))
              row(h, 'hook', C.gold, () => toggleHook(h)),
          ],
          if (s.trends.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Trends (${s.trends.length})',
                style: const TextStyle(
                    fontSize: 12, color: C.soft, fontWeight: FontWeight.w700)),
            for (final t in List.of(s.trends))
              row(
                t.contains('|') ? t.substring(t.indexOf('|') + 1) : t,
                catLabel[t.split('|').first]?.substring(2).trim() ??
                    t.split('|').first,
                C.blue,
                () => toggleTrend(t),
              ),
          ],
        ],
      ),
    );
  }
}
