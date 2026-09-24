/// App state + persistence. Same JSON shape as the web version
/// (localStorage key "socialflow_v2"), so data is interchangeable.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CampaignRef {
  String name, result, url, why;
  CampaignRef({this.name = '', this.result = '', this.url = '', this.why = ''});

  factory CampaignRef.fromJson(Map<String, dynamic> j) => CampaignRef(
        name: j['name'] ?? '',
        result: j['result'] ?? '',
        url: j['url'] ?? '',
        why: j['why'] ?? '',
      );
  Map<String, dynamic> toJson() =>
      {'name': name, 'result': result, 'url': url, 'why': why};
}

class Competitor {
  String name;
  Map<String, String> handles;
  Map<String, String> followers;
  List<CampaignRef> topCampaigns;
  List<String> picks;
  // web search hits: each {title, snippet, url}
  List<Map<String, String>> googleHits;
  List<Map<String, String>> adHits;
  // winning creatives: each {category, image, thumb, title, source, w, h}
  List<Map<String, String>> graphics;
  List<String> graphicPicks; // selected graphic image URLs

  Competitor({
    this.name = '',
    Map<String, String>? handles,
    Map<String, String>? followers,
    List<CampaignRef>? topCampaigns,
    List<String>? picks,
    List<Map<String, String>>? googleHits,
    List<Map<String, String>>? adHits,
    List<Map<String, String>>? graphics,
    List<String>? graphicPicks,
  })  : handles = handles ?? {},
        followers = followers ?? {},
        topCampaigns = topCampaigns ?? [],
        picks = picks ?? [],
        googleHits = googleHits ?? [],
        adHits = adHits ?? [],
        graphics = graphics ?? [],
        graphicPicks = graphicPicks ?? [];

  static List<Map<String, String>> _hits(dynamic v) => ((v ?? []) as List)
      .map((e) => Map<String, String>.from(
          (e as Map).map((k, x) => MapEntry(k.toString(), x.toString()))))
      .toList();

  factory Competitor.fromJson(Map<String, dynamic> j) => Competitor(
        name: j['name'] ?? '',
        handles: Map<String, String>.from(j['handles'] ?? {}),
        followers: Map<String, String>.from(j['followers'] ?? {}),
        topCampaigns: ((j['topCampaigns'] ?? []) as List)
            .map((e) => CampaignRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        picks: List<String>.from(j['picks'] ?? []),
        googleHits: _hits(j['googleHits']),
        adHits: _hits(j['adHits']),
        graphics: _hits(j['graphics']),
        graphicPicks: List<String>.from(j['graphicPicks'] ?? []),
      );
  Map<String, dynamic> toJson() => {
        'name': name,
        'handles': handles,
        'followers': followers,
        'topCampaigns': topCampaigns.map((e) => e.toJson()).toList(),
        'picks': picks,
        'googleHits': googleHits,
        'adHits': adHits,
        'graphics': graphics,
        'graphicPicks': graphicPicks,
      };
}

class Segment {
  String name, role, facts, convert;
  Segment({this.name = '', this.role = '', this.facts = '', this.convert = ''});

  factory Segment.fromJson(Map<String, dynamic> j) => Segment(
        name: j['name'] ?? '',
        role: j['role'] ?? '',
        facts: j['facts'] ?? '',
        convert: j['convert'] ?? '',
      );
  Map<String, dynamic> toJson() =>
      {'name': name, 'role': role, 'facts': facts, 'convert': convert};
}

class Pillar {
  String name, why;
  int pct;
  bool off;
  Pillar({this.name = '', this.why = '', this.pct = 10, this.off = false});

  factory Pillar.fromJson(Map<String, dynamic> j) => Pillar(
        name: j['name'] ?? '',
        why: j['why'] ?? '',
        pct: j['pct'] ?? 10,
        off: j['off'] ?? false,
      );
  Map<String, dynamic> toJson() =>
      {'name': name, 'why': why, 'pct': pct, 'off': off};
}

class GalleryItem {
  String url, title, prompt, pillar, model;
  GalleryItem(
      {this.url = '',
      this.title = '',
      this.prompt = '',
      this.pillar = '',
      this.model = ''});

  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(
        url: j['url'] ?? '',
        title: j['title'] ?? '',
        prompt: j['prompt'] ?? '',
        pillar: j['pillar'] ?? '',
        model: j['model'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'prompt': prompt,
        'pillar': pillar,
        if (model.isNotEmpty) 'model': model,
      };
}

class CalDay {
  int day;
  String title, stage, pillar, platforms, format, hook, cta;
  String refImage, imgPrompt;
  CalDay({
    required this.day,
    this.title = '',
    this.stage = '',
    this.pillar = '',
    this.platforms = '',
    this.format = '',
    this.hook = '',
    this.cta = '',
    this.refImage = '',
    this.imgPrompt = '',
  });

  factory CalDay.fromJson(Map<String, dynamic> j) => CalDay(
        day: j['day'] ?? 0,
        title: j['title'] ?? '',
        stage: j['stage'] ?? '',
        pillar: j['pillar'] ?? '',
        platforms: j['platforms'] ?? '',
        format: j['format'] ?? '',
        hook: j['hook'] ?? '',
        cta: j['cta'] ?? '',
        refImage: j['refImage'] ?? '',
        imgPrompt: j['imgPrompt'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'day': day,
        'title': title,
        'stage': stage,
        'pillar': pillar,
        'platforms': platforms,
        'format': format,
        'hook': hook,
        'cta': cta,
        if (refImage.isNotEmpty) 'refImage': refImage,
        'imgPrompt': imgPrompt,
      };
}

class BrandInfo {
  String name, product, website, voice, goal, siteText;
  List<String> platforms, productImages;
  BrandInfo({
    this.name = '',
    this.product = '',
    this.website = '',
    this.voice = '',
    this.goal = 'Launch / awareness',
    this.siteText = '',
    List<String>? platforms,
    List<String>? productImages,
  })  : platforms = platforms ?? ['Instagram', 'YouTube', 'Facebook'],
        productImages = productImages ?? [];

  factory BrandInfo.fromJson(Map<String, dynamic> j) => BrandInfo(
        name: j['name'] ?? '',
        product: j['product'] ?? '',
        website: j['website'] ?? '',
        voice: j['voice'] ?? '',
        goal: j['goal'] ?? 'Launch / awareness',
        siteText: j['siteText'] ?? '',
        platforms: List<String>.from(
            j['platforms'] ?? ['Instagram', 'YouTube', 'Facebook']),
        productImages: List<String>.from(j['productImages'] ?? []),
      );
  Map<String, dynamic> toJson() => {
        'name': name,
        'product': product,
        'website': website,
        'voice': voice,
        'goal': goal,
        'siteText': siteText,
        'platforms': platforms,
        'productImages': productImages,
      };
}

class StrategyState {
  String platform;
  List<Pillar> pillars;
  Map<String, String> cadence;
  StrategyState({this.platform = '', List<Pillar>? pillars, Map<String, String>? cadence})
      : pillars = pillars ?? [],
        cadence = cadence ?? {};

  factory StrategyState.fromJson(Map<String, dynamic> j) => StrategyState(
        platform: j['platform'] ?? '',
        pillars: ((j['pillars'] ?? []) as List)
            .map((e) => Pillar.fromJson(e as Map<String, dynamic>))
            .toList(),
        cadence: Map<String, String>.from(j['cadence'] ?? {}),
      );
  Map<String, dynamic> toJson() => {
        'platform': platform,
        'pillars': pillars.map((e) => e.toJson()).toList(),
        'cadence': cadence,
      };
}

class AppState extends ChangeNotifier {
  static const storageKey = 'socialflow_v2';
  static final AppState instance = AppState._();
  AppState._();

  BrandInfo brand = BrandInfo();
  List<Competitor> competitors = [];
  List<Segment> segments = [];
  List<String> trends = [];
  List<String> hooks = [];
  StrategyState strategy = StrategyState();
  List<GalleryItem> gallery = [];
  List<CalDay>? calendar;
  Set<int> done = {};

  // ── Device-local settings (never part of toJson → never uploaded/shared) ──
  static const localKey = 'socialflow_local_v1';
  int step = 0; // wizard step to reopen after a reload
  String imageModel = 'auto';
  Map<String, String> modelKeys = {}; // {ENV_NAME: api key}
  String draftTitle = '', draftPrompt = '', draftRatio = '1:1';

  /// Persists to disk and rebuilds the UI. Call after every mutation
  /// (mirrors the web version's save()).
  void save() {
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(toJson()));
      await prefs.setString(
          localKey,
          jsonEncode({
            'step': step,
            'imageModel': imageModel,
            'modelKeys': modelKeys,
            'draftTitle': draftTitle,
            'draftPrompt': draftPrompt,
            'draftRatio': draftRatio,
          }));
    } catch (_) {}
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      final local = prefs.getString(localKey);
      if (local != null && local.isNotEmpty) {
        final l = jsonDecode(local) as Map<String, dynamic>;
        step = (l['step'] as num?)?.toInt() ?? 0;
        imageModel = l['imageModel']?.toString() ?? 'auto';
        modelKeys = Map<String, String>.from(l['modelKeys'] ?? {});
        draftTitle = l['draftTitle']?.toString() ?? '';
        draftPrompt = l['draftPrompt']?.toString() ?? '';
        draftRatio = l['draftRatio']?.toString() ?? '1:1';
      }
      notifyListeners();
    } catch (_) {}
  }

  Map<String, dynamic> toJson() => {
        'brand': brand.toJson(),
        'competitors': competitors.map((e) => e.toJson()).toList(),
        'segments': segments.map((e) => e.toJson()).toList(),
        'trends': trends,
        'hooks': hooks,
        'strategy': strategy.toJson(),
        'gallery': gallery.map((e) => e.toJson()).toList(),
        'calendar': calendar?.map((e) => e.toJson()).toList(),
        'done': {for (final i in done) '$i': true},
      };

  void fromJson(Map<String, dynamic> j) {
    brand = BrandInfo.fromJson(j['brand'] ?? {});
    competitors = ((j['competitors'] ?? []) as List)
        .map((e) => Competitor.fromJson(e as Map<String, dynamic>))
        .toList();
    segments = ((j['segments'] ?? []) as List)
        .map((e) => Segment.fromJson(e as Map<String, dynamic>))
        .toList();
    trends = List<String>.from(j['trends'] ?? []);
    hooks = List<String>.from(j['hooks'] ?? []);
    strategy = StrategyState.fromJson(j['strategy'] ?? {});
    gallery = ((j['gallery'] ?? []) as List)
        .map((e) => GalleryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final cal = j['calendar'];
    calendar = cal == null
        ? null
        : (cal as List)
            .map((e) => CalDay.fromJson(e as Map<String, dynamic>))
            .toList();
    done = ((j['done'] ?? {}) as Map)
        .entries
        .where((e) => e.value == true)
        .map((e) => int.tryParse(e.key))
        .whereType<int>()
        .toSet();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    brand = BrandInfo();
    competitors = [];
    segments = [];
    trends = [];
    hooks = [];
    strategy = StrategyState();
    gallery = [];
    calendar = null;
    done = {};
    // keep model choice & API keys; reset only the in-progress work
    step = 0;
    draftTitle = draftPrompt = '';
    _persist();
    notifyListeners();
  }
}
