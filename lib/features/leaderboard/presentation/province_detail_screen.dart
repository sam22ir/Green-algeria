import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/supabase_service.dart';
import '../../../constants/provinces.dart';
import '../../../models/user_model.dart';
import '../../../models/campaign_model.dart';
import '../../leaderboard/presentation/public_profile_screen.dart';
import '../../campaigns/presentation/campaign_details_screen.dart';

class ProvinceDetailScreen extends StatefulWidget {
  final int provinceId;
  final int rank;
  final int totalTrees;
  final int maxTrees; // للـ progress bar النسبي

  const ProvinceDetailScreen({
    super.key,
    required this.provinceId,
    required this.rank,
    required this.totalTrees,
    required this.maxTrees,
  });

  @override
  State<ProvinceDetailScreen> createState() => _ProvinceDetailScreenState();
}

class _ProvinceDetailScreenState extends State<ProvinceDetailScreen> {
  final _supabase = SupabaseService();

  List<UserModel> _topUsers = [];
  List<CampaignModel> _campaigns = [];
  int _volunteerCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _supabase.getProvinceTopUsers(widget.provinceId, limit: 10);
    final camps = await _supabase.getActiveCampaigns(
      type: 'provincial',
      provinceId: widget.provinceId,
    );
    // عدد المتطوعين = كل المستخدمين في الولاية غير الصفريين
    final volCount = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('province_id', widget.provinceId)
        .count();
    if (mounted) {
      setState(() {
        _topUsers = users;
        _campaigns = camps;
        _volunteerCount = volCount.count;
        _isLoading = false;
      });
    }
  }

  String get _provinceName {
    try {
      final prov = algeriaProvinces.firstWhere((p) => p.id == widget.provinceId);
      return context.locale.languageCode == 'ar' ? prov.nameAr : prov.nameEn;
    } catch (_) {
      return 'unspecified'.tr();
    }
  }

  /// Returns rank icon data instead of emoji — matched to Stitch design
  IconData get _rankIcon {
    switch (widget.rank) {
      case 1: return Icons.emoji_events_rounded;  // gold trophy
      case 2: return Icons.workspace_premium_rounded;  // silver
      case 3: return Icons.military_tech_rounded;  // bronze
      default: return Icons.leaderboard_rounded;
    }
  }

  Color get _rankColor {
    switch (widget.rank) {
      case 1: return const Color(0xFFFFD700);  // Gold
      case 2: return const Color(0xFFC0C0C0);  // Silver
      case 3: return const Color(0xFFCD7F32);  // Bronze
      default: return const Color(0xFF606C38);  // Olive
    }
  }

  String get _rankLabel {
    switch (widget.rank) {
      case 1:
      case 2:
      case 3:
        return 'national_rank'.tr(args: [widget.rank.toString()]);
      default: return '#${widget.rank}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = widget.maxTrees > 0 ? widget.totalTrees / widget.maxTrees : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1F14) : const Color(0xFFFBFBF7),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header بتدرج أخضر ────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: const Color(0xFF606C38),
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF606C38), Color(0xFF3A5A1E)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // رقم الولاية
                              Text(
                                'WL - ${widget.provinceId.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _provinceName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Badge المركز
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_rankIcon, color: _rankColor, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _rankLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── بطاقات الإحصائيات ────────────────────────
                      _buildStatsRow(theme, isDark, progress),
                      const SizedBox(height: 24),

                      // ── أبرز المتطوعين ───────────────────────────
                      _buildSectionTitle(theme, isDark, 'top_volunteers'.tr(), Icons.people_rounded),
                      const SizedBox(height: 12),
                      if (_topUsers.isEmpty)
                        _buildEmpty(theme, isDark)
                      else
                        ..._topUsers.asMap().entries.map((e) => _buildVolunteerRow(
                              theme, isDark, e.key + 1, e.value,
                              maxTrees: _topUsers.isNotEmpty ? (_topUsers.first.treeCount) : 1,
                            )),

                      const SizedBox(height: 24),

                      // ── الحملات ──────────────────────────────────
                      _buildSectionTitle(theme, isDark, 'active_campaigns'.tr(), Icons.campaign_rounded),
                      const SizedBox(height: 12),
                      if (_campaigns.isEmpty)
                        _buildEmpty(theme, isDark)
                      else
                        ..._campaigns.map((c) => _buildCampaignCard(theme, isDark, c)),

                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // بطاقات الإحصائيات الثلاثة
  Widget _buildStatsRow(ThemeData theme, bool isDark, double progress) {
    final bgColor = isDark ? const Color(0xFF232B1A) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final textSecondary = isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C);

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(theme, isDark, bgColor, textPrimary, textSecondary,
                '${widget.totalTrees}', 'total_trees'.tr(), Icons.park_rounded),
            const SizedBox(width: 10),
            _buildStatCard(theme, isDark, bgColor, textPrimary, textSecondary,
                '$_volunteerCount', 'volunteers'.tr(), Icons.people_rounded),
            const SizedBox(width: 10),
            _buildStatCard(theme, isDark, bgColor, textPrimary, textSecondary,
                '${_campaigns.length}', 'campaigns'.tr(), Icons.campaign_rounded),
          ],
        ),
        const SizedBox(height: 12),
        // Progress bar نسبي
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('national_contribution'.tr(),
                      style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38),
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? const Color(0xFF2A3320) : const Color(0xFFE7EADF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, bool isDark, Color bg, Color textPri, Color textSec,
      String value, String label, IconData icon) {
    final brandColor = isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: brandColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w900, color: textPri, fontSize: 16)),
            Text(label,
                style: TextStyle(color: textSec, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, bool isDark, String title, IconData icon) {
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    return Row(
      children: [
        Icon(icon, color: isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38), size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(fontWeight: FontWeight.w900, color: textPrimary, fontSize: 16)),
      ],
    );
  }

  Widget _buildVolunteerRow(ThemeData theme, bool isDark, int rank, UserModel user,
      {required int maxTrees}) {
    final bgColor = isDark ? const Color(0xFF232B1A) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final barColor = isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);
    final progress = maxTrees > 0 ? user.treeCount / maxTrees : 0.0;

    final avatarColors = [
      const Color(0xFF606C38), const Color(0xFF5A7233), const Color(0xFF7A9E45),
      const Color(0xFF4A6828), const Color(0xFF3A5A1E),
    ];
    final avatarColor = avatarColors[(rank - 1) % avatarColors.length];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            // الاسم
            Expanded(
              flex: 3,
              child: Text(
                user.fullName,
                style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Progress bar
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? const Color(0xFF2A3320) : const Color(0xFFE7EADF),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // عدد الأشجار
            Row(
              children: [
                Icon(Icons.eco_rounded, color: barColor, size: 14),
                const SizedBox(width: 3),
                Text('${user.treeCount}',
                    style: TextStyle(color: barColor, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(ThemeData theme, bool isDark, CampaignModel camp) {
    final bgColor = isDark ? const Color(0xFF232B1A) : const Color(0xFFF4F3ED);
    final textPrimary = isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D);
    final textSecondary = isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CampaignDetailsScreen(campaign: camp))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            // غلاف الحملة
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: camp.coverImageAsset != null
                  ? Image.asset(camp.coverImageAsset!,
                      width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 56, height: 56,
                        color: const Color(0xFF606C38),
                        child: const Icon(Icons.forest_rounded, color: Colors.white, size: 24),
                      ))
                  : Container(
                      width: 56, height: 56,
                      color: const Color(0xFF606C38),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(camp.title,
                      style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildCampaignTypeBadge(camp.type),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF606C38).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'active'.tr(),
                          style: const TextStyle(
                              color: Color(0xFF606C38), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    camp.endDate != null
                        ? 'ends'.tr(args: [DateFormat('yyyy-MM-dd').format(camp.endDate!)])
                        : '',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignTypeBadge(String type) {
    Color color;
    String label;
    switch (type) {
      case 'national':
        color = Colors.orange;
        label = 'national_type'.tr();
        break;
      case 'provincial':
        color = Colors.blue;
        label = 'provincial_type'.tr();
        break;
      default:
        color = const Color(0xFF606C38);
        label = 'local_type'.tr();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmpty(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text('no_data_available'.tr(),
            style: TextStyle(
                color: isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C))),
      ),
    );
  }
}
