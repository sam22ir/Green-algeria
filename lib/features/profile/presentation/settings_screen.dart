import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../services/auth_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      appBar: AppBar(
        backgroundColor: AppColors.linenWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.slateCharcoal, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGeneralGroup(),
              const SizedBox(height: 24),
              _buildSupportGroup(),
              const SizedBox(height: 24),
              _buildActionsGroup(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralGroup() {
    final settings = context.watch<SettingsProvider>();
    return CustomCard(
      padding: EdgeInsets.zero,
      color: AppColors.ivorySand,
      child: Column(
        children: [
          _buildListTile(
            title: 'اللغة',
            icon: Icons.language,
            trailing: Text(
              settings.locale.languageCode == 'ar' ? 'العربية' : 'English',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.slateCharcoal,
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
            title: 'الوضع الداكن',
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              activeColor: AppColors.oliveGrove,
              onChanged: (val) {
                context.read<SettingsProvider>().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          _buildDivider(),
          _buildListTile(
            title: 'الإشعارات',
            icon: Icons.notifications_none,
            trailing: Switch(
              value: settings.notificationsEnabled,
              activeColor: AppColors.oliveGrove,
              onChanged: (val) {
                context.read<SettingsProvider>().setNotificationsEnabled(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportGroup() {
    return CustomCard(
      padding: EdgeInsets.zero,
      color: AppColors.ivorySand,
      child: Column(
        children: [
          _buildListTile(
            title: 'الإبلاغ عن مشكلة',
            icon: Icons.report_problem_outlined,
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () {
              _showComingSoon(context, 'سيتم تفعيل ميزة الإبلاغ عن مشكلة قريباً.');
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: 'الدعم الفني',
            icon: Icons.headset_mic_outlined,
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () {
              _showComingSoon(context, 'سيتم توفير الدعم الفني قريباً.');
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: 'عن التطبيق',
            icon: Icons.info_outline,
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () {
              _showComingSoon(context, 'الجزائر خضراء - إصدار 1.0\\nمطور بحب من قبل: Saadi Samir');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGroup(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      color: AppColors.ivorySand,
      child: Column(
        children: [
          _buildListTile(
            title: 'طلب ترقية الحساب',
            icon: Icons.star_border,
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () {
              context.push('/role-request');
            },
          ),
          _buildDivider(),
          _buildListTile(
            title: 'تسجيل الخروج',
            icon: Icons.logout,
            textColor: const Color(0xFFD9534F),
            iconColor: const Color(0xFFD9534F),
            trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟', textAlign: TextAlign.right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.oliveGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('نعم، الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        backgroundColor: AppColors.mossForest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required Widget trailing,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: iconColor ?? AppColors.mossForest),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.slateCharcoal,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFFEBEBEB),
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}
