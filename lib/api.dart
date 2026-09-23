/// API client — talks to the deployed SOCIALFLOW Flask server.
/// The Kimi credential stays server-side; this app only calls the HTTP API.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

class Api {
  // ⚠️ REQUIRED: paste your deployed server URL here (Render / Railway),
  //    e.g. 'https://socialflow-xxxx.onrender.com' — no trailing slash.
  static const String baseUrl = 'https://your-app.onrender.com';

  static const _timeout = Duration(seconds: 90);

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(_timeout);
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': 'AI engine unreachable — set your server URL in lib/api.dart'};
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
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': 'AI engine unreachable — set your server URL in lib/api.dart'};
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

  /// Step 2 — plain search (competitor suggestions).
  static Future<Map<String, dynamic>> search(String q) =>
      _get('/api/search?q=${_q(q)}');

  /// Steps 6/7 — start an image job. Returns the job id.
  static Future<String> startGenImage(
      String prompt, String ratio, List<String> refs) async {
    final d = await _post('/api/genimage', {
      'prompt': prompt,
      'ratio': ratio,
      if (refs.isNotEmpty) 'reference_image_urls': refs,
    });
    if (d['error'] != null) throw Exception(d['error']);
    return d['job'] as String;
  }

  static Future<Map<String, dynamic>> genImageStatus(String job) =>
      _get('/api/genimage/$job');

  /// Convenience: submit + poll until done. Throws on error.
  static Future<String> genImage(
      String prompt, String ratio, List<String> refs) async {
    final job = await startGenImage(prompt, ratio, refs);
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 5));
      final s = await genImageStatus(job);
      if (s['status'] == 'done') return s['url'] as String? ?? '';
      if (s['status'] == 'error') {
        throw Exception(s['error'] ?? 'generation failed');
      }
    }
    throw Exception('Timed out — try again');
  }

  /// Dashboard — save project, returns the share path ('/p/<id>').
  static Future<String> saveProject(String name, Map<String, dynamic> data) async {
    final d = await _post('/api/project', {'name': name, 'data': data});
    if (d['error'] != null) throw Exception(d['error']);
    return d['path'] as String? ?? '';
  }

  static Future<Map<String, dynamic>> getProject(String pid) =>
      _get('/api/project/$pid');
}
