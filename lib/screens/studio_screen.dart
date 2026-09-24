library;

import 'package:flutter/material.dart' hide Thumb;
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class StudioScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const StudioScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final s = AppState.instance;
  final titleCtrl = TextEditingController();
  final promptCtrl = TextEditingController();
  final imgLinkCtrl = TextEditingController();
  final keyCtrls = <String, TextEditingController>{};
  bool useRef = true;
  bool generating = false;
  String? genError;
  String genStatus = '';
  bool pillarRunning = false;
  String pillarStatus = '';
  String? style = 'Editorial';
  int ideaIdx = 0;
  bool showKeys = false;

  List<Map<String, dynamic>> models = [];
  String? modelsError;

  static const ratios = {
    '1:1': '1:1 feed',
    '9:16': '9:16 reels/stories',
    '16:9': '16:9 wide',
  };

  /// Where to get each provider's key.
  static const keyInfo = {
    'KIMI_API_KEY': ('Kimi (sk-kimi-…)', 'https://www.kimi.com/'),
    'FAL_KEY': ('fal.ai', 'https://fal.ai/dashboard/keys'),
    'REPLICATE_API_TOKEN': ('Replicate', 'https://replicate.com/account/api-tokens'),
    'OPENAI_API_KEY': ('OpenAI', 'https://platform.openai.com/api-keys'),
    'GEMINI_API_KEY': ('Google AI Studio', 'https://aistudio.google.com/apikey'),
    'STABILITY_API_KEY': ('Stability AI', 'https://platform.stability.ai/account/keys'),
  };

  @override
  void initState() {
    super.initState();
    titleCtrl.text = s.draftTitle;
    promptCtrl.text = s.draftPrompt;
    if (promptCtrl.text.trim().isEmpty) _applyIdea(0, save: false); // auto-generate
    titleCtrl.addListener(_saveDraft);
    promptCtrl.addListener(_saveDraft);
    for (final k in keyInfo.keys) {
      keyCtrls[k] = TextEditingController(text: s.modelKeys[k] ?? '');
    }
    _loadModels();
  }

  @override
  void dispose() {
    for (final c in [titleCtrl, promptCtrl, imgLinkCtrl, ...keyCtrls.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveDraft() {
    s.draftTitle = titleCtrl.text;
    s.draftPrompt = promptCtrl.text;
    s.save();
  }

  Future<void> _loadModels() async {
    final d = await Api.models();
    if (!mounted) return;
    setState(() {
      if (d['error'] != null) {
        modelsError = d['error'].toString();
      } else {
        models = ((d['models'] ?? []) as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        modelsError = null;
      }
    });
  }

  // ── model helpers ─────────────────────────────────────────────────────
  bool _ready(Map<String, dynamic> m) =>
      m['ready'] == true ||
      (m['key'] != null && (s.modelKeys[m['key']] ?? '').isNotEmpty);

  Map<String, dynamic>? get _selected => s.imageModel == 'auto'
      ? models.where(_ready).firstOrNull // list is sorted cheapest-first
      : models.where((m) => m['id'] == s.imageModel).firstOrNull;

  String _price(num? p) => p == null
      ? ''
      : p == 0
          ? 'Free'
          : '≈\$${p < 0.01 ? p.toStringAsFixed(3) : p.toStringAsFixed(2)}/img';

  void _selectModel(Map<String, dynamic>? m) {
    if (m != null && !_ready(m)) {
      setState(() => showKeys = true);
      toast(context, 'Add a ${m['provider']} API key below to use ${m['name']}');
      return;
    }
    setState(() => s.imageModel = m == null ? 'auto' : m['id'].toString());
    s.save();
  }

  void _saveKeys() {
    setState(() {
      for (final e in keyCtrls.entries) {
        final v = e.value.text.trim();
        if (v.isEmpty) {
          s.modelKeys.remove(e.key);
        } else {
          s.modelKeys[e.key] = v;
        }
      }
    });
    s.save();
    toast(context, 'API keys saved on this device');
  }

  // ── prompts ───────────────────────────────────────────────────────────
  String _withStyle(String prompt) {
    final st = style == null ? null : stylePresets[style];
    return st == null ? prompt : '$prompt Style: $st.';
  }

  void _applyIdea(int i, {bool save = true}) {
    final ideas = promptIdeas(s);
    if (ideas.isEmpty) return;
    ideaIdx = i % ideas.length;
    titleCtrl.text = ideas[ideaIdx].title;
    promptCtrl.text = ideas[ideaIdx].prompt;
    if (save) {
      setState(() {});
      _saveDraft();
    }
  }

  // ── generation ────────────────────────────────────────────────────────
  List<String> get _refs => useRef && s.brand.productImages.isNotEmpty
      ? s.brand.productImages.take(1).toList()
      : <String>[];

  Future<void> studioGen() async {
    final p = promptCtrl.text.trim();
    if (p.isEmpty) return toast(context, 'Write a prompt first');
    setState(() {
      generating = true;
      genError = null;
      genStatus = 'Starting…';
    });
    try {
      final r = await Api.genImageFull(_withStyle(p), s.draftRatio, _refs,
          onModel: (name) {
        if (mounted) setState(() => genStatus = 'Generating with $name…');
      });
      if (!mounted) return;
      final model = r['model_name']?.toString() ?? '';
      setState(() {
        s.gallery.insert(
            0,
            GalleryItem(
                url: r['url']?.toString() ?? '',
                title: titleCtrl.text.trim().isEmpty ? 'Visual' : titleCtrl.text.trim(),
                prompt: p,
                pillar: 'custom',
                model: model));
        s.save();
        generating = false;
      });
      toast(context, 'Added to gallery · $model');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        generating = false;
        genError = 'Failed: $e';
      });
    }
  }

  Future<void> pillarSet() async {
    final ideas = promptIdeas(s)
        .where((i) => pillarLib.any((p) => p.name == i.label) ||
            s.strategy.pillars.any((p) => p.name == i.label))
        .toList();
    setState(() {
      pillarRunning = true;
      pillarStatus = '';
      genError = null;
    });
    var i = 0;
    for (final idea in ideas) {
      i++;
      setState(() => pillarStatus = 'Generating $i/${ideas.length}: ${idea.label}…');
      try {
        final r = await Api.genImageFull(_withStyle(idea.prompt), '1:1', _refs);
        s.gallery.insert(
            0,
            GalleryItem(
                url: r['url']?.toString() ?? '',
                title: idea.label,
                prompt: idea.prompt,
                pillar: idea.label,
                model: r['model_name']?.toString() ?? ''));
        s.save();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          pillarRunning = false;
          genError = 'Failed on ${idea.label}: $e';
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() => pillarRunning = false);
    toast(context, 'Pillar set complete!');
  }

  // ── UI ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(
          crumb: 'STEP 6 · AI IMAGE STUDIO',
          title: 'Your visual kit',
          lead:
              'Prompts are written for you from your strategy — pick a model (the cheapest is chosen automatically) and generate.',
        ),
        SplitView(
          leftFlex: 5,
          rightFlex: 6,
          left: [_modelCard(), _generateCard(), _pillarCard(), _refsCard()],
          right: [_gallery()],
        ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }

  Widget _h(String t, {Widget? trailing}) => Row(
        children: [
          Expanded(
            child: Text(t,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
          ),
          if (trailing != null) trailing,
        ],
      );

  Widget _modelCard() {
    final sel = _selected;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _h('🤖 Image model',
              trailing: SfButton(showKeys ? 'Hide API keys' : '🔑 API keys',
                  ghost: true, onPressed: () => setState(() => showKeys = !showKeys))),
          const SizedBox(height: 4),
          Text(
              sel == null
                  ? 'Loading models…'
                  : s.imageModel == 'auto'
                      ? 'Auto picks the cheapest ready model — now: ${sel['name']} (${_price(sel['price'])}). Falls back to the next one if it fails.'
                      : 'Using ${sel['name']} (${_price(sel['price'])}).',
              style: const TextStyle(fontSize: 12, color: C.soft)),
          if (modelsError != null) ErrText(modelsError!),
          const SizedBox(height: 10),
          _modelTile(null),
          for (final m in models) _modelTile(m),
          if (showKeys) _keysPanel(),
        ],
      ),
    );
  }

  Widget _modelTile(Map<String, dynamic>? m) {
    final auto = m == null;
    final id = auto ? 'auto' : m['id'].toString();
    final on = s.imageModel == id;
    final ready = auto || _ready(m);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => _selectModel(m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFF5F8F2) : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: on ? C.green : C.line, width: on ? 2 : 1.2),
          ),
          child: Row(
            children: [
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18, color: on ? C.green : C.soft),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auto ? '⚡ Auto — cheapest available' : m['name'].toString(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ready ? C.brand : C.soft)),
                    if (!auto && (m['note'] ?? '').toString().isNotEmpty)
                      Text(
                          '${m['note']}${m['refs'] == true ? ' · uses product photo' : ''}',
                          style: const TextStyle(fontSize: 11, color: C.soft)),
                  ],
                ),
              ),
              if (!auto) Pill(_price(m['price'] as num?), color: (m['price'] as num? ?? 0) == 0 ? C.green : C.gold),
              if (!auto && !ready) const Pill('🔑 key', color: C.rose),
              if (auto) const Pill('Recommended', color: C.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keysPanel() => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.cream, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔑 Model API keys',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: C.brand)),
            const SizedBox(height: 4),
            const Text(
                'Saved only on this device and sent only to your SOCIALFLOW server when generating. '
                'Never included in shared client links. Keys set on the server (env vars) work without this.',
                style: TextStyle(fontSize: 11.5, color: C.soft, height: 1.35)),
            for (final e in keyInfo.entries)
              Field(
                '${e.value.$1} · ${e.key}',
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: keyCtrls[e.key],
                        obscureText: true,
                        decoration: sfInput('Paste key…'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(e.value.$2)),
                      child: const Text('Get key ↗',
                          style: TextStyle(fontSize: 12, color: C.accent)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SfButton('Save keys', onPressed: _saveKeys),
          ],
        ),
      );

  Widget _generateCard() {
    final b = s.brand;
    final ideas = promptIdeas(s);
    final sel = _selected;
    final refsUsed = _refs.isNotEmpty && (sel == null || sel['refs'] == true);
    final title = Field('Title',
        TextField(controller: titleCtrl, decoration: sfInput('e.g., Liquor pour shot')));
    final ratioField = Field(
      'Ratio',
      DropdownButtonFormField<String>(
        initialValue: ratios.containsKey(s.draftRatio) ? s.draftRatio : '1:1',
        isExpanded: true,
        decoration: sfInput(),
        items: [
          for (final e in ratios.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          s.draftRatio = v ?? '1:1';
          s.save();
        },
      ),
    );
    return SfCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _h('🎨 Generate a visual',
              trailing: SfButton('🎲 New idea',
                  ghost: true, onPressed: () => _applyIdea(ideaIdx + 1))),
          const SizedBox(height: 8),
          const Text('Prompt ideas from your strategy — tap one:',
              style: TextStyle(fontSize: 12, color: C.soft)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < ideas.length; i++)
                ChoiceChip(
                  label: Text(ideas[i].label, style: const TextStyle(fontSize: 11.5)),
                  selected: i == ideaIdx && promptCtrl.text == ideas[i].prompt,
                  showCheckmark: false,
                  selectedColor: C.brand,
                  labelStyle: TextStyle(
                      color: i == ideaIdx && promptCtrl.text == ideas[i].prompt
                          ? Colors.white
                          : C.brand),
                  onSelected: (_) => _applyIdea(i),
                ),
            ],
          ),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 520
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: title),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: ratioField),
                    ],
                  )
                : Column(children: [title, ratioField]),
          ),
          Field(
              'Prompt (edit freely)',
              TextField(
                  controller: promptCtrl,
                  minLines: 3,
                  maxLines: 7,
                  decoration: sfInput('Describe the visual…'))),
          Field(
            'Style',
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final st in ['None', ...stylePresets.keys])
                  ChoiceChip(
                    label: Text(st, style: const TextStyle(fontSize: 11.5)),
                    selected: (style ?? 'None') == st,
                    showCheckmark: false,
                    selectedColor: C.accent,
                    labelStyle: TextStyle(
                        color: (style ?? 'None') == st ? Colors.white : C.brand),
                    onSelected: (_) => setState(() => style = st == 'None' ? null : st),
                  ),
              ],
            ),
          ),
          if (b.productImages.isNotEmpty)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                  refsUsed || !useRef
                      ? 'Use my product image as reference'
                      : 'Use my product image as reference (only Kimi supports this — Auto will prefer it)',
                  style: const TextStyle(fontSize: 12.5)),
              value: useRef,
              onChanged: (v) => setState(() => useRef = v ?? true),
              activeColor: C.green,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              SfButton(
                  sel == null ? '⚡ Generate' : '⚡ Generate · ${_price(sel['price'])}',
                  onPressed: generating || pillarRunning ? null : studioGen),
              if (generating) ...[
                const SizedBox(width: 12),
                Expanded(child: Thinking(genStatus)),
              ],
            ],
          ),
          if (genError != null) ErrText(genError!),
        ],
      ),
    );
  }

  Widget _pillarCard() {
    final n = promptIdeas(s).where((i) => !i.label.startsWith('Hook') && i.label != 'Seasonal').length;
    final sel = _selected;
    final price = (sel?['price'] as num?) ?? 0;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _h('✨ One-click pillar set'),
          const SizedBox(height: 6),
          Text(
              'Creates $n visuals — one per content pillar, prompts auto-written'
              '${style != null ? ', $style style' : ''}. '
              'Est. cost: ${price == 0 ? 'free' : '≈\$${(price * n).toStringAsFixed(2)}'}.',
              style: const TextStyle(fontSize: 12.5, color: C.soft)),
          const SizedBox(height: 10),
          Row(
            children: [
              SfButton('Generate pillar set',
                  alt: true, onPressed: pillarRunning || generating ? null : pillarSet),
              if (pillarRunning) ...[
                const SizedBox(width: 12),
                Expanded(
                    child: Text(pillarStatus,
                        style: const TextStyle(fontSize: 12.5, color: C.soft))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _refsCard() {
    final b = s.brand;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _h(b.productImages.isNotEmpty
              ? '📸 Product references (${b.productImages.length})'
              : '📸 Product image links (optional)'),
          const SizedBox(height: 10),
          if (b.productImages.isNotEmpty)
            LayoutBuilder(
              builder: (context, box) => GridView.count(
                crossAxisCount: gridCols(box.maxWidth, minTile: 90, min: 3),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final u in b.productImages) Thumb(url: u, onTap: () {}),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: imgLinkCtrl,
                  decoration: sfInput('https://…/product.jpg'),
                ),
              ),
              const SizedBox(width: 8),
              SfButton('Add', alt: true, onPressed: () {
                final u = imgLinkCtrl.text.trim();
                if (u.isNotEmpty) {
                  setState(() {
                    b.productImages.add(u);
                    s.save();
                    imgLinkCtrl.clear();
                  });
                }
              }),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Tip: Step 1 “Read my site” pulls them automatically.',
              style: TextStyle(fontSize: 12, color: C.soft)),
        ],
      ),
    );
  }

  Widget _gallery() {
    final desktop = Responsive.isDesktop(context);
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🖼 Gallery (${s.gallery.length})',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
          const SizedBox(height: 10),
          if (s.gallery.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
              decoration: BoxDecoration(
                  color: C.cream, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Icon(Icons.image_outlined, size: 40, color: C.accent),
                  const SizedBox(height: 8),
                  Text(
                      desktop
                          ? 'Nothing yet — a prompt is ready on the left, just hit Generate.'
                          : 'Nothing yet — a prompt is ready above, just hit Generate.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: C.soft, fontSize: 13)),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, box) => GridView.count(
              crossAxisCount: gridCols(box.maxWidth, minTile: 200),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .8,
              children: [for (var i = 0; i < s.gallery.length; i++) _galleryTile(i)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryTile(int i) {
    final g = s.gallery[i];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(Api.img(g.url),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, color: C.soft)),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        s.gallery.removeAt(i);
                        s.save();
                      }),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(g.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: C.brand)),
          Wrap(children: [
            Pill(g.pillar, color: C.accent),
            if (g.model.isNotEmpty) Pill(g.model, color: C.blue),
          ]),
        ],
      ),
    );
  }
}
