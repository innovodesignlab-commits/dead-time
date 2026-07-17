# 📱 Publishing Dead Time to the Play Store — Step by Step

Follow these in order. Budget roughly one weekend for the whole process, plus Google's review time.

## Phase 1 — AdMob (your money pipe)

1. Go to https://admob.google.com and sign in with a Google account.
2. Complete the account setup (country, timezone, payment currency). In Pakistan, AdMob pays via **wire transfer to a local bank account** once you cross the $100 threshold — add your bank details under Payments when prompted.
3. Click **Apps → Add app** → "Android" → "No, the app isn't listed on a store yet" → name it *Dead Time*. Copy the **App ID** (looks like `ca-app-pub-1234567890~0987654321`).
4. Inside the app, create **three ad units**:
   - Banner → name it `home_banner`
   - Interstitial → name it `wait_over_interstitial`
   - Rewarded → name it `double_score_rewarded`
5. Paste the three ad unit IDs into `lib/services/ad_service.dart`, and the App ID into `android/app/src/main/AndroidManifest.xml`.
6. In AdMob → Settings → Test devices, add your own phone so you keep seeing test ads on it. **Clicking your own live ads gets your account permanently banned.**

## Phase 2 — Signing key (your app's identity)

1. Generate a keystore (run in a terminal; keep this file forever, losing it means losing the ability to update your app):
   ```
   keytool -genkey -v -keystore dead-time-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias deadtime
   ```
2. Create `android/key.properties`:
   ```
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=deadtime
   storeFile=/full/path/to/dead-time-key.jks
   ```
3. Configure signing in `android/app/build.gradle` — follow the official guide exactly: https://docs.flutter.dev/deployment/android#sign-the-app
4. Back up the `.jks` file and passwords in at least two places (cloud + USB drive).

## Phase 3 — Build the release bundle

```
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab` — this is the file you upload. Install-test the release build on your phone first with `flutter build apk --release` and sideload it.

## Phase 4 — Google Play Console

1. Go to https://play.google.com/console and pay the **one-time $25 registration fee** (needs a card that supports international payments).
2. **Identity verification:** Google will ask for a government ID (CNIC/passport) and may take a few days to verify. New personal accounts must also run a **closed test with at least 12 testers for 14 days** before you're allowed to publish publicly — plan for this. Recruit friends/family via a Google Group or email list.
3. Create app → name *Dead Time*, App (not game category-wise it can be "Casual" game), Free.
4. Fill in every section of the dashboard checklist:
   - **Privacy policy** (required because of ads): generate one free at app-privacy-policy-generator sites, host it on a free GitHub Pages page, paste the URL.
   - **Ads declaration:** YES, the app contains ads.
   - **Data safety form:** declare that AdMob collects device identifiers for advertising (Google publishes exactly what to declare for AdMob — search "AdMob data safety Play Console" for their official mapping).
   - **Content rating questionnaire:** answer honestly → you'll get "Everyone".
   - **Target audience:** 13+ (do NOT target children — that triggers strict Families policy requirements for ads).
5. **Store listing assets** you need to prepare:
   - App icon: 512×512 PNG
   - Feature graphic: 1024×500 PNG
   - At least 2 phone screenshots (just screenshot the app on your phone)
   - Short description (80 chars): *"Waiting for something? Kill exactly that many minutes with micro-games."*
   - Full description: explain the wait-timer concept, list the 3 games.
6. Upload the `.aab` under **Testing → Closed testing** first. After your 14-day / 12-tester requirement completes, apply for production access, then **promote to Production**.
7. First review typically takes 1–7 days.

## Phase 5 — After launch

- Link AdMob to the published Play listing (AdMob will prompt you) — this improves ad fill.
- Watch AdMob's "Match rate" and eCPM. Pakistan eCPMs are low ($0.1–0.5); the money is in volume and in Tier-1 downloads, so localize the listing in English first, Urdu second.
- Update regularly — even tiny updates improve Play ranking.
- Once you have ~1,000 daily users, add AdMob **mediation** (bidding) to raise eCPM.

## Honest expectations

Ad revenue is a volume game: roughly $1–5 per 1,000 ad impressions blended. A few hundred installs won't pay much — the plan should be: launch → get feedback → iterate on retention (the "waits survived" streak) → then push downloads via short-form video content (TikTok/Reels showing the "game ends when your chai is ready" hook, which is very filmable).
