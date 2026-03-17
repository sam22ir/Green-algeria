/// Matches the `tree_plantings` Supabase table:
/// id INTEGER (auto), user_id TEXT, campaign_id INTEGER, tree_species_id INTEGER,
/// latitude FLOAT, longitude FLOAT, planted_at TIMESTAMPTZ, is_synced BOOL
class TreePlantingModel {
  final int? id;          // INTEGER in DB (auto-generated)
  final String userId;    // TEXT in DB (auth.uid() as text)
  final int? campaignId;  // INTEGER FK → campaigns.id (was wrongly String)
  final int? treeSpeciesId; // INTEGER FK → tree_species.id (was wrongly String, also wrong column name 'species_id')
  final double? latitude;
  final double? longitude;
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
    this.plantedAt,
    this.isSynced = true,
    this.createdAt,
  });

  factory TreePlantingModel.fromJson(Map<String, dynamic> json) {
    return TreePlantingModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString() ?? '',
      campaignId: json['campaign_id'] as int?,
      treeSpeciesId: json['tree_species_id'] as int?,  // FIX: correct column name
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
    // NOTE: Do NOT include 'id' — DB auto-generates INTEGER serial
    if (campaignId != null) data['campaign_id'] = campaignId;   // FIX: int, not String
    if (treeSpeciesId != null) data['tree_species_id'] = treeSpeciesId; // FIX: correct column name + int type
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (plantedAt != null) data['planted_at'] = plantedAt?.toIso8601String();
    return data;
  }
}
