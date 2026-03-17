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

  Future<List<Map<String, dynamic>>> getPendingUpgradeRequests() async {
    try {
      // v3.4.1 Fix: Fetch upgrade_requests without relying on join with users.
      // The join can fail due to RLS policies. We enrich user data separately.
      final data = await client
          .from('upgrade_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      final requests = List<Map<String, dynamic>>.from(data);

      // Enrich each request with user data via a separate query
      final enriched = <Map<String, dynamic>>[];
      for (final req in requests) {
        final userId = req['user_id']?.toString();
        Map<String, dynamic> userData = {};
        if (userId != null) {
          try {
            final userRow = await client
                .from('users')
                .select('full_name, email, role')
                .eq('id', userId)
                .maybeSingle();
            userData = userRow ?? {};
          } catch (_) {}
        }
        enriched.add({...req, 'users': userData});
      }
      return enriched;
    } catch (e) {
      debugPrint('Error fetching pending upgrade requests: $e');
      return [];
    }
  }

  Future<void> updateUpgradeRequestStatus({
    required int requestId,     // FIX: upgrade_requests.id is INTEGER serial
    required String userId,
    required String status,
    required String reviewerId,
    String? newRole,
  }) async {
    try {
      // 1. Update request status
      await client.from('upgrade_requests').update({
        'status': status,
        'reviewed_by': reviewerId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      // 2. If approved, update user role
      if (status == 'approved' && newRole != null) {
        await client.from('users').update({'role': newRole}).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error updating upgrade request status: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await client.from('users').update(user.toJson()).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getUsers({String? query}) async {
    try {
      var dbQuery = client.from('users').select();
      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.or('full_name.ilike.%$query%,email.ilike.%$query%');
      }
      final data = await dbQuery.order('created_at', ascending: false);
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await client.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user role: $e');
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

  Future<List<CampaignModel>> getActiveCampaigns({String? type, int? provinceId}) async {
    try {
      var query = client
          .from('campaigns')
          .select('*, users!organizer_id(full_name)')
          .inFilter('status', ['active', 'upcoming']);
      if (type != null) {
        query = query.eq('type', type);
      }
      if (provinceId != null && (type == 'provincial' || type == 'local')) {
        query = query.eq('province_id', provinceId);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => CampaignModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching active campaigns: $e');
      // Fallback without join if RLS blocks it
      try {
        var fallback = client
            .from('campaigns')
            .select()
            .inFilter('status', ['active', 'upcoming']);
        if (type != null) fallback = fallback.eq('type', type);
        if (provinceId != null && (type == 'provincial' || type == 'local')) {
          fallback = fallback.eq('province_id', provinceId);
        }
        final data2 = await fallback.order('created_at', ascending: false);
        return (data2 as List).map((e) => CampaignModel.fromJson(e)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<CampaignModel>> getAllCampaigns() async {
    try {
      final data = await client.from('campaigns').select().order('created_at', ascending: false);
      return (data as List).map((e) => CampaignModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching all campaigns: $e');
      return [];
    }
  }

  Future<void> updateCampaignStatus(int id, String status) async {
    try {
      await client.from('campaigns').update({'status': status}).eq('id', id);
    } catch (e) {
      debugPrint('Error updating campaign status: $e');
      rethrow;
    }
  }

  Future<void> endCampaign({
    required int campaignId,  // FIX: int, not String
    required String adminId,
    required String reason,
  }) async {
    try {
      await client.from('campaigns').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
        'ended_by': adminId,
        'end_reason': reason,
      }).eq('id', campaignId);
    } catch (e) {
      debugPrint('Error ending campaign: $e');
      rethrow;
    }
  }

  Future<CampaignModel?> getUpcomingNationalCampaign() async {
    try {
      // v3.4.1 Fix: Return active campaigns first, then upcoming.
      // Prioritize 'active' so ongoing campaigns show with end countdown.
      final data = await client
          .from('campaigns')
          .select()
          .eq('type', 'national')
          .inFilter('status', ['active', 'upcoming'])
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

  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      final data = await client.from('provinces').select().order('code', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
      return [];
    }
  }

  // --- Tree Plantings ---
  Future<List<TreePlantingModel>> getTreePlantings() async {
    try {
      final data = await client
          .from('tree_plantings')
          .select()
          .order('planted_at', ascending: false);
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

  /// أعلى N متطوعين في ولاية معينة (Province Detail)
  Future<List<UserModel>> getProvinceTopUsers(int provinceId, {int limit = 10}) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('province_id', provinceId)
          .order('tree_count', ascending: false)
          .limit(limit);
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching province top users: $e');
      return [];
    }
  }

  /// جميع أشجار مستخدم معين مع تفاصيل الفصيلة (Public Profile - Trees tab)
  Future<List<Map<String, dynamic>>> getUserTreePlantings(String userId) async {
    try {
      final data = await client
          .from('tree_plantings')
          .select('*, tree_species(name_ar, name_en, image_asset_path)')
          .eq('user_id', userId)
          .order('planted_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching user tree plantings: $e');
      return [];
    }
  }

  /// الحملات التي شارك فيها المستخدم + عدد أشجاره في كل حملة (Public Profile - Campaigns tab)
  Future<List<Map<String, dynamic>>> getUserCampaignParticipation(String userId) async {
    try {
      // نجلب الأشجار التي لها campaign_id
      final data = await client
          .from('tree_plantings')
          .select('campaign_id, campaigns(id, title, type, status)')
          .eq('user_id', userId)
          .not('campaign_id', 'is', null);

      // نجمع محلياً: campaign_id → { campaign info, count }
      final Map<String, Map<String, dynamic>> agg = {};
      for (final row in (data as List)) {
        final campId = row['campaign_id']?.toString();
        if (campId == null) continue;
        final camp = row['campaigns'];
        if (camp == null) continue;
        if (!agg.containsKey(campId)) {
          agg[campId] = {
            'campaign_id': campId,
            'title': camp['title'] ?? '',
            'type': camp['type'] ?? 'local',
            'status': camp['status'] ?? 'active',
            'tree_count': 0,
          };
        }
        agg[campId]!['tree_count'] = (agg[campId]!['tree_count'] as int) + 1;
      }
      final result = agg.values.toList();
      result.sort((a, b) => (b['tree_count'] as int).compareTo(a['tree_count'] as int));
      return result;
    } catch (e) {
      debugPrint('Error fetching user campaign participation: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> getProvincialLeaderboard() async {
    try {
      final data = await client.from('leaderboard_cache').select().order('total_trees', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching leaderboard_cache, falling back to local aggregation: $e');
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
        .stream(primaryKey: ['province_id'])
        .eq('province_id', provinceId);
  }

  Future<void> logNotification({
    required String title,
    required String body,
    required String type,
    int? provinceId,
    required String sentBy,
  }) async {
    try {
      await client.from('notifications').insert({
        'title': title,
        'body': body,
        'type': type,
        'province_id': provinceId,
        'sent_by': sentBy,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging notification: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSentNotifications() async {
    return getNotificationHistory();
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final data = await client
          .from('notifications')
          .select('*, provinces(name_ar)')
          .order('sent_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching notification history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBugReports() async {
    try {
      final data = await client
          .from('bug_reports')
          .select('*, users(full_name, email)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching bug reports: $e');
      return [];
    }
  }

  Future<void> resolveBugReport(int id, String reviewerId) async {
    try {
      await client.from('bug_reports').update({
        'status': 'resolved',
      }).eq('id', id);
    } catch (e) {
      debugPrint('Error resolving bug report: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSupportMessages() async {
    try {
      final data = await client
          .from('support_messages')
          .select('*, users(full_name, email), support_replies(*)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching support messages: $e');
      return [];
    }
  }

  Future<void> sendSupportReply({
    required dynamic messageId,
    required String replyText,
    required String repliedBy,
  }) async {
    try {
      await client.from('support_replies').insert({
        'message_id': messageId,
        'reply_text': replyText,
        'replied_by': repliedBy,
      });

      // Update message status to replied
      await client.from('support_messages').update({'is_replied': true}).eq('id', messageId);
    } catch (e) {
      debugPrint('Error sending support reply: $e');
      rethrow;
    }
  }

  Future<void> updateUserAvatarAsset(String userId, String assetPath) async {
    try {
      await client.from('users').update({'avatar_asset': assetPath}).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user avatar asset: $e');
      rethrow;
    }
  }

  // --- Push Notifications (Edge Function) ---
  Future<void> sendPushNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await client.functions.invoke(
        'send-fcm',
        body: {
          'topic': topic,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
    } catch (e) {
      debugPrint('Error calling send-fcm edge function: $e');
      // We don't rethrow here to prevent crashing the UI for notification failures
    }
  }
}
