import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/ad_service.dart';
import 'home_screen.dart';
import 'session_screen.dart';

class ResultsScreen extends StatefulWidget {
  final GameType game;
  final int score;
  final int minutes;
  final bool isRecord;
  final int totalWaits;

  const ResultsScreen({
    super.key,
    required this.game,
    required this.score,
    required this.minutes,
    required this.isRecord,
    required this.totalWaits,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late int _score = widget.score;
  bool _doubled = false;

  void _doublePoints() {
    // Rewarded ad: the user chooses to watch — highest-value ad format.
    AdService.instance.showRewarded(onReward: () async {
      HapticFeedback.mediumImpact();
      setState(() {
        _score *= 2;
        _doubled = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final bestKey = 'best_${widget.game.name}';
      if (_score > (prefs.getInt(bestKey) ?? 0)) {
        await prefs.setInt(bestKey, _score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final meta = games.firstWhere((g) => g.type == widget.game);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.hourglass_disabled_rounded,
                  color: DT.amber, size: 56),
              const SizedBox(height: 16),
              Text('WAIT SURVIVED', style: t.displayMedium),
              const SizedBox(height: 6),
              Text(
                'You just killed ${widget.minutes} minute${widget.minutes == 1 ? '' : 's'} of dead time.',
                style: t.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DT.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: widget.isRecord ? DT.amber : DT.surfaceHi,
                      width: widget.isRecord ? 2 : 1),
                ),
                child: Column(
                  children: [
                    Text(meta.name.toUpperCase(),
                        style: t.labelLarge?.copyWith(
                            color: DT.textLo, letterSpacing: 2, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('$_score',
                        style: t.displayLarge
                            ?.copyWith(fontSize: 72, color: meta.color)),
                    if (widget.isRecord)
                      const Text('🏆 NEW PERSONAL BEST',
                          style: TextStyle(color: DT.amber)),
                    const SizedBox(height: 8),
                    Text('${widget.totalWaits} waits survived all-time',
                        style: t.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_doubled && AdService.instance.rewardedReady)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DT.violet,
                      side: const BorderSide(color: DT.violet),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _doublePoints,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('WATCH AD · DOUBLE MY SCORE'),
                  ),
                ),
              const Spacer(),
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
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  ),
                  child: const Text('DONE WAITING'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SessionScreen(
                      game: widget.game,
                      duration: Duration(minutes: widget.minutes),
                    ),
                  ),
                ),
                child: const Text('Still waiting? Go again →',
                    style: TextStyle(color: DT.textLo)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
