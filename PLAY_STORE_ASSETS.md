# 🇺🇸 Play Store Asset Pack — US / Tier-1 Targeting

Everything Google Play will ask you for, pre-written and optimized for the American audience (highest ad RPMs: USA, Canada, UK, Australia).

---

## 1. App identity

| Field | Value |
|---|---|
| App name (30 chars max) | `Dead Time: Wait Killer Games` |
| Category | Games → Casual |
| Price | Free |
| Contains ads | **Yes** (must declare) |
| In-app purchases | No |
| Target audience | **13+** — never select under-13; that triggers Families policy which blocks personalized ads and cuts your RPM roughly in half |

## 2. Short description (80 chars — this drives search ranking)

```
Waiting for coffee, an Uber, laundry? Kill EXACTLY that many minutes. Not more.
```

## 3. Full description (US-optimized, paste as-is)

```
Ever open a game "for a minute" and lose an hour? Dead Time is the opposite.

Tell it how long you're waiting — for your coffee order, your ride, the dryer,
the microwave, the meeting to start — and play a micro-game that ends EXACTLY
when your wait does. No stopping points to find. No guilt. The game respects
your time because it's built around it.

⏳ SET YOUR WAIT — spin the dial from 1 to 15 minutes
🎮 FOUR MICRO-GAMES —
   • Tap Rush: pure reflex orb-hunting
   • Math Sprint: rapid-fire mental math with streak multipliers
   • Memory Match: endless pair-matching rounds
   • Color Clash: the infamous Stroop test — tap the ink, not the word
🏆 WAITS SURVIVED — build your all-time streak and beat your personal bests
📴 WORKS OFFLINE — subway, airplane, dead-zone waiting rooms

Perfect for: coffee lines, Uber/Lyft waits, laundry cycles, ad breaks,
boarding queues, waiting rooms, microwave minutes, and the eternal
"they said 5 minutes" situation.

Download free. Your dead time just got a pulse.
```

## 4. Keywords to work into the listing (Google Play indexes description text)

waiting games, time killer, quick games, offline games, 5 minute games, casual games, brain games, reflex game, one hand games, boredom, kill time

## 5. Graphics you must create (sizes are mandatory)

| Asset | Size | Tip |
|---|---|---|
| App icon | 512×512 PNG, no transparency | Hourglass glyph in amber (#FFB84D) on midnight navy (#0C1022). Flat, bold, readable at 48px. |
| Feature graphic | 1024×500 PNG | Big text: "The game that ends when your wait does." + phone mockup |
| Phone screenshots | Min 2, up to 8. 16:9 or 9:16 | Take: dial screen, each of the 4 games, results screen. Add one-line captions ("Set your wait" / "Beat the clock"). |

Free tools: Canva (feature graphic + captioned screenshots), your phone (raw screenshots via `flutter run --release`).

## 6. Privacy policy (REQUIRED — you can't submit without a URL)

Host this on a free GitHub Pages / Google Sites page, fill the blanks:

```
Privacy Policy for Dead Time
Last updated: [DATE]

Dead Time ("the app") is developed by [YOUR NAME] ("we").

Information we collect: The app itself collects no personal information and
requires no account. Game scores are stored only on your device.

Advertising: The app displays ads served by Google AdMob. AdMob may collect
device identifiers (such as the Advertising ID), approximate location derived
from IP address, and app interaction data to serve and measure ads. See
Google's policy: https://policies.google.com/technologies/partner-sites
Users in applicable regions are shown a consent form and may choose
non-personalized ads. You can reset your Advertising ID in Android settings.

Children: The app is not directed at children under 13.

Contact: [YOUR EMAIL]
```

## 7. Data safety form (Play Console) — answer exactly this for AdMob

- Does your app collect or share user data? → **Yes**
- Data types → **Device or other IDs** (collected, shared with third parties, for Advertising/Marketing; optional: App interactions → Analytics)
- Is data encrypted in transit? → **Yes**
- Can users request deletion? → **No** (no accounts exist)
- Also complete the **Advertising ID declaration** → Yes, uses Advertising ID → purpose: Advertising.

(Cross-check against AdMob's current published disclosure guidance when you fill it — Google updates this form periodically.)

## 8. Content rating questionnaire

Answer no violence / no gambling / no user-generated content / contains ads → result: **Everyone / Everyone 10+**. Takes 5 minutes.

## 9. Countries

Release to **all countries** — but the listing language/copy above is tuned for the US. Downloads from anywhere still earn; US/UK/CA/AU installs are the ones worth marketing dollars.
