library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../widgets.dart';

class BrandScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const BrandScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final s = AppState.instance;
  final siteCtrl = TextEditingController();
  bool loadingSite = false;
  String? siteError;
  List<String> siteImages = [];
  bool imagesLoaded = false;

  static const goals = [
    'Launch / awareness',
    'Follower growth',
    'Sales & conversions',
    'Community & UGC',
    'Full funnel (recommended)',
  ];
  static const allPlatforms = [
    'Instagram', 'TikTok', 'YouTube', 'X', 'Facebook', 'LinkedIn', 'Pinterest'
  ];

  @override
  void initState() {
    super.initState();
    siteCtrl.text = s.brand.website;
  }

  Future<void> fetchSite() async {
    final url = siteCtrl.text.trim();
    if (url.isEmpty) return toast(context, 'Enter your website URL first');
    setState(() {
      loadingSite = true;
      siteError = null;
    });
    final d = await Api.siteImages(url);
    if (!mounted) return;
    setState(() => loadingSite = false);
    if (d['error'] != null) {
      setState(() => siteError = d['error'].toString());
      return;
    }
    s.brand.website = url;
    s.brand.siteText = (d['text'] ?? '').toString().substring(
        0, (d['text'] ?? '').toString().length.clamp(0, 1500));
    s.save();
    setState(() {
      siteImages = List<String>.from(d['images'] ?? []);
      imagesLoaded = true;
    });
    toast(context,
        siteImages.isEmpty ? 'Website read ✓ (no images found)' : 'Website read — select your product images');
  }

  @override
  Widget build(BuildContext context) {
    final b = s.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          crumb: 'STEP 1 · YOUR BRAND',
          title: 'Who are we building for?',
          lead:
              'Type the basics. If you add the website, the wizard reads it and pulls the product images by itself.',
        ),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Field(
                'Brand name',
                TextFormField(
                  initialValue: b.name,
                  decoration: sfInput('e.g., GOVAA'),
                  onChanged: (v) {
                    b.name = v;
                    s.save();
                  },
                ),
              ),
              Field(
                'Website (optional but powerful)',
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: siteCtrl,
                        decoration: sfInput('e.g., govaa.in'),
                        onChanged: (v) {
                          b.website = v;
                          s.save();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SfButton('⚡ Read my site',
                        onPressed: loadingSite ? null : fetchSite),
                  ],
                ),
              ),
              if (loadingSite) const Thinking('Reading your website — pulling text & product images…'),
              if (siteError != null) ErrText(siteError!),
              if (imagesLoaded && siteImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Text('Product images found on your site — tap to select',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: C.brand)),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 640 ? 6 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        for (final u in siteImages)
                          Thumb(
                            url: u,
                            selected: b.productImages.contains(u),
                            onTap: () => setState(() {
                              if (!b.productImages.remove(u)) b.productImages.add(u);
                              s.save();
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              if (imagesLoaded && siteImages.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      'Site read ✓ but no images detected — you can add image links manually in the AI Studio step.',
                      style: TextStyle(fontSize: 13, color: C.soft)),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Field(
                      'Product category',
                      TextFormField(
                        initialValue: b.product,
                        decoration: sfInput('e.g., liquor-infused chocolates'),
                        onChanged: (v) {
                          b.product = v;
                          s.save();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Field(
                      'Brand voice (3 words)',
                      TextFormField(
                        initialValue: b.voice,
                        decoration: sfInput('e.g., warm, bold, Goan'),
                        onChanged: (v) {
                          b.voice = v;
                          s.save();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Field(
                '30-day goal',
                DropdownButtonFormField<String>(
                  initialValue: b.goal,
                  decoration: sfInput(),
                  items: [
                    for (final g in goals)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) {
                    b.goal = v ?? goals.first;
                    s.save();
                  },
                ),
              ),
              Field(
                'Platforms',
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in allPlatforms)
                      FilterChip(
                        label: Text(p),
                        selected: b.platforms.contains(p),
                        onSelected: (on) => setState(() {
                          if (on && !b.platforms.contains(p)) b.platforms.add(p);
                          if (!on) b.platforms.remove(p);
                          s.save();
                        }),
                        selectedColor: C.cream,
                        checkmarkColor: C.green,
                        labelStyle: TextStyle(
                            fontSize: 12.5,
                            color: b.platforms.contains(p) ? C.brand : C.soft),
                        side: const BorderSide(color: C.line),
                        backgroundColor: Colors.white,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (b.productImages.isNotEmpty)
          SfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your product images (${b.productImages.length} selected)',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 640 ? 6 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final u in b.productImages)
                      Thumb(
                        url: u,
                        selected: true,
                        onTap: () => setState(() {
                          b.productImages.remove(u);
                          s.save();
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                    'These guide the AI Studio — generated visuals will match your real product.',
                    style: TextStyle(fontSize: 12, color: C.soft)),
              ],
            ),
          ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}
