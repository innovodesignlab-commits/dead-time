import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

/// MEMORY MATCH — find all pairs; each cleared board deals a fresh one.
class MemoryMatchGame extends StatefulWidget {
  final void Function(int delta) onScore;
  const MemoryMatchGame({super.key, required this.onScore});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _Card {
  final String emoji;
  bool faceUp = false;
  bool matched = false;
  _Card(this.emoji);
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const _pool = [
    '🍋', '🚀', '🐙', '🌵', '🎧', '🍩', '⚡', '🎲',
    '🪐', '🦊', '🍉', '🧊', '🎯', '🐝', '🌶️', '🔮',
  ];
  final _rng = Random();
  late List<_Card> _cards;
  _Card? _first;
  bool _locked = false;
  int _round = 1;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final pairs = min(6 + _round, 8); // 12–16 cards
    final picks = List.of(_pool)..shuffle(_rng);
    final chosen = picks.take(pairs).toList();
    _cards = [for (final e in chosen) ...[_Card(e), _Card(e)]]..shuffle(_rng);
    _first = null;
    _locked = false;
    setState(() {});
  }

  void _flip(_Card card) {
    if (_locked || card.faceUp || card.matched) return;
    HapticFeedback.selectionClick();
    setState(() => card.faceUp = true);

    if (_first == null) {
      _first = card;
      return;
    }
    final a = _first!;
    _first = null;

    if (a.emoji == card.emoji) {
      HapticFeedback.mediumImpact();
      setState(() {
        a.matched = true;
        card.matched = true;
      });
      widget.onScore(2);
      if (_cards.every((c) => c.matched)) {
        widget.onScore(5); // board-clear bonus
        _round++;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _deal();
        });
      }
    } else {
      _locked = true;
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          a.faceUp = false;
          card.faceUp = false;
          _locked = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _cards.length <= 12 ? 3 : 4;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('ROUND $_round',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DT.textLo, letterSpacing: 3, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: cols,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final card in _cards) _FlipCard(card: card, onTap: () => _flip(card)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  final _Card card;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showing = card.faceUp || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: showing ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        builder: (context, v, _) {
          final angle = v * pi;
          final isBack = angle < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? _face(
                    color: DT.surface,
                    border: DT.surfaceHi,
                    child: const Icon(Icons.hourglass_empty_rounded,
                        color: DT.textLo, size: 22),
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _face(
                      color: card.matched
                          ? DT.mint.withOpacity(0.18)
                          : DT.surfaceHi,
                      border: card.matched ? DT.mint : DT.violet,
                      child: Text(card.emoji,
                          style: const TextStyle(fontSize: 30)),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _face(
      {required Color color, required Color border, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Center(child: child),
    );
  }
}
