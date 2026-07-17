import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../games/color_clash.dart';
import '../games/math_sprint.dart';
import '../games/memory_match.dart';
import '../games/tap_rush.dart';
import '../main.dart';
import '../services/ad_service.dart';
import 'home_screen.dart';
import 'results_screen.dart';

/// Wraps a game with the wait countdown. The session lasts exactly as long
/// as the user's real-world wait — that's the whole product.
///
/// Hardened: the timer is TIMESTAMP-BASED, so if the phone locks or the user
/// switches apps (they're waiting for something, they WILL check other apps),
/// the countdown stays true to real-world time instead of freezing.
class SessionScreen extends StatefulWidget {
  final GameType game;
  final Duration duration;
  const SessionScreen({super.key, required this.game, required this.duration});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with WidgetsBindingObserver {
  int _score = 0;
  int _countdown = 3; // 3-2-1 intro
  DateTime? _endsAt; // real-world end moment
  int _secondsLeft = 0;
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = widget.duration.inSeconds;
    _runIntro();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user comes back from another app, re-sync with real time.
    if (state == AppLifecycleState.resumed && _endsAt != null && !_ended) {
      final left = _endsAt!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        _endSession();
      } else {
        setState(() => _secondsLeft = left);
      }
    }
  }

  void _runIntro() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      HapticFeedback.lightImpact();
      if (_countdown <= 0) {
        t.cancel();
        _startClock();
      }
    });
  }

  void _startClock() {
    _endsAt = DateTime.now().add(widget.duration);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final left = _endsAt!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        t.cancel();
        _endSession();
      } else {
        setState(() => _secondsLeft = left);
      }
    });
  }

  Future<void> _endSession() async {
    if (_ended) return; // guard: only ever end once
    _ended = true;
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    var waits = 1;
    var isRecord = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      waits = (prefs.getInt('waits_survived') ?? 0) + 1;
      await prefs.setInt('waits_survived', waits);
      final bestKey = 'best_${widget.game.name}';
      final best = prefs.getInt(bestKey) ?? 0;
      isRecord = _score > best;
      if (isRecord) await prefs.setInt(bestKey, _score);
    } catch (_) {
      // Storage hiccup must never block the flow.
    }

    if (!mounted) return;
    // Natural ad moment: the wait is over, the session was ending anyway.
    AdService.instance.showInterstitial(onDone: () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultsScreen(
          game: widget.game,
          score: _score,
          minutes: widget.duration.inMinutes,
          isRecord: isRecord,
          totalWaits: waits,
        ),
      ));
    });
  }

  void _addScore(int delta) {
    if (_ended) return; // no scoring after the buzzer
    setState(() => _score += delta);
  }

  Future<void> _confirmQuit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DT.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abandon this wait?'),
        content: const Text(
            'Your score won\'t count and the streak won\'t grow.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep playing')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Quit', style: TextStyle(color: DT.coral))),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  String get _clock {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final meta = games.firstWhere((g) => g.type == widget.game);
    final total = widget.duration.inSeconds;
    final frac = total == 0 ? 0.0 : (_secondsLeft / total).clamp(0.0, 1.0).toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_ended) _confirmQuit();
      },
      child: Scaffold(
        body: SafeArea(
          child: _countdown > 0
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_countdown',
                          style: t.displayLarge
                              ?.copyWith(fontSize: 120, color: meta.color)),
                      Text('GET READY',
                          style: t.labelLarge?.copyWith(
                              color: DT.textLo, letterSpacing: 4)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Top bar: draining time + score ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: DT.textLo),
                            onPressed: _confirmQuit,
                          ),
                          Text(_clock,
                              style: t.displayMedium?.copyWith(
                                  color: _secondsLeft <= 10
                                      ? DT.coral
                                      : DT.textHi)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: DT.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('★ $_score',
                                style: t.titleLarge?.copyWith(
                                    color: meta.color, fontSize: 17)),
                          ),
                        ],
                      ),
                    ),
                    // ── Hourglass bar: drains with the real wait ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 6,
                          backgroundColor: DT.surfaceHi,
                          valueColor: AlwaysStoppedAnimation(
                              _secondsLeft <= 10 ? DT.coral : meta.color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildGame()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGame() {
    switch (widget.game) {
      case GameType.tapRush:
        return TapRushGame(onScore: _addScore);
      case GameType.mathSprint:
        return MathSprintGame(onScore: _addScore);
      case GameType.memoryMatch:
        return MemoryMatchGame(onScore: _addScore);
      case GameType.colorClash:
        return ColorClashGame(onScore: _addScore);
    }
  }
}
