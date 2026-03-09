import 'package:flutter_test/flutter_test.dart';
import 'package:green_algeria/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses complete JSON correctly', () {
      final json = {
        'id': 'uid-abc-123',
        'full_name': 'سمير سعدي',
        'email': 'samir@example.com',
        'province_id': 16,
        'role': 'provincial_organizer',
        'avatar_url': 'https://example.com/avatar.jpg',
        'tree_count': 42,
        'campaign_count': 3,
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-06-20T14:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'uid-abc-123');
      expect(user.fullName, 'سمير سعدي');
      expect(user.email, 'samir@example.com');
      expect(user.provinceId, 16);
      expect(user.role, 'provincial_organizer');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.treeCount, 42);
      expect(user.campaignCount, 3);
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
    });

    test('fromJson defaults role to volunteer when null', () {
      final json = {
        'id': 'uid-def-456',
        'full_name': 'Test User',
        'email': 'test@example.com',
      };

      final user = UserModel.fromJson(json);
      expect(user.role, 'volunteer');
      expect(user.treeCount, 0);
      expect(user.campaignCount, 0);
    });

    test('isOrganizer returns true for elevated roles', () {
      for (final role in ['developer', 'initiative_owner', 'provincial_organizer', 'local_organizer']) {
        final user = UserModel(id: '1', fullName: 'Test', email: 'e@e.com', role: role);
        expect(user.isOrganizer, true, reason: '$role should be organizer');
      }
    });

    test('isOrganizer returns false for volunteer', () {
      final user = UserModel(id: '1', fullName: 'Test', email: 'e@e.com', role: 'volunteer');
      expect(user.isOrganizer, false);
    });

    test('isAdmin returns true only for developer and initiative_owner', () {
      expect(UserModel(id: '1', fullName: 'T', email: 'e', role: 'developer').isAdmin, true);
      expect(UserModel(id: '1', fullName: 'T', email: 'e', role: 'initiative_owner').isAdmin, true);
      expect(UserModel(id: '1', fullName: 'T', email: 'e', role: 'provincial_organizer').isAdmin, false);
      expect(UserModel(id: '1', fullName: 'T', email: 'e', role: 'volunteer').isAdmin, false);
    });

    test('toJson produces correct map', () {
      final user = UserModel(
        id: 'uid-1',
        fullName: 'Ahmed',
        email: 'ahmed@test.com',
        provinceId: 9,
        role: 'volunteer',
        treeCount: 5,
        campaignCount: 1,
      );

      final json = user.toJson();

      expect(json['id'], 'uid-1');
      expect(json['full_name'], 'Ahmed');
      expect(json['province_id'], 9);
      expect(json['tree_count'], 5);
      expect(json.containsKey('avatar_url'), false); // null avatar excluded
    });
  });
}
