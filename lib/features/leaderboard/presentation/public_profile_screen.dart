import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_model.dart';
import '../../../models/campaign_model.dart';
import '../../../constants/provinces.dart';
import '../../campaigns/presentation/past_campaign_detail_screen.dart';


class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  late final TabController _tabController;

  UserModel? _user;
  List<Map<String, dynamic>> _treePlantings = [];
  List<Map<String, dynamic>> _campaignParticipation = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await _supabase.getUserRecord(widget.userId);
    final trees = await _supabase.getUserTreePlantings(widget.userId);
    final camps = await _supabase.getUserCampaignParticipation(widget.userId);
    if (mounted) {
      setState(() {
        _user = user;
        _treePlantings = trees;
        _campaignParticipation = camps;
        _isLoading = false;
      });
    }
  }

  String _getProvinceName(int? id) {
    if (id == null) return 'unspecified'.tr();
    try {
      final prov = algeriaProvinces.firstWhere((p) => p.id == id);
      return context.locale.languageCode == 'ar' ? prov.nameAr : prov.nameEn;
    } catch (_) {
      return 'unspecified'.tr();
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'developer': return 'developer'.tr();
      case 'initiative_owner': return 'initiative_owner'.tr();
      case 'provincial_organizer': return 'provincial_organizer'.tr();
      case 'local_organizer': return 'local_organizer'.tr();
      default: return 'volunteer'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1F14) : const Color(0xFFFBFBF7),
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('user_not_found'.tr())),
        body: Center(child: Text('user_not_found'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1F14) : const Color(0xFFFBFBF7),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          _buildHeader(ctx, user, isDark),
          _buildStatsSliver(user, isDark),
          _buildTabBarSliver(theme, isDark),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTreesTab(isDark),
            _buildCampaignsTab(isDark),
          ],
        ),
      ),
    );
  }

  // ── SliverAppBar Header ────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx, UserModel user, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF606C38),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية طبيعة
            Image.asset(
              'assets/images/forest_bg_signin.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF606C38), Color(0xFF3A5A1E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.45)),
            // محتوى Header
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF606C38),
                    child: user.avatarAsset != null
                        ? ClipOval(
                            child: Image.asset(user.avatarAsset!,
                                width: 80, height: 80, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => _defaultAvatar(user)))
                        : _defaultAvatar(user),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getProvinceName(user.provinceId)} • ${_roleLabel(user.role)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(UserModel user) => Text(
        user.fullName.isNotEmpty ? user.fullName[0] : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
      );

  // ── بطاقة الإحصائيات ──────────────────────────────────────────────
  Widget _buildStatsSliver(UserModel user, bool isDark) {
    final bgColor = isDark ? const Color(0xFF232B1A) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final textSecondary = isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: Row(
          children: [
            _buildStatCol(textPrimary, textSecondary, '${user.treeCount}', 'total_trees'.tr(), Icons.park_rounded),
            _buildDivider(isDark),
            _buildStatCol(textPrimary, textSecondary, '${_campaignParticipation.length}', 'campaigns'.tr(), Icons.campaign_rounded),
            _buildDivider(isDark),
            _buildStatCol(textPrimary, textSecondary, '${_treePlantings.length}', 'plantings'.tr(), Icons.eco_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(Color pri, Color sec, String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: pri),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: pri, fontSize: 18)),
          Text(label, style: TextStyle(color: sec, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1, height: 48,
      color: isDark ? const Color(0xFF2A3320) : const Color(0xFFE7EADF),
    );
  }

  // ── TabBar ────────────────────────────────────────────────────────
  Widget _buildTabBarSliver(ThemeData theme, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1F14) : const Color(0xFFFBFBF7);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38),
          unselectedLabelColor: isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C),
          indicatorColor: isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38),
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'trees'.tr(), icon: Icon(Icons.park_rounded, size: 18)),
            Tab(text: 'campaigns'.tr(), icon: Icon(Icons.campaign_rounded, size: 18)),
          ],
        ),
        bgColor: bgColor,
      ),
    );
  }

  // ── تبويب الأشجار ────────────────────────────────────────────────
  Widget _buildTreesTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF232B1A) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final textSecondary = isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C);
    final brandColor = isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);

    if (_treePlantings.isEmpty) {
      return Center(child: Text('no_plantings'.tr(), style: TextStyle(color: textSecondary)));
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _treePlantings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = _treePlantings[i];
        final species = item['tree_species'] as Map<String, dynamic>?;
        final speciesName = context.locale.languageCode == 'ar'
            ? (species?['name_ar'] ?? 'unknown'.tr())
            : (species?['name_en'] ?? 'unknown'.tr());
        final plantedAt = item['planted_at'] != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item['planted_at']))
            : '';

        final lat = item['latitude'] as double?;
        final lng = item['longitude'] as double?;

        return GestureDetector(
          onTap: (lat != null && lng != null)
              ? () => context.go('/map', extra: {'lat': lat, 'lng': lng})
              : null,
          child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Row(
            children: [
              // أيقونة الشجرة
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.eco_rounded, color: brandColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(speciesName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14)),
                    if (plantedAt.isNotEmpty)
                      Text(plantedAt, style: TextStyle(color: textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                lat != null ? Icons.location_on_rounded : Icons.location_off_outlined,
                color: lat != null ? brandColor : textSecondary,
                size: 18,
              ),
            ],
          ),
        ));
      },
    );
  }

  // ── تبويب الحملات ────────────────────────────────────────────────
  Widget _buildCampaignsTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF232B1A) : const Color(0xFFF4F3ED);
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final textSecondary = isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C);
    final brandColor = isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);

    if (_campaignParticipation.isEmpty) {
      return Center(child: Text('no_campaigns_joined'.tr(), style: TextStyle(color: textSecondary)));
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _campaignParticipation.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final camp = _campaignParticipation[i];
        final type = camp['type'] as String? ?? 'local';
        final treeCount = camp['tree_count'] as int? ?? 0;
        final status = camp['status'] as String? ?? 'completed';

        return GestureDetector(
          onTap: () {
            if (status == 'completed') {
              final campaignModel = CampaignModel.fromJson(Map<String, dynamic>.from(camp));
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PastCampaignDetailScreen(campaign: campaignModel),
                ),
              );
            } else {
              context.go('/map');
            }
          },
          child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Row(
            children: [
              // أيقونة الحملة
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _typeColor(type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.campaign_rounded, color: _typeColor(type), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(camp['title'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTypeBadge(type),
                        const SizedBox(width: 8),
                        Icon(Icons.eco_rounded, color: brandColor, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '$treeCount ${'tree_sm'.tr()}',
                          style: TextStyle(color: brandColor, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary.withValues(alpha: 0.4)),
            ],
          ),
        ));
      },
    );
  }


  Color _typeColor(String type) {
    switch (type) {
      case 'national': return Colors.orange;
      case 'provincial': return Colors.blue;
      default: return const Color(0xFF606C38);
    }
  }

  Widget _buildTypeBadge(String type) {
    final color = _typeColor(type);
    String label;
    switch (type) {
      case 'national': label = 'national_type'.tr(); break;
      case 'provincial': label = 'provincial_type'.tr(); break;
      default: label = 'local_type'.tr();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Delegate للـ SliverPersistentHeader ────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;

  _TabBarDelegate(this.tabBar, {required this.bgColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlaps) {
    return Container(color: bgColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}
