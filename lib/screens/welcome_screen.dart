library;

import 'package:flutter/material.dart';

import '../state.dart';
import '../widgets.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart, onDashboard;
  const WelcomeScreen(
      {super.key, required this.onStart, required this.onDashboard});

  static const _features = [
    _Feature('🔍', 'Live research',
        'Brand & competitor intel pulled from the web as you type names — tap to select.'),
    _Feature('🧠', 'AI suggestions',
        'Audiences, trends, hooks and strategy pre-answered from your research.'),
    _Feature('🎨', 'Image studio',
        'Your website\'s product photos pulled automatically; AI visuals generated in-panel.'),
    _Feature('🔗', 'Client link',
        'One click → a clean read-only calendar link to send your customer.'),
  ];

  static const _steps = [
    'Brand',
    'Competitors',
    'Audience',
    'Trends',
    'Strategy',
    'AI Studio',
    'Calendar',
    'Dashboard',
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: mobile ? 8 : 28),
            LayoutBuilder(builder: (context, box) {
              final split = box.maxWidth >= 900;
              final hero = _hero(context, centered: !split);
              const preview = _CalendarPreview();
              if (!split) {
                return Column(
                    children: [hero, const SizedBox(height: 28), preview]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 11, child: hero),
                  const SizedBox(width: 48),
                  const Expanded(flex: 10, child: preview),
                ],
              );
            }),
            SizedBox(height: mobile ? 32 : 56),
            _featureGrid(),
            const SizedBox(height: 4),
            _howItWorks(mobile),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, {required bool centered}) {
    final s = AppState.instance;
    final mobile = Responsive.isMobile(context);
    final brand = s.brand.name.trim();
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: C.cream, borderRadius: BorderRadius.circular(20)),
          child: const Text('✨ AI SOCIAL CAMPAIGN WIZARD',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.2,
                  color: C.accent,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Build a month of social media '),
            TextSpan(
                text: 'in one sitting.',
                style: TextStyle(color: C.accent.withValues(alpha: .95))),
          ]),
          textAlign: align,
          style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: mobile ? 32 : 50,
              height: 1.12,
              color: C.brand,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Type a brand name. The wizard researches it live, analyzes competitors, '
            'suggests audiences, trends and strategy — you just tap to select. Then it '
            'generates your 30-day calendar, visuals included, with a link to send your client.',
            textAlign: align,
            style: TextStyle(
                color: C.soft, fontSize: mobile ? 14.5 : 16.5, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            SfButton('Start building →', big: true, onPressed: onStart),
            if (brand.isNotEmpty)
              SfButton('Continue $brand',
                  big: true, alt: true, onPressed: onDashboard),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: const [
            _Check('Live web research'),
            _Check('30 days of posts'),
            _Check('Shareable client link'),
          ],
        ),
      ],
    );
  }

  Widget _featureGrid() => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 900 ? 4 : (box.maxWidth >= 520 ? 2 : 1);
        final rows = <Widget>[];
        for (var i = 0; i < _features.length; i += cols) {
          final chunk = _features.skip(i).take(cols).toList();
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: 14),
                  Expanded(
                      child: j < chunk.length
                          ? chunk[j]
                          : const SizedBox.shrink()),
                ],
              ],
            ),
          ));
        }
        return Column(children: rows);
      });

  Widget _howItWorks(bool mobile) => SfCard(
        child: Column(
          children: [
            const Text('HOW IT WORKS · 8 STEPS',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: C.accent,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: C.cream, shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: C.brand)),
                      ),
                      const SizedBox(width: 6),
                      Text(_steps[i],
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: C.brand)),
                    ],
                  ),
                  if (i < _steps.length - 1 && !mobile)
                    const Text('→',
                        style: TextStyle(color: C.line, fontSize: 16)),
                ],
              ],
            ),
          ],
        ),
      );
}

class _Check extends StatelessWidget {
  final String text;
  const _Check(this.text);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: C.green),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, color: C.soft)),
        ],
      );
}

/// Right-hand hero visual: two weeks of the calendar — the user's real one if
/// generated, otherwise a representative sample.
class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview();

  static const _sample = [
    ('Pour in slow-mo', 'Awareness'),
    ('Meme Monday', 'Engagement'),
    ('Behind the craft', 'Engagement'),
    ('Rate this 1–10', 'Engagement'),
    ('Gift guide', 'Conversion'),
    ('Fan repost', 'Advocacy'),
    ('Weekend bundle', 'Conversion'),
    ('Texture close-up', 'Awareness'),
    ('POV: Friday 6pm', 'Engagement'),
    ('Founder story', 'Engagement'),
    ('UGC challenge', 'Advocacy'),
    ('Drop teaser', 'Awareness'),
    ('Limited drop', 'Conversion'),
    ('Thank-you reel', 'Advocacy'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final cal = s.calendar;
    final real = cal != null && cal.length >= 14;
    final days =
        real ? [for (final c in cal.take(14)) (c.title, c.stage)] : _sample;
    final brand = s.brand.name.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A5B3A29), blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    real && brand.isNotEmpty
                        ? '$brand · 30-day calendar'
                        : '30-day calendar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
              ),
              Pill(real ? 'Your plan' : 'Preview',
                  color: real ? C.green : C.gold),
            ],
          ),
          for (var w = 0; w < 2; w++) ...[
            const SizedBox(height: 14),
            Text('Week ${w + 1}',
                style: const TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: C.accent)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  if (d > 0) const SizedBox(width: 6),
                  Expanded(child: _DayTile(w * 7 + d + 1, days[w * 7 + d])),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final st in [
                'Awareness',
                'Engagement',
                'Conversion',
                'Advocacy'
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: stageColor(st), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(st,
                        style: const TextStyle(fontSize: 11, color: C.soft)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final int day;
  final (String, String) item;
  const _DayTile(this.day, this.item);

  @override
  Widget build(BuildContext context) {
    final color = stageColor(item.$2);
    return LayoutBuilder(builder: (context, box) {
      final tiny =
          box.maxWidth < 64; // phones: 7 tiles ≈ 40px — day number only
      return AspectRatio(
        aspectRatio: tiny ? .9 : .72,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
          decoration: BoxDecoration(
            color: Color.alphaBlend(color.withValues(alpha: .10), Colors.white),
            borderRadius: BorderRadius.circular(9),
            border: Border(top: BorderSide(color: color, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$day',
                  style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.accent)),
              if (!tiny) ...[
                const Spacer(),
                Text(item.$1,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: C.brand)),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _Feature extends StatelessWidget {
  final String icon, title, body;
  const _Feature(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: C.cream, borderRadius: BorderRadius.circular(11)),
            child: Text(icon, style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
          const SizedBox(height: 6),
          Text(body,
              style:
                  const TextStyle(fontSize: 13, color: C.soft, height: 1.45)),
        ],
      ),
    );
  }
}
