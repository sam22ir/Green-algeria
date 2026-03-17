import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../widgets/custom_card.dart';
import '../../../../services/supabase_service.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardStatsSection extends StatefulWidget {
  const DashboardStatsSection({super.key});

  @override
  State<DashboardStatsSection> createState() => _DashboardStatsSectionState();
}

class _DashboardStatsSectionState extends State<DashboardStatsSection> {
  Map<String, int> _stats = {
    'trees': 0,
    'users': 0,
    'active_campaigns': 0,
    'active_provinces': 0,
    'pending_upgrades': 0,
    'open_reports': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final client = SupabaseService.client;
      
      final results = await Future.wait<dynamic>([
        // 0. Total Trees from leaderboard_cache
        client.from('leaderboard_cache').select('total_trees'),
        // 1. Total Users
        client.from('users').select('id').count(CountOption.exact),
        // 2. Active Campaigns
        client.from('campaigns').select('id').eq('status', 'active').count(CountOption.exact),
        // 3. Active Provinces (count provinces with trees > 0)
        client.from('leaderboard_cache').select('province_id').gt('total_trees', 0).count(CountOption.exact),
        // 4. Pending Upgrades
        client.from('upgrade_requests').select('id').eq('status', 'pending').count(CountOption.exact),
        // 5. Open Reports
        client.from('bug_reports').select('id').eq('status', 'pending').count(CountOption.exact),
      ]);

      // Calculate total trees sum
      final List<dynamic> treeList = results[0] as List<dynamic>? ?? [];
      final totalTrees = treeList.fold<int>(0, (sum, item) => sum + (item['total_trees'] as int? ?? 0));

      if (mounted) {
        setState(() {
          _stats = {
            'trees': totalTrees,
            'users': results[1].count ?? 0,
            'active_campaigns': results[2].count ?? 0,
            'active_provinces': results[3].count ?? 0,
            'pending_upgrades': results[4].count ?? 0,
            'open_reports': results[5].count ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard('total_trees'.tr(), _stats['trees'].toString(), Icons.park, colorScheme.primary),
        _buildStatCard('total_users'.tr(), _stats['users'].toString(), Icons.people, Colors.blue),
        _buildStatCard('active_campaigns'.tr(), _stats['active_campaigns'].toString(), Icons.nature_people, Colors.orange),
        _buildStatCard('active_provinces'.tr(), _stats['active_provinces'].toString(), Icons.map, Colors.purple),
        _buildStatCard('pending_upgrades'.tr(), _stats['pending_upgrades'].toString(), Icons.upgrade, Colors.teal),
        _buildStatCard('open_reports'.tr(), _stats['open_reports'].toString(), Icons.bug_report, colorScheme.error),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
