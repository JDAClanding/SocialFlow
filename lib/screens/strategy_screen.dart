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

  @override
  void initState() {
    super.initState();
    if (s.strategy.pillars.isEmpty) {
      s.strategy.pillars = [
        for (final p in pillarLib) Pillar(name: p.name, why: p.why, pct: p.pct)
      ];
    }
    platformCtrl.text = s.strategy.platform;
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

  @override
  Widget build(BuildContext context) {
    final st = s.strategy;
    final plats = this.plats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 5 · STRATEGY',
          title: 'Your game plan, composed from your research',
          lead:
              'Built from ${s.competitors.length} competitors, ${s.segments.length} segments and ${s.trends.length} trends you selected. Tap to adjust — everything is editable.',
        ),
        SfCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 Brand platform — pick one (or write your own)',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 10),
              for (final p in suggestPlatforms(s.brand))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelCard(
                    title: '“$p”',
                    snippet: '',
                    selected: st.platform == p,
                    onTap: () => setState(() {
                      st.platform = p;
                      platformCtrl.text = p;
                      s.save();
                    }),
                  ),
                ),
              Field(
                'Or write your own',
                TextField(
                  controller: platformCtrl,
                  decoration: sfInput('One sentence everything hangs on…'),
                  onChanged: (v) {
                    st.platform = v;
                    s.save();
                  },
                ),
              ),
            ],
          ),
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Content pillars — tap to toggle, edit the mix',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 10),
              for (var i = 0; i < st.pillars.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.line),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: !st.pillars[i].off,
                        onChanged: (v) => setState(() {
                          st.pillars[i].off = !(v ?? false);
                          s.save();
                        }),
                        activeColor: C.green,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(st.pillars[i].name,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: st.pillars[i].off ? C.soft : C.brand)),
                            Text(st.pillars[i].why,
                                style: const TextStyle(
                                    fontSize: 12, color: C.soft)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: '${st.pillars[i].pct}',
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: sfInput(),
                          onChanged: (v) {
                            st.pillars[i].pct = int.tryParse(v) ?? 0;
                            s.save();
                          },
                        ),
                      ),
                      const Text(' %', style: TextStyle(color: C.soft)),
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
              const Text('Weekly cadence per platform',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              for (final p in plats)
                Field(
                  p,
                  Builder(builder: (context) {
                    cadenceCtrls.putIfAbsent(
                        p,
                        () => TextEditingController(
                            text: st.cadence[p] ?? cadenceLib[p] ?? '3–5/wk'));
                    return TextField(
                      controller: cadenceCtrls[p],
                      decoration: sfInput(),
                      onChanged: (v) {
                        st.cadence[p] = v;
                        s.save();
                      },
                    );
                  }),
                ),
            ],
          ),
        ),
        Container(
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
        ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}
