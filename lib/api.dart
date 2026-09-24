/// API client — talks to the deployed SOCIALFLOW Flask server.
/// The Kimi credential stays server-side; this app only calls the HTTP API.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'state.dart';

class Api {
  // Server URL (no trailing slash). Set it at build/run time:
  //   flutter run --dart-define=API_URL=https://socialflow-xxxx.onrender.com
  // Defaults to the local server (`python server.py` → port 8080).
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

  static const _timeout = Duration(seconds: 90);

  static const _unreachable =
      'Can\'t reach the SOCIALFLOW server at $baseUrl — start it (python server.py) '
      'or run with --dart-define=API_URL=<your server URL>';

  static Map<String, dynamic> _decode(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {'error': 'Server error (${r.statusCode})'};
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(_timeout);
      return _decode(r);
    } catch (_) {
      return {'error': _unreachable};
    }
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final r = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(r);
    } catch (_) {
      return {'error': _unreachable};
    }
  }

  static String _q(String s) => Uri.encodeQueryComponent(s);

  /// Step 1 — read a website, extract product images + text.
  static Future<Map<String, dynamic>> siteImages(String url) =>
      _get('/api/siteimages?url=${_q(url)}');

  /// Step 2 — auto-analyze a competitor (handles, followers, campaigns).
  static Future<Map<String, dynamic>> analyze(String name) =>
      _get('/api/analyze?name=${_q(name)}');

  /// Steps 2 & 4 — categorized research cards (campaigns/stats/ugc/trends/memes).
  static Future<Map<String, dynamic>> suggest(String base, List<String> cats) =>
      _get('/api/suggest?base=${_q(base)}&cats=${cats.join(',')}');

  /// Step 2 — competitor's winning creatives (image search, by category).
  static Future<Map<String, dynamic>> graphics(String name) =>
      _get('/api/graphics?name=${_q(name)}');

  /// Step 2 — competitor's Meta (Facebook/Instagram) ads for the in-app panel.
  /// mode 'api' = official Ad Library API; 'search' = image-search fallback.
  static Future<Map<String, dynamic>> metaAds(String name) =>
      _get('/api/metaads?name=${_q(name)}');

  /// Search-image CDN has no CORS, so the web build loads it via the server.
  static String img(String url) => kIsWeb &&
          (url.startsWith('https://kimi-web-img.kimi.ai/') ||
              url.startsWith('https://kimi-web-img.moonshot.cn/'))
      ? '$baseUrl/api/img?u=${_q(url)}'
      : url;

  /// Step 2 — plain search (competitor suggestions).
  static Future<Map<String, dynamic>> search(String q) =>
      _get('/api/search?q=${_q(q)}');

  /// Step 6 — image models, cheapest first (id, name, provider, price, key, ready…).
  static Future<Map<String, dynamic>> models() => _get('/api/models');

  /// Steps 6/7 — start an image job. Returns the job id.
  /// [model] defaults to the user's saved choice ('auto' = cheapest available);
  /// the user's own API keys ride along for models the server has no key for.
  static Future<String> startGenImage(String prompt, String ratio, List<String> refs,
      {String? model}) async {
    final s = AppState.instance;
    final d = await _post('/api/genimage', {
      'prompt': prompt,
      'ratio': ratio,
      'model': model ?? s.imageModel,
      if (s.modelKeys.isNotEmpty) 'keys': s.modelKeys,
      if (refs.isNotEmpty) 'reference_image_urls': refs,
    });
    if (d['error'] != null) throw Exception(d['error']);
    return d['job'] as String;
  }

  static Future<Map<String, dynamic>> genImageStatus(String job) =>
      _get('/api/genimage/$job');

  /// Submit + poll until done. Returns {url, model_name, price}. Throws on error.
  static Future<Map<String, dynamic>> genImageFull(
      String prompt, String ratio, List<String> refs,
      {String? model, void Function(String modelName)? onModel}) async {
    final job = await startGenImage(prompt, ratio, refs, model: model);
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 3));
      final st = await genImageStatus(job);
      if (st['model_name'] != null) onModel?.call(st['model_name'].toString());
      if (st['status'] == 'done') return st;
      if (st['status'] == 'error') {
        throw Exception(st['error'] ?? 'generation failed');
      }
    }
    throw Exception('Timed out — try again');
  }

  /// Convenience: returns just the image URL.
  static Future<String> genImage(String prompt, String ratio, List<String> refs,
          {String? model}) async =>
      (await genImageFull(prompt, ratio, refs, model: model))['url']?.toString() ?? '';

  /// Dashboard — save project, returns the share path ('/p/<id>').
  static Future<String> saveProject(String name, Map<String, dynamic> data) async {
    final d = await _post('/api/project', {'name': name, 'data': data});
    if (d['error'] != null) throw Exception(d['error']);
    return d['path'] as String? ?? '';
  }

  static Future<Map<String, dynamic>> getProject(String pid) =>
      _get('/api/project/$pid');
}
