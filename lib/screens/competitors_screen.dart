library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../state.dart';
import '../widgets.dart';

class CompetitorsScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const CompetitorsScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<CompetitorsScreen> createState() => _CompetitorsScreenState();
}

class _CompetitorsScreenState extends State<CompetitorsScreen> {
  final s = AppState.instance;
  final acCtrl = TextEditingController();
  bool analyzing = false;
  String? analyzeError;
  Competitor? analyzed;

  bool suggesting = false;
  List<String> suggestions = [];

  // deep-dive per competitor index
  final Set<int> diving = {};
  final Map<int, Map<String, List<Map<String, String>>>> deepResults = {};
  final Map<int, String?> deepErrors = {};

  Future<void> autoAnalyze() async {
    final name = acCtrl.text.trim();
    if (name.isEmpty) return toast(context, 'Type a competitor name');
    setState(() {
      analyzing = true;
      analyzeError = null;
      analyzed = null;
    });
    final d = await Api.analyze(name);
    if (!mounted) return;
    setState(() => analyzing = false);
    if (d['error'] != null) {
      setState(() => analyzeError = d['error'].toString());
      return;
    }
    final r = Map<String, dynamic>.from(d['report'] as Map? ?? {});
    final c = Competitor(name: r['name']?.toString() ?? name);
    c.handles = Map<String, String>.from(r['handles'] ?? {});
    c.followers = Map<String, String>.from(r['followers'] ?? {});
    c.topCampaigns = ((r['topCampaigns'] ?? []) as List)
        .map((e) => CampaignRef.fromJson(e as Map<String, dynamic>))
        .toList();
    setState(() => analyzed = c);
  }

  void keepAnalyzed() {
    final c = analyzed;
    if (c == null) return;
    setState(() {
      s.competitors.add(c);
      analyzed = null;
      acCtrl.clear();
      s.save();
    });
    toast(context, '${c.name} added to your board');
  }

  Future<void> suggestComps() async {
    setState(() {
      suggesting = true;
      suggestions = [];
    });
    final cat = s.brand.product.isEmpty ? 'chocolate' : s.brand.product;
    final d = await Api.search('top $cat brands social media');
    if (!mounted) return;
    setState(() => suggesting = false);
    if (d['error'] != null || d['results'] == null) return;
    final names = <String>{};
    for (final r in (d['results'] as List)) {
      final m = RegExp(r"^[A-Z][A-Za-z'&]+").firstMatch((r['title'] ?? '').toString());
      if (m != null) names.add(m.group(0)!);
    }
    setState(() => suggestions = names.take(8).toList());
  }

  Future<void> deepDive(int i) async {
    final c = s.competitors[i];
    setState(() {
      diving.add(i);
      deepErrors[i] = null;
    });
    final d = await Api.suggest(c.name, ['campaigns', 'stats', 'ugc', 'memes']);
    if (!mounted) return;
    setState(() => diving.remove(i));
    if (d['error'] != null) {
      setState(() => deepErrors[i] = d['error'].toString());
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
    setState(() => deepResults[i] = cats);
  }

  void pickRef(int i, String key) {
    setState(() {
      final picks = s.competitors[i].picks;
      final idx = picks.indexWhere((p) => p.startsWith(key));
      if (idx >= 0) {
        picks.removeAt(idx);
      } else {
        picks.add(key);
      }
      s.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catLabel = {
      'campaigns': '🏆 Campaigns',
      'stats': '📊 Statistics',
      'ugc': '🤳 UGC & creators',
      'memes': '😂 Memes & culture',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          crumb: 'STEP 2 · COMPETITOR STUDY',
          title: 'Who are you up against?',
          lead:
              'Type a competitor → the wizard analyzes their socials live and builds a report. Then dig into their best campaigns — categorized, with links — and tap what you like.',
        ),
        SfCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚡ Auto-analyze a competitor',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: acCtrl,
                      decoration: sfInput('e.g., Cadbury, Nutella…'),
                      onSubmitted: (_) => autoAnalyze(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SfButton('Analyze now',
                      onPressed: analyzing ? null : autoAnalyze),
                ],
              ),
              if (analyzing)
                const Thinking('Analyzing — Instagram, TikTok, YouTube, campaigns, strategy…'),
              if (analyzeError != null) ErrText(analyzeError!),
              if (analyzed != null) _analysisCard(analyzed!),
            ],
          ),
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Don't know who to pick?",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 8),
              SfButton('Suggest competitors for my category',
                  alt: true, onPressed: suggesting ? null : suggestComps),
              if (suggesting) const Thinking('Finding top brands in your category…'),
              if (suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final n in suggestions)
                        SfButton(n,
                            alt: true,
                            onPressed: () {
                              acCtrl.text = n;
                              autoAnalyze();
                            }),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Text('Your board (${s.competitors.length})',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
        ),
        if (s.competitors.isEmpty)
          const SfCard(
            child: Text('Empty — analyze your first competitor above.',
                style: TextStyle(color: C.soft, fontSize: 13.5)),
          ),
        for (var i = 0; i < s.competitors.length; i++)
          _competitorCard(i, catLabel),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }

  Widget _analysisCard(Competitor c) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: C.cream, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(c.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: C.brand)),
              ),
              SfButton('✓ Add to board',
                  onPressed: keepAnalyzed, alt: true),
            ],
          ),
          const SizedBox(height: 6),
          if (c.handles.isNotEmpty || c.followers.isNotEmpty)
            Wrap(
              children: [
                for (final e in c.handles.entries)
                  Pill('${e.key} ${e.value}', color: C.blue),
                for (final e in c.followers.entries)
                  Pill('${e.key} ${e.value}', color: C.gold),
              ],
            ),
          for (final x in c.topCampaigns.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: '${x.name} — ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: C.brand)),
                    TextSpan(
                        text: x.result.length > 120
                            ? '${x.result.substring(0, 120)}…'
                            : x.result,
                        style: const TextStyle(color: C.soft)),
                    if (x.url.isNotEmpty)
                      TextSpan(
                        text: ' view ↗',
                        style: const TextStyle(
                            color: C.accent, fontWeight: FontWeight.w700),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(Uri.parse(x.url)),
                      ),
                  ],
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _competitorCard(int i, Map<String, String> catLabel) {
    final c = s.competitors[i];
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(c.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              ),
              SfButton('✕',
                  ghost: true,
                  onPressed: () => setState(() {
                        s.competitors.removeAt(i);
                        deepResults.remove(i);
                        s.save();
                      })),
            ],
          ),
          if (c.handles.isNotEmpty || c.followers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                children: [
                  for (final e in c.handles.entries)
                    Pill('${e.key} ${e.value}', color: C.blue),
                  for (final e in c.followers.entries)
                    Pill('${e.key} ${e.value}', color: C.gold),
                ],
              ),
            ),
          if (c.topCampaigns.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('🏆 Campaigns found',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
            for (final x in c.topCampaigns)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: x.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: C.brand)),
                    TextSpan(
                        text:
                            ' — ${x.result.length > 120 ? '${x.result.substring(0, 120)}…' : x.result} ',
                        style: const TextStyle(color: C.soft)),
                    if (x.url.isNotEmpty)
                      TextSpan(
                          text: 'view ↗',
                          style: const TextStyle(
                              color: C.accent, fontWeight: FontWeight.w700),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(Uri.parse(x.url))),
                  ]),
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
          if (c.picks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('✅ Your selected references',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
            Wrap(
              children: [
                for (final p in c.picks)
                  Pill(p.length > 60 ? '${p.substring(0, 60)}…' : p,
                      color: C.green),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SfButton('🔍 Find best campaigns & stats',
              alt: true, onPressed: diving.contains(i) ? null : () => deepDive(i)),
          if (diving.contains(i))
            const Thinking('Researching campaigns, stats, UGC & trends…'),
          if (deepErrors[i] != null) ErrText(deepErrors[i]!),
          if (deepResults[i] != null) ...[
            for (final cat in deepResults[i]!.entries) ...[
              if (cat.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${catLabel[cat.key] ?? cat.key} — tap to select',
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
                      selected:
                          c.picks.any((p) => p.startsWith('${cat.key}|${it['title']}')),
                      onTap: () => pickRef(i, '${cat.key}|${it['title']}'),
                    ),
                  ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
