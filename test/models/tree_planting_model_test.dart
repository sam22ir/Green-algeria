import 'package:flutter_test/flutter_test.dart';
import 'package:green_algeria/models/tree_planting_model.dart';

void main() {
  group('TreePlantingModel', () {
    test('fromJson parses complete JSON correctly', () {
      final json = {
        'id': 101,
        'user_id': 'uid-abc',
        'campaign_id': 5,
        'tree_species_id': 12,
        'latitude': 36.7525,
        'longitude': 3.0420,
        'photo_url': 'https://example.com/photo.jpg',
        'planted_at': '2024-03-01T09:00:00Z',
        'is_synced': true,
        'created_at': '2024-03-01T09:01:00Z',
      };

      final planting = TreePlantingModel.fromJson(json);

      expect(planting.id, 101);
      expect(planting.userId, 'uid-abc');
      expect(planting.campaignId, 5);
      expect(planting.treeSpeciesId, 12);
      expect(planting.latitude, 36.7525);
      expect(planting.longitude, 3.0420);
      expect(planting.photoUrl, 'https://example.com/photo.jpg');
      expect(planting.plantedAt, isNotNull);
      expect(planting.isSynced, true);
    });

    test('fromJson handles nullable fields', () {
      final json = {
        'user_id': 'uid-xyz',
      };

      final planting = TreePlantingModel.fromJson(json);

      expect(planting.id, isNull);
      expect(planting.campaignId, isNull);
      expect(planting.latitude, isNull);
      expect(planting.longitude, isNull);
      expect(planting.photoUrl, isNull);
      expect(planting.isSynced, true); // default
    });

    test('fromJson handles numeric latitude/longitude as int', () {
      final json = {
        'user_id': 'uid-1',
        'latitude': 36, // int instead of double
        'longitude': 3,
      };

      final planting = TreePlantingModel.fromJson(json);
      expect(planting.latitude, 36.0);
      expect(planting.longitude, 3.0);
    });

    test('toJson excludes null fields', () {
      final planting = TreePlantingModel(userId: 'uid-1');
      final json = planting.toJson();

      expect(json['user_id'], 'uid-1');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('campaign_id'), false);
      expect(json.containsKey('latitude'), false);
      expect(json.containsKey('photo_url'), false);
      expect(json['is_synced'], true);
    });

    test('toJson includes all provided fields', () {
      final planting = TreePlantingModel(
        id: 1,
        userId: 'uid-1',
        campaignId: 10,
        treeSpeciesId: 5,
        latitude: 35.0,
        longitude: 2.0,
        photoUrl: 'https://photo.url',
        plantedAt: DateTime.utc(2024, 5, 1),
      );

      final json = planting.toJson();

      expect(json['id'], 1);
      expect(json['campaign_id'], 10);
      expect(json['tree_species_id'], 5);
      expect(json['latitude'], 35.0);
      expect(json['longitude'], 2.0);
      expect(json['photo_url'], 'https://photo.url');
      expect(json['planted_at'], '2024-05-01T00:00:00.000Z');
    });
  });
}
