library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../data.dart';
import '../state.dart';
import '../widgets.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onBack, onNext;
  const DashboardScreen({super.key, required this.onBack, required this.onNext});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final s = AppState.instance;
  bool saving = false;
  String? shareUrl;

  Future<void> saveAndShare() async {
    setState(() => saving = true);
    try {
      final path = await Api.saveProject(
          s.brand.name.isEmpty ? 'Campaign' : s.brand.name, s.toJson());
      if (!mounted) return;
      setState(() => shareUrl = Api.baseUrl + path);
      toast(context, 'Saved! Client link ready');
    } catch (e) {
      if (mounted) toast(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cal = s.calendar ?? [];
    final byStage = <String, int>{};
    for (final c in cal) {
      byStage[c.stage] = (byStage[c.stage] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          crumb: 'STEP 8 · DASHBOARD',
          title: '${s.brand.name.isEmpty ? 'Your campaign' : s.brand.name} — ready to run 🎉',
          lead: 'Everything you built, saved and shareable.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat('${cal.length}', 'days planned'),
            _Stat('${s.competitors.length}', 'competitors'),
            _Stat('${s.segments.length}', 'segments'),
            _Stat('${s.trends.length + s.hooks.length}', 'trends & hooks'),
            _Stat('${s.gallery.length}', 'visuals'),
          ],
        ),
        const SizedBox(height: 14),
        SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Funnel balance',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 8),
              if (byStage.isEmpty)
                const Text('Generate the calendar first.',
                    style: TextStyle(color: C.soft, fontSize: 12.5)),
              Wrap(
                children: [
                  for (final e in byStage.entries)
                    Pill('${e.key}: ${e.value} days', color: stageColor(e.key)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Brand platform: ${s.strategy.platform.isEmpty ? '—' : s.strategy.platform}',
                  style: const TextStyle(fontSize: 12.5, color: C.soft)),
            ],
          ),
        ),
        SfCard(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔗 Client share link',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 6),
              const Text(
                  'Save the project to the cloud and get a clean read-only calendar link to send your client. They see only the final 30-day plan.',
                  style: TextStyle(fontSize: 13, color: C.soft)),
              const SizedBox(height: 10),
              SfButton(saving ? 'Saving…' : 'Save project & get link',
                  onPressed: saving ? null : saveAndShare),
              if (shareUrl != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4EA),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: C.green, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Saved! Client link:\n$shareUrl',
                          style: const TextStyle(fontSize: 13, color: C.ink)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          SfButton('Copy link', alt: true, onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareUrl!));
                            toast(context, 'Link copied — send it to your client');
                          }),
                          SfButton('Open ↗', ghost: true, onPressed: () {
                            launchUrl(Uri.parse(shareUrl!),
                                mode: LaunchMode.externalApplication);
                          }),
                        ],
                      ),
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
              const Text('Export',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SfButton('Copy .json', alt: true, onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(s.toJson())));
                    toast(context, 'JSON copied — paste it into any doc');
                  }),
                  SfButton('Copy calendar as text', alt: true, onPressed: () {
                    if (s.calendar == null) return toast(context, 'Generate the calendar first');
                    Clipboard.setData(ClipboardData(text: calendarAsText(s)));
                    toast(context, 'Copied — paste into any doc or scheduler');
                  }),
                ],
              ),
            ],
          ),
        ),
        SfCard(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly operating rhythm',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: C.brand)),
              SizedBox(height: 6),
              Text(
                  'Mon: batch-create the week (3–4h) · Tue: schedule at peak windows · '
                  'Daily: 30-min community block · Fri: trend-jack + metrics review.',
                  style: TextStyle(fontSize: 13, color: C.soft)),
            ],
          ),
        ),
        NavRow(showBack: true, onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.line),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    color: C.accent,
                    fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 11, color: C.soft)),
          ],
        ),
      ),
    );
  }
}
