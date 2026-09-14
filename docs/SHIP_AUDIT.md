# Bstory (BOMA) ship audit — 14 Sep 2026

Internal repo: [parsaforughi/BOMA](https://github.com/parsaforughi/BOMA). User-facing name: **Bstory**. Client: **Abolfazl Nouri**.

This is a product+code audit, not an implementation pass. No app code was changed.

## Product correction

This repo is **not** AI captions / smart cuts / video.

It is a **Persian Instagram-story text styler**: type text, pick font/effect/color, export PNG, copy styled text into Instagram Stories.

There is no caption model, no video pipeline, no Nevise backend in this tree. If Nouri’s brief is still “AI captions + smart cuts,” that product is missing here and needs a separate decision.

---

## 1. Repo map

| Path | What it is |
|------|------------|
| `lib/` | Flutter app (62 Dart files). One editor screen + auth/premium/purchase/settings/update. |
| `server/` | Node/Express + SQLite: OTP, analytics, force-update, admin HTML, FCM v1. Railway target. |
| `assets/` | Fonts (~44 families), ~296 sticker PNGs, style previews, photo background packs, Figma JSON. |
| `docs/` | Figma style-import notes only (plus this audit). |
| `test/` | One file: Farsi number/phone helpers. No widget/editor/auth tests. |
| `android/` / `ios/` / `macos/` / `web/` | Mobile is the product. Web/macOS look like leftover `flutter create` shells. |
| `.github/` | **None.** No CI, no issues. |

**Screens (all routed in `lib/app.dart`):** splash → home (auth optional). Login + 4-box OTP. Settings is a bottom sheet. Premium + purchase exist. Force-update exists.

**Not present:** onboarding, privacy/terms, language picker UI, real payment, FCM client, video, AI.

---

## 2. Implemented vs incomplete

### Shipped enough to demo

- Portrait Flutter editor (Riverpod + go_router). Default locale `fa`, RTL hardcoded on most screens.
- Canvas: text, 16 listed Persian fonts + extra effect fonts in `pubspec`, stroke/shadow/bubble/gradient, ~30 Pishrafte presets, custom font import (TTF/OTF).
- Drafts/history (local, max 10) + auto-save last session.
- Export: save PNG to gallery (`gal`); copy styled **text** PNG to clipboard for IG Stories (Android method channel).
- OTP UI + server (`sms.ir` bulk send). If `BOMA_API_BASE` is empty, **any 4+ digit code logs you in** (dev mode).
- Splash analytics ping + remote force-update (`/api/app/version`).
- Admin panel at `/admin` (Basic auth): users, daily opens, force-update knobs, push composer, OTP lookup.

### Stubbed / broken (looks done, is not)

| Area | Reality |
|------|---------|
| **Stickers on canvas** | `CanvasState.addSticker` is **never called**. Picker tap copies the **asset path string** to the clipboard (`Clipboard.setData(text: sticker.assetPath)`). Drag-to-trash UI exists for stickers that cannot be added. |
| **Photo backgrounds** | 4 packs (3D Character, Car, Glass Morphism, Lights) + gradients. Tap → “save to gallery” only. Canvas has **no image background field** — text cannot sit on a photo. |
| **Payment** | Purchase waits 2s, then `setPro()` **locally**. No Zarinpal/IDPay/IAP. Discount-code buttons are `onPressed: () {}`. |
| **Monetization** | `kAllFeaturesFreeForNow = true` → everyone is Pro. Credits pill shows ∞. |
| **Support links** | Telegram / WhatsApp / Instagram icons: empty `onTap`. |
| **Push** | Server can send FCM v1. App has **no** `firebase_messaging`. Tokens are never collected. |
| **Pro from server** | Verify OTP returns `isPro`; Flutter **ignores** it. `setPro` never writes `users.is_pro` on the server. |
| **l10n** | ARB for fa/ar/en exists. Almost every screen hardcodes Persian. `setLocale` has **no UI**. Language strings in ARB are unused. |
| **Share sheet** | `ExportService.shareImage` (`share_plus`) is unused. Save sheet = gallery + IG clipboard only. |
| **README** | Still describes backend as “force-update only.” Server is a full OTP/admin app. Open docs PR: [#2](https://github.com/parsaforughi/BOMA/pull/2). |

### Auth OTP mismatch (ship blocker if SMS is on)

Server generates a **5-digit** code (`10000–99999`). App OTP screen is **4 boxes** and rejects anything but length 4. Verify API accepts 4–6 digits. Live SMS login will fail until these match.

SMS copy still says **«کد تأیید بوما»**.

---

## 3. Signals of unfinished work

- **GitHub issues:** none.
- **PRs:** #1 merged (rename to Bstory). #2 open (docs hygiene, not merged).
- **Last product commit:** 22 Aug 2026 (`feat: rename user-facing product name to Bstory`). Package still `name: boma`, `version: 1.0.0+1`.
- **TODOs in Android Gradle:** unique application id; **release still signed with debug keys**.
- **Admin comment in server:** OTP lookup “delete in production.”
- **`.env.example` vs code:** example still mentions IdealPayamak `OTP_API_URL`; code uses `SMS_IR_API_KEY`.
- **Rename leftovers:** iOS photo permission strings, force-update default message, admin title, some premium copy still say بوما. Package ids: Android `com.boma.app`, iOS `com.boma.boma`.
- **No LICENSE, privacy policy, or store listing assets** in repo.

---

## 4. Tech stack and deploy

**App:** Flutter ≥ 3.2, Dart 3, Riverpod, go_router, `http`, `gal`, `share_plus`, `file_picker`, `package_info_plus`, `connectivity_plus`, `url_launcher`. No Firebase client. No in-app purchase package.

**Server:** Node 20, Express, `better-sqlite3`, JWT (365-day tokens). FCM via service-account JSON in `FIREBASE_SERVICE_ACCOUNT`.

**Deploy:** `server/railway.toml` + `nixpacks.toml` (root directory must be `server/`). Health: `GET /health`. Repo-root `railway.json` would start `node index.js` from the **wrong** directory if Railway is pointed at repo root.

**Live status from this audit:** unknown. Client `BOMA_API_BASE` **defaults to empty** — a Play/Bazaar APK built without `--dart-define=BOMA_API_BASE=...` never talks to the backend (offline OTP, no force-update, no analytics). Store URLs are placeholders (`com.boma.app` on Play; iOS `id0000000000` / `https://apps.apple.com`).

**Release blockers besides product:** debug signing; `android:usesCleartextTraffic="true"`; default `JWT_SECRET` / `ADMIN_PASSWORD=boma1234` if env not set; SQLite needs a Railway volume (`DB_PATH`); no CI.

---

## 5. Prioritized gap list (for Parsa)

### Must-have to ship a usable v1 (free, Android-first)

1. **Decide the product.** Confirm with Nouri: Bstory text styler **or** AI captions/smart cuts. This repo only supports the first.
2. **Sticker tap → place on canvas** (call `addSticker`). Stop copying asset paths. Optionally also copy PNG via the existing clipboard channel for IG.
3. **Photo backgrounds on the canvas** (or remove the packs from the picker so they don’t look broken).
4. **OTP length** (4 vs 5) + SMS brand string **Bstory**.
5. **Release signing** + bump `versionCode` off `+1`. Pick **one** application id (`com.boma.app` vs `com.boma.boma` vs a Bstory id).
6. **Wire `BOMA_API_BASE`** into the release APK. Confirm Railway is up, volume mounted, `SMS_IR_*` / `JWT_SECRET` / admin password set. Remove or protect `/admin/api/otp/:phone`.
7. **Store channel:** Cafe Bazaar / Myket vs Play. Replace placeholder store URLs. Privacy policy URL (Bazaar/Play require it).
8. **Support links** that actually open Telegram/WhatsApp/IG.
9. **Finish Boma → Bstory** in SMS, admin, iOS usage strings, force-update copy.
10. **Smoke-test** on a real phone: login with real SMS, save to gallery, IG paste, force-update off.

v1 can keep `kAllFeaturesFreeForNow = true` and skip payment if Nouri agrees.

### Nice-to-have (after v1)

- Real share sheet (WhatsApp/Telegram/native share) — code already in `ExportService.shareImage`.
- User photo as canvas background.
- FCM in the app (or drop admin “send notification” until then).
- Wire ARB strings; language switcher **or** drop ar/en claims from README.
- Onboarding (one-time “how to paste into IG Stories”).
- Server-side Pro flag + discount codes when paid.
- OTP rate limit, stronger admin auth than Basic.
- CI (`flutter analyze` + tests). Widget tests for editor/export.
- Delete unused `web/`/`macos/` or actually support them.
- Merge or close docs PR #2.

### Unknown (needs a product decision)

| Question | Why it matters |
|----------|----------------|
| **Ship store?** Cafe Bazaar / Myket / Play / TestFlight / sideload APK only | Signing, listing, privacy, force-update URLs |
| **Paid now or later?** Flip `kAllFeaturesFreeForNow` | Needs a real gateway (Zarinpal etc.) and server `is_pro` |
| **Credits vs subscription?** UI has ∞ diamond + 3/6/12 month plans | Two different models sketched, neither live |
| **Must login?** Today splash → home with optional login | Analytics/push/pro all weaker without login |
| **iOS this round?** | Bundle id, App Store, photo permissions still say بوما; no iOS clipboard channel |
| **AI captions / smart cuts in scope?** | Not in this repo. New product or out of scope |
| **Who owns sms.ir / Railway / Firebase?** | Cannot confirm production env from GitHub |
| **Legal name / Enamad / tax for payments** | Required if charging in Iran |

---

## Suggested next sprint (smallest path to “Nouri can install it”)

1. Fix stickers + photo backgrounds (or hide those tabs).
2. Fix OTP digits + Bstory SMS.
3. Signed Android APK with `BOMA_API_BASE` pointed at Railway.
4. Privacy page + Bazaar (or Play) listing + working support links.
5. Sit with Nouri: confirm **no AI/video in v1**, **free vs paid**, **store**.
