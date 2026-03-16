# Changelog — Green Algeria 🌿

All notable changes are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [v3.7] — 2026-03-16

### Added
- **Tutorial System (نظام التعليمات)**: glassmorphism olive-green card shown once per screen
  - 5 screens covered: Home, Map, Campaigns, Leaderboard, Profile
  - Custom Arabic/English messages per screen
  - Dismissed by "حسناً، فهمت!" button or outside tap
  - Old users: no tutorial shown (SharedPreferences-based)
- `TutorialService` — SharedPreferences service (`shouldShow` + `markSeen`)
- `TutorialOverlay` widget — fade animation, RTL-aware, outside-tap dismiss
- 16 new translation keys for tutorial content in `ar.json` + `en.json`

### Fixed
- Campaign counter in Profile: now fetches live from `campaign_participants` table (was reading stale field)
- Missing translation keys: `ends_in` and `starts_in` added to AR/EN

### Changed
- Initiative owner name updated to **فؤاد معلى (Fouad Mo'alla)** across all files

---

## [v3.6.5] — 2026-03-15

### Fixed
- Tree popup: planter name now fetched from `users` table (was always "مجهول")
- Tree popup: planting date now reads `planted_at` field (was always "غير معروف")
- Tree popup: share button now works via `share_plus` with clipboard fallback
- Tree popup: removed hardcoded 65% growth status section

### Removed
- Tree popup: heart/favorite button removed from action row

### Changed (Stitch MCP Redesigns)
- Countdown timer: 3 frosted glass boxes on olive-green gradient card
- Province rankings: gold/silver/bronze light-toned cards with circular badges
- Notification history: 2 pill tabs (وطني / ولائي) with unread badges

### Added
- 6 new translation keys: `national_tab`, `provincial_tab`, `no_national_notifications`, `no_provincial_notifications`, `copied_to_clipboard`, `share_tree`

---

## [v3.6] — 2026-03-14

### Fixed
- Map tree popup: was always showing `'blida'` — now shows real GPS coordinates
- Map popup layout: overflow fixed, species info enriched from `_speciesMap`
- WhatsApp link: replaced with "Coming Soon" dialog (no broken external link)

### Added
- Map: "Hide All" filter chip (`none`) hides both trees and campaign polygons
- Map: `MapScreen` accepts `initialLat/initialLng` via `GoRouterState.extra`
- Profile: tree cards now navigate to map location on tap
- `POST_NOTIFICATIONS` permission for Android 13+
- 3 new avatar assets + 3 new campaign cover assets (total: 8 each)
- Campaign organizer name resolved from UUID via Supabase join

### Removed
- Map: "Add Tree" FAB removed; location FAB now works correctly

---

## [v3.5] — 2026-03-13

### Added
- Past Campaigns screen (صفحة الحملات السابقة) — tabbed list + detail screen
- Province dropdown in Create Campaign sheet for admin/developer roles
- Memorial message in About screen

### Fixed
- Countdown timer units now use `.tr()` (Arabic: ساعة / دقيقة)
- Campaign card is now fully tappable → `/campaign-details`
- Provincial notifications scoped correctly to wilaya FCM topic

### Removed
- Floating `+` FAB removed from Campaigns screen

---

## [v3.4.1] — 2026-03-12

### Fixed
- Campaigns not displaying: explicit `.inFilter('status', ['active', 'upcoming'])` added
- Tree marker visibility: removed zone-based marker hiding logic
- Connectivity false negative: RPC failure no longer triggers offline save
- Upgrade requests not visible in dashboard: bypassed RLS join restriction
- Notifications not reaching users: fixed iOS foreground + FCM token refresh
- Instagram link correction: `sam22ir` → `sam__22__ir`

### Added
- `fcm_token` column added to `users` table in Supabase

---

## [v3.4] — 2026-03-11

### Added
- Province Detail Screen (accessible from Leaderboard province cards)
- Public Profile Screen (accessible from Leaderboard user rows)
- Notification History Screen with unread badge
- Notification Bell in Profile AppBar with unread count badge
- Official social media links in About screen (Facebook, Instagram, X, TikTok, YouTube)

---

## [v3.3] — 2026-03-10

### Added
- Official logo integration with Hero animations across 6 core screens
- Ray Casting algorithm for campaign zone click detection (point-in-polygon)
- ChoiceChip-based map filters replacing legacy buttons

### Fixed
- Glassmorphism crashes: replaced `BackdropFilter` with solid semi-transparent containers

---

## [v3.2] — 2026-03-09

### Changed
- Global `BouncingScrollPhysics` applied to all scrollable widgets
- Arabic plural rules verified (`tree_count_few/many/two`)

---

## [v3.0] — 2026-03-07

### Added
- Premium Leaderboard & Profile redesign via Stitch MCP
- Campaign termination logic (`ended_at`, `ended_by`, `end_reason`)
- Brave Browser as primary testing target (`flutter run -d chrome`)

---

## [v2.1] — 2026-03-01

### Added
- Admin Dashboard (7 sections, role-adaptive)
- Full i18n system using `easy_localization` (AR + EN)
- Offline Mode with SQLite queue + auto-sync engine
- 4 granular FCM notification topics per user

---

## [v1.0] — 2026-02-15

### Added
- Initial release: Auth, Map, Campaigns, Leaderboard, Profile, Settings
- 69 Wilayas support
- Supabase backend with RLS on all tables
- Firebase Auth + FCM integration
