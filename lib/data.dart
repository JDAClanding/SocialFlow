/// Static libraries and the calendar generator — ported 1:1 from the
/// original SOCIALFLOW web wizard (static/index.html).
library;

import 'state.dart';

class AudienceEntry {
  final String name, role, facts, convert;
  const AudienceEntry(this.name, this.role, this.facts, this.convert);
}

const Map<String, List<AudienceEntry>> audienceLib = {
  'chocolate': [
    AudienceEntry('Gen Z snackers (18–27)', 'Primary reach',
        'Impulse buyers; texture/sound drives cravings; TikTok-first; distrust obvious AI content',
        'ASMR reels, memes, challenges, drop FOMO, shoppable video'),
    AudienceEntry('Millennial treaters (28–44)', 'Primary revenue',
        'Buy via FB/IG; read reviews; nostalgia works; deliberate purchasers',
        'Testimonials, recipes, bundles, retargeting with UGC'),
    AudienceEntry('Gifting buyers', 'High order value',
        'Packaging is the #1 gift purchase driver; festive spikes',
        'Unboxings, gift guides, personalization, festive countdowns'),
    AudienceEntry('Experience seekers / tourists', 'Brand story',
        'Want unique local stories; share novelty finds; gift regional specialties',
        'Origin stories, "only here" exclusivity, collabs with local creators'),
  ],
  'food': [
    AudienceEntry('Gen Z foodies (18–27)', 'Primary reach',
        'Discover via TikTok; visual-first; impulse orders',
        'ASMR, recipe shorts, creator collabs'),
    AudienceEntry('Busy professionals (25–40)', 'Primary revenue',
        'Convenience + quality; lunch/snack occasions',
        'Quick recipes, bundles, subscription offers'),
    AudienceEntry('Family shoppers', 'Repeat buyers',
        'Value, trust, ingredients matter',
        'Transparency posts, family moments, offers'),
    AudienceEntry('Gifting & occasion buyers', 'High AOV',
        'Festive and celebration spikes',
        'Gift guides, festive bundles'),
  ],
  'generic': [
    AudienceEntry('Gen Z (18–27)', 'Primary reach',
        'Impulse-driven; short video natives; trust creators over ads',
        'Trends, memes, challenges, shoppable video'),
    AudienceEntry('Millennials (28–44)', 'Primary revenue',
        'Research before buying; respond to proof and reviews',
        'Testimonials, demos, offers, retargeting'),
    AudienceEntry('Gift & occasion buyers', 'High AOV',
        'Buy around events; presentation matters',
        'Unboxings, gift guides, festive content'),
    AudienceEntry('Loyal community', 'Advocacy',
        'Engaged followers who share and refer',
        'UGC challenges, reposts, referral rewards'),
  ],
};

String catKey(String product) {
  final p = product.toLowerCase();
  if (RegExp(r'choco|cocoa|sweet|candy|desser').hasMatch(p)) return 'chocolate';
  if (RegExp(r'food|snack|drink|beverage|sauce|coffee|tea').hasMatch(p)) return 'food';
  return 'generic';
}

const List<String> hookBank = [
  'The snap/break in the first 2 seconds',
  '“Crack it open” slow-mo',
  'Gooey cross-section reveal',
  '“POV: you found the limited drop”',
  'Duet-bait: “Rate this 1–10”',
  'Scarcity: “Only 500 today”',
  'Nostalgia hook',
  'ASMR packaging unwrap',
  'Dupes vs original',
  'Before/after transformation',
  '“POV: it\'s 4pm…”',
  'Tag-a-friend bait',
];

class PillarDef {
  final String name;
  final int pct;
  final String why;
  const PillarDef(this.name, this.pct, this.why);
}

const List<PillarDef> pillarLib = [
  PillarDef('Sensory / product showcase', 30,
      'Reach engine — texture, sound, crave visuals'),
  PillarDef('Relatable & memes', 20,
      'Share engine — humor, POV, cultural moments'),
  PillarDef('Craft & brand story', 15,
      'Trust engine — BTS, sourcing, founder, values'),
  PillarDef('Community & UGC', 20,
      'Loyalty engine — reposts, polls, contests, creators'),
  PillarDef('Shop & offers', 15,
      'Revenue engine — shoppable posts, drops, codes, bundles'),
];

const Map<String, String> cadenceLib = {
  'Instagram': '4–5 feed/wk + 1 Reel/day + 2–3 Stories/day',
  'TikTok': '1 post/day',
  'YouTube': '1 long-form/wk + 2–3 Shorts/wk',
  'X': '1–2/day + replies',
  'Facebook': '4–5/wk',
  'LinkedIn': '2–3/wk',
  'Pinterest': '3–5 pins/wk',
};

List<String> suggestPlatforms(BrandInfo b) {
  final v = (b.voice.split(RegExp(r'[,,]')).first.trim());
  final first = v.isEmpty ? 'your moment' : v;
  final p = b.product.isEmpty ? 'our product' : b.product;
  final lastWord = p.split(' ').last;
  return [
    'Every break deserves better $lastWord.',
    'Made for the ones who ${first == 'warm' ? 'share' : 'dare'}.',
    'Not just $p. A whole mood.',
  ];
}

const Map<String, String> pillarStage = {
  'Sensory / product showcase': 'Awareness',
  'Relatable & memes': 'Engagement',
  'Craft & brand story': 'Engagement',
  'Community & UGC': 'Advocacy',
  'Shop & offers': 'Conversion',
};

const Map<String, String> stageCta = {
  'Awareness': 'Follow + share this',
  'Engagement': 'Comment / vote / save',
  'Conversion': 'Shop now — link in bio',
  'Advocacy': 'Post yours with our hashtag',
};

const Map<String, List<List<String>>> ideas = {
  'Sensory / product showcase': [
    ['ASMR: the snap', '10s macro break-sound loop, no music'],
    ['ASMR: the unwrap', 'Foil unwrap + snap, binaural'],
    ['Slow-mo cross-section', 'Gooey center reveal in first 2s'],
    ['Texture montage', 'Pour/drip/snap to trending audio'],
    ['Hero flat-lay', 'Premium styling + packaging detail'],
  ],
  'Relatable & memes': [
    ['POV: 4pm slump', 'POV meme video, relatable workplace'],
    ['Relatable meme remix', '“Me: just one piece. The box:”'],
    ['Trend-jack (flex)', 'Remix this week\'s trend to your platform'],
    ['Duet-bait taste test', '“Rate this 1–10”'],
    ['This-or-that poll', 'Team A vs Team B, wrong answers only'],
  ],
  'Craft & brand story': [
    ['Founder story', '3–5 min: why the brand exists'],
    ['BTS: how it\'s made', 'Process video, hands & craft'],
    ['Educational carousel', 'The craft/science behind it'],
    ['Meet the maker', 'People & sourcing story'],
    ['Values post', 'Sustainability/transparency'],
  ],
  'Community & UGC': [
    ['UGC repost roundup', 'Repost best tagged content'],
    ['Testimonial reel', '“Real people, real moments” compilation'],
    ['Hashtag challenge push', 'Prompt entries'],
    ['Giveaway: tag a friend', '“Tag your buddy — you both win”'],
    ['Comment-bait question', 'Fun divisive question'],
  ],
  'Shop & offers': [
    ['Drop teaser', '“500 units. 72 hours. Gone.”'],
    ['Scarcity BTS', '“Hand-wrapping every unit for Friday”'],
    ['DROP DAY', 'Shoppable posts all day + hourly Stories'],
    ['Sold-out social proof', '“You cleared it in __ hours”'],
    ['Follower-only code', '24h flash code'],
    ['Gifting angle', 'Gift-guide + personalization reel'],
  ],
};

/// Port of genCalendar() from the web wizard.
List<CalDay> generateCalendar(AppState s) {
  final pillars = s.strategy.pillars.where((p) => !p.off).toList();
  final pool = <String>[];
  for (final p in pillars) {
    for (var i = 0; i < [1, (p.pct / 10).round()].reduce((a, b) => a > b ? a : b); i++) {
      pool.add(p.name);
    }
  }
  final plats = s.brand.platforms.isNotEmpty ? s.brand.platforms : ['Instagram'];
  final galByPillar = <String, List<String>>{};
  for (final g in s.gallery) {
    galByPillar.putIfAbsent(g.pillar, () => []).add(g.url);
  }
  final cal = <CalDay>[];
  final used = <String, int>{};
  List<String> pickIdea(String pillar, int day) {
    if (day == 15) return ideas['Shop & offers']![0];
    if (day == 16) return ideas['Shop & offers']![1];
    if (day == 17) return ['Creator co-hosted giveaway', 'Live unbox + giveaway with a creator'];
    if (day == 18) return ideas['Shop & offers']![2];
    if (day == 19) return ideas['Shop & offers']![3];
    if (day == 30) return ['Month recap + thank you', 'Montage + stats + next-month tease'];
    final o = ideas[pillar] ?? ideas['Relatable & memes']!;
    used[pillar] = (used[pillar] ?? 0) + 1;
    return o[(used[pillar]! - 1) % o.length];
  }

  for (var d = 1; d <= 30; d++) {
    String pillar;
    if (d >= 15 && d <= 19) {
      pillar = (d == 17) ? 'Community & UGC' : 'Shop & offers';
    } else if (d == 30) {
      pillar = 'Community & UGC';
    } else {
      pillar = pool.isEmpty ? 'Relatable & memes' : pool[(d - 1) % pool.length];
    }
    final idea = pickIdea(pillar, d);
    final stage = pillarStage[pillar] ?? 'Engagement';
    final gal = galByPillar[pillar] ?? galByPillar['custom'] ?? <String>[];
    final hook = s.hooks.isNotEmpty
        ? s.hooks[d % s.hooks.length]
        : hookBank[d % hookBank.length];
    final c = CalDay(
      day: d,
      title: idea[0],
      stage: stage,
      pillar: pillar,
      platforms: plats.take(3).join(' · '),
      format: idea[1],
      hook: hook,
      cta: stageCta[stage] ?? '',
    );
    if (gal.isNotEmpty) c.refImage = gal[(d - 1) % gal.length];
    c.imgPrompt =
        '$pillar social media visual for ${s.brand.name.isEmpty ? 'brand' : s.brand.name} '
        '(${s.brand.product.isEmpty ? 'product' : s.brand.product}). Post: "${idea[0]}" — '
        '${idea[1]}. Style: ${s.brand.voice.isEmpty ? 'warm, premium' : s.brand.voice}, '
        'warm low-saturation palette, editorial quality, no text, no logos.';
    cal.add(c);
  }
  return cal;
}

/// Port of copyCal() — plain-text export of the calendar.
String calendarAsText(AppState s) {
  final b = StringBuffer()
    ..writeln('${s.brand.name.isEmpty ? 'BRAND' : s.brand.name} — 30-DAY CALENDAR')
    ..writeln('Platform: ${s.strategy.platform}')
    ..writeln();
  for (final c in s.calendar ?? <CalDay>[]) {
    b
      ..writeln('DAY ${c.day} [${c.stage}] ${c.title}')
      ..writeln('  ${c.platforms}')
      ..writeln('  Format: ${c.format}')
      ..writeln('  Hook: ${c.hook}')
      ..writeln('  CTA: ${c.cta}')
      ..writeln('  Visual: ${c.refImage.isEmpty ? '-' : c.refImage}')
      ..writeln('  Img prompt: ${c.imgPrompt.isEmpty ? '-' : c.imgPrompt}')
      ..writeln();
  }
  return b.toString();
}
