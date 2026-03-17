/// Matches the `tree_species` Supabase table:
/// id INTEGER (serial), name_ar TEXT, name_en TEXT, name_scientific TEXT,
/// description TEXT, is_active BOOL, ecological_zone TEXT, metadata JSONB, image_asset_path TEXT
class TreeSpecies {
  final int id;           // INTEGER in DB — was wrongly String
  final String nameAr;
  final String nameEn;
  final String? nameScientific;
  final String? description;
  final String? imageUrl;
  final String? ecologicalZone;
  final Map<String, dynamic>? metadata;
  final String? imageAssetPath;
  final bool isActive;

  TreeSpecies({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.nameScientific,
    this.description,
    this.imageUrl,
    this.ecologicalZone,
    this.metadata,
    this.isActive = true,
    this.imageAssetPath,
  });

  String getLocalizedName(String languageCode) {
    if (languageCode == 'ar') return nameAr;
    return nameEn;
  }

  factory TreeSpecies.fromJson(Map<String, dynamic> json) {
    return TreeSpecies(
      id: json['id'] as int,       // FIX: parse as int directly
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      nameScientific: json['name_scientific'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      ecologicalZone: json['ecological_zone'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      imageAssetPath: json['image_asset_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'name_scientific': nameScientific,
      'description': description,
      'image_url': imageUrl,
      'ecological_zone': ecologicalZone,
      'metadata': metadata,
      'is_active': isActive,
      'image_asset_path': imageAssetPath,
    };
  }
}
