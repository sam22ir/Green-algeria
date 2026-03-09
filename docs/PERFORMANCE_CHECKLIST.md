# ⚡ Green Algeria — Performance Checklist
> **Version:** v1.0.0 | **Date:** 2026-03-09

This document defines the performance standards that must be met before each production release.

---

## 1. Map Screen — 1,000+ Pin Stress Test

### Standard
- Map must remain smooth (≥60fps) with 1,000+ tree pins.
- Clustering must activate at zoom levels < 13.
- Cluster tap must expand smoothly in < 200ms.

### Test Procedure
```sql
-- Seed 1000 random tree plantings within Algeria bounds for testing:
INSERT INTO tree_plantings (user_id, latitude, longitude, tree_species_id, planted_at, is_synced)
SELECT
  'test-uid-perf',
  18.9 + random() * (37.1 - 18.9),  -- lat: Algeria bounds
  -8.7 + random() * (11.9 - (-8.7)), -- lng: Algeria bounds
  1,
  NOW(),
  true
FROM generate_series(1, 1000);
```

### Pass Criteria
- [ ] Map loads within 3 seconds on mid-range Android device
- [ ] Clustering groups pins visibly at zoom < 13
- [ ] Panning and zooming remain smooth (no jank)
- [ ] Tapping a cluster expands without black screen

---

## 2. Leaderboard — 500+ Users Performance

### Standard
- Leaderboard must load within **2 seconds** on first render.
- Data is served from `leaderboard_cache` table — NOT from live aggregation.
- Scrolling through 500+ rows must remain smooth.

### Test Procedure
```sql
-- Verify leaderboard_cache has populated entries:
SELECT COUNT(*) FROM leaderboard_cache;
-- Must return ≥ the number of users

-- Test query speed:
EXPLAIN ANALYZE
SELECT * FROM leaderboard_cache ORDER BY rank_national ASC LIMIT 100;
-- Execution time must be < 50ms
```

### Pass Criteria
- [ ] Leaderboard renders within 2 seconds on first load
- [ ] Scrolling 500+ items is smooth (no dropped frames)
- [ ] Search (filter by name) returns results in < 500ms
- [ ] Pull-to-refresh completes within 2 seconds

---

## 3. Offline Mode — 10 Queued Plantings Sync Test

### Standard
- All 10 offline items must sync correctly when connectivity restores.
- Zero duplicates allowed in `tree_plantings` table after sync.
- Each item must transition: `pending → uploading → synced → deleted from queue`.

### Test Procedure
1. Enable airplane mode on the test device.
2. Document 10 tree plantings on the Map Screen.
3. Verify 10 items appear in the local offline queue (orange banner shows).
4. Re-enable internet connectivity.
5. Verify sync icon appears in top bar.
6. After sync completes, verify:
   - 10 new pins appear on the map.
   - Local offline queue is empty.
   - `tree_plantings` table has 10 new rows.
   - No duplicate pins on the map.

### Pass Criteria
- [ ] All 10 offline plantings appear on the map after sync
- [ ] Local queue is completely empty after sync
- [ ] No duplicate records in `tree_plantings` table
- [ ] Sync completes within 30 seconds on a normal 4G connection
- [ ] If sync fails mid-way, remaining items retain `pending` status and retry

---

## 4. Realtime Latency Test

### Standard
- New tree pin must appear on other devices within **2 seconds** of planting.
- New campaign must appear in Campaigns tab on other devices within **2 seconds**.
- Leaderboard must refresh within **3 seconds** of new planting.

### Test Procedure
1. Open the app on **Device A** and **Device B** simultaneously.
2. Plant a tree on Device A → Start timer → Observe Device B map.
3. Create a campaign on Device A → Start timer → Observe Device B campaigns tab.

### Pass Criteria
- [ ] Map pin appears on Device B within 2 seconds of Device A planting
- [ ] Campaign card appears on Device B within 2 seconds of Device A creating it
- [ ] Leaderboard updates on Device B within 3 seconds

---

## 5. General App Performance

### Standard
| Metric | Target |
|--------|--------|
| App cold start (splash to home) | < 3 seconds |
| Screen-to-screen navigation | < 300ms |
| Image loading (tree photos, species images) | < 1.5 seconds with cached_network_image |
| API calls (Supabase queries) | < 1 second for indexed queries |
| Dark mode toggle | Instant (< 50ms visual change) |
| Language switch (AR ↔ EN) | < 500ms including RTL/LTR layout change |

### Pass Criteria
- [ ] All metrics above met on a mid-range Android device (3GB RAM)
- [ ] No memory leaks detected after 10 minutes of usage (check with Flutter DevTools)
- [ ] App size (APK) < 50MB

---

*Green Algeria — الجزائر خضراء*
*Performance standards defined by Saadi Samir — v1.0.0*
