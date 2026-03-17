class UserModel {
  final String id;
  final String fullName;
  final String email;
  final int? provinceId;
  final String role;
  final String? avatarUrl;
  final String? avatarAsset;
  final int treeCount;
  final int campaignCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? provinceChangedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.provinceId,
    required this.role,
    this.avatarUrl,
    this.avatarAsset,
    this.treeCount = 0,
    this.campaignCount = 0,
    this.createdAt,
    this.updatedAt,
    this.provinceChangedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      provinceId: json['province_id'] as int?,
      role: json['role'] as String? ?? 'volunteer',
      avatarUrl: json['avatar_url'] as String?,
      avatarAsset: json['avatar_asset'] as String?,
      treeCount: json['tree_count'] as int? ?? 0,
      campaignCount: json['campaign_count'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      provinceChangedAt: json['province_changed_at'] != null ? DateTime.parse(json['province_changed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'province_id': provinceId,
      'role': role,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (avatarAsset != null) 'avatar_asset': avatarAsset,
      'tree_count': treeCount,
      'campaign_count': campaignCount,
      if (provinceChangedAt != null) 'province_changed_at': provinceChangedAt!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    int? provinceId,
    String? role,
    String? avatarUrl,
    String? avatarAsset,
    int? treeCount,
    int? campaignCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? provinceChangedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      provinceId: provinceId ?? this.provinceId,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      treeCount: treeCount ?? this.treeCount,
      campaignCount: campaignCount ?? this.campaignCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      provinceChangedAt: provinceChangedAt ?? this.provinceChangedAt,
    );
  }

  bool get isOrganizer =>
      role == 'developer' ||
      role == 'initiative_owner' ||
      role == 'provincial_organizer' ||
      role == 'local_organizer';

  bool get isAdmin => role == 'developer' || role == 'initiative_owner';
}
