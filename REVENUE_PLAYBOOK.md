# 💰 Revenue Playbook + Your APK in 3 Commands

## Part 1 — Getting your APK

An APK must be compiled and signed on your machine (the signature is your legal
identity to Google — nobody can generate it for you). After the README setup:

```bash
# 1. Testable APK on your phone right now (test ads):
flutter build apk --release

# 2. Find it here:
#    build/app/outputs/flutter-apk/app-release.apk
#    → copy to your phone and install. This is your shareable APK.

# 3. For the Play Store, upload the BUNDLE instead (smaller downloads = more installs):
flutter build appbundle --release
#    → build/app/outputs/bundle/release/app-release.aab
```

Before the Play Store build: real AdMob IDs in `ad_service.dart` + manifest,
and signing configured per `PUBLISHING_GUIDE.md` Phase 2.

---

## Part 2 — How this app is engineered for maximum ad revenue

Your money = Impressions × eCPM. The code already implements the levers:

**1. Consent flow (UMP) → personalized ads.**
Without the consent form, AdMob serves non-personalized ads in many regions,
which pay a fraction of personalized ones. `initWithConsent()` in
`ad_service.dart` handles this — that single feature is worth more than any
extra ad placement.

**2. Adaptive banner (home screen).**
Adaptive banners fill the full screen width and consistently out-earn legacy
320×50 banners in Tier-1 markets. Already wired in.

**3. Interstitial at the natural break.**
Fires when the wait ends — the one moment the user has nothing to lose.
There's a 60-second frequency cap in the code. Do NOT remove it: Google's
systems detect aggressive interstitial behavior, punish your app in search
ranking, and advertisers bid less on inventory with bad engagement. The cap
*raises* long-run revenue.

**4. Rewarded ad (double-your-score).**
Rewarded is the highest-eCPM format that exists (often $10–25 eCPM in the US)
because the user opts in. Once you have traction, add a second rewarded
placement: "watch to add +2 minutes of overtime" when a session ends and the
user taps "Still waiting?".

**5. What NOT to do (accounts die from this):**
- Never click or ask friends to click your ads → permanent ban, unpaid balance seized.
- Never show an interstitial at app open or between menu taps → policy strike.
- Never put a banner where accidental taps happen (next to buttons) → invalid-traffic flags.

## Part 3 — Realistic US math

| Metric | Conservative US numbers |
|---|---|
| Banner eCPM | $0.5–2 |
| Interstitial eCPM | $5–12 |
| Rewarded eCPM | $10–25 |
| Blended revenue per US daily-active user | roughly $0.01–0.04/day |

So: 1,000 US daily users ≈ $300–1,200/month. The bottleneck is never ad
placement — it's **getting and keeping US users**. Which means:

**Growth plan (this is where the money actually is):**
1. Launch, get 20–50 real users, watch retention in Play Console.
2. Content marketing that fits the product perfectly: 15-second TikTok/Reels/
   Shorts — film a real wait ("my coffee order said 4 minutes") with the app
   counting down, game ends exactly as the coffee lands. This concept is
   natively filmable and US-relatable. Post 3×/week; one hit short = thousands
   of installs at $0 cost.
3. At ~1,000 DAU: enable AdMob **bidding/mediation** in the AdMob console
   (no code change needed at first) — typically +10–30% eCPM.
4. Iterate on retention: the "waits survived" streak is your hook; consider
   daily streak bonuses next.

One legal note since you're targeting the US from abroad: AdMob will have you
submit a **W-8BEN tax form** (simple, in the AdMob payments settings) so US
earnings aren't over-withheld. Takes 10 minutes; don't skip it.
