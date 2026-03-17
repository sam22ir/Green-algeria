import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/tutorial_overlay.dart';
import '../../../services/supabase_service.dart';
import '../../../models/campaign_model.dart';
import '../../../services/auth_service.dart';
import '../../../constants/campaign_covers.dart';
import '../../campaigns/presentation/past_campaign_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = true;
  int _totalTrees = 0;
  CampaignModel? _upcomingCampaign;
  List<CampaignModel> _pastCampaigns = [];
  bool _isActiveCampaign = false; // v3.4.1: true = active (countdown to end), false = upcoming (countdown to start)

  Timer? _countdownTimer;
  Duration _timeUntilNextCampaign = Duration.zero;
  RealtimeChannel? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
      _subscribeToRealtime();
    });
  }

  void _subscribeToRealtime() {
    _realtimeSubscription = Supabase.instance.client
        .channel('public:home_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tree_plantings',
          callback: (payload) {
            if (mounted) {
              _fetchDashboardData(); // Refetch to be accurate
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'campaigns',
          callback: (payload) {
            if (mounted) {
              _fetchDashboardData();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (_realtimeSubscription != null) {
      Supabase.instance.client.removeChannel(_realtimeSubscription!);
    }
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _supabaseService.getTotalTreesPlanted(),
        _supabaseService.getUpcomingNationalCampaign(),
        _supabaseService.getPastCampaigns(),
      ]);

      if (mounted) {
        setState(() {
          _totalTrees = futures[0] as int;
          final campaign = futures[1] as CampaignModel?;
          _upcomingCampaign = campaign;
          // v3.4.1: Detect if campaign is already active or just upcoming
          _isActiveCampaign = campaign?.status == 'active';
          _pastCampaigns = futures[2] as List<CampaignModel>;
          _isLoading = false;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error fetching dashboard: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    // v3.4.1: Count down to end_date if active, to start_date if upcoming
    final hasDate = _isActiveCampaign
        ? _upcomingCampaign?.endDate != null
        : _upcomingCampaign?.startDate != null;
    if (!hasDate) return;

    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_upcomingCampaign == null) return;
    final now = DateTime.now();
    // v3.4.1: Use end_date for active, start_date for upcoming
    final targetDate = _isActiveCampaign
        ? _upcomingCampaign!.endDate
        : _upcomingCampaign!.startDate;
    if (targetDate == null) return;
    final difference = targetDate.difference(now);
    if (mounted) {
      setState(() {
        _timeUntilNextCampaign = difference.isNegative ? Duration.zero : difference;
      });
    }
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
      tutorial: AppTutorials.home,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchDashboardData,
            color: colorScheme.primary,
            displacement: 40.0,
            strokeWidth: 2.5,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 32),
                  _buildTotalTreesCounter(context),
                  const SizedBox(height: 24),
                  _buildCampaignCountdown(context),
                  const SizedBox(height: 32),
                _buildRecentCampaignsSection(context),
                const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUserModel;
    final displayName = user?.fullName ?? 'volunteer'.tr();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  backgroundImage: user?.avatarAsset != null
                      ? AssetImage(user!.avatarAsset!) as ImageProvider
                      : null,
                  child: user?.avatarAsset == null
                      ? Icon(Icons.person_rounded, color: colorScheme.primary.withValues(alpha: 0.5), size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'welcome_back'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          'app_name'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTreesCounter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.park_rounded, size: 36, color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _totalTrees.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'total_trees'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCountdown(BuildContext context) {
    final theme = Theme.of(context);

    if (_upcomingCampaign == null) {
      return const SizedBox.shrink();
    }

    final days = _timeUntilNextCampaign.inDays;
    final hours = _timeUntilNextCampaign.inHours % 24;
    final minutes = _timeUntilNextCampaign.inMinutes % 60;

    // Stitch Design: بطاقة خضراء زيتية مع 3 صناديق للعد التنازلي
    return GestureDetector(
      onTap: () => context.push('/campaigns'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF606C38), Color(0xFF3A5A1E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF606C38).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس البطاقة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isActiveCampaign ? 'active_campaign'.tr() : 'upcoming_campaign'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // صناديق العد التنازلي — Stitch Design
            Row(
              children: [
                _buildCountdownBox(days.toString().padLeft(2, '0'), 'days'.tr()),
                _buildCountdownSeparator(),
                _buildCountdownBox(hours.toString().padLeft(2, '0'), 'hours'.tr()),
                _buildCountdownSeparator(),
                _buildCountdownBox(minutes.toString().padLeft(2, '0'), 'minutes'.tr()),
              ],
            ),
            const SizedBox(height: 20),

            // اسم الحملة
            Text(
              _upcomingCampaign!.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // شارة التاريخ
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      _isActiveCampaign ? 'ends_in'.tr() : 'starts_in'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRecentCampaignsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'past_campaigns'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                context.push('/past-campaigns');
              },
              child: Text(
                'view_all'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_pastCampaigns.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 40, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  Text(
                    'no_past_campaigns'.tr(), 
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3))
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 185,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _pastCampaigns.length,
              itemBuilder: (context, index) {
                final campaign = _pastCampaigns[index];
                final coverImage = campaign.coverImageAsset ?? AppCampaignCovers.forType(campaign.type);

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PastCampaignDetailScreen(campaign: campaign),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 12,
                      right: index == _pastCampaigns.length - 1 ? 0 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ✅ صورة الغلاف
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.asset(
                            coverImage,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.park_rounded, color: colorScheme.primary, size: 32),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  campaign.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${campaign.treePlanted} ${'trees'.tr()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

              },
            ),
          ),
      ],
    );
  }
}
