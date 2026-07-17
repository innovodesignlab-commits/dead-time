import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/ad_service.dart';
import 'session_screen.dart';

enum GameType { tapRush, mathSprint, memoryMatch, colorClash }

class GameMeta {
  final GameType type;
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  const GameMeta(this.type, this.name, this.tagline, this.icon, this.color);
}

const games = [
  GameMeta(GameType.tapRush, 'Tap Rush', 'Reflexes. Pure speed.',
      Icons.touch_app_rounded, DT.amber),
  GameMeta(GameType.mathSprint, 'Math Sprint', 'Quick sums under pressure.',
      Icons.calculate_rounded, DT.violet),
  GameMeta(GameType.memoryMatch, 'Memory Match', 'Find every pair.',
      Icons.grid_view_rounded, DT.mint),
  GameMeta(GameType.colorClash, 'Color Clash', 'Trust the ink, not the word.',
      Icons.psychology_rounded, DT.sky),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _minutes = 3;
  GameType _selected = GameType.tapRush;
  int _streak = 0;
  BannerAd? _banner;
  bool _bannerLoaded = false;
  bool _bannerRequested = false;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Adaptive banner needs the real screen width — available here, not initState.
    if (!_bannerRequested) {
      _bannerRequested = true;
      final width = MediaQuery.of(context).size.width.truncate();
      AdService.instance
          .createAdaptiveBanner(
        widthPx: width,
        onLoaded: () {
          if (mounted) setState(() => _bannerLoaded = true);
        },
      )
          .then((ad) {
        if (ad != null && mounted) {
          _banner = ad;
        } else {
          ad?.dispose();
        }
      });
    }
  }

  Future<void> _loadStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _streak = prefs.getInt('waits_survived') ?? 0);
      }
    } catch (_) {
      // Storage failure: show 0, never crash.
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => SessionScreen(
            game: _selected,
            duration: Duration(minutes: _minutes.round()),
          ),
        ))
        .then((_) => _loadStreak());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DEAD\nTIME', style: t.displayLarge),
                        _StreakChip(streak: _streak),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('The game that ends exactly when your wait does.',
                        style: t.bodyMedium),
                    const SizedBox(height: 28),
                    Center(
                      child: _WaitDial(
                        minutes: _minutes,
                        onChanged: (v) {
                          if (v.round() != _minutes.round()) {
                            HapticFeedback.selectionClick();
                          }
                          setState(() => _minutes = v);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('PICK YOUR GAME',
                        style: t.labelLarge?.copyWith(
                            color: DT.textLo, letterSpacing: 2, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...games.map((g) => _GameCard(
                          meta: g,
                          selected: _selected == g.type,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = g.type);
                          },
                        )),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: DT.amber,
                          foregroundColor: DT.bg,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _start,
                        child: Text(
                          'KILL ${_minutes.round()} MINUTE${_minutes.round() == 1 ? '' : 'S'}',
                          style: t.labelLarge?.copyWith(color: DT.bg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_bannerLoaded && _banner != null)
              SizedBox(
                width: _banner!.size.width.toDouble(),
                height: _banner!.size.height.toDouble(),
                child: AdWidget(ad: _banner!),
              ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DT.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DT.surfaceHi),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: DT.amber, size: 18),
          const SizedBox(width: 6),
          Text('$streak waits\nsurvived',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: DT.textHi, fontSize: 11, height: 1.1)),
        ],
      ),
    );
  }
}

/// Circular dial: drag around the ring to set wait time (1–15 min).
class _WaitDial extends StatelessWidget {
  final double minutes;
  final ValueChanged<double> onChanged;
  const _WaitDial({required this.minutes, required this.onChanged});

  static const double _min = 1, _max = 15;

  void _handle(Offset local, double size) {
    final center = Offset(size / 2, size / 2);
    final v = local - center;
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2; // 0 at top
    if (angle < 0) angle += 2 * math.pi;
    final frac = angle / (2 * math.pi);
    onChanged((_min + frac * (_max - _min)).clamp(_min, _max));
  }

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    final frac = (minutes - _min) / (_max - _min);
    return GestureDetector(
      onPanDown: (d) => _handle(d.localPosition, size),
      onPanUpdate: (d) => _handle(d.localPosition, size),
      child: CustomPaint(
        size: const Size(size, size),
        painter: _DialPainter(frac),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${minutes.round()}',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontSize: 64, color: DT.amber)),
                const Text('MINUTES TO KILL',
                    style: TextStyle(
                        color: DT.textLo, fontSize: 11, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double frac;
  _DialPainter(this.frac);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;

    final track = Paint()
      ..color = DT.surfaceHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..shader = const SweepGradient(
        colors: [DT.violet, DT.amber],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * frac, false, arc);

    // Thumb
    final angle = -math.pi / 2 + 2 * math.pi * frac;
    final thumb = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(thumb, 14, Paint()..color = DT.amber);
    canvas.drawCircle(thumb, 6, Paint()..color = DT.bg);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.frac != frac;
}

class _GameCard extends StatelessWidget {
  final GameMeta meta;
  final bool selected;
  final VoidCallback onTap;
  const _GameCard(
      {required this.meta, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? DT.surfaceHi : DT.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? meta.color : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(meta.icon, color: meta.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta.name, style: t.titleLarge),
                  Text(meta.tagline,
                      style: t.bodyMedium?.copyWith(fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: meta.color),
          ],
        ),
      ),
    );
  }
}
