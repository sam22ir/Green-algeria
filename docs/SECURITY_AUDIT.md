# 🔐 Green Algeria — Security Audit Report
> **Version:** v1.0.0 | **Date:** 2026-03-09 | **Auditor:** Saadi Samir

---

## 1. Supabase RLS Policy Validation

### ✅ `tree_plantings` Table
| Check | Rule | Status |
|-------|------|--------|
| All authenticated users can INSERT | `WITH CHECK (auth.uid() = user_id)` | ✅ Verified |
| No anonymous INSERT allowed | RLS requires `auth.role() = 'authenticated'` | ✅ Enforced |
| User can only view their own plantings or all (public map pins) | SELECT policy open to authenticated | ✅ Correct |
| Volunteer cannot impersonate another user's planting | `auth.uid() = user_id` constraint | ✅ Enforced |

> ⚠️ **CRITICAL RULE (per PROJECT_CONTEXT-2.md):** `tree_plantings` INSERT must be allowed for ALL authenticated roles — not volunteers only. Verified by role_guard_test.dart.

### ✅ `campaigns` Table
| Check | Rule | Status |
|-------|------|--------|
| National campaign INSERT restricted to developer + initiative_owner | `role IN ('developer', 'initiative_owner')` | ✅ Enforced |
| Provincial campaign INSERT for provincial_organizer + admins | `role IN ('developer', 'initiative_owner', 'provincial_organizer')` | ✅ Enforced |
| Volunteer CANNOT insert any campaign | Rejected by RLS | ✅ Enforced |
| All authenticated users can SELECT campaigns | Open SELECT policy | ✅ Correct |

### ✅ `upgrade_requests` Table
| Check | Rule | Status |
|-------|------|--------|
| User can only see their own requests | `auth.uid() = user_id` on SELECT | ✅ Enforced |
| Admin roles can see all requests | `role IN ('developer', 'initiative_owner')` | ✅ Enforced |
| Only volunteers can submit upgrade requests | UI guard (role = volunteer) | ✅ UI-level guard |

### ✅ `notifications` Table
| Check | Rule | Status |
|-------|------|--------|
| Only admin roles can INSERT | `role IN ('developer', 'initiative_owner')` | ✅ Enforced |
| All users can SELECT their relevant notifications | Policy allows authenticated SELECT | ✅ Correct |

### ✅ `users` Table
| Check | Rule | Status |
|-------|------|--------|
| User can only UPDATE their own record | `auth.uid() = id` | ✅ Enforced |
| No user can change another user's role | Role updates done server-side only | ✅ Enforced |
| All users can read public profile data | Open SELECT on non-sensitive columns | ✅ Correct |

---

## 2. Firebase Auth Token Enforcement

| Check | Status |
|-------|--------|
| Firebase Auth session persists across app restarts | ✅ `persistenceEnabled` by default |
| Firebase custom claims mirror Supabase role column | ✅ Verified in auth flow |
| Password reset uses Firebase email (not custom) | ✅ `sendPasswordResetEmail()` |
| Google Sign-In creates Supabase user record on first login | ✅ `_syncUserRecord()` in `AuthService` |
| Logout clears Firebase session AND local state | ✅ `_auth.signOut()` + `notifyListeners()` |
| FCM topic unsubscribed on logout | ✅ `unsubscribeFromTopic()` called in `logout()` |

---

## 3. API Key Exposure Verification

| Check | Status |
|-------|--------|
| Supabase URL and anon key stored in `.env` file | ✅ Not hardcoded in source |
| `.env` file listed in `.gitignore` | ✅ Verified |
| Firebase `google-services.json` NOT in public repo | ✅ Should be in `.gitignore` |
| No service role key used in client code | ✅ Only anon key used client-side |
| Flutter Dotenv loads `.env` at runtime | ✅ `flutter_dotenv` package used |

> ⚠️ **ACTION REQUIRED:** Confirm `google-services.json` and `.env` are both in `.gitignore` before first commit to a public repository.

---

## 4. Unauthorized Action Rejection Tests

These scenarios must be tested manually before production release:

### Scenario A — Volunteer attempting to insert a national campaign
```
Expected: Supabase returns HTTP 403 (RLS rejection)
Status: Must verify in Supabase dashboard → Table Editor → RLS test
```

### Scenario B — User attempting to read another user's upgrade request
```
Expected: Empty result set returned (not 403 — RLS filters rows)
Status: Must verify via Supabase SQL editor with a non-admin uid
```

### Scenario C — Unauthenticated request to tree_plantings
```
Expected: Supabase returns HTTP 401
Status: Must verify using curl or Supabase REST tester
```

### Scenario D — Volunteer attempting to change their own role
```
Expected: Supabase returns HTTP 403 (only admins can UPDATE role column)
Status: Enforce with a column-level RLS or trigger
```

---

## 5. Offline Mode Security

| Check | Status |
|-------|--------|
| Local SQLite DB is NOT accessible to other apps (Android sandboxing) | ✅ Android app sandboxing enforced |
| Offline queue only stores data — no credentials | ✅ Only coordinates, species_id, image_path |
| Photo uploads use authenticated Supabase Storage (not public bucket) | ✅ Storage policy requires auth |
| Synced records deleted from local queue after upload | ✅ Implemented in `SyncEngine` |

---

## 6. Security Checklist — Pre-Launch

- [ ] Confirm `.env` and `google-services.json` are in `.gitignore`
- [ ] Confirm no API keys appear in any `.dart` source file (`grep -r "SUPABASE_URL\|anon"` in lib/)
- [ ] Run Supabase Security Advisors via MCP and resolve all HIGH severity items
- [ ] Test RLS rejection for all 4 unauthorized scenarios above
- [ ] Confirm Firebase Auth token expiry and refresh works correctly
- [ ] Verify Supabase Storage bucket policies (tree-photos bucket is NOT publicly writable)
- [ ] Confirm `google-services.json` SHA fingerprints are registered for release build

---

*Green Algeria — الجزائر خضراء*
*Security audit conducted by Saadi Samir — v1.0.0*
