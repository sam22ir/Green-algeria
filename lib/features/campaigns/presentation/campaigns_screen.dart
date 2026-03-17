import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/supabase_service.dart';
import '../../../models/campaign_model.dart';
import '../../../models/user_model.dart';
import 'widgets/campaign_card.dart';
import 'widgets/create_campaign_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/campaign_utils.dart';
import '../../../widgets/tutorial_overlay.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  int _selectedTabIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<CampaignModel>> _nationalFuture;
  late Future<List<CampaignModel>> _provincialFuture;
  late Future<List<CampaignModel>> _localFuture;
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  RealtimeChannel? _campaignsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserRole();
      _loadCampaigns();
      _setupRealtime();
    });
  }

  void _setupRealtime() {
    _campaignsSubscription = Supabase.instance.client
        .channel('public:campaigns')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'campaigns',
            callback: (payload) {
              if (mounted) {
                _loadCampaigns();
              }
            })
        .subscribe();
  }

  @override
  void dispose() {
    _campaignsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await _supabaseService.getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  void _loadCampaigns() {
    setState(() {
      _nationalFuture = _supabaseService.getActiveCampaigns(type: 'national');
      _provincialFuture = _supabaseService.getActiveCampaigns(
        type: 'provincial',
        provinceId: _currentUser?.provinceId,
      );
      _localFuture = _supabaseService.getActiveCampaigns(
        type: 'local',
        provinceId: _currentUser?.provinceId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TutorialOverlay(
      tutorial: AppTutorials.campaigns,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadCampaigns();
              await Future.delayed(const Duration(milliseconds: 200));
            },
            color: colorScheme.primary,
            displacement: 40.0,
            strokeWidth: 2.5,
            child: Column(
              children: [
                _buildAppBar(theme),
                _buildTabBar(theme),
                Expanded(
                  child: _buildTabView(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateCampaignSheet() async {
    if (_currentUser == null) return;
    
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCampaignSheet(currentUser: _currentUser!),
    );

    if (created == true) {
      _loadCampaigns(); // Refresh lists
    }
  }

  Widget _buildAppBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          // Past campaigns button (left/start side in RTL)
          Tooltip(
            message: 'past_campaigns'.tr(),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/past-campaigns'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'past_campaigns'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Centered title
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_rounded, color: colorScheme.primary, size: 26),
                const SizedBox(width: 8),
                Text(
                  'campaigns'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Invisible spacer to balance layout
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(theme, 0, 'national'.campaignTypeLabel),
          _buildTab(theme, 1, 'provincial'.campaignTypeLabel),
          _buildTab(theme, 2, 'local'.campaignTypeLabel),
        ],
      ),
    );
  }

  Widget _buildTab(ThemeData theme, int index, String title) {
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabView(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    Future<List<CampaignModel>> futureToUse;
    if (_selectedTabIndex == 0) {
      futureToUse = _nationalFuture;
    } else if (_selectedTabIndex == 1) {
      futureToUse = _provincialFuture;
    } else {
      futureToUse = _localFuture;
    }

    return FutureBuilder<List<CampaignModel>>(
      future: futureToUse,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('error_loading_campaigns'.tr(args: [snapshot.error.toString()])));
        }

        final campaigns = snapshot.data ?? [];
        if (campaigns.isEmpty) {
          return Center(
            child: Text(
              'no_campaigns_category'.tr(),
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return CampaignCard(
              campaign: campaign,
              onTap: () {
                context.push('/campaigns/details', extra: campaign);
              },
              onJoinTap: () {
                // Navigate to map to plant tree (campaign pre-selected)
                // Need to implement Map screen handling of extra args next
                context.go('/map');
              },
            );
          },
        );
      },
    );
  }
}
