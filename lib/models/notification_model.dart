/// Matches `notifications` table:
/// id INTEGER (serial), title, body, type, province_id INTEGER, 
/// sent_by TEXT, sent_at TIMESTAMPTZ, is_active BOOL
class NotificationModel {
  final int id;           // FIX: INTEGER in DB, not String
  final String title;
  final String body;
  final String type;      // national, provincial
  final int? provinceId;
  final String? sentBy;
  final DateTime? sentAt;
  final bool isActive;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.provinceId,
    this.sentBy,
    this.sentAt,
    this.isActive = true,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,      // FIX: parse as int directly
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      provinceId: json['province_id'] as int?,
      sentBy: json['sent_by'] as String?,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // NOTE: do NOT include 'id' — DB auto-generates it
      'title': title,
      'body': body,
      'type': type,
      if (provinceId != null) 'province_id': provinceId,
      if (sentBy != null) 'sent_by': sentBy,
      'is_active': isActive,
    };
  }
}
