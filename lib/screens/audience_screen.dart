library;

import 'package:flutter/material.dart';

import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class AudienceScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const AudienceScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  final s = AppState.instance;
  final nameCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final factsCtrl = TextEditingController();
  final convCtrl = TextEditingController();

  List<AudienceEntry> get lib => audienceLib[catKey(s.brand.product)]!;

  void toggleSeg(AudienceEntry e) => setState(() {
        final idx = s.segments.indexWhere((x) => x.name == e.name);
        if (idx >= 0) {
          s.segments.removeAt(idx);
        } else {
          s.segments.add(Segment(
              name: e.name, role: e.role, facts: e.facts, convert: e.convert));
        }
        s.save();
      });

  void addCustom() {
    final n = nameCtrl.text.trim();
    if (n.isEmpty) return toast(context, 'Name your segment');
    setState(() {
      s.segments.add(Segment(
          name: n,
          role: roleCtrl.text.trim(),
          facts: factsCtrl.text.trim(),
          convert: convCtrl.text.trim()));
      nameCtrl.clear();
      roleCtrl.clear();
      factsCtrl.clear();
      convCtrl.clear();
      s.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compNote = s.competitors.isNotEmpty
        ? 'Based on your ${s.competitors.length} competitor${s.competitors.length > 1 ? 's' : ''} and category.'
        : 'Based on your category.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 3 · AUDIENCE',
          title: 'Who are we talking to?',
          lead:
              '$compNote The wizard suggests the segments worth targeting — tap to select. Edit any after selecting.',
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '✨ Suggested segments for ${s.brand.product.isEmpty ? 'your product' : s.brand.product}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 10),
              for (final e in lib)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelCard(
                    title: e.name,
                    snippet: 'Facts: ${e.facts}\nConverts with: ${e.convert}',
                    selected: s.segments.any((x) => x.name == e.name),
                    onTap: () => toggleSeg(e),
                  ),
                ),
            ],
          ),
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('+ Custom segment',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Field('Name',
                        TextField(controller: nameCtrl, decoration: sfInput())),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Field('Role',
                        TextField(controller: roleCtrl, decoration: sfInput('e.g., High AOV'))),
                  ),
                ],
              ),
              Field('Behavior facts',
                  TextField(controller: factsCtrl, maxLines: 3, decoration: sfInput())),
              Field('Converts with',
                  TextField(controller: convCtrl, maxLines: 3, decoration: sfInput())),
              const SizedBox(height: 10),
              SfButton('Add segment', alt: true, onPressed: addCustom),
            ],
          ),
        ),
        if (s.segments.isNotEmpty)
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected (${s.segments.length})',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    for (var i = 0; i < s.segments.length; i++)
                      GestureDetector(
                        onTap: () => setState(() {
                          s.segments.removeAt(i);
                          s.save();
                        }),
                        child: Pill('${s.segments[i].name} ✕', color: C.rose),
                      ),
                  ],
                ),
              ],
            ),
          ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}
