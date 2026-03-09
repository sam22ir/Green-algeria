# 🚀 Green Algeria — Deployment Guide
> **Version:** v1.0.0 | **Date:** 2026-03-09 | **Developer:** Saadi Samir

---

## Pre-Launch Checklist

Before building the release APK/AAB, verify all of the following:

### Code Readiness
- [ ] `flutter analyze` returns **0 errors, 0 warnings**
- [ ] `flutter test` — all tests pass
- [ ] No hardcoded colors (all from `AppColors`)
- [ ] No hardcoded strings (all localized via `l10n`)
- [ ] `.env` file has all production keys (Supabase URL, anon key)
- [ ] `google-services.json` is the **production** Firebase config (not debug)
- [ ] App version in `pubspec.yaml` is `1.0.0+1`

### Firebase Readiness
- [ ] Firebase Authentication enabled: Email/Password + Google Sign-In
- [ ] Firebase Cloud Messaging (FCM) enabled for Android
- [ ] SHA-1 and SHA-256 fingerprints registered for release keystore in Firebase Console
- [ ] Production `google-services.json` downloaded and placed in `android/app/`

### Supabase Readiness
- [ ] All RLS policies active and tested
- [ ] Supabase Realtime enabled for: `tree_plantings`, `campaigns`, `leaderboard_cache`
- [ ] At least 30 tree species seeded in `tree_species` table
- [ ] All 58 Algerian provinces seeded in `provinces` table
- [ ] Supabase Security Advisors: all HIGH severity issues resolved
- [ ] Supabase Storage buckets configured (tree-photos, species-images)

### App Store Assets
- [ ] App icon: 1024×1024 PNG (no alpha), all resolutions generated
- [ ] Splash screen: Android & iOS variants
- [ ] Screenshots: minimum 3 screens in Arabic, 3 screens in English
- [ ] Short description (80 chars max) in Arabic and English
- [ ] Full description (4000 chars max) in Arabic and English

---

## Building Release APK (Android)

### Step 1 — Create / Verify the Keystore
```powershell
# Run once — save keystore file securely (NEVER commit to Git)
keytool -genkey -v `
  -keystore D:\keys\green_algeria_release.jks `
  -alias green_algeria `
  -keyalg RSA -keysize 2048 `
  -validity 10000
```

### Step 2 — Configure Signing in android/app/build.gradle
Add the signing config (reference from local.properties, not hardcoded):
```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

### Step 3 — Build Signed APK
```powershell
# Navigate to project folder
cd "d:\New folder (12)\green_algeria"

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Step 4 — Build Release AAB (for Play Store)
```powershell
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
# Use AAB for Google Play Store submission (preferred)
```

---

## Google Play Store Submission

### App Details (Arabic — Primary Language)

**اسم التطبيق:** الجزائر خضراء

**وصف قصير (80 حرف):**
```
وثّق كل شجرة تزرعها وانضم إلى المبادرة الوطنية للتشجير عبر خريطة الجزائر التفاعلية
```

**وصف كامل:**
```
الجزائر خضراء هو تطبيق مجتمعي يربط المتطوعين والمنظمين والمبادرة الوطنية لتشجير الجزائر على منصة واحدة.

المميزات:
🌳 وثّق الأشجار التي تزرعها مع الصور والموقع الجغرافي
🗺️ شاهد كل شجرة مزروعة على خريطة الجزائر في الوقت الحقيقي
🏆 تنافس على لوحة الشرف الوطنية والولائية
📢 تابع الحملات الوطنية والولائية والمحلية
📴 يعمل بدون إنترنت — تتزامن البيانات تلقائياً عند الاتصال

المبادرة: الأخ فؤاد | المطور: سعدي سمير
```

### App Details (English — Secondary Language)

**App Name:** Green Algeria — الجزائر خضراء

**Short Description (80 chars):**
```
Document every tree you plant and join Algeria's national reforestation initiative.
```

**Full Description:**
```
Green Algeria is a community platform connecting volunteers, organizers, and initiative leaders to document and celebrate tree planting across Algeria.

Features:
🌳 Document plantings with GPS coordinates and photos
🗺️ See every planted tree on a live interactive map of Algeria
🏆 Compete on national and provincial leaderboards
📢 Follow national, provincial, and local campaigns
📴 Works offline — auto-syncs when connectivity restores

Initiative Owner: Brother Fouad | Developer: Saadi Samir
```

---

## Post-Release Checklist

- [ ] Tag the Git repository: `git tag -a v1.0.0 -m "Green Algeria v1.0.0 — Initial Release"`
- [ ] Push the tag: `git push origin v1.0.0`
- [ ] Verify FCM works by sending a test national notification
- [ ] Monitor Supabase dashboard for any unexpected RLS errors
- [ ] Enable Supabase Realtime monitoring
- [ ] Share the app link with Brother Fouad and the initiative team

---

*Green Algeria — الجزائر خضراء*
*Built with Google Antigravity IDE + Stitch MCP + Supabase MCP + Firebase MCP*
