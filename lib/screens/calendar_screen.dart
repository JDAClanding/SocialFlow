library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class CalendarScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const CalendarScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final s = AppState.instance;

  void genCalendar() {
    setState(() {
      s.calendar = generateCalendar(s);
      s.save();
    });
    toast(context, '🎉 Your 30-day calendar is ready — tap any day to edit');
  }

  @override
  Widget build(BuildContext context) {
    final cal = s.calendar;
    if (cal == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            crumb: 'STEP 7 · 30-DAY CALENDAR',
            title: 'Generate your month',
            lead:
                'One click: your pillar mix becomes 30 days of posts — with hooks, CTAs, visuals and image prompts pre-filled. Week 3 includes a Drop event.',
          ),
          SfCard(
            child: Center(
              child: SfButton('⚡ Generate my 30-day calendar',
                  big: true, onPressed: genCalendar),
            ),
          ),
          NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
        ],
      );
    }

    final weeks = <int, List<CalDay>>{};
    for (final c in cal) {
      weeks.putIfAbsent(((c.day - 1) ~/ 7) + 1, () => []).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          crumb: 'STEP 7 · 30-DAY CALENDAR',
          title: 'Your month at a glance',
          lead: 'Tap any day to edit or generate its visual. Regenerate resets edits.',
        ),
        SfButton('↻ Regenerate', alt: true, onPressed: genCalendar),
        const SizedBox(height: 12),
        for (final wk in weeks.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text('Week ${wk.key}${wk.key == 3 ? ' — DROP EVENT' : ''}',
                style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 15,
                    color: C.accent,
                    fontWeight: FontWeight.w700)),
          ),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 700
                ? 7
                : MediaQuery.of(context).size.width > 420
                    ? 3
                    : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .8,
            children: [
              for (final c in wk.value)
                GestureDetector(
                  onTap: () => _editDay(c),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.day}',
                            style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 19,
                                color: C.accent,
                                fontWeight: FontWeight.w700)),
                        Text(c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: C.brand)),
                        Pill(c.stage, color: stageColor(c.stage)),
                        Expanded(
                          child: Text(c.format,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, color: C.soft)),
                        ),
                        if (c.refImage.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(c.refImage,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }

  Future<void> _editDay(CalDay c) async {
    final titleCtrl = TextEditingController(text: c.title);
    final stageCtrl = ValueNotifier<String>(c.stage);
    final platCtrl = TextEditingController(text: c.platforms);
    final fmtCtrl = TextEditingController(text: c.format);
    final hookCtrl = TextEditingController(text: c.hook);
    final ctaCtrl = TextEditingController(text: c.cta);
    final imgCtrl = TextEditingController(text: c.imgPrompt);
    var refImage = c.refImage;
    var genBusy = false;
    String? genErr;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> genDayImg() async {
              final p = imgCtrl.text.trim();
              if (p.isEmpty) return toast(ctx, 'No prompt');
              setSheet(() {
                genBusy = true;
                genErr = null;
              });
              try {
                final url = await Api.genImage(p, '1:1', s.brand.productImages.take(1).toList());
                setSheet(() {
                  refImage = url;
                  genBusy = false;
                  s.gallery.add(GalleryItem(
                      url: url, title: 'Day ${c.day} — ${c.title}', prompt: p, pillar: c.pillar));
                  s.save();
                });
                toast(ctx, 'Visual ready & attached');
              } catch (e) {
                setSheet(() {
                  genBusy = false;
                  genErr = 'Failed: $e';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 18,
                  right: 18,
                  top: 18),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Day ${c.day}',
                        style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 20,
                            color: C.brand,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Field('Title',
                        TextField(controller: titleCtrl, decoration: sfInput())),
                    Field(
                      'Stage',
                      ValueListenableBuilder<String>(
                        valueListenable: stageCtrl,
                        builder: (_, v, __) => DropdownButtonFormField<String>(
                          initialValue: v,
                          decoration: sfInput(),
                          items: [
                            for (final st in ['Awareness', 'Engagement', 'Conversion', 'Advocacy'])
                              DropdownMenuItem(value: st, child: Text(st)),
                          ],
                          onChanged: (nv) => stageCtrl.value = nv ?? v,
                        ),
                      ),
                    ),
                    Field('Platforms',
                        TextField(controller: platCtrl, decoration: sfInput())),
                    Field('Format',
                        TextField(controller: fmtCtrl, maxLines: 2, decoration: sfInput())),
                    Field('Hook',
                        TextField(controller: hookCtrl, maxLines: 2, decoration: sfInput())),
                    Field('CTA',
                        TextField(controller: ctaCtrl, decoration: sfInput())),
                    Field(
                      'Visual',
                      refImage.isNotEmpty
                          ? Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.network(refImage,
                                      width: 110, height: 110, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                ),
                                const SizedBox(width: 10),
                                SfButton('Remove', ghost: true, onPressed: () => setSheet(() => refImage = '')),
                              ],
                            )
                          : const Text('None yet',
                              style: TextStyle(fontSize: 12, color: C.soft)),
                    ),
                    if (s.gallery.isNotEmpty) ...[
                      Field('Attach from gallery', const SizedBox.shrink()),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: s.gallery.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setSheet(() => refImage = s.gallery[i].url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(s.gallery[i].url,
                                  width: 76, height: 76, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: C.soft)),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Field('AI image prompt',
                        TextField(controller: imgCtrl, maxLines: 3, decoration: sfInput())),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SfButton('⚡ Generate this visual now',
                            alt: true, onPressed: genBusy ? null : genDayImg),
                        if (genBusy) ...[
                          const SizedBox(width: 10),
                          const Expanded(child: Thinking('Generating…')),
                        ],
                      ],
                    ),
                    if (genErr != null) ErrText(genErr!),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SfButton('Save day', onPressed: () {
                          c.title = titleCtrl.text;
                          c.stage = stageCtrl.value;
                          c.platforms = platCtrl.text;
                          c.format = fmtCtrl.text;
                          c.hook = hookCtrl.text;
                          c.cta = ctaCtrl.text;
                          c.imgPrompt = imgCtrl.text;
                          c.refImage = refImage;
                          s.save();
                          Navigator.pop(ctx);
                          setState(() {});
                          toast(context, 'Day ${c.day} saved');
                        }),
                        const SizedBox(width: 8),
                        SfButton('Cancel', ghost: true, onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
