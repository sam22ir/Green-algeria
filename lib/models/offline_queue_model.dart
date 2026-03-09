class OfflineQueueModel {
  final int? id;
  final String userId;
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
  final bool isSynced;

  OfflineQueueModel({
    this.id,
    required this.userId,
    required this.actionType,
    required this.payload,
    this.createdAt,
    this.isSynced = false,
  });

  factory OfflineQueueModel.fromJson(Map<String, dynamic> json) {
    return OfflineQueueModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      isSynced: json['is_synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'user_id': userId,
      'action_type': actionType,
      'payload': payload,
      'is_synced': isSynced,
    };
    if (id != null) data['id'] = id;
    return data;
  }
}
