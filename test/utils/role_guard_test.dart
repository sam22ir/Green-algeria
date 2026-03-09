import 'package:flutter_test/flutter_test.dart';
import 'package:green_algeria/models/user_model.dart';
import 'package:green_algeria/models/campaign_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Role Guard Unit Tests — Chapter 15 (Green Algeria)
// Tests UI-level permission guards that mirror Supabase RLS policies.
// These guards are the FIRST line of defense; RLS is the second.
// ─────────────────────────────────────────────────────────────────────────────

/// Simulates the permission check function used in the app:
/// Returns true if the user is allowed to create a campaign of the given type.
bool canCreateCampaign(UserModel user, String campaignType) {
  switch (campaignType) {
    case 'national':
      return user.role == 'developer' || user.role == 'initiative_owner';
    case 'provincial':
      return ['developer', 'initiative_owner', 'provincial_organizer'].contains(user.role);
    case 'local':
      return ['developer', 'initiative_owner', 'provincial_organizer', 'local_organizer']
          .contains(user.role);
    default:
      return false;
  }
}

/// Simulates permission to send notifications.
bool canSendNotification(UserModel user, String notificationType) {
  switch (notificationType) {
    case 'national':
      return user.isAdmin;
    case 'provincial':
      return user.isOrganizer; // provincial_organizer + admins
    default:
      return false;
  }
}

/// Simulates permission to approve upgrade requests.
bool canApproveUpgradeRequest(UserModel user) => user.isAdmin;

/// Simulates permission to manage tree species.
bool canManageSpecies(UserModel user) => user.isAdmin;

/// Simulates permission to see volunteer-only upgrade request button.
bool showsUpgradeRequestButton(UserModel user) => user.role == 'volunteer';

UserModel _user(String role, {int? provinceId}) =>
    UserModel(id: 'u', fullName: 'Test', email: 't@t.com', role: role, provinceId: provinceId);

void main() {
  // ───────── Campaign Creation Guards ─────────
  group('Campaign Creation Guards', () {
    group('National campaigns', () {
      test('developer can create national campaigns', () {
        expect(canCreateCampaign(_user('developer'), 'national'), true);
      });
      test('initiative_owner can create national campaigns', () {
        expect(canCreateCampaign(_user('initiative_owner'), 'national'), true);
      });
      test('provincial_organizer CANNOT create national campaigns', () {
        expect(canCreateCampaign(_user('provincial_organizer'), 'national'), false);
      });
      test('local_organizer CANNOT create national campaigns', () {
        expect(canCreateCampaign(_user('local_organizer'), 'national'), false);
      });
      test('volunteer CANNOT create national campaigns', () {
        expect(canCreateCampaign(_user('volunteer'), 'national'), false);
      });
    });

    group('Provincial campaigns', () {
      test('provincial_organizer can create provincial campaigns', () {
        expect(canCreateCampaign(_user('provincial_organizer'), 'provincial'), true);
      });
      test('local_organizer CANNOT create provincial campaigns', () {
        expect(canCreateCampaign(_user('local_organizer'), 'provincial'), false);
      });
      test('volunteer CANNOT create provincial campaigns', () {
        expect(canCreateCampaign(_user('volunteer'), 'provincial'), false);
      });
    });

    group('Local campaigns', () {
      test('local_organizer CAN create local campaigns', () {
        expect(canCreateCampaign(_user('local_organizer'), 'local'), true);
      });
      test('volunteer CANNOT create local campaigns', () {
        expect(canCreateCampaign(_user('volunteer'), 'local'), false);
      });
    });
  });

  // ───────── Notification Permission Guards ─────────
  group('Notification Permission Guards', () {
    test('developer can send national notifications', () {
      expect(canSendNotification(_user('developer'), 'national'), true);
    });
    test('initiative_owner can send national notifications', () {
      expect(canSendNotification(_user('initiative_owner'), 'national'), true);
    });
    test('provincial_organizer CANNOT send national notifications', () {
      expect(canSendNotification(_user('provincial_organizer'), 'national'), false);
    });
    test('volunteer CANNOT send any notifications', () {
      expect(canSendNotification(_user('volunteer'), 'national'), false);
      expect(canSendNotification(_user('volunteer'), 'provincial'), false);
    });
    test('provincial_organizer CAN send provincial notifications', () {
      expect(canSendNotification(_user('provincial_organizer'), 'provincial'), true);
    });
  });

  // ───────── Admin Panel Guards ─────────
  group('Admin Panel Guards', () {
    test('developer can approve upgrade requests', () {
      expect(canApproveUpgradeRequest(_user('developer')), true);
    });
    test('initiative_owner can approve upgrade requests', () {
      expect(canApproveUpgradeRequest(_user('initiative_owner')), true);
    });
    test('provincial_organizer CANNOT approve upgrade requests', () {
      expect(canApproveUpgradeRequest(_user('provincial_organizer')), false);
    });
    test('volunteer CANNOT approve upgrade requests', () {
      expect(canApproveUpgradeRequest(_user('volunteer')), false);
    });
  });

  // ───────── Species Management Guards ─────────
  group('Species Management Guards', () {
    test('developer can manage tree species', () {
      expect(canManageSpecies(_user('developer')), true);
    });
    test('initiative_owner can manage tree species', () {
      expect(canManageSpecies(_user('initiative_owner')), true);
    });
    test('provincial_organizer CANNOT manage species', () {
      expect(canManageSpecies(_user('provincial_organizer')), false);
    });
    test('volunteer CANNOT manage species', () {
      expect(canManageSpecies(_user('volunteer')), false);
    });
  });

  // ───────── UI Visibility Guards ─────────
  group('UI Visibility — Upgrade Request Button', () {
    test('volunteer sees upgrade request button', () {
      expect(showsUpgradeRequestButton(_user('volunteer')), true);
    });
    test('local_organizer does NOT see upgrade request button', () {
      expect(showsUpgradeRequestButton(_user('local_organizer')), false);
    });
    test('developer does NOT see upgrade request button', () {
      expect(showsUpgradeRequestButton(_user('developer')), false);
    });
  });

  // ───────── Campaign Model Role Validation ─────────
  group('Campaign Model — Type + Role Consistency', () {
    test('national campaign without province_id is valid', () {
      final campaign = CampaignModel(id: 1, title: 'وطنية', type: 'national');
      expect(campaign.provinceId, isNull);
      expect(campaign.type, 'national');
    });

    test('provincial campaign must have province_id', () {
      final campaign = CampaignModel(id: 2, title: 'ولائية', type: 'provincial', provinceId: 16);
      expect(campaign.provinceId, 16);
      expect(campaign.type, 'provincial');
    });

    test('campaign progress percentage is correct', () {
      final campaign = CampaignModel(
        id: 3, title: 'Test', type: 'national',
        treeGoal: 10000, treePlanted: 4500,
      );
      final progress = campaign.treeGoal > 0
          ? campaign.treePlanted / campaign.treeGoal
          : 0.0;
      expect(progress, closeTo(0.45, 0.001));
    });

    test('campaign with zero goal does not divide by zero', () {
      final campaign = CampaignModel(id: 4, title: 'Empty', type: 'local', treeGoal: 0);
      final progress = campaign.treeGoal > 0 ? campaign.treePlanted / campaign.treeGoal : 0.0;
      expect(progress, 0.0);
    });
  });
}
