class TreePlantingModel {
  final int? id;
  final String userId;
  final int? campaignId;
  final int? treeSpeciesId;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final DateTime? plantedAt;
  final bool isSynced;
  final DateTime? createdAt;

  TreePlantingModel({
    this.id,
    required this.userId,
    this.campaignId,
    this.treeSpeciesId,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.plantedAt,
    this.isSynced = true,
    this.createdAt,
  });

  factory TreePlantingModel.fromJson(Map<String, dynamic> json) {
    return TreePlantingModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      campaignId: json['campaign_id'] as int?,
      treeSpeciesId: json['tree_species_id'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      plantedAt: json['planted_at'] != null ? DateTime.parse(json['planted_at']) : null,
      isSynced: json['is_synced'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'user_id': userId,
      'is_synced': isSynced,
    };
    if (id != null) data['id'] = id;
    if (campaignId != null) data['campaign_id'] = campaignId;
    if (treeSpeciesId != null) data['tree_species_id'] = treeSpeciesId;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (plantedAt != null) data['planted_at'] = plantedAt?.toIso8601String();
    
    return data;
  }
}
