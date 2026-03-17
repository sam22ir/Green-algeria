import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';
import '../../../services/supabase_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../models/user_model.dart';
import '../../../constants/provinces.dart';
import 'province_detail_screen.dart';
import 'public_profile_screen.dart';
import '../../../widgets/tutorial_overlay.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  List<UserModel> _allIndividuals = [];
  List<UserModel> _filteredIndividuals = [];
  List<Map<String, dynamic>> _provincesRankings = [];
  
  bool _isLoading = true;
  String _currentUserId = '';
  RealtimeChannel? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentUser();
      _loadData();
      _subscribeToPlantingUpdates();
    });
  }

  void _subscribeToPlantingUpdates() {
    _realtimeSubscription = Supabase.instance.client
        .channel('public:planted_trees_leaderboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tree_plantings',
          callback: (payload) {
            // Re-fetch the leaderboard data to keep rankings accurate
            if (mounted) {
              _loadData();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_realtimeSubscription != null) {
      Supabase.instance.client.removeChannel(_realtimeSubscription!);
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _supabaseService.getUserProfile();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _loadData() async {
    // Only set loading to true if it's the initial load to avoid jank on refresh
    if (_allIndividuals.isEmpty) {
      setState(() => _isLoading = true);
    }
    final ind = await _supabaseService.getTopIndividuals();
    final prov = await _supabaseService.getProvincialLeaderboard();
    
    if (mounted) {
      setState(() {
        _allIndividuals = ind;
        _filteredIndividuals = ind;
        _provincesRankings = prov;
        _isLoading = false;
      });
    }
  }

  void _filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredIndividuals = _allIndividuals);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredIndividuals = _allIndividuals.where((u) {
        return u.fullName.toLowerCase().contains(q) ||
               _getProvinceName(u.provinceId).toLowerCase().contains(q);
      }).toList();
    });
  }

  String _getProvinceName(int? id) {
    if (id == null) return 'unspecified'.tr();
    try {
      final province = algeriaProvinces.firstWhere((p) => p.id == id);
      return context.locale.languageCode == 'ar' ? province.nameAr : province.nameEn;
    } catch (_) {
      return 'unspecified'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TutorialOverlay(
      tutorial: AppTutorials.leaderboard,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: colorScheme.primary,
            displacement: 20.0,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(theme)),
                SliverToBoxAdapter(child: _buildToggle(theme)),
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTabIndex == 0 ? _buildSearchBar(theme) : const SizedBox(height: 16),
                  ),
                ),
                if (_selectedTabIndex == 0 && !_isLoading && _filteredIndividuals.isNotEmpty)
                  SliverToBoxAdapter(child: _buildPodium(theme)),
                
                if (_isLoading)
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                  )
                else
                  _selectedTabIndex == 0 ? _buildIndividualsSliverList(theme) : _buildProvincesSliverList(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'leaderboard'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _buildTab(theme, 0, 'individuals'.tr()),
            _buildTab(theme, 1, 'provinces'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(ThemeData theme, int index, String title) {
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTabIndex != index) {
            setState(() => _selectedTabIndex = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(ThemeData theme) {
    if (_allIndividuals.isEmpty) return const SizedBox();
    
    final first = _allIndividuals.isNotEmpty ? _allIndividuals[0] : null;
    final second = _allIndividuals.length > 1 ? _allIndividuals[1] : null;
    final third = _allIndividuals.length > 2 ? _allIndividuals[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd Place
          if (second != null)
            Expanded(child: _buildPodiumPlace(theme, 2, second, 120, const Color(0xFFC0C0C0))),
          
          const SizedBox(width: 8),
          
          // 1st Place (Center)
          if (first != null)
            Expanded(child: _buildPodiumPlace(theme, 1, first, 160, const Color(0xFFFFD700), isFirst: true)),
          
          const SizedBox(width: 8),
          
          // 3rd Place
          if (third != null)
            Expanded(child: _buildPodiumPlace(theme, 3, third, 100, const Color(0xFFCD7F32))),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(ThemeData theme, int rank, UserModel user, double height, Color medalColor, {bool isFirst = false}) {
    // ◄ onTap → Public Profile
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user.id)),
      ),
      child: _buildPodiumPlaceContent(theme, rank, user, height, medalColor, isFirst: isFirst),
    );
  }

  Widget _buildPodiumPlaceContent(ThemeData theme, int rank, UserModel user, double height, Color medalColor, {bool isFirst = false}) {
    final colorScheme = theme.colorScheme;
    List<String> names = user.fullName.split(' ');
    String dispName = names.isNotEmpty ? names[0] : user.fullName;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: medalColor,
                  width: isFirst ? 3 : 2,
                ),
                boxShadow: isFirst ? [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ] : [],
              ),
              child: Hero(
                tag: 'user_avatar_${user.id}',
                child: CircleAvatar(
                  radius: isFirst ? 42 : 32,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  backgroundImage: user.avatarAsset != null ? AssetImage(user.avatarAsset!) : null,
                  child: user.avatarAsset == null 
                      ? Icon(Icons.person_outline_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3), size: isFirst ? 40 : 30)
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (isFirst)
              const Positioned(
                top: -24,
                child: Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 36),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          dispName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isFirst ? FontWeight.w900 : FontWeight.w800,
            color: colorScheme.onSurface,
            fontSize: isFirst ? 15 : 13,
          ),
        ),
        Text(
          'tree_count_display'.tr(args: [user.treeCount.toString()]),
          style: TextStyle(
            color: isFirst ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
            fontSize: isFirst ? 13 : 11,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surfaceContainerHigh,
                colorScheme.surfaceContainerLow,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: isFirst ? Center(
            child: Icon(Icons.eco_rounded, color: colorScheme.primary.withValues(alpha: 0.2), size: 40),
          ) : null,
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'search_volunteers'.tr(),
            hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 22),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: _filterSearch,
        ),
      ),
    );
  }

  Widget _buildIndividualsSliverList(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final list = _filteredIndividuals;
    
    if (list.length <= 3) {
      if (list.isEmpty) {
        return SliverFillRemaining(
          child: Center(child: Text('no_volunteers_yet'.tr(), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)))),
        );
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = list[index + 3];
            final rank = index + 4;
            return _buildRankingItem(
              theme, rank,
              user.fullName,
              _getProvinceName(user.provinceId),
              user.treeCount,
              user.id == _currentUserId,
              userId: user.id,
              avatarAsset: user.avatarAsset,
            );
          },
          childCount: list.length - 3,
        ),
      ),
    );
  }

  Widget _buildProvincesSliverList(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_provincesRankings.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text('no_data_available'.tr(), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)))),
      );
    }

    // الحد الأقصى لحساب نسبة progress
    final maxTrees = (_provincesRankings.isNotEmpty
        ? (_provincesRankings.first['total_trees'] as int? ?? 0)
        : 1);

    final top3 = _provincesRankings.take(3).toList();
    final rest = _provincesRankings.length > 3 ? _provincesRankings.sublist(3) : <Map<String, dynamic>>[];

    return SliverToBoxAdapter(
      child: Container(
        color: isDark
            ? const Color(0xFF1A1F14)
            : const Color(0xFFE7EADF), // sage-cream خلفية مميزة للولايات
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top 3 بطاقات ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: List.generate(top3.length, (i) {
                  final provinceId = top3[i]['province_id'] as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProvinceDetailScreen(
                          provinceId: provinceId,
                          rank: i + 1,
                          totalTrees: top3[i]['total_trees'] as int? ?? 0,
                          maxTrees: maxTrees,
                        )),
                      ),
                      child: _buildTop3ProvinceCard(
                        theme: theme,
                        rank: i + 1,
                        provName: _getProvinceName(top3[i]['province_id'] as int?),
                        trees: top3[i]['total_trees'] as int? ?? 0,
                        maxTrees: maxTrees,
                        isDark: isDark,
                      ),
                    ),
                  );
                }),
              ),
            ),
            // ── بقية الولايات ────────────────────────────────────
            if (rest.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: List.generate(rest.length, (i) {
                    final data = rest[i];
                    final provinceId = data['province_id'] as int? ?? 0;
                    final provName = _getProvinceName(data['province_id'] as int?);
                    final trees = data['total_trees'] as int? ?? 0;
                    final progress = maxTrees > 0 ? trees / maxTrees : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProvinceDetailScreen(
                            provinceId: provinceId,
                            rank: i + 4,
                            totalTrees: trees,
                            maxTrees: maxTrees,
                          )),
                        ),
                        child: _buildProvinceListRow(
                          theme: theme,
                          rank: i + 4,
                          provName: provName,
                          trees: trees,
                          progress: progress,
                          isDark: isDark,
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// بطاقة Top 3 — تصميم Stitch: خلفيات فاتحة ملونة + شارة دائرية + اسم المرتبة
  Widget _buildTop3ProvinceCard({
    required ThemeData theme,
    required int rank,
    required String provName,
    required int trees,
    required int maxTrees,
    required bool isDark,
  }) {
    final progress = maxTrees > 0 ? trees / maxTrees : 0.0;

    // Stitch Design: ألوان فاتحة مع شارات
    late Color bgColor;
    late Color badgeColor;
    late Color badgeBorder;
    late Color barColor;
    late Color textPrimary;
    late Color textSecondary;
    late String rankLabel;
    late String medal;

    switch (rank) {
      case 1:
        bgColor = isDark ? const Color(0xFF2A2D1A) : const Color(0xFFFFF9E6);
        badgeColor = const Color(0xFFFFD700);
        badgeBorder = const Color(0xFFE6B800);
        barColor = const Color(0xFF606C38);
        textPrimary = isDark ? const Color(0xFFFFF9E6) : const Color(0xFF2D2D2D);
        textSecondary = isDark ? const Color(0xFFB8A830) : const Color(0xFF8B7200);
        rankLabel = 'المركز الأول';
        medal = '🥇';
        break;
      case 2:
        bgColor = isDark ? const Color(0xFF1E2226) : const Color(0xFFF0F4F8);
        badgeColor = const Color(0xFFB0BEC5);
        badgeBorder = const Color(0xFF90A4AE);
        barColor = const Color(0xFF606C38);
        textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
        textSecondary = isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A);
        rankLabel = 'المركز الثاني';
        medal = '🥈';
        break;
      default:
        bgColor = isDark ? const Color(0xFF261E14) : const Color(0xFFFFF3E0);
        badgeColor = const Color(0xFFCD7F32);
        badgeBorder = const Color(0xFFB56A1E);
        barColor = const Color(0xFF606C38);
        textPrimary = isDark ? const Color(0xFFFFF3E0) : const Color(0xFF2D2D2D);
        textSecondary = isDark ? const Color(0xFFCD7F32) : const Color(0xFF8D4E00);
        rankLabel = 'المركز الثالث';
        medal = '🥉';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // الشارة الدائرية
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor.withValues(alpha: 0.15),
              border: Border.all(color: badgeBorder, width: 2),
            ),
            child: Center(
              child: Text(
                medal,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // اسم الولاية والمرتبة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provName,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rankLabel,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: badgeColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // عدد الأشجار
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.eco_rounded, color: barColor, size: 18),
              const SizedBox(height: 2),
              Text(
                _formatTrees(trees),
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTrees(int trees) {
    if (trees >= 1000000) return '${(trees / 1000000).toStringAsFixed(1)}M';
    if (trees >= 1000) return '${(trees / 1000).toStringAsFixed(0)}K';
    return '$trees';
  }

  /// صف الولايات 4+ مع progress bar نسبي
  Widget _buildProvinceListRow({
    required ThemeData theme,
    required int rank,
    required String provName,
    required int trees,
    required double progress,
    required bool isDark,
  }) {
    final bgColor = isDark ? const Color(0xFF232B1A) : Colors.white;
    final barColor = isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final textSecondary = isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // رقم الترتيب
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // اسم الولاية
          SizedBox(
            width: 90,
            child: Text(
              provName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: textPrimary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          // شريط التقدم
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? const Color(0xFF2A3320)
                    : const Color(0xFFE7EADF),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // عدد الأشجار
          Row(
            children: [
              Icon(Icons.eco_rounded, color: barColor, size: 13),
              const SizedBox(width: 3),
              Text(
                _formatTrees(trees),
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(ThemeData theme, int rank, String title, String subtitle, int count, bool isCurrentUser, {bool isProvince = false, String? avatarAsset, String? userId}) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: userId != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userId)),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomCard(
          color: isCurrentUser ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 24,
          child: Row(
            children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: rank <= 3 ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: rank <= 3 ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (!isProvince)
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.surface,
                backgroundImage: avatarAsset != null ? AssetImage(avatarAsset) : null,
                child: avatarAsset == null ? Icon(Icons.person_outline_rounded, color: colorScheme.primary.withValues(alpha: 0.3), size: 24) : null,
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.map_rounded, color: colorScheme.primary, size: 24),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco_rounded, color: colorScheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ), // child of Padding
  ); // end GestureDetector
  }
}
