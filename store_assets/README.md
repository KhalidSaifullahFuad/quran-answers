# Play Store release kit

Everything Play Console asks for, and what to answer. Graphics are generated;
text is in `listing.md`; the privacy policy is `privacy-policy.md`.

## Regenerating graphics

```bash
flutter test tool/render_assets_test.dart
```

Writes the launcher icons (`android/app/src/main/res/mipmap-*`) and, into
`output/`, `icon_512.png`, `0_feature.png` and the numbered screenshots
`1_home.png` … `6_surahs.png` (upload in that order). The screenshots are the real app on
the shipped content database (last made 2026-10-19 from all 200 questions);
rerun after any content or design change. The home screenshot shows the day it
was generated. Each screenshot is framed for the listing: on a warm paper-to-gold
gradient, a small eyebrow line and a two-line serif Bengali headline (Noto
Serif Bengali from `tool/fonts/`, not shipped in the app) above the screen in a
phone that runs off the bottom edge; the captions and their order live in the
test and are mirrored in `screenshot_copy.md`. `output/` is gitignored: run the generator
before every upload. Store PNGs are written without alpha, as Play asks.

## One-time setup (author only — involves secrets)

1. **Upload key.** Create it once and back it up somewhere safe; losing it
   means asking Google for a key reset.

   ```bash
   keytool -genkey -v -keystore <somewhere-outside-the-repo>/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **`android/key.properties`** (gitignored):

   ```properties
   storeFile=<absolute path to upload-keystore.jks>
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Without this file a release build is signed with the debug key and Play
   rejects the upload.

3. **Play App Signing**: accept Google-managed app signing when creating the
   app; the key above is only the upload key.

4. **Privacy policy URL**: Play requires one. Host `privacy-policy.md` anywhere
   public (e.g. GitHub Pages or a Google Site), fill in the date and email.

## Build

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Bump `version:` in `pubspec.yaml` for every upload — the part after `+` is the
Android `versionCode` and must increase.

## Play Console answers

**App content → Data safety**

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| (Follows from) | No internet permission in the release manifest; bookmarks, history and settings stay in app-private storage. |

**App content → other declarations**

| Item | Answer |
|---|---|
| Ads | No ads |
| App access | All functionality available without special access |
| Content rating (IARC) | Reference / religious text; no violence, sex, profanity, gambling, user interaction or location sharing. Expect "Everyone" / 3+. |
| Target audience | 13+ recommended. Including under-13s puts the app under the Families policy, which adds requirements without benefit here. |
| News app | No |
| Government app | No |
| Financial features | None |
| Health | No |

**Store settings**: category Books & Reference; free; countries at the
author's discretion (Bangladesh, India at minimum).

## First release track

Play requires new personal developer accounts to run a **closed test with at
least 12 testers for 14 days** before production access. Plan for it.
