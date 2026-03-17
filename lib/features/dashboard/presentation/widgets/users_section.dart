import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';

import '../../../../models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardUsersSection extends StatefulWidget {
  const DashboardUsersSection({super.key});

  @override
  State<DashboardUsersSection> createState() => _DashboardUsersSectionState();
}

class _DashboardUsersSectionState extends State<DashboardUsersSection> {
  final _searchController = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService().getUserProfile();
    _currentUserRole = profile?.role;
    await _searchUsers();
  }

  Future<void> _searchUsers() async {
    final users = await SupabaseService().getUsers(query: _searchController.text);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Color _roleColor(String role, ColorScheme colorScheme) {
    switch (role) {
      case 'developer': return colorScheme.primary;
      case 'initiative_owner': return colorScheme.secondary;
      default: return colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  void _showRolePicker(UserModel user) {
    if (_currentUserRole != 'developer') return;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'change_user_role'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user.fullName,
                textAlign: TextAlign.center, 
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              ...['developer', 'initiative_owner', 'provincial_organizer', 'local_organizer', 'volunteer'].map((role) {
                return ListTile(
                  title: Text(_getRoleI18nKey(role).tr()),
                  leading: CircleAvatar(backgroundColor: _roleColor(role, colorScheme), radius: 8),
                  trailing: user.role == role ? Icon(Icons.check, color: colorScheme.primary) : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateRole(user.id, role);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateRole(String userId, String role) async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await SupabaseService().updateUserRole(userId, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('role_updated_success'.tr()), 
            backgroundColor: colorScheme.primary,
          ),
        );
        _searchUsers();
      }
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

  String _getRoleI18nKey(String role) {
    switch (role) {
      case 'developer': return 'developer';
      case 'initiative_owner': return 'initiative_owner';
      case 'provincial_organizer': return 'provincial_organizer';
      case 'local_organizer': return 'local_organizer';
      case 'volunteer': return 'volunteer';
      default: return 'volunteer';
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
        initiallyExpanded: false,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.primary,
        leading: Icon(Icons.people_outline, color: colorScheme.primary),
        title: Text('user_management'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_users_hint'.tr(),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => _searchUsers(),
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else if (_users.isEmpty)
            Padding(padding: const EdgeInsets.all(20), child: Text('no_users_found'.tr()))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user.fullName),
                  subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getRoleI18nKey(user.role).tr(),
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  onTap: () => _showRolePicker(user),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
