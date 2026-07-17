import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

/// MATH SPRINT — rapid-fire arithmetic. Streaks multiply your points.
class MathSprintGame extends StatefulWidget {
  final void Function(int delta) onScore;
  const MathSprintGame({super.key, required this.onScore});

  @override
  State<MathSprintGame> createState() => _MathSprintGameState();
}

class _MathSprintGameState extends State<MathSprintGame> {
  final _rng = Random();
  late String _question;
  late int _answer;
  late List<int> _options;
  int _streak = 0;
  int _solved = 0;
  int? _flashIndex; // index of last tapped option
  bool? _flashCorrect;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _solved++;
    // Difficulty ramps: bigger numbers + multiplication appear as you solve.
    final hard = min(_solved ~/ 5, 3);
    final op = _rng.nextInt(hard >= 1 ? 3 : 2); // 0:+ 1:- 2:×
    int a, b;
    switch (op) {
      case 2:
        a = 2 + _rng.nextInt(6 + hard * 3);
        b = 2 + _rng.nextInt(6 + hard * 2);
        _answer = a * b;
        _question = '$a × $b';
      case 1:
        a = 10 + _rng.nextInt(20 + hard * 25);
        b = _rng.nextInt(a);
        _answer = a - b;
        _question = '$a − $b';
      default:
        a = 3 + _rng.nextInt(20 + hard * 30);
        b = 3 + _rng.nextInt(20 + hard * 30);
        _answer = a + b;
        _question = '$a + $b';
    }
    final opts = <int>{_answer};
    while (opts.length < 4) {
      final wrong = _answer + (_rng.nextInt(11) - 5);
      if (wrong != _answer && wrong >= 0) opts.add(wrong);
    }
    _options = opts.toList()..shuffle(_rng);
    _flashIndex = null;
    _flashCorrect = null;
    setState(() {});
  }

  void _pick(int index) {
    final correct = _options[index] == _answer;
    setState(() {
      _flashIndex = index;
      _flashCorrect = correct;
    });
    if (correct) {
      HapticFeedback.lightImpact();
      _streak++;
      widget.onScore(1 + min(_streak ~/ 3, 3)); // streak bonus up to +4
    } else {
      HapticFeedback.heavyImpact();
      _streak = 0;
      widget.onScore(-1);
    }
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          if (_streak >= 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: DT.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🔥 streak ×${1 + min(_streak ~/ 3, 3)}',
                  style: const TextStyle(color: DT.amber)),
            ),
          const SizedBox(height: 16),
          Text(_question,
              style: t.displayLarge?.copyWith(fontSize: 58, color: DT.textHi)),
          const Spacer(),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              for (var i = 0; i < _options.length; i++)
                _OptionButton(
                  label: '${_options[i]}',
                  flash: _flashIndex == i ? _flashCorrect : null,
                  onTap: () => _pick(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool? flash; // null = idle, true = correct, false = wrong
  final VoidCallback onTap;
  const _OptionButton(
      {required this.label, required this.flash, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = flash == null
        ? DT.surface
        : (flash! ? DT.mint.withOpacity(0.25) : DT.coral.withOpacity(0.25));
    final border = flash == null
        ? DT.surfaceHi
        : (flash! ? DT.mint : DT.coral);
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontSize: 26)),
        ),
      ),
    );
  }
}
