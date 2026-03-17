import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardUpgradeSection extends StatefulWidget {
  const DashboardUpgradeSection({super.key});

  @override
  State<DashboardUpgradeSection> createState() => _DashboardUpgradeSectionState();
}

class _DashboardUpgradeSectionState extends State<DashboardUpgradeSection> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requests = await SupabaseService().getPendingUpgradeRequests();
    if (mounted) {
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _processRequest(Map<String, dynamic> req, bool approved) async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final status = approved ? 'approved' : 'rejected';
      final currentUser = AuthService().firebaseUser;
      if (currentUser == null) return;

      await SupabaseService().updateUpgradeRequestStatus(
        requestId: req['id'],
        userId: req['user_id'],
        status: status,
        reviewerId: currentUser.id,
        newRole: approved ? req['requested_role'] : null,
      );

      // Send Notification
      final title = approved ? 'upgrade_success_title'.tr() : 'upgrade_request_title'.tr();
      final body = approved 
          ? 'upgrade_approved_msg'.tr(args: [_getRoleLabel(req['requested_role'])])
          : 'upgrade_rejected_msg'.tr();
          
      await NotificationService.sendToUser(
        userId: req['user_id'],
        title: title,
        body: body,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'request_accepted'.tr() : 'request_rejected'.tr()),
            backgroundColor: approved ? colorScheme.primary : colorScheme.error,
          ),
        );
      }
      
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'), 
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleRequest(Map<String, dynamic> req, bool approved) {
    _processRequest(req, approved);
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'developer': return 'developer'.tr();
      case 'initiative_owner': return 'initiative_owner'.tr();
      case 'provincial_organizer': return 'provincial_organizer'.tr();
      case 'local_organizer': return 'local_organizer'.tr();
      case 'volunteer': return 'volunteer'.tr();
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        leading: Icon(Icons.upgrade_outlined, color: colorScheme.primary),
        title: Text(
          'upgrade_requests'.tr(args: [_requests.length.toString()]), 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        children: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else if (_requests.isEmpty)
            Padding(padding: const EdgeInsets.all(20), child: Text('no_pending_upgrades'.tr()))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                final user = req['users'] ?? {};
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  color: colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            user['full_name'] ?? 'unspecified'.tr(), 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user['email'] ?? ''),
                        ),
                        Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
                        Text(
                          '${'requested_role'.tr()}: ${_getRoleLabel(req['requested_role'])}', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'reason'.tr()}: ${req['reason'] ?? ''}', 
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _handleRequest(req, false),
                              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                              child: Text('reject'.tr()),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _handleRequest(req, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('approve'.tr()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
