import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardNotificationsSection extends StatefulWidget {
  const DashboardNotificationsSection({super.key});

  @override
  State<DashboardNotificationsSection> createState() => _DashboardNotificationsSectionState();
}

class _DashboardNotificationsSectionState extends State<DashboardNotificationsSection> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'national';
  int? _selectedProvinceId;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await SupabaseService().getNotificationHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('notification_title'.tr() + ' / ' + 'notification_body'.tr() + ' مطلوبان')),
      );
      return;
    }
    if (_selectedType == 'provincial' && _selectedProvinceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_province'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    // FIX: Map type to the correct FCM topic that users actually subscribe to.
    // Users subscribe to: 'national-notifications', 'province-{id}'
    final String topic;
    if (_selectedType == 'national') {
      topic = 'national-notifications';
    } else {
      topic = 'province-$_selectedProvinceId';
    }

    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

    try {
      // 1. Send the push notification via Edge Function
      await NotificationService.sendToTopic(
        topic: topic,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      // 2. Log the notification in the database (type = 'national' or 'provincial', NOT the topic string)
      await SupabaseService().logNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _selectedType, // FIX: store 'national' or 'provincial', not the topic
        provinceId: _selectedType == 'provincial' ? _selectedProvinceId : null,
        sentBy: currentUserId ?? 'admin',
      );

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('notification_sent_success'.tr()),
            backgroundColor: colorScheme.primary,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        _loadHistory();
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإرسال: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
      color: colorScheme.surface,
      child: ExpansionTile(
        leading: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
        title: Text(
          'send_notifications'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'notification_title'.tr(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: 3,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'notification_body'.tr(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'notification_type'.tr(),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: [
                    DropdownMenuItem(value: 'national', child: Text('national'.tr())),
                    DropdownMenuItem(value: 'provincial', child: Text('provincial'.tr())),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedType = val!;
                    _selectedProvinceId = null;
                  }),
                ),
                if (_selectedType == 'provincial') ...[
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: SupabaseService().getProvinces(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return LinearProgressIndicator(color: colorScheme.primary);
                      return DropdownButtonFormField<int>(
                        value: _selectedProvinceId,
                        dropdownColor: colorScheme.surface,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'select_province'.tr(),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: snapshot.data!
                            .map((p) => DropdownMenuItem(
                                  value: p['id'] as int,
                                  child: Text('${p['id']} - ${p['name_ar']}', style: TextStyle(color: colorScheme.onSurface)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedProvinceId = val),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: _isLoading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'جارٍ الإرسال...' : 'send'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'notification_history'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    if (_isLoadingHistory)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.refresh_rounded, size: 18, color: colorScheme.primary),
                        onPressed: _loadHistory,
                        tooltip: 'تحديث',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Text(
                    'no_notif_history'.tr(),
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      // FIX: Use 'type' and 'sent_at' — the actual column names in the DB
                      final typeStr = item['type']?.toString() ?? '-';
                      final sentAt = item['sent_at']?.toString() ?? '';
                      final displayDate = sentAt.length >= 16 ? sentAt.substring(0, 16) : sentAt;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          typeStr == 'national' ? Icons.public_rounded : Icons.location_city_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        title: Text(item['title'] ?? '-', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '$typeStr | $displayDate',
                          style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
