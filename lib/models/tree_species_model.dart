class TreeSpeciesModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  TreeSpeciesModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  factory TreeSpeciesModel.fromJson(Map<String, dynamic> json) {
    return TreeSpeciesModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_ar': nameAr,
      'name_en': nameEn,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}
