library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../meta_embed.dart';
import '../state.dart';
import '../widgets.dart';

class CompetitorsScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const CompetitorsScreen(
      {super.key, required this.onBack, required this.onNext});

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

  // search-as-you-type
  Timer? _debounce;
  int _reqId = 0;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    acCtrl.dispose();
    super.dispose();
  }

  /// Accepts a brand name or a website ("https://www.cadbury.co.uk/" → "Cadbury").
  static String brandFrom(String input) {
    final t = input.trim();
    final looksLikeUrl = t.contains('://') ||
        RegExp(r'^(www\.)?[a-z0-9-]+(\.[a-z]{2,})+(/.*)?$',
                caseSensitive: false)
            .hasMatch(t);
    if (!looksLikeUrl) return t;
    final host = Uri.tryParse(t.contains('://') ? t : 'https://$t')?.host ?? '';
    final parts = host.toLowerCase().split('.')
      ..removeWhere((p) => p.isEmpty || p == 'www' || p == 'm');
    if (parts.isEmpty) return t;
    // drop TLDs like .com / .co.uk / .com.au — keep the registrable name
    const tlds = {
      'com',
      'co',
      'org',
      'net',
      'uk',
      'in',
      'au',
      'io',
      'de',
      'fr',
      'us',
      'ca',
      'shop',
      'store'
    };
    while (parts.length > 1 && tlds.contains(parts.last)) {
      parts.removeLast();
    }
    final n = parts.last.replaceAll('-', ' ');
    return n.isEmpty ? t : n[0].toUpperCase() + n.substring(1);
  }

  void onQueryChanged(String v) {
    _debounce?.cancel();
    final q = brandFrom(v);
    if (q.length < 3) {
      _reqId++; // drop any in-flight result
      setState(() {
        analyzing = false;
        analyzeError = null;
        analyzed = null;
        _lastQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 900), () {
      if (q.toLowerCase() != _lastQuery.toLowerCase()) autoAnalyze();
    });
  }

  Future<void> autoAnalyze() async {
    _debounce?.cancel();
    final name = brandFrom(acCtrl.text);
    if (name.isEmpty) return toast(context, 'Type a competitor name');
    final id = ++_reqId;
    _lastQuery = name;
    setState(() {
      analyzing = true;
      analyzeError = null;
      analyzed = null;
    });
    final year = DateTime.now().year;
    // Socials report + Google web/news + ads, all in parallel.
    final res = await Future.wait([
      Api.analyze(name),
      Api.search('$name brand marketing news'),
      Api.search('$name new ad campaign commercial $year'),
    ]);
    if (!mounted || id != _reqId) return; // a newer search superseded this one
    setState(() => analyzing = false);
    final d = res[0];
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
    c.googleHits = _hitsFrom(res[1]);
    c.adHits = _hitsFrom(res[2]);
    setState(() => analyzed = c);
    loadGraphics(c); // then pull their winning creatives
  }

  // winning graphics, keyed by competitor object (survives board reordering)
  final Set<Competitor> _gfxLoading = {};
  final Map<Competitor, String> _gfxErrors = {};
  final Map<Competitor, String> _gfxFilter = {};
  final Map<Competitor, int> _gfxShown = {};
  static const _gfxPage = 18;

  Future<void> loadGraphics(Competitor c) async {
    if (_gfxLoading.contains(c)) return;
    setState(() {
      _gfxLoading.add(c);
      _gfxErrors.remove(c);
    });
    final d = await Api.graphics(c.name);
    if (!mounted) return;
    setState(() {
      _gfxLoading.remove(c);
      if (d['error'] != null) {
        _gfxErrors[c] = d['error'].toString();
      } else {
        c.graphics = ((d['graphics'] ?? []) as List)
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v.toString())))
            .toList();
        _gfxFilter.remove(c);
        _gfxShown.remove(c);
        // persist if already on the board
        if (s.competitors.contains(c)) s.save();
      }
    });
  }

  void toggleGraphic(Competitor c, String url) {
    setState(() {
      if (!c.graphicPicks.remove(url)) c.graphicPicks.add(url);
      if (s.competitors.contains(c)) s.save();
    });
  }

  Widget _graphicsSection(Competitor c) {
    final loading = _gfxLoading.contains(c);
    final cats = <String>{for (final g in c.graphics) g['category'] ?? ''}
      ..remove('');
    final filter = _gfxFilter[c];
    final list = filter == null
        ? c.graphics
        : c.graphics.where((g) => g['category'] == filter).toList();
    final shown = _gfxShown[c] ?? _gfxPage;

    Widget chip(String label, String? value) {
      final on = filter == value;
      return ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: on,
        showCheckmark: false,
        selectedColor: C.brand,
        labelStyle: TextStyle(color: on ? Colors.white : C.brand),
        onSelected: (_) => setState(() {
          if (value == null) {
            _gfxFilter.remove(c);
          } else {
            _gfxFilter[c] = value;
          }
          _gfxShown.remove(c);
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                  '🖼 Winning graphics'
                  '${c.graphics.isEmpty ? '' : ' (${c.graphics.length})'}'
                  '${c.graphicPicks.isEmpty ? '' : ' · ${c.graphicPicks.length} selected'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.brand)),
            ),
            if (!loading)
              SfButton(c.graphics.isEmpty ? 'Find graphics' : '↻ Refresh',
                  ghost: true, onPressed: () => loadGraphics(c)),
          ],
        ),
        if (loading)
          const Thinking(
              'Collecting campaign visuals, posters, billboards, social posts, award winners…'),
        if (_gfxErrors[c] != null) ErrText(_gfxErrors[c]!),
        if (c.graphics.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text('Tap to select the ones you like · ↗ opens the source',
              style: TextStyle(fontSize: 11.5, color: C.soft)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            chip('All', null),
            for (final k in cats) chip(k, k),
          ]),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, box) {
            final cols = (box.maxWidth / 150).floor().clamp(2, 6);
            final size = (box.maxWidth - (cols - 1) * 8) / cols;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in list.take(shown))
                  SizedBox(width: size, child: _graphicTile(c, g)),
              ],
            );
          }),
          if (list.length > shown)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SfButton('Show more (${list.length - shown})',
                  alt: true,
                  onPressed: () =>
                      setState(() => _gfxShown[c] = shown + _gfxPage)),
            ),
        ],
      ],
    );
  }

  Widget _graphicTile(Competitor c, Map<String, String> g) {
    final url = g['image'] ?? '';
    final selected = c.graphicPicks.contains(url);
    final source = g['source'] ?? '';
    return Tooltip(
      message: g['title'] ?? '',
      waitDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () => toggleGraphic(c, url),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: selected ? C.green : Colors.transparent, width: 3),
            color: C.cream,
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(Api.img(g['thumb'] ?? url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, color: C.soft)),
                if (selected)
                  const Positioned(
                    left: 6,
                    top: 6,
                    child: CircleAvatar(
                        radius: 11,
                        backgroundColor: C.green,
                        child:
                            Icon(Icons.check, size: 14, color: Colors.white)),
                  ),
                if (source.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => launchUrl(Uri.parse(source)),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.open_in_new,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87]),
                    ),
                    child: Text(g['category'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Normalizes /api/search results into {title, snippet, url}; empty on error.
  List<Map<String, String>> _hitsFrom(Map<String, dynamic> d, {int max = 5}) {
    if (d['error'] != null || d['results'] is! List) return [];
    final seen = <String>{};
    final out = <Map<String, String>>[];
    for (final e in d['results'] as List) {
      if (e is! Map) continue;
      final url = (e['url'] ?? e['link'] ?? '').toString();
      final title = (e['title'] ?? '').toString();
      if (title.isEmpty || !seen.add(url.isEmpty ? title : url)) continue;
      out.add({
        'title': title,
        'snippet': (e['snippet'] ?? e['description'] ?? '').toString(),
        'url': url,
      });
      if (out.length >= max) break;
    }
    return out;
  }

  /// Meta Ad Library search, all ads worldwide, highest impressions first.
  static String metaLibraryUrl(String name) =>
      'https://www.facebook.com/ads/library/?active_status=all&ad_type=all&country=ALL'
      '&is_targeted_country=false&media_type=all&q=${Uri.encodeQueryComponent(name)}'
      '&search_type=keyword_unordered'
      '&sort_data%5Bmode%5D=total_impressions&sort_data%5Bdirection%5D=desc';

  /// Competitors whose Meta Ad Library is expanded inline (desktop embed).
  final Set<Competitor> _metaOpen = {};

  void _openMeta(Competitor c) {
    if (canEmbedWeb) {
      setState(() {
        if (!_metaOpen.remove(c)) _metaOpen.add(c);
      });
    } else {
      _showMetaAds(c); // web: Facebook forbids iframing → in-app panel
    }
  }

  /// Public ad-library search pages for a brand (opened in the browser).
  static Map<String, String> adLibraryLinks(String name) {
    final q = Uri.encodeQueryComponent(name);
    return {
      'Meta Ad Library': metaLibraryUrl(name),
      'Google Ads Transparency':
          'https://adstransparency.google.com/?region=anywhere&query=$q',
      'TikTok Ad Library':
          'https://library.tiktok.com/ads?region=all&adv_name=$q&query_type=1',
      'LinkedIn Ad Library':
          'https://www.linkedin.com/ad-library/search?companyName=$q',
    };
  }

  /// Meta ads shown in an in-app panel (no redirect to facebook.com).
  Future<void> _showMetaAds(Competitor c) {
    final future = Api.metaAds(c.name);
    return showDialog(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final mobile = size.width < 700;
        return Dialog(
          backgroundColor: C.bg,
          insetPadding: EdgeInsets.all(mobile ? 10 : 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: 1100,
            height: size.height * .88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: C.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('📘 Meta ads · ${c.name}',
                            style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: C.brand)),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close, color: C.brand),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: future,
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: Thinking('Loading Facebook & Instagram ads…'));
                      }
                      final d = snap.data!;
                      if (d['error'] != null) {
                        return Padding(
                            padding: const EdgeInsets.all(20),
                            child: ErrText(d['error'].toString()));
                      }
                      final ads = ((d['ads'] ?? []) as List)
                          .whereType<Map>()
                          .map((e) => e.map((k, v) => MapEntry(k.toString(), v.toString())))
                          .toList();
                      final api = d['mode'] == 'api';
                      return ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: C.cream, borderRadius: BorderRadius.circular(11)),
                            child: Text(
                                api
                                    ? '${ads.length} ads from the official Meta Ad Library '
                                        '(ads delivered in ${(d['countries'] as List?)?.join(', ') ?? 'the EU'}).'
                                    : '${ads.length} Facebook & Instagram ad creatives found on the web. '
                                        'For the full official Meta Ad Library inside this panel, add a '
                                        'META_ACCESS_TOKEN to the server.',
                                style: const TextStyle(fontSize: 12.5, color: C.soft)),
                          ),
                          const SizedBox(height: 14),
                          if (ads.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(30),
                              child: Center(
                                  child: Text('No ads found for this brand.',
                                      style: TextStyle(color: C.soft))),
                            )
                          else if (api)
                            LayoutBuilder(
                              builder: (ctx, box) {
                                final cols = gridCols(box.maxWidth, minTile: 320, min: 1, max: 3);
                                final w = (box.maxWidth - (cols - 1) * 12) / cols;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final a in ads)
                                      SizedBox(width: w, child: _metaAdCard(a)),
                                  ],
                                );
                              },
                            )
                          else
                            LayoutBuilder(
                              builder: (ctx, box) => GridView.count(
                                crossAxisCount: gridCols(box.maxWidth, minTile: 200),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: .78,
                                children: [for (final a in ads) _metaCreativeTile(ctx, a)],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metaAdCard(Map<String, String> a) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a['page'] ?? '',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800, color: C.brand)),
            const SizedBox(height: 4),
            Wrap(children: [
              if ((a['start'] ?? '').isNotEmpty)
                Pill(
                    (a['stop'] ?? '').isEmpty
                        ? 'Running since ${a['start']}'
                        : '${a['start']} → ${a['stop']}',
                    color: (a['stop'] ?? '').isEmpty ? C.green : C.blue),
              if ((a['platforms'] ?? '').isNotEmpty) Pill(a['platforms']!, color: C.gold),
            ]),
            if ((a['title'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(a['title']!,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: C.ink)),
            ],
            if ((a['body'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(a['body']!,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: C.soft, height: 1.4)),
            ],
          ],
        ),
      );

  /// Image creative; tap to view large inside the app.
  Widget _metaCreativeTile(BuildContext ctx, Map<String, String> a) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog(
          context: ctx,
          builder: (c2) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Center(
                    child: Image.network(Api.img(a['image'] ?? ''),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.network(
                            Api.img(a['thumb'] ?? ''),
                            fit: BoxFit.contain)),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(c2),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.network(Api.img(a['thumb'] ?? ''),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, color: C.soft)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(a['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: C.brand)),
              ),
            ],
          ),
        ),
      );

  Widget _adsAndGoogle(Competitor c) {
    Widget hitList(String label, List<Map<String, String>> hits) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
            for (final h in hits)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: h['title'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: C.brand)),
                    if ((h['snippet'] ?? '').isNotEmpty)
                      TextSpan(
                          text:
                              ' — ${h['snippet']!.length > 120 ? '${h['snippet']!.substring(0, 120)}…' : h['snippet']} ',
                          style: const TextStyle(color: C.soft)),
                    if ((h['url'] ?? '').isNotEmpty)
                      TextSpan(
                          text: ' view ↗',
                          style: const TextStyle(
                              color: C.accent, fontWeight: FontWeight.w700),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(Uri.parse(h['url']!))),
                  ]),
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.googleHits.isNotEmpty) hitList('🔎 On Google', c.googleHits),
        if (c.adHits.isNotEmpty) hitList('📣 Ads & commercials', c.adHits),
        const SizedBox(height: 10),
        const Text('📚 Live ads in ad libraries',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Meta shows inside this section; the others still link out.
            SfButton(
                _metaOpen.contains(c)
                    ? '📘 Hide Meta Ad Library'
                    : '📘 Meta Ad Library',
                onPressed: () => _openMeta(c)),
            for (final e in adLibraryLinks(c.name).entries)
              if (e.key != 'Meta Ad Library')
                SfButton('${e.key} ↗',
                    alt: true, onPressed: () => launchUrl(Uri.parse(e.value))),
          ],
        ),
        if (_metaOpen.contains(c)) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: C.line),
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.all(4),
            child: embeddedWeb(metaLibraryUrl(c.name), height: 680),
          ),
        ],
      ],
    );
  }

  void keepAnalyzed() {
    final c = analyzed;
    if (c == null) return;
    setState(() {
      s.competitors.add(c);
      analyzed = null;
      _lastQuery = '';
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
      final m = RegExp(r"^[A-Z][A-Za-z'&]+")
          .firstMatch((r['title'] ?? '').toString());
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
        SplitView(leftFlex: 6, rightFlex: 5, left: [
          SfCard(
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚡ Auto-analyze a competitor',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: acCtrl,
                        decoration:
                            sfInput('Start typing — e.g., Cadbury, Nutella…'),
                        onChanged: onQueryChanged,
                        onSubmitted: (_) => autoAnalyze(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SfButton('Analyze now',
                        onPressed: analyzing ? null : autoAnalyze),
                  ],
                ),
                if (analyzing)
                  const Thinking(
                      'Analyzing — Instagram, TikTok, YouTube, Google, ads, campaigns…'),
                if (analyzeError != null) ErrText(analyzeError!),
                if (analyzed != null) _analysisCard(analyzed!),
              ],
            ),
          ),
        ], right: [
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Don't know who to pick?",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
                const SizedBox(height: 8),
                SfButton('Suggest competitors for my category',
                    alt: true, onPressed: suggesting ? null : suggestComps),
                if (suggesting)
                  const Thinking('Finding top brands in your category…'),
                if (suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final n in suggestions)
                          SfButton(n, alt: true, onPressed: () {
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
              child: Text(
                  'Empty — analyze your first competitor and tap “Add to board”.',
                  style: TextStyle(color: C.soft, fontSize: 13.5)),
            ),
          for (var i = 0; i < s.competitors.length; i++)
            _competitorCard(i, catLabel),
        ]),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: C.brand)),
              ),
              SfButton('✓ Add to board', onPressed: keepAnalyzed, alt: true),
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
          _adsAndGoogle(c),
          _graphicsSection(c),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
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
          _adsAndGoogle(c),
          _graphicsSection(c),
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
              alt: true,
              onPressed: diving.contains(i) ? null : () => deepDive(i)),
          if (diving.contains(i))
            const Thinking('Researching campaigns, stats, UGC & trends…'),
          if (deepErrors[i] != null) ErrText(deepErrors[i]!),
          if (deepResults[i] != null) ...[
            for (final cat in deepResults[i]!.entries) ...[
              if (cat.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${catLabel[cat.key] ?? cat.key} — tap to select',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
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
                      selected: c.picks.any(
                          (p) => p.startsWith('${cat.key}|${it['title']}')),
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
