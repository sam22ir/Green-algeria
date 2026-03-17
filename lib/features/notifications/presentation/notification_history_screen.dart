import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _nationalNotifs = [];
  List<Map<String, dynamic>> _provincialNotifs = [];
  bool _isLoading = true;
  int? _userProvinceId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // جلب الولاية الخاصة بالمستخدم
      try {
        final profile = await _client
            .from('users')
            .select('province_id')
            .eq('id', userId)
            .maybeSingle();
        _userProvinceId = profile?['province_id'] as int?;
      } catch (_) {}

      // الإشعارات الوطنية (province_id = null)
      final globalNotifs = await _client
          .from('notifications')
          .select('id, title, body, type, province_id, sent_at, is_active')
          .eq('is_active', true)
          .order('sent_at', ascending: false)
          .limit(50)
          .catchError((_) => <Map<String, dynamic>>[]);

      // الإشعارات الشخصية للمستخدم
      final userNotifs = await _client
          .from('user_notifications')
          .select('id, title, body, type, created_at, is_read, campaign_id, campaigns(title), province_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50)
          .catchError((_) => <Map<String, dynamic>>[]);

      final national = <Map<String, dynamic>>[];
      final provincial = <Map<String, dynamic>>[];

      for (final n in List<Map<String, dynamic>>.from(globalNotifs)) {
        final item = {
          'id': n['id'],
          'title': n['title'] ?? '',
          'body': n['body'] ?? '',
          'type': n['type'] ?? 'national',
          'date': n['sent_at'],
          'is_read': true,
          'source': 'global',
          'province_id': n['province_id'],
        };
        if (n['province_id'] == null) {
          national.add(item);
        } else {
          provincial.add(item);
        }
      }

      for (final n in List<Map<String, dynamic>>.from(userNotifs)) {
        final item = {
          'id': n['id'],
          'title': n['title'] ?? '',
          'body': n['body'] ?? '',
          'type': n['type'] ?? 'personal',
          'date': n['created_at'],
          'is_read': n['is_read'] ?? false,
          'campaign_title': (n['campaigns'] as Map<String, dynamic>?)?['title'],
          'source': 'user',
          'province_id': n['province_id'],
        };
        final pId = n['province_id'] as int?;
        if (pId == null) {
          national.add(item);
        } else {
          provincial.add(item);
        }
      }

      // ترتيب تنازلي بالتاريخ
      _sortByDate(national);
      _sortByDate(provincial);

      if (mounted) {
        setState(() {
          _nationalNotifs = national;
          _provincialNotifs = provincial;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortByDate(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });
  }

  Future<void> _markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      _loadNotifications();
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  int get _unreadCount {
    return [..._nationalNotifs, ..._provincialNotifs]
        .where((n) => n['is_read'] == false)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1F14) : const Color(0xFFFBFBF7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'notification_history'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'mark_all_read'.tr(),
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTabBar(colorScheme, isDark),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(_nationalNotifs, colorScheme, isDark, isNational: true),
                _buildTabContent(_provincialNotifs, colorScheme, isDark, isNational: false),
              ],
            ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232B1A) : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('national_tab'.tr()),
                  if (_nationalNotifs.any((n) => n['is_read'] == false)) ...[
                    const SizedBox(width: 6),
                    _buildBadge(_nationalNotifs.where((n) => n['is_read'] == false).length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_city_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('provincial_tab'.tr()),
                  if (_provincialNotifs.any((n) => n['is_read'] == false)) ...[
                    const SizedBox(width: 6),
                    _buildBadge(_provincialNotifs.where((n) => n['is_read'] == false).length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildTabContent(List<Map<String, dynamic>> items, ColorScheme colorScheme, bool isDark,
      {required bool isNational}) {
    if (items.isEmpty) {
      return _buildEmpty(
        colorScheme,
        isDark,
        isNational ? 'no_national_notifications'.tr() : 'no_provincial_notifications'.tr(),
        isNational ? Icons.flag_outlined : Icons.location_city_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: colorScheme.primary,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _buildNotificationCard(items[i], isDark, colorScheme),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark, ColorScheme cs) {
    final isUnread = notif['is_read'] == false;
    final type = notif['type'] as String? ?? 'national';
    final dateStr = notif['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final bgColor = isUnread
        ? (isDark ? const Color(0xFF2A3320) : const Color(0xFFE7EADF))
        : (isDark ? const Color(0xFF232B1A) : Colors.white);
    final iconColor = _colorForType(type, isDark);
    final icon = _iconForType(type);

    return GestureDetector(
      onTap: () => _showDetail(notif),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          border: isUnread ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 1) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                            color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] ?? '',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (date != null)
                    Text(
                      _relativeTime(date),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return DateFormat('d MMM yyyy', 'ar').format(date);
  }

  void _showDetail(Map<String, dynamic> notif) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final type = notif['type'] as String? ?? 'national';
    final iconColor = _colorForType(type, isDark);
    final icon = _iconForType(type);
    final dateStr = notif['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    if (notif['source'] == 'user' && notif['is_read'] == false) {
      _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notif['id'])
          .then((_) => _loadNotifications())
          .catchError((_) {});
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232B1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16,
                          color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D),
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d MMMM yyyy، HH:mm', 'ar').format(date),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notif['body'] ?? '',
              style: TextStyle(
                fontSize: 15, height: 1.6,
                color: isDark ? const Color(0xFFF0EDE4) : const Color(0xFF2D2D2D),
              ),
            ),
            if (notif['campaign_title'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: iconColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notif['campaign_title'],
                        style: TextStyle(color: iconColor, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, bool isDark, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72,
              color: (isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C)).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? const Color(0xFFA8A898) : const Color(0xFF6B705C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'national': return Icons.flag_rounded;
      case 'provincial': return Icons.location_city_rounded;
      case 'campaign': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type, bool isDark) {
    switch (type) {
      case 'national': return Colors.orange;
      case 'provincial': return Colors.blue;
      case 'campaign': return isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);
      default: return isDark ? const Color(0xFF7A9E45) : const Color(0xFF606C38);
    }
  }
}
