import 'package:flutter_test/flutter_test.dart';
import 'package:green_algeria/models/tree_species.dart';

void main() {
  group('TreeSpecies', () {
    test('fromJson parses complete JSON correctly', () {
      final json = {
        'id': 1,
        'name_ar': 'صنوبر حلبي',
        'name_en': 'Aleppo Pine',
        'name_scientific': 'Pinus halepensis',
        'description': 'A Mediterranean conifer',
        'image_url': 'https://example.com/pine.jpg',
        'ecological_zone': 'Mediterranean',
        'metadata': {'drought_resistance': 'high', 'growth_rate': 'moderate'},
        'is_active': true,
        'image_asset_path': 'assets/images/trees/tree_pine.png',
      };

      final species = TreeSpecies.fromJson(json);

      expect(species.id, 1);
      expect(species.nameAr, 'صنوبر حلبي');
      expect(species.nameEn, 'Aleppo Pine');
      expect(species.nameScientific, 'Pinus halepensis');
      expect(species.description, 'A Mediterranean conifer');
      expect(species.imageUrl, 'https://example.com/pine.jpg');
      expect(species.ecologicalZone, 'Mediterranean');
      expect(species.metadata?['drought_resistance'], 'high');
      expect(species.isActive, true);
      expect(species.imageAssetPath, 'assets/images/trees/tree_pine.png');
    });

    test('fromJson handles nullable fields gracefully', () {
      final json = {
        'id': 5,
        'name_ar': 'خروب',
        'name_en': 'Carob',
      };

      final species = TreeSpecies.fromJson(json);

      expect(species.id, 5);
      expect(species.nameScientific, isNull);
      expect(species.description, isNull);
      expect(species.imageUrl, isNull);
      expect(species.ecologicalZone, isNull);
      expect(species.metadata, isNull);
      expect(species.imageAssetPath, isNull);
      expect(species.isActive, true); // defaults to true
    });

    test('toJson produces correct map', () {
      final species = TreeSpecies(
        id: 10,
        nameAr: 'زيتون',
        nameEn: 'Olive',
        nameScientific: 'Olea europaea',
        ecologicalZone: 'Mediterranean',
      );

      final json = species.toJson();

      expect(json['id'], 10);
      expect(json['name_ar'], 'زيتون');
      expect(json['name_en'], 'Olive');
      expect(json['name_scientific'], 'Olea europaea');
      expect(json['ecological_zone'], 'Mediterranean');
      expect(json['is_active'], true);
    });

    test('getLocalizedName returns correct language', () {
      final species = TreeSpecies(
        id: 1,
        nameAr: 'صنوبر',
        nameEn: 'Pine',
      );
      expect(species.getLocalizedName('ar'), 'صنوبر');
      expect(species.getLocalizedName('en'), 'Pine');
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = {
        'id': 3,
        'name_ar': 'أرز أطلسي',
        'name_en': 'Atlas Cedar',
        'name_scientific': 'Cedrus atlantica',
        'description': 'Native to the Atlas mountains',
        'image_url': null,
        'ecological_zone': 'Mountain',
        'metadata': null,
        'is_active': false,
        'image_asset_path': null,
      };

      final species = TreeSpecies.fromJson(original);
      final output = species.toJson();

      expect(output['name_ar'], original['name_ar']);
      expect(output['name_en'], original['name_en']);
      expect(output['is_active'], false);
    });
  });
}
