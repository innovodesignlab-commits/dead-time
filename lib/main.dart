import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'services/ad_service.dart';

void main() {
  // Global crash guard: an uncaught error must never take the app down
  // in front of a user (Play Store vitals punish crashes hard in ranking).
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('Flutter error: ${details.exception}');
    };

    runApp(const DeadTimeApp());

    // Consent + ad init happens AFTER first frame so launch feels instant.
    unawaited(AdService.instance.initWithConsent());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
  });
}

/// ---------------------------------------------------------------------------
/// DEAD TIME · color system
/// Deep "waiting room at midnight" navy, with an hourglass-amber accent.
/// ---------------------------------------------------------------------------
class DT {
  static const bg = Color(0xFF0C1022); // midnight navy
  static const surface = Color(0xFF171D36); // raised card
  static const surfaceHi = Color(0xFF222A4D); // pressed / highlighted
  static const amber = Color(0xFFFFB84D); // hourglass sand (primary accent)
  static const violet = Color(0xFF9B8CFF); // secondary accent
  static const mint = Color(0xFF5CE6C3); // success
  static const coral = Color(0xFFFF6B7A); // danger / wrong
  static const sky = Color(0xFF5BB8FF); // fourth game accent
  static const textHi = Color(0xFFF4F2EC);
  static const textLo = Color(0xFF8B92B3);
}

class DeadTimeApp extends StatelessWidget {
  const DeadTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Dead Time',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: DT.bg,
        colorScheme: base.colorScheme.copyWith(
          primary: DT.amber,
          secondary: DT.violet,
          surface: DT.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: DT.textHi,
              height: 1.05),
          displayMedium: GoogleFonts.spaceGrotesk(
              fontSize: 30, fontWeight: FontWeight.w700, color: DT.textHi),
          titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 20, fontWeight: FontWeight.w600, color: DT.textHi),
          bodyMedium:
              GoogleFonts.inter(fontSize: 15, color: DT.textLo, height: 1.5),
          labelLarge: GoogleFonts.spaceGrotesk(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
