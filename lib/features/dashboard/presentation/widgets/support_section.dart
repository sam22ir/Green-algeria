import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';
import 'package:easy_localization/easy_localization.dart';


class DashboardSupportSection extends StatefulWidget {
  const DashboardSupportSection({super.key});

  @override
  State<DashboardSupportSection> createState() => _DashboardSupportSectionState();
}

class _DashboardSupportSectionState extends State<DashboardSupportSection> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final messages = await SupabaseService().getSupportMessages();
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReply(int messageId, String userId, String reply) async {
    final colorScheme = Theme.of(context).colorScheme;
    if (reply.isEmpty) return;

    await SupabaseService().sendSupportReply(
      messageId: messageId,
      replyText: reply,
      repliedBy: userId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reply_sent_to_user'.tr()), 
          backgroundColor: colorScheme.primary,
        ),
      );
    }
    _loadData();
  }

  void _showReplyDialog(Map<String, dynamic> msg) {
    final replyController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('send_reply'.tr()),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'write_reply_hint'.tr(),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('cancel'.tr(), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.isEmpty) return;
              Navigator.pop(context); // Close dialog first
              await _sendReply(msg['id'], msg['user_id'], replyController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, 
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('send'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingCount = _messages.where((m) => (m['support_replies'] as List? ?? []).isEmpty).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      color: colorScheme.surface,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Icon(Icons.support_agent_outlined, color: colorScheme.primary),
        title: Text(
          'support_messages_count'.tr(args: [pendingCount.toString()]),
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        children: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else if (_messages.isEmpty)
            Padding(padding: const EdgeInsets.all(20), child: Text('no_support_messages'.tr()))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final user = msg['users'] ?? {};
                final replies = (msg['support_replies'] as List? ?? []);
                final isReplied = replies.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  color: isReplied ? colorScheme.surfaceContainerLowest : colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user['full_name'] ?? msg['name'] ?? 'unspecified'.tr(), 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (isReplied)
                              Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
                            Text(
                              DateFormat('dd/MM HH:mm').format(DateTime.parse(msg['created_at'])), 
                              style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                        Text(
                          user['email'] ?? 'volunteer'.tr(), 
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 8),
                        Text(msg['message'] ?? '', style: const TextStyle(fontSize: 13)),
                        if (isReplied) ...[
                          const SizedBox(height: 12),
                          Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
                          Text(
                            'replies'.tr(), 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                          ...replies.map((r) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '• ${r['reply_text']}', 
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          )),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showReplyDialog(msg),
                            icon: Icon(Icons.reply, size: 18, color: colorScheme.primary),
                            label: Text('reply'.tr(), style: TextStyle(color: colorScheme.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
