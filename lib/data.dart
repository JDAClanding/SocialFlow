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
  // Alcohol: every segment is of legal drinking age (LDA). Never target under-LDA.
  'alcohol': [
    AudienceEntry('Young adult explorers (LDA–30)', 'Primary reach',
        'Legal-drinking-age only; discover via reels & creators; try new flavours, RTDs and cocktails; value experiences over labels',
        'Cocktail recipe reels, bartender collabs, event/venue content, age-gated shoppable posts'),
    AudienceEntry('Premium connoisseurs (30–50)', 'Primary revenue',
        'Buy on provenance, ageing, awards and craft; research before buying; brand-loyal once convinced',
        'Distillery/heritage stories, tasting notes, award proof, limited editions'),
    AudienceEntry('Hosts & home entertainers', 'Volume',
        'Plan parties, festivals and weekends; buy multiple bottles; want easy serves',
        'Party-pack bundles, batch-cocktail recipes, festive playlists, pairing guides'),
    AudienceEntry('Gifting & occasion buyers', 'High AOV',
        'Festive, wedding and corporate gifting peaks; packaging and prestige drive choice',
        'Gift boxes, personalised engraving, festive countdowns, corporate gifting guides'),
    AudienceEntry('Mindful drinkers', 'Growth',
        'Drink less but better; interested in low/no-alcohol and responsible serves',
        'Low/no variants, "drink better not more" messaging, mocktail content'),
  ],
  'beauty': [
    AudienceEntry('Gen Z skincare natives (18–27)', 'Primary reach',
        'Learn routines on TikTok; ingredient-literate; love dupes and honest reviews',
        'GRWM videos, creator routines, before/after, ingredient explainers'),
    AudienceEntry('Millennial self-care buyers (28–44)', 'Primary revenue',
        'Pay for results and clean formulas; loyal to what works',
        'Clinical proof, dermatologist content, subscriptions, reviews'),
    AudienceEntry('Gift & festive buyers', 'High AOV',
        'Gift sets and minis spike around festivals', 'Gift sets, advent calendars, bundles'),
    AudienceEntry('Beauty community & creators', 'Advocacy',
        'Share looks, review launches, drive word of mouth', 'Seeding kits, UGC challenges, affiliate codes'),
  ],
  'fashion': [
    AudienceEntry('Trend chasers (18–27)', 'Primary reach',
        'Discover on reels; buy drops fast; style is identity',
        'Outfit reels, try-on hauls, drop countdowns, creator styling'),
    AudienceEntry('Considered buyers (28–44)', 'Primary revenue',
        'Value fit, fabric and longevity; compare before buying',
        'Fabric close-ups, fit guides, reviews, capsule wardrobes'),
    AudienceEntry('Occasion shoppers', 'High AOV',
        'Weddings, festivals, parties drive big baskets', 'Occasion lookbooks, styling services, bundles'),
    AudienceEntry('Sustainable shoppers', 'Brand story',
        'Care about materials, makers and waste', 'Behind-the-seams, material stories, repair/resale'),
  ],
  'tech': [
    AudienceEntry('Early adopters', 'Primary reach',
        'Follow launches and reviewers; buy on specs and hype', 'Teasers, unboxings, spec breakdowns, reviewer seeding'),
    AudienceEntry('Practical upgraders (25–45)', 'Primary revenue',
        'Research heavily; compare prices; want reliability', 'Comparisons, demos, reviews, EMI/offers'),
    AudienceEntry('Gift buyers', 'High AOV',
        'Festive and birthday gifting of gadgets', 'Gift guides, bundles, festive offers'),
    AudienceEntry('Pro / creator users', 'Advocacy',
        'Use the product for work; influence peers', 'Pro workflows, creator collabs, tutorials'),
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
  // alcohol first — "drink" words would otherwise fall into food
  if (RegExp(r'liquor|alcohol|whisk|vodka|\brum\b|\bgin\b|tequila|brandy|wine|beer|spirit|brew|cocktail|scotch|bourbon|champagne|cider|sake')
      .hasMatch(p)) {
    return 'alcohol';
  }
  if (RegExp(r'choco|cocoa|sweet|candy|desser').hasMatch(p)) return 'chocolate';
  if (RegExp(r'skin|beauty|cosmetic|makeup|serum|hair|fragrance|perfume').hasMatch(p)) return 'beauty';
  if (RegExp(r'fashion|apparel|cloth|wear|shoe|sneaker|jewel|bag').hasMatch(p)) return 'fashion';
  if (RegExp(r'tech|phone|gadget|laptop|software|app\b|electronic|headphone|watch').hasMatch(p)) return 'tech';
  if (RegExp(r'food|snack|drink|beverage|sauce|coffee|tea').hasMatch(p)) return 'food';
  return 'generic';
}

/// Universal hooks that work in any category.
const List<String> hookBank = [
  '“POV: you found the limited drop”',
  'Duet-bait: “Rate this 1–10”',
  'Scarcity: “Only 500 today”',
  'Nostalgia hook',
  'ASMR packaging unwrap',
  'Before/after transformation',
  'Tag-a-friend bait',
  '“3 things nobody tells you about…”',
  'Unpopular opinion opener',
  'Behind-the-scenes “how it\'s made”',
];

/// Category-specific hooks, shown before the universal ones.
const Map<String, List<String>> hookLib = {
  'chocolate': [
    'The snap/break in the first 2 seconds',
    '“Crack it open” slow-mo',
    'Gooey cross-section reveal',
    '“POV: it\'s 4pm…”',
    'Dupes vs original',
  ],
  'alcohol': [
    'The perfect pour in slow-mo',
    'Ice-crack & fizz ASMR',
    '“3-ingredient cocktail in 15 seconds”',
    'Bartender vs home-bartender challenge',
    '“POV: you\'re hosting Friday night”',
    'Cask/barrel-to-bottle story',
    'Blind taste-test reactions (of-age creators)',
    'Food-pairing reveal',
    '“Rate my home bar”',
    'Low/no-alcohol mocktail twist',
  ],
  'food': [
    'First-bite reaction',
    'Sizzle / crunch ASMR',
    '“Recipe in 30 seconds”',
    'Cheese-pull / pour close-up',
    '“What I eat in a day” feature',
  ],
  'beauty': [
    'GRWM (get ready with me)',
    'Half-face before/after',
    'Texture swatch close-up',
    '“Derm reacts” / ingredient breakdown',
    '“Dupe or worth it?”',
  ],
  'fashion': [
    'Outfit transition on the beat',
    '“1 piece, 5 ways” styling',
    'Try-on haul with ratings',
    'Fabric close-up & fit check',
    '“Get dressed with me” for an occasion',
  ],
  'tech': [
    'Unboxing in 10 seconds',
    '“Hidden feature you didn\'t know”',
    'Speed/battery test vs rival',
    '“Is it worth the upgrade?”',
    'Setup tour / desk tour',
  ],
};

List<String> hooksFor(String product) {
  final extra = hookLib[catKey(product)] ?? const [];
  return [...extra, ...hookBank.where((h) => !extra.contains(h))];
}

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

/// Auto-tunes the pillar mix (same order as [pillarLib]) from the brand's goal,
/// category, selected segments and trends. Always sums to 100, in steps of 5.
List<int> autoPillarMix(AppState s) {
  // sensory, memes, story, community, shop
  final w = [for (final p in pillarLib) p.pct.toDouble()];
  void add(int i, double v) => w[i] += v;

  final goal = s.brand.goal.toLowerCase();
  if (goal.contains('launch')) {
    add(0, 5); add(1, 5); add(4, -5);
  } else if (goal.contains('follower')) {
    add(1, 10); add(3, 5); add(2, -5); add(4, -10);
  } else if (goal.contains('sales')) {
    add(4, 15); add(0, 5); add(1, -10); add(2, -5); add(3, -5);
  } else if (goal.contains('community')) {
    add(3, 15); add(1, 5); add(0, -5); add(2, -5); add(4, -10);
  }

  if (catKey(s.brand.product) == 'alcohol') {
    add(2, 5); add(1, -5); // heritage/craft sells spirits; keep humour responsible
  }

  var memes = 0, ugc = 0, trends = 0;
  for (final t in s.trends) {
    final c = t.split('|').first;
    if (c == 'memes') memes++;
    if (c == 'ugc') ugc++;
    if (c == 'trends') trends++;
  }
  add(1, (memes * 2).clamp(0, 10).toDouble());
  add(3, (ugc * 2).clamp(0, 10).toDouble());
  add(0, trends.clamp(0, 5).toDouble());

  for (final seg in s.segments) {
    final n = '${seg.name} ${seg.role}'.toLowerCase();
    if (RegExp(r'connoisseur|premium|craft|heritage|story|sustainab|tourist').hasMatch(n)) add(2, 4);
    if (RegExp(r'gift|occasion|aov|revenue|host').hasMatch(n)) add(4, 3);
    if (RegExp(r'community|creator|loyal|advocacy').hasMatch(n)) add(3, 4);
    if (RegExp(r'gen z|trend|explorer|reach').hasMatch(n)) add(1, 2);
  }

  // clamp, normalize to 100 in steps of 5
  for (var i = 0; i < w.length; i++) {
    if (w[i] < 5) w[i] = 5;
  }
  final total = w.reduce((a, b) => a + b);
  final out = [for (final v in w) ((v / total * 100) / 5).round() * 5];
  var diff = 100 - out.reduce((a, b) => a + b);
  while (diff != 0) {
    // push the rounding remainder onto the largest (or trim it)
    final i = out.indexOf(out.reduce((a, b) => a > b ? a : b));
    final step = diff > 0 ? 5 : -5;
    out[i] += step;
    diff -= step;
  }
  return out;
}

/// Visual style presets appended to image prompts.
const Map<String, String> stylePresets = {
  'Editorial': 'premium editorial photography, soft directional light, shallow depth of field',
  'Flat-lay': 'top-down flat-lay composition, styled props, even soft light',
  'Lifestyle': 'candid lifestyle photo, natural light, real-life setting',
  'Studio minimal': 'minimal studio shot, seamless backdrop, crisp product focus',
  'Moody': 'dark moody low-key lighting, rich shadows, cinematic',
  'Bright & bold': 'bright saturated colours, bold graphic composition, high energy',
  '3D render': 'photoreal 3D render, clean materials, studio lighting',
};

class PromptIdea {
  final String label, title, prompt;
  const PromptIdea(this.label, this.title, this.prompt);
}

/// Ready-to-use image prompts built from the brand, strategy pillars and hooks.
List<PromptIdea> promptIdeas(AppState s) {
  final b = s.brand;
  final brand = b.name.trim().isEmpty ? 'the brand' : b.name.trim();
  final product = b.product.trim().isEmpty ? 'the product' : b.product.trim();
  final voice = b.voice.trim().isEmpty ? 'warm, premium' : b.voice.trim();
  final alcohol = catKey(b.product) == 'alcohol';
  final safety = alcohol
      ? ' Any people shown are clearly adults over 25; responsible, no excessive drinking.'
      : '';
  final tail = ' Mood: $voice. No text, no logos, no watermarks.$safety';

  const scenes = {
    'Sensory / product showcase':
        'macro close-up of {p} highlighting texture and detail, a single hero moment mid-action',
    'Relatable & memes':
        'playful everyday scene featuring {p}, relatable moment, expressive and fun',
    'Craft & brand story':
        'behind-the-scenes of how {p} is made, hands at work, authentic craft details',
    'Community & UGC':
        'friends sharing {p}, authentic phone-camera UGC look, candid smiles',
    'Shop & offers':
        '{p} product hero shot with gift-ready packaging, clean space for an offer',
  };

  final ideas = <PromptIdea>[];
  final pillars = s.strategy.pillars.where((p) => !p.off).toList();
  for (final p in pillars.isEmpty ? pillarLib.map((d) => Pillar(name: d.name)).toList() : pillars) {
    final scene = (scenes[p.name] ?? 'on-brand social visual of {p}').replaceAll('{p}', product);
    ideas.add(PromptIdea(p.name, '${p.name} — $brand',
        '${scene[0].toUpperCase()}${scene.substring(1)} for $brand.$tail'));
  }
  for (final h in s.hooks.take(3)) {
    final hook = h.replaceAll(RegExp(r'[“”"]'), '');
    ideas.add(PromptIdea('Hook: ${hook.length > 28 ? '${hook.substring(0, 28)}…' : hook}',
        hook, 'Scroll-stopping visual for "$hook" featuring $product by $brand, first-frame impact.$tail'));
  }
  ideas.add(PromptIdea('Seasonal', 'Festive — $brand',
      'Festive seasonal scene with $product by $brand, warm celebratory lights, gifting mood.$tail'));
  return ideas;
}

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
