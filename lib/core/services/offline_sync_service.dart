import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'local_database.dart';
import '../../services/supabase_service.dart';

class OfflineSyncService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool isSyncing = false;

  bool get isOnline => _isOnline;

  OfflineSyncService() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool wasOffline = !_isOnline;
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    notifyListeners();

    if (wasOffline && _isOnline) {
      syncOfflineQueue();
    }
  }

  /// Add an action to the local queue when offline
  Future<void> queueAction(String action, Map<String, dynamic> payload) async {
    final db = await LocalDatabase.instance.database;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Attempt sync if we might be online
    if (_isOnline) {
      syncOfflineQueue();
    }
  }

  /// Process the offline queue when online
  Future<void> syncOfflineQueue() async {
    if (isSyncing || !_isOnline) return;

    try {
      isSyncing = true;
      notifyListeners();

      final db = await LocalDatabase.instance.database;
      final queue = await db.query('sync_queue', orderBy: 'id ASC');

      for (var item in queue) {
        final id = item['id'] as int;
        final action = item['action'] as String;
        final payload = jsonDecode(item['payload'] as String);

        bool success = await _executeNetworkAction(action, payload);
        
        if (success) {
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
        } else {
          // Stop syncing if an action fails (to maintain order and handle errors)
          break;
        }
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  /// Map queued actions to real network requests
  Future<bool> _executeNetworkAction(String action, Map<String, dynamic> payload) async {
    try {
      switch (action) {
        case 'plant_tree':
          await SupabaseService.client.from('trees').insert(payload);
          return true;
        case 'update_profile':
          await SupabaseService.client.from('profiles').upsert(payload);
          return true;
        // add more actions here
        default:
          debugPrint('Unknown sync action: $action');
          return true; // Return true to remove unknown actions from queue
      }
    } catch (e) {
      debugPrint('Error executing network action $action: $e');
      return false; // Retry later
    }
  }
}
