import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_db_service.dart';

class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  final LocalDbService _localDb = LocalDbService();

  bool _isSyncing = false;

  void initialize() {
    // Initial check and periodic check logic are handled by the service
    // We just listen to the service's state if it had a stream, 
    // but here we can just trigger sync attempts when we detect changes indirectly 
    // or rely on a timer for robustness.
    
    // As per v2.1 SyncEngine should fire when connectivity restores.
    // We'll hook into a simplified check for now or rely on the service init.
    _startSyncTimer();
  }

  void _startSyncTimer() {
    // Attempt sync every 5 minutes regardless, plus on init
    syncPendingRecords();
    Stream.periodic(const Duration(minutes: 5)).listen((_) => syncPendingRecords());
  }

  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      final pendingRecords = await _localDb.getPendingPlantings();
      
      if (pendingRecords.isEmpty) {
        debugPrint('SyncEngine: No pending records to sync.');
        return;
      }

      debugPrint('SyncEngine: Found ${pendingRecords.length} pending records.');

      for (final record in pendingRecords) {
        final id = record['id'];

        try {
          // FIX: Column names must match tree_plantings table exactly:
          // 'tree_species_id' (not 'species_id'), campaign_id must be int
          final insertData = <String, dynamic>{
            'user_id': record['user_id'],
            'latitude': record['latitude'],
            'longitude': record['longitude'],
            'planted_at': record['created_at'],
          };
          // Parse integer FKs from local SQLite string values
          final speciesRaw = record['species_id'];
          if (speciesRaw != null) {
            insertData['tree_species_id'] = speciesRaw is int ? speciesRaw : int.tryParse(speciesRaw.toString());
          }
          final campaignRaw = record['campaign_id'];
          if (campaignRaw != null) {
            insertData['campaign_id'] = campaignRaw is int ? campaignRaw : int.tryParse(campaignRaw.toString());
          }

          await Supabase.instance.client.from('tree_plantings').insert(insertData);

          // 2. Delete local record (no physical file to delete anymore)
          await _localDb.removeSyncedRecord(id);
          
          debugPrint('SyncEngine: Successfully synced record $id');

        } catch (e) {
          debugPrint('SyncEngine: Error syncing record $id: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
