library;

import 'package:flutter/material.dart';

import 'screens/audience_screen.dart';
import 'screens/brand_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/competitors_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/strategy_screen.dart';
import 'screens/studio_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/welcome_screen.dart';
import 'state.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  runApp(const SocialFlowApp());
}

class SocialFlowApp extends StatelessWidget {
  const SocialFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOCIALFLOW — AI Campaign Wizard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
            seedColor: C.brand, primary: C.brand, surface: C.bg),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: C.ink)),
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const steps = [
    'Welcome',
    'Brand',
    'Competitors',
    'Audience',
    'Trends',
    'Strategy',
    'AI Studio',
    'Calendar',
    'Dashboard',
  ];

  int cur = 0;
  final s = AppState.instance;

  void go(int i) => setState(() => cur = i.clamp(0, steps.length - 1));

  void next() {
    setState(() {
      s.done.add(cur);
      if (cur < steps.length - 1) cur++;
    });
    s.save();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  cur: cur,
                  done: s.done,
                  onDot: go,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(cur),
                    padding: const EdgeInsets.fromLTRB(18, 32, 18, 90),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: _screenFor(cur),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _screenFor(int i) {
    switch (i) {
      case 1:
        return BrandScreen(onBack: () => go(0), onNext: next);
      case 2:
        return CompetitorsScreen(onBack: () => go(1), onNext: next);
      case 3:
        return AudienceScreen(onBack: () => go(2), onNext: next);
      case 4:
        return TrendsScreen(onBack: () => go(3), onNext: next);
      case 5:
        return StrategyScreen(onBack: () => go(4), onNext: next);
      case 6:
        return StudioScreen(onBack: () => go(5), onNext: next);
      case 7:
        return CalendarScreen(onBack: () => go(6), onNext: next);
      case 8:
        return DashboardScreen(onBack: () => go(7), onNext: next);
      default:
        return WelcomeScreen(onStart: () => go(1), onDashboard: () => go(8));
    }
  }
}

class _TopBar extends StatelessWidget {
  final int cur;
  final Set<int> done;
  final void Function(int) onDot;
  const _TopBar({required this.cur, required this.done, required this.onDot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFDF9),
        border: Border(bottom: BorderSide(color: C.line)),
      ),
      child: Row(
        children: [
          const Text('SOCIAL',
              style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: C.brand)),
          const Text('FLOW',
              style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: C.accent)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: C.gold, borderRadius: BorderRadius.circular(8)),
            child: const Text('v13 · LIVE',
                style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _HomeShellState.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => onDot(i),
                        child: Tooltip(
                          message: _HomeShellState.steps[i],
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == cur
                                  ? C.brand
                                  : (done.contains(i) ? C.green : C.cream),
                            ),
                            child: Text(
                              done.contains(i) ? '✓' : (i == 0 ? '★' : '$i'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: (i == cur || done.contains(i))
                                    ? Colors.white
                                    : C.brand,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
