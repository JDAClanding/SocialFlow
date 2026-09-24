/// Embedded browser for pages that refuse to be iframed (e.g. Meta Ad Library).
/// Real WebView2 on Windows desktop; unavailable on web (browsers enforce
/// Facebook's X-Frame-Options), where callers fall back to the in-app panel.
library;

export 'meta_embed_stub.dart' if (dart.library.io) 'meta_embed_io.dart';
