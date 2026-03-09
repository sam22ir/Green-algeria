# 🌿 Green Algeria — Release Notes v1.0.0
> **Release Date:** 2026-03-09 | **Build:** 1.0.0+1
> **Developer:** Saadi Samir | **Initiative Owner:** Brother Fouad

---

## Summary

Green Algeria v1.0.0 is the **initial production release** of the community tree-planting documentation platform for Algeria. This release delivers all 15 chapters of the master development plan across 3 phases.

---

## ✅ What's Included in v1.0.0

### Phase 1 — Foundation & Core Setup
- **Chapter 1:** Project initialized with Flutter/Dart. MCPs connected (Stitch, Supabase, Firebase). Scalable folder structure created.
- **Chapter 2:** Complete design system established using the Soft Organic palette (linen-white, moss-forest, olive-grove, ivory-sand, sage-cream, slate-charcoal, olive-grey). All reusable UI components built via Stitch MCP. Full Light/Dark Mode support.
- **Chapter 3:** Firebase Authentication with Email/Password and Google Sign-In. 5-role user hierarchy (Developer, Initiative Owner, Provincial Organizer, Local Organizer, Volunteer). Upgrade request system for volunteers to request organizer role.
- **Chapter 4:** Full Supabase database schema deployed with 10 tables. RLS policies on all tables. Database indexes on all frequently queried columns. 30+ Algerian tree species seeded. All 58 provinces seeded in Arabic and English.
- **Chapter 5:** App shell with go_router navigation. 5-tab bottom navigation. Splash screen. Full Arabic (RTL) and English (LTR) localization. Light/Dark theme management.

### Phase 2 — Feature Development
- **Chapter 6:** Home Screen with national campaign countdown, total trees counter (Supabase realtime), and past campaigns feed.
- **Chapter 7:** Interactive Algeria map (flutter_map) with GPS, tap-to-plant flow, photo upload to Supabase Storage, species selector, pin clustering, and offline queuing.
- **Chapter 8:** Campaigns Screen with 3 tabs (National / Provincial / Local). Role-based campaign creation. Campaign detail screen. Real-time campaign updates.
- **Chapter 9:** Leaderboard with top-3 medals, individual and provincial rankings, current user highlight, search, and Supabase cache for performance.
- **Chapter 10:** Profile Screen (avatar, stats, planting history). Settings Screen (language, dark mode, notifications, bug report, upgrade request, logout). About Screen (mission, Fouad's initiative, social links, developer credit).

### Phase 3 — Advanced Systems & Production
- **Chapter 11:** Two-tier push notification system via Firebase Cloud Messaging. FCM topic subscriptions per user (national + province). Admin notification sending UI. In-app banners + OS notifications.
- **Chapter 12:** Offline-first system with local SQLite queue (sqflite). Automatic background sync when connectivity restores. Visual offline indicator (orange banner). Sync progress indicator. No tree planting data is ever lost.
- **Chapter 13:** Tree species database with 30+ Algerian native species. Searchable species selector (Arabic and English). Species detail view with planting count. Admin species management panel. Extensible JSONB metadata column.
- **Chapter 14:** Full Supabase Realtime implementation. Single RealtimeService managing all channels. Live map pins, live tree counter, live campaign feed, live leaderboard. Optimistic UI updates. Auto-reconnect on disconnect.
- **Chapter 15 (this release):** 8 unit test files, 30+ test cases covering all models, offline queue, sync engine, role guards, and FCM logic. Security audit documentation. Performance standards defined and validated. SCALABILITY.md written for future contributors. Full deployment guide with Play Store listing content in Arabic and English.

---

## 📊 Test Coverage

| Test File | Tests | Coverage Area |
|-----------|-------|---------------|
| `user_model_test.dart` | 5 | UserModel serialization, role getters |
| `campaign_model_test.dart` | 4 | CampaignModel serialization, defaults |
| `tree_planting_model_test.dart` | 5 | TreePlantingModel, nullable fields, types |
| `tree_species_test.dart` | 4 | TreeSpecies, metadata, roundtrip |
| `local_db_service_test.dart` | 4 | SQLite queue insert, filter, update, delete |
| `auth_service_test.dart` | 12 | Role hierarchy, FCM topics, session restore |
| `sync_engine_test.dart` | 10 | Queue lifecycle, dedup, stress, coordinates |
| `role_guard_test.dart` | 18 | All permission guards for all 5 roles |
| **Total** | **62** | All critical app logic paths |

---

## 🏗️ Architecture Decisions in v1.0.0

| Decision | Reason |
|----------|--------|
| Supabase for all data (not Firebase Firestore) | RLS + Realtime + PostgREST better suited for this data model |
| Firebase for Auth + FCM only | Best-in-class push + Google Sign-In |
| Stitch MCP for all UI design | Ensures design system consistency across all screens |
| `leaderboard_cache` table | Avoids expensive live aggregation; refreshed by DB trigger |
| `offline_queue` in local SQLite | Reliable offline-first without depending on Supabase offline mode |
| `olive-grove #606C38` as primary action color | Swapped from moss-forest for better visual contrast (v1.1 decision) |
| Tree planting allowed for ALL roles | All authenticated users can document trees regardless of role |

---

## 🔮 Future Features Backlog (v2.0 Planning)

| Feature | Priority |
|---------|----------|
| Badges & Achievements (digital medals for volunteers) | 🔴 High |
| CO₂ Statistics (environmental impact dashboard) | 🔴 High |
| Facebook Sign-In | 🟡 Medium |
| Team System (competitive groups between cities) | 🟡 Medium |
| Photo Gallery (public feed of planting photos) | 🟡 Medium |
| Comment System (reactions on map pins) | 🟡 Medium |
| Campaign Calendar | 🟢 Low |
| Home Screen Widget (tree counter outside the app) | 🟢 Low |

---

*Green Algeria — الجزائر خضراء*
*Built with Google Antigravity IDE + Stitch MCP + Supabase MCP + Firebase MCP*
*One tree, one pin, one person at a time — until Algeria is green.*
