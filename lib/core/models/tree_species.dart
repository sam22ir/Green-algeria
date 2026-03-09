class TreeSpecies {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? nameScientific;
  final String? description;
  final String? imageUrl;
  final String? ecologicalZone;
  final Map<String, dynamic>? metadata;
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
  });

  factory TreeSpecies.fromJson(Map<String, dynamic> json) {
    return TreeSpecies(
      id: json['id'].toString(), // Safely stringify Supabase's bigserial/integer responses
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      nameScientific: json['name_scientific'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      ecologicalZone: json['ecological_zone'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
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
    };
  }
}
