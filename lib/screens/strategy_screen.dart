library;

import 'package:flutter/material.dart';

import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class StrategyScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const StrategyScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  final s = AppState.instance;
  final platformCtrl = TextEditingController();
  final cadenceCtrls = <String, TextEditingController>{};
  int _mixVersion = 0; // bumps to refresh the % fields after auto-balance

  static const pillarColors = [C.accent, C.gold, C.brand, C.green, C.rose];

  @override
  void initState() {
    super.initState();
    final st = s.strategy;
    // Auto-select everything on first visit; the user can change any of it.
    if (st.pillars.isEmpty) {
      final mix = autoPillarMix(s);
      st.pillars = [
        for (var i = 0; i < pillarLib.length; i++)
          Pillar(name: pillarLib[i].name, why: pillarLib[i].why, pct: mix[i])
      ];
    }
    if (st.platform.trim().isEmpty) {
      final opts = suggestPlatforms(s.brand);
      if (opts.isNotEmpty) st.platform = opts.first;
    }
    for (final p in plats) {
      st.cadence.putIfAbsent(p, () => cadenceLib[p] ?? '3–5/wk');
    }
    platformCtrl.text = st.platform;
    s.save();
  }

  @override
  void dispose() {
    platformCtrl.dispose();
    for (final c in cadenceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get plats =>
      s.brand.platforms.isNotEmpty ? s.brand.platforms : ['Instagram'];

  int get activeTotal =>
      s.strategy.pillars.where((p) => !p.off).fold(0, (a, p) => a + p.pct);

  void autoBalance() {
    final mix = autoPillarMix(s);
    setState(() {
      final st = s.strategy;
      for (var i = 0; i < st.pillars.length && i < mix.length; i++) {
        st.pillars[i]
          ..pct = mix[i]
          ..off = false;
      }
      _mixVersion++;
      s.save();
    });
    toast(context, 'Mix balanced from your goal, audience & trends');
  }

  /// Rescales active pillars so they add up to exactly 100%.
  void normalize() {
    final active = s.strategy.pillars.where((p) => !p.off).toList();
    final total = activeTotal;
    if (active.isEmpty || total == 0) return;
    setState(() {
      for (final p in active) {
        p.pct = (p.pct * 100 / total).round();
      }
      active.first.pct += 100 - activeTotal;
      _mixVersion++;
      s.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 5 · STRATEGY',
          title: 'Your game plan, composed from your research',
          lead:
              'Built from ${s.competitors.length} competitors, ${s.segments.length} segments, '
              '${s.trends.length} trends and ${s.hooks.length} hooks you selected — pre-selected for you. '
              'Tap anything to adjust.',
        ),
        LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 1000;
          final left = [_platformCard(), _cadenceCard()];
          final right = [_pillarsCard(), _tip()];
          if (!wide) {
            return Column(children: [left[0], right[0], left[1], right[1]]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: Column(children: left)),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: Column(children: right)),
            ],
          );
        }),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }

  Widget _title(String text, {Widget? trailing}) => Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
          ),
          if (trailing != null) trailing,
        ],
      );

  Widget _platformCard() {
    final st = s.strategy;
    final options = suggestPlatforms(s.brand);
    return SfCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('🎯 Brand platform'),
          const SizedBox(height: 4),
          const Text(
              'We picked the strongest one — tap another or write your own.',
              style: TextStyle(fontSize: 12, color: C.soft)),
          const SizedBox(height: 10),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  SelCard(
                    title: '“${options[i]}”',
                    snippet: '',
                    selected: st.platform == options[i],
                    onTap: () => setState(() {
                      st.platform = options[i];
                      platformCtrl.text = options[i];
                      s.save();
                    }),
                  ),
                  if (i == 0)
                    const Positioned(
                        right: 38,
                        top: 10,
                        child: Pill('Recommended', color: C.green)),
                ],
              ),
            ),
          Field(
            'Or write your own',
            TextField(
              controller: platformCtrl,
              decoration: sfInput('One sentence everything hangs on…'),
              onChanged: (v) => setState(() {
                st.platform = v;
                s.save();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillarsCard() {
    final st = s.strategy;
    final total = activeTotal;
    final ok = total == 100;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('🧱 Content pillars',
              trailing: SfButton('✨ Auto-balance',
                  ghost: true, onPressed: autoBalance)),
          const SizedBox(height: 4),
          const Text(
              'Mix pre-set from your goal, audience & trends. Untick to drop a pillar; edit any %.',
              style: TextStyle(fontSize: 12, color: C.soft)),
          const SizedBox(height: 12),
          // stacked mix bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (var i = 0; i < st.pillars.length; i++)
                    if (!st.pillars[i].off && st.pillars[i].pct > 0)
                      Expanded(
                        flex: st.pillars[i].pct,
                        child: Container(
                            color: pillarColors[i % pillarColors.length]),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Total: $total%',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ok ? C.green : C.rose)),
              if (!ok) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: normalize,
                  child: const Text('Fix to 100%',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: C.accent)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < st.pillars.length; i++) _pillarRow(i),
        ],
      ),
    );
  }

  Widget _pillarRow(int i) {
    final st = s.strategy;
    final p = st.pillars[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: p.off ? const Color(0xFFFAF7F2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Checkbox(
            value: !p.off,
            onChanged: (v) => setState(() {
              p.off = !(v ?? false);
              s.save();
            }),
            activeColor: C.green,
          ),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: p.off ? C.line : pillarColors[i % pillarColors.length],
                shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.off ? C.soft : C.brand)),
                Text(p.why,
                    style: const TextStyle(fontSize: 12, color: C.soft)),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: TextFormField(
              key: ValueKey('pct-$i-$_mixVersion'),
              initialValue: '${p.pct}',
              enabled: !p.off,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: sfInput(),
              onChanged: (v) => setState(() {
                p.pct = int.tryParse(v) ?? 0;
                s.save();
              }),
            ),
          ),
          const Text(' %', style: TextStyle(color: C.soft)),
        ],
      ),
    );
  }

  Widget _cadenceCard() {
    final st = s.strategy;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('📅 Weekly cadence per platform'),
          const SizedBox(height: 4),
          const Text(
              'Pre-filled with proven posting rhythms — edit to fit your team.',
              style: TextStyle(fontSize: 12, color: C.soft)),
          for (final p in plats)
            Field(
              p,
              TextField(
                controller: cadenceCtrls.putIfAbsent(
                    p,
                    () => TextEditingController(
                        text: st.cadence[p] ?? cadenceLib[p] ?? '3–5/wk')),
                decoration: sfInput(),
                onChanged: (v) {
                  st.cadence[p] = v;
                  s.save();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _tip() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF4E6),
          borderRadius: BorderRadius.circular(12),
          border: const Border(left: BorderSide(color: C.gold, width: 4)),
        ),
        child: const Text(
            '💡 Rule from the competitor study: ONE long-running platform, refreshed with culture — never replaced. Your calendar in the next steps follows exactly this mix.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6A5A34))),
      );
}
