class LeaderboardCacheModel {
  final int id;
  final String userId;
  final int? provinceId;
  final int totalTrees;
  final int? rankNational;
  final int? rankProvincial;
  final DateTime? lastUpdated;

  LeaderboardCacheModel({
    required this.id,
    required this.userId,
    this.provinceId,
    this.totalTrees = 0,
    this.rankNational,
    this.rankProvincial,
    this.lastUpdated,
  });

  factory LeaderboardCacheModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardCacheModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      provinceId: json['province_id'] as int?,
      totalTrees: json['total_trees'] as int? ?? 0,
      rankNational: json['rank_national'] as int?,
      rankProvincial: json['rank_provincial'] as int?,
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (provinceId != null) 'province_id': provinceId,
      'total_trees': totalTrees,
      if (rankNational != null) 'rank_national': rankNational,
      if (rankProvincial != null) 'rank_provincial': rankProvincial,
    };
  }
}
