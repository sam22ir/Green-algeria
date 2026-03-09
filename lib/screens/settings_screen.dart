import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../components/role_guard.dart';
import '../components/app_button.dart';
import '../constants/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _showUpgradeDialog(BuildContext context) async {
    final roleController = TextEditingController(text: 'local_organizer');
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Request Upgrade', style: AppTypography.headingMd),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: roleController.text,
                    items: const [
                      DropdownMenuItem(value: 'local_organizer', child: Text('Local Organizer')),
                      DropdownMenuItem(value: 'provincial_organizer', child: Text('Provincial Organizer')),
                    ],
                    onChanged: (v) => setState(() => roleController.text = v!),
                    decoration: const InputDecoration(labelText: 'Requested Role'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Reason for upgrade'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  text: 'Submit Request',
                  isLoading: isSubmitting,
                  onPressed: () async {
                    if (reasonController.text.isEmpty) return;
                    setState(() => isSubmitting = true);
                    try {
                      final uid = context.read<AuthService>().firebaseUser?.uid;
                      if (uid != null) {
                        await SupabaseService().requestUpgrade(
                          uid,
                          roleController.text,
                          reasonController.text,
                        );
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upgrade request submitted successfully')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    } finally {
                      setState(() => isSubmitting = false);
                    }
                  },
                )
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoleGuard(
            allowedRoles: const ['developer', 'initiative_owner'],
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                // Navigate to Admin Panel
              },
            ),
          ),
          RoleGuard(
            allowedRoles: const ['volunteer'],
            child: AppButton(
              text: 'Request Upgrade to Organizer',
              onPressed: () => _showUpgradeDialog(context),
              type: AppButtonType.secondary,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Logout',
            type: AppButtonType.danger,
            onPressed: () async {
              await context.read<AuthService>().logout();
            },
          ),
        ],
      ),
    );
  }
}
