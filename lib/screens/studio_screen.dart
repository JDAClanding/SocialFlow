library;

import 'package:flutter/material.dart';

import '../api.dart';
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
  String ratio = '1:1';
  bool useRef = true;
  bool generating = false;
  String? genError;
  bool pillarRunning = false;
  String pillarStatus = '';

  static const ratios = {
    '1:1': '1:1 feed',
    '9:16': '9:16 reels/stories',
    '16:9': '16:9 wide',
  };

  Future<void> studioGen() async {
    final p = promptCtrl.text.trim();
    if (p.isEmpty) return toast(context, 'Write a prompt first');
    setState(() {
      generating = true;
      genError = null;
    });
    try {
      final refs = useRef && s.brand.productImages.isNotEmpty
          ? s.brand.productImages.take(1).toList()
          : <String>[];
      final url = await Api.genImage(p, ratio, refs);
      if (!mounted) return;
      setState(() {
        s.gallery.add(GalleryItem(
            url: url,
            title: titleCtrl.text.trim().isEmpty ? 'Visual' : titleCtrl.text.trim(),
            prompt: p,
            pillar: 'custom'));
        s.save();
        generating = false;
      });
      toast(context, 'Added to gallery');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        generating = false;
        genError = 'Failed: $e';
      });
    }
  }

  Future<void> pillarSet() async {
    final pillars = s.strategy.pillars.where((p) => !p.off).toList();
    final b = s.brand;
    final refs = b.productImages.take(1).toList();
    setState(() {
      pillarRunning = true;
      pillarStatus = '';
    });
    var i = 0;
    for (final p in pillars) {
      i++;
      setState(() => pillarStatus = 'Generating $i/${pillars.length}: ${p.name}…');
      try {
        final prompt =
            '${p.name} social media visual for ${b.name.isEmpty ? 'the brand' : b.name} '
            '(${b.product.isEmpty ? 'product' : b.product}). ${p.why}. '
            'Style: ${b.voice.isEmpty ? 'warm, premium' : b.voice}, low-saturation warm '
            'palette, editorial quality, no text, no logos.';
        final url = await Api.genImage(prompt, '1:1', refs);
        s.gallery.add(GalleryItem(url: url, title: p.name, prompt: prompt, pillar: p.name));
        s.save();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          pillarRunning = false;
          genError = 'Failed on ${p.name}: $e';
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() => pillarRunning = false);
    toast(context, 'Pillar set complete!');
  }

  @override
  Widget build(BuildContext context) {
    final b = s.brand;
    final activePillars = s.strategy.pillars.where((p) => !p.off).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          crumb: 'STEP 6 · AI IMAGE STUDIO',
          title: 'Your visual kit',
          lead:
              'Generate campaign visuals in-panel. Your product photos guide the AI so visuals match the real thing.',
        ),
        if (b.productImages.isNotEmpty)
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📸 Product references (from your website)',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 640 ? 6 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final u in b.productImages) Thumb(url: u, onTap: () {}),
                  ],
                ),
              ],
            ),
          )
        else
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add product image links (optional)',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
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
                const Text('Tip: go back to Step 1 and use “Read my site” to pull them automatically.',
                    style: TextStyle(fontSize: 12, color: C.soft)),
              ],
            ),
          ),
        SfCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎨 Generate a visual',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              Field('Title',
                  TextField(controller: titleCtrl, decoration: sfInput('e.g., Liquor pour shot'))),
              Field(
                  'Prompt',
                  TextField(
                      controller: promptCtrl,
                      maxLines: 3,
                      decoration: sfInput(
                          'e.g., Luxury liquor-infused chocolate, warm Goan sunset tones, premium editorial photography'))),
              Field(
                'Ratio',
                DropdownButtonFormField<String>(
                  initialValue: ratio,
                  decoration: sfInput(),
                  items: [
                    for (final e in ratios.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => ratio = v ?? '1:1'),
                ),
              ),
              if (b.productImages.isNotEmpty)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Use my product image as reference',
                      style: TextStyle(fontSize: 12.5)),
                  value: useRef,
                  onChanged: (v) => setState(() => useRef = v ?? true),
                  activeColor: C.green,
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SfButton('⚡ Generate',
                      onPressed: generating || pillarRunning ? null : studioGen),
                  if (generating) ...[
                    const SizedBox(width: 12),
                    const Expanded(child: Thinking('Generating… 1–3 min. You can keep working.')),
                  ],
                ],
              ),
              if (genError != null) ErrText(genError!),
            ],
          ),
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨ One-click: generate a visual for each content pillar',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 6),
              Text(
                  'Creates ${activePillars == 0 ? 5 : activePillars} visuals matched to your strategy'
                  '${b.productImages.isNotEmpty ? ' using your product photo as reference' : ''}.',
                  style: const TextStyle(fontSize: 12.5, color: C.soft)),
              const SizedBox(height: 10),
              Row(
                children: [
                  SfButton('Generate pillar set',
                      alt: true,
                      onPressed: pillarRunning || generating ? null : pillarSet),
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
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Text('Gallery (${s.gallery.length})',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
        ),
        if (s.gallery.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Nothing yet — generate above.',
                style: TextStyle(color: C.soft, fontSize: 13)),
          ),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: .85,
          children: [
            for (final g in s.gallery)
              Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(g.url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: C.soft)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(g.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: C.brand)),
                    Pill(g.pillar, color: C.accent),
                  ],
                ),
              ),
          ],
        ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}
