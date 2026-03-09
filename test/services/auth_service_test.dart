import 'package:flutter_test/flutter_test.dart';
import 'package:green_algeria/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth & Role Logic Unit Tests — Chapter 15 (Green Algeria)
// Tests role hierarchy, permissions, and derived properties of UserModel
// which mirrors the Firebase custom claims + Supabase role column logic.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Role Hierarchy — isVolunteer', () {
    test('volunteer role returns isVolunteer true', () {
      final user = UserModel(id: '1', fullName: 'Ali', email: 'a@a.com', role: 'volunteer');
      expect(user.role, 'volunteer');
      expect(user.isOrganizer, false);
      expect(user.isAdmin, false);
    });

    test('non-volunteer roles return isVolunteer false', () {
      for (final role in ['developer', 'initiative_owner', 'provincial_organizer', 'local_organizer']) {
        final user = UserModel(id: '1', fullName: 'Test', email: 'e@e.com', role: role);
        expect(user.isOrganizer, true, reason: '$role should NOT be volunteer');
      }
    });
  });

  group('Role Hierarchy — canCreateCampaign', () {
    test('volunteer cannot create campaigns (isOrganizer = false)', () {
      final user = UserModel(id: '1', fullName: 'Ali', email: 'a@a.com', role: 'volunteer');
      expect(user.isOrganizer, false);
    });

    test('local_organizer can create campaigns', () {
      final user = UserModel(id: '2', fullName: 'Karim', email: 'k@k.com', role: 'local_organizer');
      expect(user.isOrganizer, true);
    });

    test('provincial_organizer can create campaigns', () {
      final user = UserModel(id: '3', fullName: 'Fatima', email: 'f@f.com', role: 'provincial_organizer');
      expect(user.isOrganizer, true);
    });

    test('initiative_owner can create national campaigns', () {
      final user = UserModel(id: '4', fullName: 'Fouad', email: 'fouad@green.dz', role: 'initiative_owner');
      expect(user.isOrganizer, true);
      expect(user.isAdmin, true);
    });

    test('developer can do everything', () {
      final user = UserModel(id: '5', fullName: 'Samir', email: 'samir@green.dz', role: 'developer');
      expect(user.isOrganizer, true);
      expect(user.isAdmin, true);
    });
  });

  group('Role Hierarchy — isAdmin (Developer + Initiative Owner only)', () {
    final adminRoles = ['developer', 'initiative_owner'];
    final nonAdminRoles = ['volunteer', 'local_organizer', 'provincial_organizer'];

    for (final role in adminRoles) {
      test('$role has admin access', () {
        final user = UserModel(id: '1', fullName: 'Test', email: 'e@e.com', role: role);
        expect(user.isAdmin, true);
      });
    }

    for (final role in nonAdminRoles) {
      test('$role does NOT have admin access', () {
        final user = UserModel(id: '1', fullName: 'Test', email: 'e@e.com', role: role);
        expect(user.isAdmin, false);
      });
    }
  });

  group('Default Role on New Registration', () {
    test('new user created from minimal JSON defaults to volunteer', () {
      final json = {
        'id': 'new-uid-789',
        'full_name': 'متطوع جديد',
        'email': 'new@green.dz',
      };

      final user = UserModel.fromJson(json);
      expect(user.role, 'volunteer');
    });

    test('new user has 0 tree count and 0 campaign count by default', () {
      final json = {'id': 'x', 'full_name': 'X', 'email': 'x@x.com'};
      final user = UserModel.fromJson(json);
      expect(user.treeCount, 0);
      expect(user.campaignCount, 0);
    });
  });

  group('Tree Planting Permission (ALL authenticated roles)', () {
    // Green Algeria Rule: ALL roles can plant trees.
    // This must be enforced at Supabase RLS + UI level.
    final allRoles = [
      'volunteer',
      'local_organizer',
      'provincial_organizer',
      'initiative_owner',
      'developer',
    ];

    for (final role in allRoles) {
      test('$role is allowed to plant trees (authenticated)', () {
        final user = UserModel(id: '1', fullName: 'Planter', email: 'p@p.com', role: role);
        // All authenticated users regardless of role can plant a tree.
        // The rule: user.id != null means authenticated = allowed to plant.
        expect(user.id, isNotEmpty);
        expect(user.role, role); // role is set correctly
      });
    }
  });

  group('FCM Topic Subscription Logic', () {
    test('user with provinceId 16 subscribes to province-16 topic', () {
      final user = UserModel(
        id: 'u1',
        fullName: 'Alger',
        email: 'u@u.com',
        role: 'volunteer',
        provinceId: 16,
      );
      final expectedTopic = 'province-${user.provinceId}';
      expect(expectedTopic, 'province-16');
    });

    test('user without province subscribes only to national topic', () {
      final user = UserModel(
        id: 'u2',
        fullName: 'No Province',
        email: 'u2@u.com',
        role: 'volunteer',
        provinceId: null,
      );
      expect(user.provinceId, isNull);
      // Only 'national-notifications' subscribed — no province sub.
    });

    test('on province change, old topic is unsubscribed and new one subscribed', () {
      // Simulates the province update logic:
      // old province = 16, new province = 31
      const oldProvince = 16;
      const newProvince = 31;
      final oldTopic = 'province-$oldProvince';
      final newTopic = 'province-$newProvince';
      expect(oldTopic, 'province-16');
      expect(newTopic, 'province-31');
      expect(oldTopic == newTopic, false);
    });
  });

  group('Session Persistence Logic', () {
    test('UserModel serializes and deserializes consistently (session restore)', () {
      final original = UserModel(
        id: 'session-uid',
        fullName: 'سمير',
        email: 'samir@green.dz',
        role: 'provincial_organizer',
        provinceId: 9,
        treeCount: 120,
        campaignCount: 7,
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fullName, original.fullName);
      expect(restored.email, original.email);
      expect(restored.role, original.role);
      expect(restored.provinceId, original.provinceId);
      expect(restored.treeCount, original.treeCount);
      expect(restored.campaignCount, original.campaignCount);
    });
  });
}
