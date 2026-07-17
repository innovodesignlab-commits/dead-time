# ⏳ Dead Time

**The game that ends exactly when your wait does.**

Pick how long you're waiting (1–15 min) → play a micro-game sized to that exact window → session ends when your wait ends. Monetized with AdMob: banner on home, interstitial when the wait finishes (a natural break), and a rewarded "double my score" ad.

## What's included

```
lib/
  main.dart                    App entry + theme (midnight navy / hourglass amber)
  services/ad_service.dart     AdMob banner + interstitial + rewarded (test IDs)
  screens/home_screen.dart     Circular wait dial, game picker, streak chip, banner ad
  screens/session_screen.dart  3-2-1 intro, live countdown, draining hourglass bar
  screens/results_screen.dart  Score card, personal bests, rewarded-ad doubler
  games/tap_rush.dart          Reflex orb-tapping (gold +3 / violet +1 / red trap −2)
  games/math_sprint.dart       Rapid arithmetic with streak multipliers
  games/memory_match.dart      Pair-matching with endless rounds
android_config/
  AndroidManifest.xml          Manifest template with AdMob meta-data
```

## Setup (one-time, ~30 minutes)

1. **Install Flutter** → https://docs.flutter.dev/get-started/install (choose Windows/macOS/Linux, follow the Android setup including Android Studio). Run `flutter doctor` until everything is green.

2. **Unzip this project**, open a terminal inside the `dead_time` folder.

3. **Generate the Android platform files:**
   ```
   flutter create --org com.yourname --project-name dead_time .
   ```
   Replace `com.yourname` with your own reversed domain (e.g. `com.alikhan`). **This becomes your permanent package name — it cannot be changed after publishing.**

4. **Replace the manifest:** copy `android_config/AndroidManifest.xml` over `android/app/src/main/AndroidManifest.xml`.

5. **Install dependencies and run:**
   ```
   flutter pub get
   flutter run
   ```
   Plug in an Android phone with USB debugging on, or use an emulator. You'll see the full app with Google's **test ads**.

6. In `android/app/build.gradle`, make sure `minSdkVersion` is at least **21** (required by google_mobile_ads). Set `minSdk = 23` to be safe.

## Before release (critical)

- Replace the 3 test ad unit IDs in `lib/services/ad_service.dart` with your real AdMob IDs.
- Replace the test APPLICATION_ID in `AndroidManifest.xml` with your real AdMob **App ID**.
- **Never tap your own live ads.** Add your device as a test device in AdMob during development.

Full Play Store steps → see `PUBLISHING_GUIDE.md`.
