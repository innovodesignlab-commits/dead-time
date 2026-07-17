import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

/// COLOR CLASH — the Stroop effect. A color word appears written in a
/// DIFFERENT ink color. Tap the INK color, not the word. Brutal and addictive.
class ColorClashGame extends StatefulWidget {
  final void Function(int delta) onScore;
  const ColorClashGame({super.key, required this.onScore});

  @override
  State<ColorClashGame> createState() => _ColorClashGameState();
}

class _Ink {
  final String name;
  final Color color;
  const _Ink(this.name, this.color);
}

class _ColorClashGameState extends State<ColorClashGame> {
  static const _inks = [
    _Ink('AMBER', DT.amber),
    _Ink('VIOLET', DT.violet),
    _Ink('MINT', DT.mint),
    _Ink('CORAL', DT.coral),
  ];

  final _rng = Random();
  late _Ink _word; // what the text SAYS
  late _Ink _ink; // what color it's PAINTED in (the correct answer)
  int _streak = 0;
  double _timeBank = 3.0; // seconds allowed per answer, shrinks as you go
  Timer? _tick;
  double _remaining = 3.0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    // Guard: always ensure word != ink so there's a real conflict.
    _word = _inks[_rng.nextInt(_inks.length)];
    do {
      _ink = _inks[_rng.nextInt(_inks.length)];
    } while (_ink.name == _word.name);

    _remaining = _timeBank;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining -= 0.05);
      if (_remaining <= 0) {
        t.cancel();
        _miss(); // ran out of time
      }
    });
    setState(() {});
  }

  void _pick(_Ink choice) {
    _tick?.cancel();
    if (choice.name == _ink.name) {
      HapticFeedback.lightImpact();
      _streak++;
      widget.onScore(1 + min(_streak ~/ 4, 3));
      // Difficulty curve: each correct answer shaves the time bank,
      // floor at 1.2 seconds — pure panic territory.
      if (_timeBank > 1.2) {
        _timeBank = max(1.2, _timeBank - 0.06);
      }
    } else {
      _miss();
      return;
    }
    _next();
  }

  void _miss() {
    HapticFeedback.heavyImpact();
    _streak = 0;
    widget.onScore(-1);
    // Mercy rule: a miss resets the time bank slightly upward.
    if (_timeBank < 2.0) _timeBank = 2.0;
    if (mounted) _next();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final frac = (_remaining / _timeBank).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('Tap the INK color — not the word',
              style: t.bodyMedium?.copyWith(fontSize: 13)),
          const Spacer(),
          if (_streak >= 4)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: DT.sky.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🧠 streak ×${1 + min(_streak ~/ 4, 3)}',
                  style: const TextStyle(color: DT.sky)),
            ),
          const SizedBox(height: 20),
          Text(
            _word.name,
            style: t.displayLarge?.copyWith(
              fontSize: 62,
              color: _ink.color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          // Per-question timer bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: DT.surfaceHi,
              valueColor: AlwaysStoppedAnimation(
                  frac < 0.3 ? DT.coral : DT.sky),
            ),
          ),
          const Spacer(),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              for (final ink in _inks)
                GestureDetector(
                  onTapDown: (_) => _pick(ink),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ink.color.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ink.color, width: 2),
                    ),
                    child: Center(
                      child: Text(ink.name,
                          style: t.labelLarge?.copyWith(color: ink.color)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
