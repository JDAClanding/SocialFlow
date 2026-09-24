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

  final s = AppState.instance;
  // Reopen on the step the user was on (persisted across reloads).
  late int cur = s.step.clamp(0, steps.length - 1);

  void go(int i) {
    setState(() => cur = i.clamp(0, steps.length - 1));
    s.step = cur;
    s.save();
  }

  void next() {
    setState(() {
      s.done.add(cur);
      if (cur < steps.length - 1) cur++;
    });
    s.step = cur;
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
                  child: Builder(builder: (context) {
                    final size = Responsive.of(context);
                    final pad = switch (size) {
                      ScreenSize.mobile =>
                        const EdgeInsets.fromLTRB(14, 20, 14, 60),
                      ScreenSize.tablet =>
                        const EdgeInsets.fromLTRB(24, 28, 24, 80),
                      ScreenSize.desktop =>
                        const EdgeInsets.fromLTRB(40, 32, 40, 90),
                    };
                    return SingleChildScrollView(
                      key: ValueKey(cur),
                      padding: pad,
                      child: Center(
                        child: ConstrainedBox(
                          // tablet: one comfortable column; desktop: room for two
                          constraints: BoxConstraints(
                              maxWidth: size == ScreenSize.tablet ? 960 : 1440),
                          child: _screenFor(cur),
                        ),
                      ),
                    );
                  }),
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
    final mobile = Responsive.isMobile(context);
    final desktop = Responsive.isDesktop(context);
    final dot = mobile ? 26.0 : 30.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 16, vertical: 10),
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
          if (!mobile) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: C.gold, borderRadius: BorderRadius.circular(8)),
              child: const Text('v13 · LIVE',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ],
          SizedBox(width: mobile ? 8 : 12),
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
                            width: dot,
                            height: dot,
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
          if (desktop)
            Text('Step $cur · ${_HomeShellState.steps[cur]}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.soft)),
        ],
      ),
    );
  }
}
