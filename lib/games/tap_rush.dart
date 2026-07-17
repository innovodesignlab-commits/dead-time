import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

/// TAP RUSH — orbs appear at random spots and shrink; tap before they vanish.
/// Gold orbs are worth 3, violet 1. Red orbs are traps: tapping them costs 2.
class TapRushGame extends StatefulWidget {
  final void Function(int delta) onScore;
  const TapRushGame({super.key, required this.onScore});

  @override
  State<TapRushGame> createState() => _TapRushGameState();
}

class _Orb {
  final int id;
  final Offset pos; // fraction of playfield (0–1)
  final int kind; // 0 = normal, 1 = gold, 2 = trap
  _Orb(this.id, this.pos, this.kind);
}

class _TapRushGameState extends State<TapRushGame> {
  final _rng = Random();
  final List<_Orb> _orbs = [];
  int _nextId = 0;
  Timer? _spawner;
  int _spawnMs = 900;

  @override
  void initState() {
    super.initState();
    _scheduleSpawn();
  }

  void _scheduleSpawn() {
    _spawner = Timer(Duration(milliseconds: _spawnMs), () {
      if (!mounted) return;
      _spawn();
      // Gets faster over time, floor at 420 ms — difficulty curve.
      _spawnMs = max(420, _spawnMs - 8);
      _scheduleSpawn();
    });
  }

  void _spawn() {
    final roll = _rng.nextDouble();
    final kind = roll < 0.12 ? 1 : (roll < 0.28 ? 2 : 0);
    final orb = _Orb(
      _nextId++,
      Offset(0.08 + _rng.nextDouble() * 0.84, 0.06 + _rng.nextDouble() * 0.82),
      kind,
    );
    setState(() => _orbs.add(orb));
    // Orbs self-destruct if not tapped.
    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _orbs.removeWhere((o) => o.id == orb.id));
    });
  }

  void _tap(_Orb orb) {
    setState(() => _orbs.removeWhere((o) => o.id == orb.id));
    switch (orb.kind) {
      case 1:
        HapticFeedback.mediumImpact();
        widget.onScore(3);
      case 2:
        HapticFeedback.heavyImpact();
        widget.onScore(-2);
      default:
        HapticFeedback.lightImpact();
        widget.onScore(1);
    }
  }

  @override
  void dispose() {
    _spawner?.cancel();
    super.dispose();
  }

  Color _color(int kind) =>
      kind == 1 ? DT.amber : (kind == 2 ? DT.coral : DT.violet);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Text(
                'gold +3 · violet +1 · red −2',
                style: TextStyle(color: DT.textLo.withOpacity(0.4), fontSize: 12),
              ),
            ),
          ),
          for (final orb in _orbs)
            Positioned(
              left: orb.pos.dx * box.maxWidth - 34,
              top: orb.pos.dy * box.maxHeight - 34,
              child: GestureDetector(
                onTapDown: (_) => _tap(orb),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 1600),
                  builder: (context, v, child) => Transform.scale(
                    scale: 0.4 + 0.6 * v,
                    child: Opacity(opacity: (0.3 + 0.7 * v).clamp(0.0, 1.0).toDouble(), child: child),
                  ),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _color(orb.kind),
                          _color(orb.kind).withOpacity(0.45),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _color(orb.kind).withOpacity(0.5),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: orb.kind == 2
                        ? const Icon(Icons.warning_amber_rounded,
                            color: DT.bg, size: 26)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
