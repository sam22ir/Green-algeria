import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/campaign_model.dart';
import '../models/tree_planting_model.dart';

class SupabaseService {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // --- Users & Roles ---
  Future<void> createUserRecord(UserModel user) async {
    try {
      await client.from('users').upsert(user.toJson());
    } catch (e) {
      debugPrint('Error creating/updating user in Supabase: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserRecord(String uid) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user from Supabase: $e');
      return null;
    }
  }

  Future<UserModel?> getUserProfile() async {
    final authUser = client.auth.currentUser;
    if (authUser == null) return null;
    return getUserRecord(authUser.id);
  }

  Future<void> requestUpgrade(String uid, String requestedRole, String reason) async {
    try {
      await client.from('upgrade_requests').insert({
        'user_id': uid,
        'requested_role': requestedRole,
        'reason': reason,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error requesting upgrade: $e');
      rethrow;
    }
  }

  // --- Campaigns ---
  Future<void> createCampaign(CampaignModel campaign) async {
    try {
      await client.from('campaigns').insert(campaign.toJson());
    } catch (e) {
      debugPrint('Error creating campaign: $e');
      rethrow;
    }
  }

  Future<List<CampaignModel>> getActiveCampaigns({String? type}) async {
    try {
      var query = client.from('campaigns').select().eq('status', 'active');
      if (type != null) {
        query = query.eq('type', type);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => CampaignModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching active campaigns: $e');
      return [];
    }
  }

  Future<CampaignModel?> getUpcomingNationalCampaign() async {
    try {
      final data = await client
          .from('campaigns')
          .select()
          .eq('type', 'national')
          .eq('status', 'upcoming')
          .order('start_date', ascending: true)
          .limit(1)
          .maybeSingle();
      if (data != null) {
        return CampaignModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching upcoming national campaign: $e');
      return null;
    }
  }

  Future<List<CampaignModel>> getPastCampaigns() async {
    try {
      final data = await client
          .from('campaigns')
          .select()
          .eq('status', 'completed')
          .order('end_date', ascending: false);
      return (data as List).map((e) => CampaignModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching past campaigns: $e');
      return [];
    }
  }

  // --- Tree Plantings ---
  Future<List<TreePlantingModel>> getTreePlantings() async {
    try {
      final data = await client
          .from('tree_plantings')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => TreePlantingModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching tree plantings: $e');
      return [];
    }
  }

  Future<void> logTreePlanting(TreePlantingModel planting) async {
    try {
      await client.from('tree_plantings').insert(planting.toJson());
    } catch (e) {
      debugPrint('Error logging tree planting: $e');
      rethrow;
    }
  }

  Future<int> getTotalTreesPlanted() async {
    try {
      final response = await client
          .from('tree_plantings')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error getting total trees planted: $e');
      return 0;
    }
  }

  // --- Leaderboard ---
  Future<List<UserModel>> getTopIndividuals({int limit = 100}) async {
    try {
      final data = await client
          .from('users')
          .select()
          .order('tree_count', ascending: false)
          .limit(limit);
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching top individuals: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProvincialLeaderboard() async {
    try {
      // Try calling RPC if it exists
      final data = await client.rpc('get_provincial_leaderboard');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('RPC get_provincial_leaderboard failed, falling back to local aggregation: $e');
      try {
        // Fallback: fetch all active users and aggregate locally
        final usersData = await client
            .from('users')
            .select('province_id, tree_count')
            .gt('tree_count', 0);
            
        final Map<int, Map<String, dynamic>> agg = {};
        for (var row in (usersData as List)) {
          final pId = row['province_id'] as int?;
          final count = row['tree_count'] as int? ?? 0;
          if (pId == null) continue;
          
          if (!agg.containsKey(pId)) {
            agg[pId] = {'province_id': pId, 'total_trees': 0, 'volunteers': 0};
          }
          agg[pId]!['total_trees'] = (agg[pId]!['total_trees'] as int) + count;
          agg[pId]!['volunteers'] = (agg[pId]!['volunteers'] as int) + 1;
        }
        
        final list = agg.values.toList();
        list.sort((a, b) => (b['total_trees'] as int).compareTo(a['total_trees'] as int));
        return list;
      } catch (innerError) {
        debugPrint('Error aggregating provincial leaderboard: $innerError');
        return [];
      }
    }
  }

  // --- Realtime Subscriptions ---
  SupabaseStreamBuilder listenToLeaderboard(int provinceId) {
    return client
        .from('leaderboard_cache')
        .stream(primaryKey: ['id'])
        .eq('province_id', provinceId);
  }

  SupabaseStreamBuilder listenToCampaigns() {
    return client
        .from('campaigns')
        .stream(primaryKey: ['id']);
  }
}
