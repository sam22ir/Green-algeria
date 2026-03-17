import 'package:flutter_test/flutter_test.dart';
import 'package:green_algeria/models/campaign_model.dart';

void main() {
  group('CampaignModel', () {
    test('fromJson parses complete JSON correctly', () {
      final json = {
        'id': 1,
        'title': 'حملة وطنية للتشجير',
        'description': 'حملة الجزائر الخضراء',
        'type': 'national',
        'province_id': null,
        'organizer_id': 'uid-admin',
        'start_date': '2024-03-21T08:00:00Z',
        'end_date': '2024-03-21T17:00:00Z',
        'status': 'active',
        'tree_goal': 10000,
        'tree_planted': 4500,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final campaign = CampaignModel.fromJson(json);

      expect(campaign.id, 1);
      expect(campaign.title, 'حملة وطنية للتشجير');
      expect(campaign.description, 'حملة الجزائر الخضراء');
      expect(campaign.type, 'national');
      expect(campaign.provinceId, isNull);
      expect(campaign.organizerId, 'uid-admin');
      expect(campaign.startDate, isNotNull);
      expect(campaign.endDate, isNotNull);
      expect(campaign.status, 'active');
      expect(campaign.treeGoal, 10000);
      expect(campaign.treePlanted, 4500);
    });

    test('fromJson defaults status and counts', () {
      final json = {
        'id': 2,
        'title': 'Test',
        'type': 'local',
      };

      final campaign = CampaignModel.fromJson(json);

      expect(campaign.status, 'active');
      expect(campaign.treeGoal, 0);
      expect(campaign.treePlanted, 0);
      expect(campaign.hasZone, false);
    });

    test('toJson excludes null optional fields', () {
      final campaign = CampaignModel(
        id: 3,
        title: 'Spring Planting',
        type: 'provincial',
        status: 'upcoming',
        treeGoal: 500,
      );

      final json = campaign.toJson();

      expect(json['title'], 'Spring Planting');
      expect(json['type'], 'provincial');
      expect(json['status'], 'upcoming');
      expect(json['tree_goal'], 500);
      expect(json.containsKey('description'), false);
      expect(json.containsKey('province_id'), false);
      expect(json.containsKey('organizer_id'), false);
    });

    test('toJson includes dates as ISO strings', () {
      final campaign = CampaignModel(
        id: 4,
        title: 'dated',
        type: 'national',
        startDate: DateTime.utc(2024, 6, 1),
        endDate: DateTime.utc(2024, 6, 2),
      );

      final json = campaign.toJson();
      expect(json['start_date'], '2024-06-01T00:00:00.000Z');
      expect(json['end_date'], '2024-06-02T00:00:00.000Z');
    });
  });
}
