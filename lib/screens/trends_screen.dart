library;

import 'package:flutter/material.dart';

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
  bool scanning = false;
  String? scanError;
  Map<String, List<Map<String, String>>> results = {};

  static const catLabel = {
    'trends': '🔥 Trends',
    'memes': '😂 Memes & culture',
    'ugc': '🤳 UGC formats',
  };

  void toggleHook(String h) => setState(() {
        if (!s.hooks.remove(h)) s.hooks.add(h);
        s.save();
      });

  void toggleTrend(String key) => setState(() {
        if (!s.trends.remove(key)) s.trends.add(key);
        s.save();
      });

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
          .toList();
    });
    setState(() => results = cats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 4 · TRENDS & HOOKS',
          title: 'What\'s working right now',
          lead:
              'Pulled live from the web for ${s.brand.product.isEmpty ? 'your category' : s.brand.product}'
              '${s.competitors.isNotEmpty ? ' and your competitors' : ''} — categorized. Tap to add to your playbook.',
        ),
        SfCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚡ Scan live trends',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 8),
              Row(
                children: [
                  SfButton('Scan now', onPressed: scanning ? null : scan),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Searches TikTok/IG trends, memes & UGC formats for your category',
                        style: TextStyle(fontSize: 12, color: C.soft)),
                  ),
                ],
              ),
              if (scanning) const Thinking('Scanning live trends for your category…'),
              if (scanError != null) ErrText(scanError!),
              for (final cat in results.entries) ...[
                if (cat.value.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(catLabel[cat.key] ?? cat.key,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
                  const SizedBox(height: 6),
                  for (final it in cat.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelCard(
                        title: it['title']!.length > 70
                            ? '${it['title']!.substring(0, 70)}…'
                            : it['title']!,
                        snippet: it['snippet']!.length > 110
                            ? '${it['snippet']!.substring(0, 110)}…'
                            : it['snippet']!,
                        selected: s.trends.any((t) => t.startsWith('${cat.key}|${it['title']}')),
                        onTap: () => toggleTrend('${cat.key}|${it['title']}'),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hook bank — tap your favorites',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final h in hookBank)
                    GestureDetector(
                      onTap: () => toggleHook(h),
                      child: Pill(h, color: s.hooks.contains(h) ? C.gold : C.accent),
                    ),
                ],
              ),
              if (s.hooks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      '${s.hooks.length} hooks selected — they\'ll rotate into your calendar captions.',
                      style: const TextStyle(fontSize: 12, color: C.soft)),
                ),
            ],
          ),
        ),
        if (s.trends.isNotEmpty)
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your trend playbook (${s.trends.length})',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
                for (var i = 0; i < s.trends.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                  text: (s.trends[i].split('|').length > 1
                                          ? s.trends[i].split('|')[1]
                                          : s.trends[i])
                                      .toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: C.brand)),
                            ]),
                          ),
                        ),
                        Pill(s.trends[i].split('|').first, color: C.blue),
                        GestureDetector(
                          onTap: () => setState(() {
                            s.trends.removeAt(i);
                            s.save();
                          }),
                          child: const Text('remove',
                              style: TextStyle(fontSize: 12, color: C.rose)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}
