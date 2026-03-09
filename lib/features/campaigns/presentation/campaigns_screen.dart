import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../../../models/campaign_model.dart';
import '../../../models/user_model.dart';
import 'widgets/campaign_card.dart';
import 'widgets/create_campaign_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _loadUserRole();
    _loadCampaigns();
    _setupRealtime();
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
      // For now, loading all provincial/local. Later filter by user province dynamically.
      _provincialFuture = _supabaseService.getActiveCampaigns(type: 'provincial');
      _localFuture = _supabaseService.getActiveCampaigns(type: 'local');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadCampaigns();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: Column(
            children: [
              _buildAppBar(l10n),
              _buildTabBar(l10n),
              Expanded(
                child: _buildTabView(l10n),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoadingUser || _currentUser == null || !_currentUser!.isOrganizer
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.mossForest,
              onPressed: _showCreateCampaignSheet,
              child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildAppBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        l10n.campaigns,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.slateCharcoal,
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ivorySand.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(0, l10n.national),
          _buildTab(1, l10n.wilaya),
          _buildTab(2, l10n.individual),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mossForest : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.mossForest.withValues(alpha: 0.3),
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
              color: isSelected ? Colors.white : AppColors.slateCharcoal,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabView(AppLocalizations l10n) {
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
          return const Center(child: CircularProgressIndicator(color: AppColors.mossForest));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading campaigns: ${snapshot.error}'));
        }

        final campaigns = snapshot.data ?? [];
        if (campaigns.isEmpty) {
          return Center(
            child: Text(
              'لا توجد حملات حالياً في هذا التصنيف', // Translation needed
              style: const TextStyle(color: AppColors.oliveGrey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
