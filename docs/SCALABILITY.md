# 🌿 Green Algeria — Scalability Guide
> **Version:** v1.0.0 | **Author:** Saadi Samir | **Date:** 2026-03-09
> This document is the definitive reference for extending Green Algeria without breaking existing functionality.

---

## 1. How to Add a New Screen

### Steps
1. **Create the screen file** under `/lib/features/<feature_name>/presentation/<screen_name>_screen.dart`.
2. **Register the route** in `/lib/core/router/app_router.dart`:
   ```dart
   GoRoute(
     path: '/new-screen',
     name: 'newScreen',
     builder: (context, state) => const NewScreen(),
   ),
   ```
3. **Add localization keys** to `/lib/l10n/app_ar.arb` and `app_en.arb`.
4. **Role-guard the screen** if needed: wrap with a check on `AuthService.currentUserModel?.role`.
5. **Add navigation** from the relevant parent (bottom nav or settings list).
6. **Write at least one widget test** in `/test/features/<feature_name>/`.

### Rules
- Never skip step 4 for admin-only screens.
- Never hardcode strings — always use localization keys.
- Always use design tokens from `AppColors` — never hardcode hex values.

---

## 2. How to Add a New User Role

### Steps
1. **Add the role value** to the roles reference in Supabase via Supabase MCP:
   ```sql
   -- No roles table needed since roles are stored as TEXT in users.role column.
   -- Just document the new value here and in PROJECT_CONTEXT-2.md.
   ```
2. **Update `UserModel`** (`/lib/models/user_model.dart`):
   - Add a helper getter if needed (e.g., `bool isRegionalCoordinator`).
3. **Update role guard functions** in all screens that check `user.role`.
4. **Update Firebase custom claims** logic in `AuthService` for server-side enforcement.
5. **Update all Supabase RLS policies** via Supabase MCP to include the new role in the correct `USING` / `WITH CHECK` clauses.
6. **Update `PROJECT_CONTEXT-2.md`** — Role Hierarchy section.
7. **Write role guard unit tests** in `/test/utils/role_guard_test.dart`.

### Rules
- Never add a role without a corresponding RLS policy update.
- Document the new role's exact permissions in `PROJECT_CONTEXT-2.md` before implementing.

---

## 3. How to Add a New Tree Species to the Database

### Option A — Via Admin Panel (Production, no app update)
1. Log in with a `developer` or `initiative_owner` account.
2. Navigate to **Settings → Species Management**.
3. Tap **+ Add Species** and fill in all fields:
   - `name_ar`, `name_en`, `scientific_name`, `description`, `ecological_zone`
   - Upload image (saved to Supabase Storage under `/species-images/`)
4. Tap **Save** — species appears immediately in the species selector for all users.

### Option B — Via Supabase MCP (Bulk import / seeding)
```sql
INSERT INTO tree_species (name_ar, name_en, name_scientific, description, ecological_zone, is_active) VALUES
('أَرُز', 'Cedar', 'Cedrus libani', 'الأرز اللبناني', 'Mountain', true),
('...', '...', '...', '...', '...', true);
```

### Rules
- Always provide both Arabic and English names.
- `is_active = false` hides the species from the selector without deleting data.
- Use the `metadata` JSONB column for any extra fields — never add raw columns without a migration plan.

---

## 4. How to Add a New Authentication Provider

### Example: Adding Apple Sign-In
1. **Enable the provider** via Firebase MCP in Antigravity IDE:
   - Firebase Console → Authentication → Sign-in method → Apple → Enable.
2. **Add the iOS configuration** (Apple requires a `.entitlements` file and keychain settings).
3. **Install the package** if needed (e.g., `sign_in_with_apple`).
4. **Add the sign-in method** in `AuthService`:
   ```dart
   Future<void> signInWithApple() async {
     // ... Apple auth credential logic
     await _auth.signInWithCredential(appleCredential);
   }
   ```
5. **Add a button** on the Login Screen using a Stitch MCP component.
6. **Test** the full flow: sign in → Supabase user record created → role = 'volunteer'.

### Rules
- New auth providers must still create a Supabase `users` record on first login.
- Default role for any new auth provider is always `volunteer`.
- Facebook Sign-In is already scaffolded (placeholder in `auth_service.dart`) — just activate in Firebase Console and add the credential handler.

---

## 5. How to Add a New Notification Type

### Steps
1. **Define the new FCM topic** name (e.g., `city-{city_id}` for city-level alerts).
2. **Subscribe users** to the topic in `AuthService._syncUserRecord()`.
3. **Add the sending UI** in the hidden admin notifications screen (role-guarded).
4. **Add the Supabase Edge Function** or update the existing one to handle the new `type`.
5. **Save to `notifications` table** with the new `type` value.
6. **Update the `notifications` table RLS** to allow the correct roles to INSERT.
7. **Handle in-app receipt** in `notification_service.dart`.
8. **Document** the new type in `PROJECT_CONTEXT-2.md` → Notification Rules section.

### Rules
- Always use FCM topics — never send to individual FCM tokens (doesn't scale).
- Unsubscribe from topics on logout.
- Re-subscribe on login.

---

## 6. Database Migration Process

### When Adding a New Column
```sql
-- Via Supabase MCP (apply_migration tool):
ALTER TABLE table_name ADD COLUMN new_column_name COLUMN_TYPE DEFAULT default_value;
```
- Always provide a `DEFAULT` value for existing rows.
- Update the corresponding Dart model class.
- Update `fromJson()` and `toJson()` in the model.
- Update any Supabase RLS policies if the new column is sensitive.

### When Adding a New Table
1. Use `mcp_supabase-mcp-server_apply_migration` with a descriptive `name`.
2. Enable RLS immediately:
   ```sql
   ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;
   ```
3. Create at minimum a `SELECT` policy for authenticated users (if public data) or a user-scoped policy.
4. Add indexes on `user_id`, `province_id`, and any foreign keys.
5. Document the new table in `PROJECT_CONTEXT-2.md` → Database Schema Overview.

### When Modifying Existing RLS Policies
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
CREATE POLICY "policy_name" ON table_name
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

### Rules
- **Never bypass RLS** — never use service role key in client code.
- **All schema changes** must be documented in `PROJECT_CONTEXT-2.md`.
- **Always test** the new policy with a non-admin user after applying.

---

## 7. Architecture Overview

```
green_algeria/
├── lib/
│   ├── core/              # Shared: theme, router, widgets, models
│   ├── features/          # Feature-first: each feature is self-contained
│   │   ├── auth/
│   │   ├── home/
│   │   ├── map/
│   │   ├── campaigns/
│   │   ├── leaderboard/
│   │   └── profile/
│   ├── models/            # Global data models (Supabase tables)
│   ├── services/          # AuthService, SupabaseService, SyncEngine, NotificationService
│   └── l10n/              # Arabic (ar.arb) + English (en.arb)
├── test/
│   ├── models/            # Unit tests for all models
│   ├── services/          # Unit tests for service logic
│   └── utils/             # Role guard and utility tests
└── docs/                  # This file and all other documentation
```

---

*Green Algeria — الجزائر خضراء*
*Developer: Saadi Samir | Initiative: Brother Fouad*
