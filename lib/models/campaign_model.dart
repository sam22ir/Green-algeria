class CampaignModel {
  final int id;
  final String title;
  final String? description;
  final String type; // national, provincial, local
  final int? provinceId;
  final String? organizerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int treeGoal;
  final int treePlanted;
  final DateTime? createdAt;

  CampaignModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.provinceId,
    this.organizerId,
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.treeGoal = 0,
    this.treePlanted = 0,
    this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      provinceId: json['province_id'] as int?,
      organizerId: json['organizer_id'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      status: json['status'] as String? ?? 'active',
      treeGoal: json['tree_goal'] as int? ?? 0,
      treePlanted: json['tree_planted'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'type': type,
      if (provinceId != null) 'province_id': provinceId,
      if (organizerId != null) 'organizer_id': organizerId,
      if (startDate != null) 'start_date': startDate?.toIso8601String(),
      if (endDate != null) 'end_date': endDate?.toIso8601String(),
      'status': status,
      'tree_goal': treeGoal,
      'tree_planted': treePlanted,
    };
  }
}
