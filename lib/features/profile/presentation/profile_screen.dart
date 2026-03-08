import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'مستخدم';
  int _treesPlanted = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        if (user.userMetadata?['full_name'] != null) {
          _userName = user.userMetadata!['full_name'];
        }

        // Fetch planted trees count
        final res = await Supabase.instance.client
            .from('planted_trees')
            .select('id')
            .eq('planter_id', user.id);
        
        _treesPlanted = (res as List).length;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.mossForest)),
                )
              else ...[
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCard(),
              ],
              const SizedBox(height: 32),
              _buildActionsList(context),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return CustomCard(
      blur: 20,
      opacity: 0.85,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 56,
            backgroundColor: AppColors.oliveGrey,
            child: Icon(Icons.person, size: 64, color: AppColors.linenWhite),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slateCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mossForest.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mossForest.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.energy_savings_leaf, size: 16, color: AppColors.mossForest),
                const SizedBox(width: 8),
                const Text(
                  'متطوع نشط',
                  style: TextStyle(
                    color: AppColors.mossForest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn('0', 'حملة'),
          Container(width: 1, height: 40, color: AppColors.ivorySand),
          _buildStatColumn('$_treesPlanted', 'شجرة'),
          Container(width: 1, height: 40, color: AppColors.ivorySand),
          _buildStatColumn('-', 'وطنياً', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.mossForest : AppColors.slateCharcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.oliveGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionItem(Icons.edit_outlined, l10n.editProfile, context: context),
          _buildDivider(),
          _buildActionItem(Icons.history, l10n.myContributionsHistory, context: context),
          _buildDivider(),
          _buildActionItem(Icons.settings_outlined, l10n.settings, onTap: () => context.push('/settings'), context: context),
          _buildDivider(),
          _buildActionItem(Icons.palette_outlined, l10n.appearance, context: context),
          _buildDivider(),
          _buildActionItem(Icons.upgrade_outlined, l10n.upgradeAccount, onTap: () => context.push('/role-request'), context: context),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, {VoidCallback? onTap, required BuildContext context}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: AppColors.mossForest),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.slateCharcoal,
        ),
      ),
      trailing: const Icon(Icons.chevron_left, color: AppColors.oliveGrey),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColors.ivorySand,
      height: 1,
      thickness: 1,
      indent: 24,
      endIndent: 24,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton(
      onPressed: () async {
        await AuthService().signOut();
        if (context.mounted) {
          context.go('/login');
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFFD9534F), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout, color: Color(0xFFD9534F)),
          const SizedBox(width: 8),
          Text(
            l10n.logout,
            style: const TextStyle(
              color: Color(0xFFD9534F),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
