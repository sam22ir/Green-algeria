/// Matches `leaderboard_cache` table:
/// province_id INTEGER, province_name TEXT, total_trees INTEGER, volunteers INTEGER, updated_at TIMESTAMPTZ
/// NOTE: This table does NOT have a serial auto-increment id.
/// The model uses province_id as a logical identifier.
class LeaderboardCacheModel {
  final int provinceId;       // PRIMARY logical key — INTEGER in DB
  final String userId;        // user_id TEXT in DB (for user-level entries if used)
  final int? rankNational;
  final int? rankProvincial;
  final int totalTrees;
  final String? provinceName;
  final int? volunteers;
  final DateTime? lastUpdated;

  LeaderboardCacheModel({
    required this.provinceId,
    required this.userId,
    this.rankNational,
    this.rankProvincial,
    this.totalTrees = 0,
    this.provinceName,
    this.volunteers,
    this.lastUpdated,
  });

  factory LeaderboardCacheModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardCacheModel(
      provinceId: json['province_id'] as int? ?? 0,
      userId: json['user_id']?.toString() ?? '',
      totalTrees: json['total_trees'] as int? ?? 0,
      rankNational: json['rank_national'] as int?,
      rankProvincial: json['rank_provincial'] as int?,
      provinceName: json['province_name'] as String?,
      volunteers: json['volunteers'] as int?,
      lastUpdated: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province_id': provinceId,
      if (userId.isNotEmpty) 'user_id': userId,
      'total_trees': totalTrees,
      if (rankNational != null) 'rank_national': rankNational,
      if (rankProvincial != null) 'rank_provincial': rankProvincial,
      if (provinceName != null) 'province_name': provinceName,
      if (volunteers != null) 'volunteers': volunteers,
    };
  }
}
