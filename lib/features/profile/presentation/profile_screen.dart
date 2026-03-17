import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/custom_card.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/avatars.dart';
import '../../notifications/presentation/notification_history_screen.dart';
import '../../../widgets/tutorial_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _currentUser;
  int _nationalRank = 0;
  int _campaignCount = 0;
  List<Map<String, dynamic>> _plantingHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().firebaseUser;
      if (user != null) {
        // Fetch user basic data
        _currentUser = await SupabaseService().getUserRecord(user.id);
        
        // Fetch rank using RPC (§11)
        final rankRes = await SupabaseService.client.rpc('get_user_rank', params: {'u_id': user.id});
        if (rankRes != null && rankRes is List && rankRes.isNotEmpty) {
           _nationalRank = rankRes[0]['rank'] ?? 0;
        } else if (rankRes != null && rankRes is int) {
           _nationalRank = rankRes;
        } else {
           _nationalRank = 0;
        }

        // Fetch planting history (last 10)
        final historyRes = await SupabaseService.client
            .from('tree_plantings')
            .select('''
              id,
              planted_at,
              latitude,
              longitude,
              tree_species (
                name_ar,
                name_en,
                image_asset_path
              ),
              campaigns (title)
            ''')
            .eq('user_id', user.id)
            .order('planted_at', ascending: false)
            .limit(10);
            
        _plantingHistory = List<Map<String, dynamic>>.from(historyRes);

        // FIX: Fetch live campaign count from campaign_participants directly
        // so it updates immediately after joining or creating a campaign.
        final campaignRes = await SupabaseService.client
            .from('campaign_participants')
            .select('id')
            .eq('user_id', user.id)
            .count();
        _campaignCount = campaignRes.count;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'choose_avatar'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: AppAvatars.list.length,
                  itemBuilder: (context, index) {
                    final asset = AppAvatars.list[index];
                    final bool isSelected = _currentUser?.avatarAsset == asset;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        if (_currentUser != null) {
                          await SupabaseService().updateUserAvatarAsset(_currentUser!.id, asset);
                          _loadProfileData();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(asset),
                          backgroundColor: colorScheme.surfaceContainerLow,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    return TutorialOverlay(
      tutorial: AppTutorials.profile,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'profile'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
          onPressed: () => context.push('/settings'),
        ),
        actions: [
          // زر سجل الإشعارات — في أعلى اليمين عكس زر الإعدادات
          _NotificationBellButton(),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          color: colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHeader(theme),
              const SizedBox(height: 32),
              _buildStatsRow(theme),
              if (_currentUser?.role == 'developer' || _currentUser?.role == 'initiative_owner') ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/dashboard'),
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                  label: Text('control_panel'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _buildHistorySection(theme),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarPicker,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  backgroundImage: _currentUser?.avatarAsset != null
                      ? AssetImage(_currentUser!.avatarAsset!) as ImageProvider
                      : (_currentUser?.avatarUrl != null ? NetworkImage(_currentUser!.avatarUrl!) : null),
                  child: (_currentUser?.avatarAsset == null && _currentUser?.avatarUrl == null)
                      ? Icon(Icons.person_rounded, size: 50, color: colorScheme.primary.withValues(alpha: 0.5))
                      : null,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  child: Icon(Icons.edit_rounded, size: 16, color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser?.fullName ?? 'volunteer'.tr(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            _getRoleDisplayName(_currentUser?.role),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
  
  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'developer': return 'developer'.tr();
      case 'initiative_owner': return 'initiative_owner'.tr();
      case 'provincial_organizer': return 'provincial_organizer'.tr();
      case 'local_organizer': return 'local_organizer'.tr();
      default: return 'volunteer'.tr();
    }
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildStatCard(theme, 'tree_count_display'.tr(args: [(_currentUser?.treeCount ?? 0).toString()]), 'trees_planted'.tr(), Icons.park_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(theme, _nationalRank > 0 ? '#$_nationalRank' : 'unranked_label'.tr(), 'national_rank'.tr(), Icons.emoji_events_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(theme, _campaignCount.toString(), 'my_campaigns'.tr(), Icons.nature_people_outlined)),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String value, String label, IconData icon) {
    final colorScheme = theme.colorScheme;
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'my_trees'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_plantingHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  Text(
                    'no_data'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: _plantingHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _plantingHistory[index];
              final dateStr = item['planted_at'] as String;
              final date = DateTime.parse(dateStr);
              final campaigns = item['campaigns'];
              final title = (campaigns != null && campaigns is Map && campaigns['title'] != null) 
                  ? campaigns['title'] 
                  : 'trees'.tr();
                  
              final lat = (item['latitude'] as num?)?.toDouble();
              final lon = (item['longitude'] as num?)?.toDouble();
              final bool canNavigate = lat != null && lon != null;

              return GestureDetector(
                onTap: canNavigate
                  ? () => context.go('/map', extra: {'lat': lat, 'lng': lon})
                  : null,
                child: CustomCard(
                  color: colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item['tree_species'] != null && item['tree_species']['image_asset_path'] != null
                              ? Image.asset(
                                  item['tree_species']['image_asset_path'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.park_rounded, color: colorScheme.primary, size: 20),
                                )
                              : Icon(Icons.park_rounded, color: colorScheme.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['tree_species'] != null 
                                  ? (context.locale.languageCode == 'ar' 
                                      ? item['tree_species']['name_ar'] 
                                      : item['tree_species']['name_en'])
                                  : title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d MMMM yyyy', context.locale.languageCode).format(date),
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canNavigate)
                        Icon(Icons.location_on_rounded, color: colorScheme.primary.withValues(alpha: 0.5), size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// زر الجرس مع badge عدد الإشعارات غير المقروءة
class _NotificationBellButton extends StatefulWidget {
  const _NotificationBellButton();

  @override
  State<_NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<_NotificationBellButton> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await Supabase.instance.client
          .from('user_notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();
      if (mounted) setState(() => _unreadCount = res.count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            _unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
            color: cs.onSurface,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
            );
            _fetchUnread(); // تحديث badge بعد العودة
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
              child: Center(
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
