library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class AudienceScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const AudienceScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  final s = AppState.instance;
  final nameCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final factsCtrl = TextEditingController();
  final convCtrl = TextEditingController();

  // live audience research
  bool researching = false;
  String? researchError;
  List<Map<String, String>> insights = [];
  final Set<String> usedInsights = {};

  @override
  void dispose() {
    for (final c in [nameCtrl, roleCtrl, factsCtrl, convCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String get cat => catKey(s.brand.product);
  bool get isAlcohol => cat == 'alcohol';
  String get productLabel =>
      s.brand.product.isEmpty ? 'your product' : s.brand.product;
  List<AudienceEntry> get lib => audienceLib[cat]!;

  bool isSelected(AudienceEntry e) => s.segments.any((x) => x.name == e.name);

  void toggleSeg(AudienceEntry e) => setState(() {
        final idx = s.segments.indexWhere((x) => x.name == e.name);
        if (idx >= 0) {
          s.segments.removeAt(idx);
        } else {
          s.segments.add(Segment(
              name: e.name, role: e.role, facts: e.facts, convert: e.convert));
        }
        s.save();
      });

  void selectAll() => setState(() {
        for (final e in lib) {
          if (!isSelected(e)) {
            s.segments.add(Segment(
                name: e.name,
                role: e.role,
                facts: e.facts,
                convert: e.convert));
          }
        }
        s.save();
      });

  void addCustom() {
    final n = nameCtrl.text.trim();
    if (n.isEmpty) return toast(context, 'Name your segment');
    if (s.segments.any((x) => x.name.toLowerCase() == n.toLowerCase())) {
      return toast(context, '"$n" is already in your segments');
    }
    setState(() {
      s.segments.add(Segment(
          name: n,
          role: roleCtrl.text.trim(),
          facts: factsCtrl.text.trim(),
          convert: convCtrl.text.trim()));
      for (final c in [nameCtrl, roleCtrl, factsCtrl, convCtrl]) {
        c.clear();
      }
      usedInsights.clear();
      s.save();
    });
    toast(context, '$n added');
  }

  Future<void> research() async {
    setState(() {
      researching = true;
      researchError = null;
      insights = [];
    });
    final year = DateTime.now().year;
    final p = s.brand.product.isEmpty ? 'consumer brand' : s.brand.product;
    final res = await Future.wait([
      Api.search('$p target audience demographics consumer insights $year'),
      Api.search('$p buyer behaviour social media trends $year'),
    ]);
    if (!mounted) return;
    final seen = <String>{};
    final out = <Map<String, String>>[];
    for (final d in res) {
      if (d['results'] is! List) continue;
      for (final e in d['results'] as List) {
        if (e is! Map) continue;
        final title = (e['title'] ?? '').toString();
        final url = (e['url'] ?? '').toString();
        if (title.isEmpty || !seen.add(url.isEmpty ? title : url)) continue;
        out.add({
          'title': title,
          'snippet': (e['snippet'] ?? '').toString(),
          'url': url,
        });
      }
    }
    setState(() {
      researching = false;
      insights = out.take(8).toList();
      if (out.isEmpty) {
        researchError =
            (res.first['error'] ?? 'No insights found — try again').toString();
      }
    });
  }

  /// Tapping an insight appends its snippet to the custom segment's facts.
  void useInsight(Map<String, String> it) {
    final snip = (it['snippet'] ?? '').trim();
    if (snip.isEmpty) return;
    setState(() {
      usedInsights.add(it['url'] ?? it['title']!);
      final short = snip.length > 220 ? '${snip.substring(0, 220)}…' : snip;
      factsCtrl.text = factsCtrl.text.trim().isEmpty
          ? short
          : '${factsCtrl.text.trim()}\n$short';
    });
    toast(context, 'Added to "Behavior facts" below');
  }

  Future<void> editSegment(int i) async {
    final seg = s.segments[i];
    final n = TextEditingController(text: seg.name);
    final r = TextEditingController(text: seg.role);
    final f = TextEditingController(text: seg.facts);
    final c = TextEditingController(text: seg.convert);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit segment',
            style: TextStyle(color: C.brand, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Field('Name', TextField(controller: n, decoration: sfInput())),
                Field('Role', TextField(controller: r, decoration: sfInput())),
                Field(
                    'Behavior facts',
                    TextField(
                        controller: f, maxLines: 3, decoration: sfInput())),
                Field(
                    'Converts with',
                    TextField(
                        controller: c, maxLines: 3, decoration: sfInput())),
              ],
            ),
          ),
        ),
        actions: [
          SfButton('Cancel',
              ghost: true, onPressed: () => Navigator.pop(ctx, false)),
          SfButton('Save', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (saved == true && n.text.trim().isNotEmpty) {
      setState(() {
        seg
          ..name = n.text.trim()
          ..role = r.text.trim()
          ..facts = f.text.trim()
          ..convert = c.text.trim();
        s.save();
      });
    }
    for (final x in [n, r, f, c]) {
      x.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final compNote = s.competitors.isNotEmpty
        ? 'Based on your ${s.competitors.length} competitor${s.competitors.length > 1 ? 's' : ''} and category.'
        : 'Based on your category.';
    final allSelected = lib.every(isSelected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 3 · AUDIENCE',
          title: 'Who are we talking to?',
          lead:
              '$compNote Pick the segments worth targeting, research your audience live, or build your own. Everything stays editable.',
        ),
        if (isAlcohol) _complianceBanner(),
        SplitView(left: [
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('✨ Suggested segments for $productLabel',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: C.brand)),
                    ),
                    if (!allSelected)
                      SfButton('Select all', ghost: true, onPressed: selectAll),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Tap a card to add or remove it.',
                    style: TextStyle(fontSize: 12, color: C.soft)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, box) {
                  final two = box.maxWidth > 620;
                  final w = two ? (box.maxWidth - 10) / 2 : box.maxWidth;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final e in lib)
                        SizedBox(width: w, child: _suggestCard(e)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ], right: [
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('🔎 Live audience research',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: C.brand)),
                    ),
                    SfButton(insights.isEmpty ? 'Research now' : '↻ Refresh',
                        alt: true, onPressed: researching ? null : research),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Pulls fresh demographics & buying-behaviour insights for $productLabel from the web. Tap one to add it to a custom segment.',
                    style: const TextStyle(fontSize: 12, color: C.soft)),
                if (researching) const Thinking('Researching your audience…'),
                if (researchError != null) ErrText(researchError!),
                for (final it in insights)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Stack(
                      children: [
                        SelCard(
                          title: it['title']!,
                          snippet: it['snippet']!,
                          selected:
                              usedInsights.contains(it['url'] ?? it['title']),
                          onTap: () => useInsight(it),
                        ),
                        if ((it['url'] ?? '').isNotEmpty)
                          Positioned(
                            right: 8,
                            bottom: 6,
                            child: InkWell(
                              onTap: () => launchUrl(Uri.parse(it['url']!)),
                              child: const Text('source ↗',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: C.accent,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('+ Custom segment',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Field(
                          'Name',
                          TextField(
                              controller: nameCtrl,
                              decoration: sfInput(isAlcohol
                                  ? 'e.g., Weekend cocktail hosts (25–35)'
                                  : 'e.g., Busy working parents'))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Field(
                          'Role',
                          TextField(
                              controller: roleCtrl,
                              decoration: sfInput('e.g., High AOV'))),
                    ),
                  ],
                ),
                Field(
                    'Behavior facts',
                    TextField(
                        controller: factsCtrl,
                        maxLines: 3,
                        decoration:
                            sfInput('How they discover, decide and buy'))),
                Field(
                    'Converts with',
                    TextField(
                        controller: convCtrl,
                        maxLines: 3,
                        decoration: sfInput(
                            'Content formats & offers that move them'))),
                const SizedBox(height: 12),
                SfButton('Add segment', onPressed: addCustom),
              ],
            ),
          ),
          if (s.segments.isNotEmpty)
            SfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('✅ Your segments (${s.segments.length})',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: C.brand)),
                      ),
                      SfButton('Clear all',
                          ghost: true,
                          onPressed: () => setState(() {
                                s.segments.clear();
                                s.save();
                              })),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < s.segments.length; i++) _selectedRow(i),
                ],
              ),
            ),
        ]),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }

  Widget _complianceBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E5),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.gold, width: 1.5),
        ),
        child: const Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '🔞 Alcohol marketing rules apply. ',
                style: TextStyle(fontWeight: FontWeight.w800, color: C.brand)),
            TextSpan(
                text:
                    'Only target people of legal drinking age (LDA) in each market (e.g. 21 in the US, 18 in the UK, 25 in parts of India). '
                    'Use platform age-gating, avoid creators or themes that appeal mainly to minors, and check local rules — some markets '
                    'restrict or ban alcohol ads entirely.',
                style: TextStyle(color: C.soft)),
          ]),
          style: TextStyle(fontSize: 12.5, height: 1.4),
        ),
      );

  Widget _suggestCard(AudienceEntry e) {
    final on = isSelected(e);
    Widget line(String label, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$label  ',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: C.brand)),
              TextSpan(text: text, style: const TextStyle(color: C.soft)),
            ]),
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        );
    return GestureDetector(
      onTap: () => toggleSeg(e),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFF5F8F2) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: on ? C.green : C.line, width: on ? 2 : 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(e.name,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: C.brand)),
                ),
                Icon(on ? Icons.check_circle : Icons.add_circle_outline,
                    size: 20, color: on ? C.green : C.soft),
              ],
            ),
            if (e.role.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Pill(e.role, color: C.gold),
              ),
            line('Facts', e.facts),
            line('Converts with', e.convert),
          ],
        ),
      ),
    );
  }

  Widget _selectedRow(int i) {
    final seg = s.segments[i];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: C.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seg.name,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
                if (seg.role.isNotEmpty || seg.convert.isNotEmpty)
                  Text(
                      [seg.role, seg.convert]
                          .where((x) => x.isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: C.soft)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 18, color: C.brand),
            onPressed: () => editSegment(i),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close, size: 18, color: C.rose),
            onPressed: () => setState(() {
              s.segments.removeAt(i);
              s.save();
            }),
          ),
        ],
      ),
    );
  }
}
