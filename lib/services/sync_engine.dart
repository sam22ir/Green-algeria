import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';

class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  final LocalDbService _localDb = LocalDbService();
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        debugPrint('SyncEngine: Connection restored. Starting sync...');
        syncPendingRecords();
      }
    });
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
        final imagePath = record['image_path'];
        final file = File(imagePath);

        if (!await file.exists()) {
          debugPrint('SyncEngine: File not found for record $id. Marking as failed.');
          await _localDb.updateRecordStatus(id, 'failed_file_missing');
          continue;
        }

        try {
          // 1. Upload photo to Supabase Storage
          final fileExt = imagePath.split('.').last;
          final fileName = 'offline_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final storagePath = '${record['user_id']}/$fileName';

          try {
            await Supabase.instance.client.storage
              .from('tree-photos')
              .upload(storagePath, file);
          } catch (e) {
             debugPrint('SyncEngine: Failed to upload image for record $id: $e');
             continue; // Leave as pending, break this record's sync
          }

          final imageUrl = Supabase.instance.client.storage
              .from('tree-photos')
              .getPublicUrl(storagePath);

          // 2. Insert into tree_plantings table
          final insertData = {
            'user_id': record['user_id'],
            'latitude': record['latitude'],
            'longitude': record['longitude'],
            'species_id': record['species_id'], // Might be null
            'campaign_id': record['campaign_id'], // Might be null
            'image_url': imageUrl,
            // Keep original offline creation time if desired, or use DB default
          };

          await Supabase.instance.client.from('tree_plantings').insert(insertData);

          // 3. Delete local record and file
          await _localDb.removeSyncedRecord(id);
          try {
            await file.delete();
          } catch (e) {
             debugPrint('SyncEngine: Could not delete local cached photo: $e');
          }
          
          debugPrint('SyncEngine: Successfully synced record $id');

        } catch (e) {
          debugPrint('SyncEngine: Error syncing record $id: $e');
          // Update status if it's a non-recoverable error, otherwise leave pending
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
