import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../services/supabase_service.dart';
import '../../../models/user_model.dart';
import '../../../constants/provinces.dart';

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
    _fetchCurrentUser();
    _loadData();
    _subscribeToPlantingUpdates();
  }

  void _subscribeToPlantingUpdates() {
    _realtimeSubscription = Supabase.instance.client
        .channel('public:tree_plantings_leaderboard')
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
    Supabase.instance.client.removeChannel(_realtimeSubscription!);
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
    if (id == null) return 'غير محدد'; // Unspecified
    try {
      return algeriaProvinces.firstWhere((p) => p.id == id).nameAr;
    } catch (_) {
      return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.mossForest,
          child: Column(
            children: [
              _buildAppBar(l10n),
              _buildToggle(l10n),
              if (_selectedTabIndex == 0) _buildSearchBar(l10n),
              const SizedBox(height: 16),
              if (_selectedTabIndex == 0) _buildPodium(),
              if (_selectedTabIndex == 0) const SizedBox(height: 24),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.mossForest))
                    : _selectedTabIndex == 0 ? _buildIndividualsList() : _buildProvincesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.mossForest, size: 28),
          const SizedBox(width: 8),
          Text(
            l10n.leaderboardTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slateCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ivorySand.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(0, l10n.individuals),
          _buildTab(1, l10n.wilayas),
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

  Widget _buildPodium() {
    if (_allIndividuals.isEmpty) return const SizedBox();
    
    final first = _allIndividuals.isNotEmpty ? _allIndividuals[0] : null;
    final second = _allIndividuals.length > 1 ? _allIndividuals[1] : null;
    final third = _allIndividuals.length > 2 ? _allIndividuals[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (second != null) _buildPodiumPlace(2, second, 100),
          if (first != null) _buildPodiumPlace(1, first, 140, isFirst: true),
          if (third != null) _buildPodiumPlace(3, third, 90),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(int rank, UserModel user, double height, {bool isFirst = false}) {
    // Extract first name and initial of last name
    List<String> parts = user.fullName.split(' ');
    String shortName = parts.isNotEmpty ? parts[0] : user.fullName;
    if (parts.length > 1) {
      shortName += ' ${parts[1][0]}.';
    }

    return Column(
      children: [
        if (isFirst)
          const Icon(Icons.workspace_premium, color: Color(0xFFFFC107), size: 36),
        CircleAvatar(
          radius: isFirst ? 36 : 28,
          backgroundColor: AppColors.ivorySand,
          child: Icon(Icons.person, color: AppColors.mossForest, size: isFirst ? 36 : 28),
        ),
        const SizedBox(height: 8),
        Text(
          shortName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateCharcoal),
        ),
        Text(
          '${user.treeCount} شجرة',
          style: TextStyle(
            color: isFirst ? AppColors.mossForest : AppColors.oliveGrey,
            fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
            fontSize: isFirst ? 14 : 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: isFirst ? AppColors.mossForest : AppColors.mossForest.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث عن متطوع...', // Add localization later if needed
            hintStyle: const TextStyle(color: AppColors.oliveGrey),
            prefixIcon: const Icon(Icons.search, color: AppColors.mossForest),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: _filterSearch,
        ),
      ),
    );
  }

  Widget _buildIndividualsList() {
    if (_filteredIndividuals.length <= 3) {
      return Center(
        child: Text(
          _filteredIndividuals.isEmpty ? 'لا يوجد متطوعون بعد.' : 'جميع المتصدرين في المراكز الأولى',
          style: const TextStyle(color: AppColors.oliveGrey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _filteredIndividuals.length - 3,
      itemBuilder: (context, index) {
        final rank = index + 4;
        final user = _filteredIndividuals[index + 3];
        final isCurrentUser = user.id == _currentUserId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (isCurrentUser)
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(left: 8), // Left margin for RTL thick border effect
                    decoration: BoxDecoration(
                      color: AppColors.mossForest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.ivorySand,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.slateCharcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.oliveGrey,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateCharcoal,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getProvinceName(user.provinceId),
                        style: const TextStyle(
                          color: AppColors.oliveGrey,
                          fontSize: 12,
                        ),
                      ),
                     ],
                  ),
                ),
                Text(
                  '${user.treeCount} شجرة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mossForest,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProvincesList() {
    if (_provincesRankings.isEmpty) {
      return const Center(child: Text('لا توجد بيانات.', style: TextStyle(color: AppColors.oliveGrey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _provincesRankings.length,
      itemBuilder: (context, index) {
        final rank = index + 1;
        final data = _provincesRankings[index];
        final provName = _getProvinceName(data['province_id'] as int?);
        final treeCount = data['total_trees'] ?? 0;
        final voln = data['volunteers'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? AppColors.mossForest.withValues(alpha: 0.1) : AppColors.ivorySand,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? AppColors.mossForest : AppColors.slateCharcoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateCharcoal,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$voln متطوع نشط',
                        style: const TextStyle(
                          color: AppColors.oliveGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$treeCount شجرة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mossForest,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
