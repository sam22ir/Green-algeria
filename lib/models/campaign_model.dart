import 'package:latlong2/latlong.dart';

class CampaignModel {
  final int id;
  final String title;
  final String? description;
  final String type;
  final int? provinceId;
  final String? organizerId;
  final String? organizerName; // joined from users table
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int treeGoal;
  final int treePlanted;
  final String? coverImageAsset;
  final bool hasZone;
  final List<LatLng>? zonePolygon;
  final DateTime? endedAt;
  final String? endedBy;
  final String? endReason;
  final DateTime? createdAt;

  CampaignModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.provinceId,
    this.organizerId,
    this.organizerName,
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.treeGoal = 0,
    this.treePlanted = 0,
    this.coverImageAsset,
    this.hasZone = false,
    this.zonePolygon,
    this.endedAt,
    this.endedBy,
    this.endReason,
    this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as int,   // INTEGER — parse as int
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      provinceId: json['province_id'] as int?,
      organizerId: json['organizer_id'] as String?,
      organizerName: (json['users'] as Map<String, dynamic>?)?['full_name'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      status: json['status'] as String? ?? 'active',
      treeGoal: json['tree_goal'] as int? ?? 0,
      treePlanted: json['tree_planted'] as int? ?? 0,
      coverImageAsset: json['cover_image_asset'] as String?,
      hasZone: json['has_zone'] as bool? ?? false,
      zonePolygon: json['zone_polygon'] != null 
          ? (json['zone_polygon'] as List)
              .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
              .toList()
          : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      endedBy: json['ended_by'] as String?,
      endReason: json['end_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  /// Used when creating a new campaign (id is excluded — DB auto-generates it)
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
      if (coverImageAsset != null) 'cover_image_asset': coverImageAsset,
      'has_zone': hasZone,
      if (zonePolygon != null)
        'zone_polygon': zonePolygon!.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      if (endedAt != null) 'ended_at': endedAt?.toIso8601String(),
      if (endedBy != null) 'ended_by': endedBy,
      if (endReason != null) 'end_reason': endReason,
    };
  }

  /// Convenience: string representation of id for places that need String
  String get idStr => id.toString();
}
