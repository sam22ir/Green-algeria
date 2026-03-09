import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../services/supabase_service.dart';
import '../../../models/campaign_model.dart';
import '../../../services/auth_service.dart';

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

  Timer? _countdownTimer;
  Duration _timeUntilNextCampaign = Duration.zero;
  RealtimeChannel? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _subscribeToTreePlantings();
  }

  void _subscribeToTreePlantings() {
    _realtimeSubscription = Supabase.instance.client
        .channel('public:tree_plantings_home')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tree_plantings',
          callback: (payload) {
            if (mounted) {
              setState(() => _totalTrees++);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    Supabase.instance.client.removeChannel(_realtimeSubscription!);
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
          _upcomingCampaign = futures[1] as CampaignModel?;
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
    if (_upcomingCampaign?.startDate == null) return;
    
    _countdownTimer?.cancel();
    _updateCountdown();
    
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_upcomingCampaign?.startDate == null) return;
    
    final now = DateTime.now();
    final difference = _upcomingCampaign!.startDate!.difference(now);
    
    if (mounted) {
      setState(() {
        _timeUntilNextCampaign = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.linenWhite,
        body: Center(child: CircularProgressIndicator(color: AppColors.mossForest)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: AppColors.mossForest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final user = AuthService().firebaseUser;
    final displayName = user?.displayName ?? AppLocalizations.of(context)!.volunteer;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.ivorySand,
              child: Icon(Icons.person, color: AppColors.mossForest),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.oliveGrey,
                  ),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateCharcoal,
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          l10n.appTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.mossForest,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTreesCounter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return CustomCard(
      blur: 20,
      opacity: 0.85,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.park_rounded, size: 48, color: AppColors.mossForest),
          const SizedBox(height: 16),
          Text(
            _totalTrees.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.mossForest,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.treesPlantedNationally,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.oliveGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCountdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_upcomingCampaign == null) {
      return CustomCard(
        padding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.noUpcomingCampaign,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.mossForest,
            ),
          ),
        ),
      );
    }

    final days = _timeUntilNextCampaign.inDays;
    final hours = _timeUntilNextCampaign.inHours % 24;
    final minutes = _timeUntilNextCampaign.inMinutes % 60;

    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sageCream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.timer_outlined, color: AppColors.mossForest, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.nextCampaign} ${_upcomingCampaign!.title}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${days.toString().padLeft(2, '0')} ${l10n.days} ${hours.toString().padLeft(2, '0')} ${l10n.hours} ${minutes.toString().padLeft(2, '0')} ${l10n.minutes}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mossForest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCampaignsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentCampaigns,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slateCharcoal,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                l10n.viewAll,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mossForest,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_pastCampaigns.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text('No past campaigns yet.', style: TextStyle(color: AppColors.oliveGrey)),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pastCampaigns.length,
              itemBuilder: (context, index) {
                final campaign = _pastCampaigns[index];
                
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(left: 16, right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ivorySand,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sageCream),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.oliveGrey.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mossForest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.completed,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                campaign.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slateCharcoal,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${campaign.treePlanted} ${l10n.treesPlanted}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mossForest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
