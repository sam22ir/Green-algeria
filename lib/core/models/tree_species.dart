class TreeSpecies {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? idealRegion;
  final String? iconName;

  TreeSpecies({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.idealRegion,
    this.iconName,
  });

  factory TreeSpecies.fromJson(Map<String, dynamic> json) {
    return TreeSpecies(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      idealRegion: json['ideal_region'] as String?,
      iconName: json['icon_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'ideal_region': idealRegion,
      'icon_name': iconName,
    };
  }
}
