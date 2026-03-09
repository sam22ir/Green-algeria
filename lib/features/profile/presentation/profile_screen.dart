import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_model.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _currentUser;
  int _nationalRank = 0;
  List<Map<String, dynamic>> _plantingHistory = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().firebaseUser;
      if (user != null) {
        // Fetch user basic data
        _currentUser = await SupabaseService().getUserRecord(user.uid);
        
        // Fetch rank from leaderboard cache
        final leaderboardData = await SupabaseService.client
            .from('leaderboard_cache')
            .select('rank_national')
            .eq('user_id', user.uid)
            .maybeSingle();
            
        if (leaderboardData != null) {
          _nationalRank = leaderboardData['rank_national'] ?? 0;
        }

        // Fetch planting history (last 10)
        final historyRes = await SupabaseService.client
            .from('tree_plantings')
            .select('''
              id,
              planted_at,
              campaigns (title)
            ''')
            .eq('user_id', user.uid)
            .order('planted_at', ascending: false)
            .limit(10);
            
        _plantingHistory = List<Map<String, dynamic>>.from(historyRes);
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.linenWhite,
        body: Center(child: CircularProgressIndicator(color: AppColors.mossForest)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.linenWhite,
      appBar: AppBar(
        backgroundColor: AppColors.linenWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.slateCharcoal,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.settings, color: AppColors.slateCharcoal),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          color: AppColors.mossForest,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 32),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.mossForest, width: 3),
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: AppColors.ivorySand,
            backgroundImage: _currentUser?.avatarUrl != null 
                ? NetworkImage(_currentUser!.avatarUrl!) 
                : null,
            child: _currentUser?.avatarUrl == null 
                ? const Icon(Icons.person, size: 64, color: AppColors.oliveGrey)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser?.fullName ?? 'مستخدم',
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
            color: AppColors.oliveGrove,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getRoleDisplayName(_currentUser?.role),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'developer': return 'مطور';
      case 'initiative_owner': return 'صاحب المبادرة';
      case 'provincial_organizer': return 'منظم ولائي';
      case 'local_organizer': return 'منظم محلي';
      default: return 'متطوع';
    }
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildStatCard(_currentUser?.treeCount.toString() ?? '0', 'الأشجار المغروسة', Icons.park_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(_nationalRank > 0 ? '#$_nationalRank' : '-', 'الرتبة', Icons.emoji_events_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(_currentUser?.campaignCount.toString() ?? '0', 'الحملات', Icons.nature_people_outlined)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: AppColors.ivorySand,
      child: Column(
        children: [
          Icon(icon, color: AppColors.mossForest, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.slateCharcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.oliveGrey,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل التشجير',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.mossForest,
          ),
        ),
        const SizedBox(height: 16),
        if (_plantingHistory.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'لم يتم توثيق أي أشجار بعد. ابدأ الغرس الآن!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.oliveGrey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _plantingHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _plantingHistory[index];
              final dateStr = item['planted_at'] as String;
              final date = DateTime.parse(dateStr);
              final campaigns = item['campaigns'];
              final title = (campaigns != null && campaigns is Map && campaigns['title'] != null) 
                  ? campaigns['title'] 
                  : 'غرس فردي';
                  
              return CustomCard(
                color: AppColors.ivorySand,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mossForest.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.energy_savings_leaf, color: AppColors.mossForest, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.slateCharcoal,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMMM yyyy', 'ar').format(date),
                            style: const TextStyle(
                              color: AppColors.oliveGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
