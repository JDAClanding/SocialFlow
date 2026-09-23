library;

import 'package:flutter/material.dart';

import '../state.dart';
import '../widgets.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart, onDashboard;
  const WelcomeScreen(
      {super.key, required this.onStart, required this.onDashboard});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text('AI SOCIAL CAMPAIGN WIZARD',
            style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 3,
                color: C.accent,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('Build a month of social media\nin one sitting.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 40,
                color: C.brand,
                fontWeight: FontWeight.w700)),
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 26),
          child: Text(
            'Type a brand name. The wizard researches it live, analyzes competitors, '
            'suggests audiences, trends and strategy — you just tap to select. Then it '
            'generates your 30-day calendar, visuals included, with a link to send your client.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.soft, fontSize: 15),
          ),
        ),
        SfButton('Start building →', big: true, onPressed: onStart),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _Feature('🔍 Live research',
                'Brand & competitor intel pulled from the web as you type names — tap to select.'),
            _Feature('🧠 AI suggestions',
                'Audiences, trends, hooks and strategy pre-answered from your research.'),
            _Feature('🎨 Image studio',
                'Your website\'s product photos pulled automatically; AI visuals generated in-panel.'),
            _Feature('🔗 Client link',
                'One click → a clean read-only calendar link to send your customer.'),
          ],
        ),
        if (s.brand.name.isNotEmpty)
          SfCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continuing ${s.brand.name}?',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                SfButton('Jump to dashboard', alt: true, onPressed: onDashboard),
              ],
            ),
          ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final String title, body;
  const _Feature(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: SfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: C.brand)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 13, color: C.soft)),
          ],
        ),
      ),
    );
  }
}
