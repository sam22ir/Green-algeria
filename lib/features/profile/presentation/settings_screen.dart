import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      appBar: AppBar(
        backgroundColor: AppColors.linenWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.slateCharcoal, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGeneralGroup(l10n),
              const SizedBox(height: 32),
              _buildAccountSupportGroup(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralGroup(AppLocalizations l10n) {
    final settings = context.watch<SettingsProvider>();
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildListTile(
            title: l10n.language,
            icon: Icons.language,
            trailing: Text(
              settings.locale.languageCode == 'ar' ? 'العربية' : 'English',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.mossForest,
              ),
            ),
            onTap: () {
              final newLocale = settings.locale.languageCode == 'ar' 
                  ? const Locale('en', 'US') 
                  : const Locale('ar', 'AE');
              context.read<SettingsProvider>().setLocale(newLocale);
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: l10n.appearance,
            icon: Icons.palette_outlined,
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              activeColor: AppColors.mossForest,
              onChanged: (val) {
                context.read<SettingsProvider>().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          _buildDivider(),
          _buildListTile(
            title: l10n.notifications,
            icon: Icons.notifications_active_outlined,
            trailing: Switch(
              value: settings.notificationsEnabled,
              activeColor: AppColors.mossForest,
              onChanged: (val) {
                context.read<SettingsProvider>().setNotificationsEnabled(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSupportGroup(AppLocalizations l10n) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildListTile(
            title: l10n.upgradeAccount,
            icon: Icons.upgrade_outlined,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.mossForest.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.available,
                style: const TextStyle(
                  color: AppColors.mossForest,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              context.push('/role-request');
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: l10n.helpSupport,
            icon: Icons.help_outline,
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            title: l10n.termsConditions,
            icon: Icons.description_outlined,
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: AppColors.mossForest),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.slateCharcoal,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColors.ivorySand,
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}
