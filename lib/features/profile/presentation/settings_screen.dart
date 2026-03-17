import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';

import '../../../widgets/custom_card.dart';
import '../../../services/settings_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';

import '../../../../models/user_model.dart';
import '../../../../constants/provinces.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/language_selection_sheet.dart';
import '../../../core/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  bool _isLoadingUser = true;
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _supabaseService.getUserProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  String _getProvinceName(int? id) {
    if (id == null) return 'not_set'.tr();
    try {
      final province = algeriaProvinces.firstWhere((p) => p.id == id);
      return context.locale.languageCode == 'ar' ? province.nameAr : province.nameEn;
    } catch (_) {
      return 'not_set'.tr();
    }
  }

  Future<void> _showProvincePicker() async {
    if (_user == null) return;
    
    // Check 3-day constraint
    if (_user!.provinceChangedAt != null) {
      final daysSinceUpdate = DateTime.now().difference(_user!.provinceChangedAt!).inDays;
      if (daysSinceUpdate < 3) {
        final daysLeft = 3 - daysSinceUpdate;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('province_change_wait'.tr(args: [daysLeft.toString()])),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
    }

    final provinces = await _supabaseService.getProvinces();
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'pick_province'.tr(), 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: provinces.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final p = provinces[index];
                    final pName = context.locale.languageCode == 'ar' ? p['name_ar'] : p['name_en'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(
                        '${p['code']} - $pName',
                        style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.primary.withValues(alpha: 0.3)),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _isLoadingUser = true);
      try {
        final updatedUser = _user!.copyWith(
          provinceId: selected['id'] as int,
          provinceChangedAt: DateTime.now(),
        );
        await _supabaseService.updateUserProfile(updatedUser);
        setState(() => _user = updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('province_updated'.tr()), 
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('province_update_failed'.tr(args: [e.toString()])), 
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _showLanguagePicker() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LanguageSelectionSheet(
        currentLanguageCode: settings.locale.languageCode,
        onLanguageSelected: (code) {
          final newLocale = Locale(code);
          context.read<SettingsProvider>().setLocale(newLocale);
          context.setLocale(newLocale);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoadingUser 
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _buildSectionHeader('general'.tr()),
                  _buildGeneralGroup(theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader('notification_preferences'.tr()),
                  _buildNotificationsGroup(theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader('support'.tr()),
                  _buildSupportGroup(theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader('account'.tr()),
                  _buildActionsGroup(context, theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGeneralGroup(ThemeData theme) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = theme.colorScheme;

    return CustomCard(
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _buildListTile(
            theme: theme,
            title: 'language'.tr(),
            icon: Icons.language_rounded,
            trailing: Text(
              settings.locale.languageCode == 'ar' ? 'العربية' : 'English',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            onTap: _showLanguagePicker,
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'province'.tr(),
            icon: Icons.location_on_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getProvinceName(_user?.provinceId),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                Icon(
                  context.locale.languageCode == 'ar' ? Icons.chevron_left : Icons.chevron_right,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            onTap: _showProvincePicker,
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'dark_mode'.tr(),
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: ThemeController().isDarkMode,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) {
                ThemeController().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsGroup(ThemeData theme) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = theme.colorScheme;

    return CustomCard(
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListTile(
            theme: theme,
            title: 'national_campaigns_notif'.tr(),
            icon: Icons.public_rounded,
            trailing: Switch(
              value: settings.notifNationalCampaigns,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) => context.read<SettingsProvider>().setNotifNationalCampaigns(val),
            ),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'provincial_campaigns_notif'.tr(),
            icon: Icons.map_rounded,
            trailing: Switch(
              value: settings.notifProvincialCampaigns,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) => context.read<SettingsProvider>().setNotifProvincialCampaigns(val),
            ),
          ),
          _buildDivider(theme),
           _buildListTile(
            theme: theme,
            title: 'local_campaigns_notif'.tr(),
            icon: Icons.location_on_rounded,
            trailing: Switch(
              value: settings.notifLocalCampaigns,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) => context.read<SettingsProvider>().setNotifLocalCampaigns(val),
            ),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'my_campaign_updates_notif'.tr(),
            icon: Icons.auto_awesome_rounded,
            trailing: Switch(
              value: settings.notifMyCampaigns,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) => context.read<SettingsProvider>().setNotifMyCampaigns(val),
            ),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'upgrades_support_notif'.tr(),
            icon: Icons.support_agent_rounded,
            trailing: Switch(
              value: settings.notifSupport,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) => context.read<SettingsProvider>().setNotifSupport(val),
            ),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'system_notifications_notif'.tr(),
            icon: Icons.notifications_active_rounded,
            trailing: Switch(
              value: settings.notifSystem,
              activeTrackColor: colorScheme.secondary,
              onChanged: (val) => context.read<SettingsProvider>().setNotifSystem(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportGroup(ThemeData theme) {
    final isAr = context.locale.languageCode == 'ar';
    final colorScheme = theme.colorScheme;

    return CustomCard(
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _buildListTile(
            theme: theme,
            title: 'report_problem'.tr(),
            icon: Icons.report_problem_outlined,
            trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () => context.push('/report-problem'),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'technical_support'.tr(),
            icon: Icons.support_agent_rounded,
            trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () => context.push('/technical-support'),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'about_app'.tr(),
            icon: Icons.info_outline_rounded,
            trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGroup(BuildContext context, ThemeData theme) {
    final isAr = context.locale.languageCode == 'ar';
    final colorScheme = theme.colorScheme;

    return CustomCard(
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _buildListTile(
            theme: theme,
            title: 'request_upgrade'.tr(),
            icon: Icons.auto_awesome_outlined,
            trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () => context.push('/role-request'),
          ),
          _buildDivider(theme),
          _buildListTile(
            theme: theme,
            title: 'logout'.tr(),
            icon: Icons.logout_rounded,
            textColor: colorScheme.error,
            iconColor: colorScheme.error,
            trailing: Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: colorScheme.error.withValues(alpha: 0.5)),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('logout'.tr(), textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface)),
        content: Text('logout_confirm'.tr(), textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('cancel'.tr(), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('confirm'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      // Use the static router to navigate — avoids async context gap issues
      // GoRouter redirect will handle it automatically via notifyListeners,
      // but we explicitly push to be safe.
      AppRouter.router.go('/login');
    }
  }

  Widget _buildListTile({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Widget trailing,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final colorScheme = theme.colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
           shape: BoxShape.circle,
         ),
         child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      color: theme.colorScheme.outline.withValues(alpha: 0.08),
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}
