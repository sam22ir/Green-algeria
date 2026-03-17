import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_model.dart';
import 'widgets/stats_section.dart';
import 'widgets/users_section.dart';
import 'widgets/upgrade_section.dart';
import 'widgets/campaigns_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/bug_reports_section.dart';
import 'widgets/support_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = AuthService().firebaseUser;
    if (user != null) {
      _currentUser = await SupabaseService().getUserRecord(user.id);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    final role = _currentUser?.role ?? 'volunteer';
    final isDeveloper = role == 'developer';
    final isInitiativeOwner = role == 'initiative_owner';

    if (!isDeveloper && !isInitiativeOwner) {
      return Scaffold(
        appBar: AppBar(title: Text('access_denied'.tr())),
        body: Center(child: Text('no_permission_dashboard'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin_dashboard'.tr(), 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
            ),
            Text(
              isDeveloper ? 'developer_role'.tr() : 'initiative_owner_role'.tr(),
              style: TextStyle(fontSize: 13, color: colorScheme.onPrimary.withValues(alpha: 0.7)),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        color: colorScheme.primary,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const DashboardStatsSection(),
            const SizedBox(height: 16),
            const DashboardUsersSection(),
            const SizedBox(height: 16),
            const DashboardUpgradeSection(),
            const SizedBox(height: 16),
            const DashboardCampaignsSection(),
            const SizedBox(height: 16),
            const DashboardNotificationsSection(),
            if (isDeveloper) ...[
              const SizedBox(height: 16),
              const DashboardBugReportsSection(),
              const SizedBox(height: 16),
              const DashboardSupportSection(),
            ],
            const SizedBox(height: 32),
            Center(
              child: Text(
                'dev_credit'.tr(),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
