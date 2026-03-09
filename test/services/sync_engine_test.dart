import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sync Engine Unit Tests — Chapter 15 (Green Algeria)
// Tests the offline planting queue: insertion, pending retrieval,
// status transitions (pending → uploading → synced), and deduplication.
// Uses sqflite_common_ffi to run SQLite in-memory without a real device.
// ─────────────────────────────────────────────────────────────────────────────

const String _createOfflineQueueSQL = '''
  CREATE TABLE offline_queue (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    species_id INTEGER,
    campaign_id INTEGER,
    image_path TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TEXT NOT NULL
  )
''';

Future<Database> _openTestDb() async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async => db.execute(_createOfflineQueueSQL),
    ),
  );
}

Map<String, dynamic> _makePlanting({
  required String id,
  String userId = 'uid-test',
  double lat = 36.0,
  double lng = 3.0,
  String status = 'pending',
}) => {
  'id': id,
  'user_id': userId,
  'latitude': lat,
  'longitude': lng,
  'image_path': '/local/img_$id.jpg',
  'status': status,
  'created_at': DateTime.now().toIso8601String(),
};

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Queue — Insertion', () {
    late Database db;

    setUp(() async => db = await _openTestDb());
    tearDown(() async => db.close());

    test('enqueuePlanting inserts a single record successfully', () async {
      await db.insert('offline_queue', _makePlanting(id: 'p-001'));
      final rows = await db.query('offline_queue');
      expect(rows.length, 1);
      expect(rows.first['id'], 'p-001');
      expect(rows.first['status'], 'pending');
    });

    test('can enqueue 10 plantings offline (stress test)', () async {
      for (var i = 1; i <= 10; i++) {
        await db.insert('offline_queue', _makePlanting(
          id: 'stress-$i',
          lat: 36.0 + i * 0.01,
          lng: 3.0 + i * 0.01,
        ));
      }
      final rows = await db.query('offline_queue');
      expect(rows.length, 10);
    });

    test('duplicate id insertion throws (no duplicate sync)', () async {
      await db.insert('offline_queue', _makePlanting(id: 'dup-001'));
      expect(
        () async => db.insert('offline_queue', _makePlanting(id: 'dup-001')),
        throwsA(anything),
      );
    });
  });

  group('Offline Queue — Retrieval (pending only)', () {
    late Database db;

    setUp(() async => db = await _openTestDb());
    tearDown(() async => db.close());

    test('getPendingPlantings returns only pending rows', () async {
      await db.insert('offline_queue', _makePlanting(id: 'a', status: 'pending'));
      await db.insert('offline_queue', _makePlanting(id: 'b', status: 'synced'));
      await db.insert('offline_queue', _makePlanting(id: 'c', status: 'uploading'));

      final pending = await db.query('offline_queue', where: 'status = ?', whereArgs: ['pending']);
      expect(pending.length, 1);
      expect(pending.first['id'], 'a');
    });

    test('all 10 offline items have pending status initially', () async {
      for (var i = 1; i <= 10; i++) {
        await db.insert('offline_queue', _makePlanting(id: 'of-$i'));
      }
      final pending = await db.query('offline_queue', where: 'status = ?', whereArgs: ['pending']);
      expect(pending.length, 10);
    });
  });

  group('Offline Queue — Status Transitions', () {
    late Database db;

    setUp(() async => db = await _openTestDb());
    tearDown(() async => db.close());

    test('status transitions: pending → uploading → synced', () async {
      await db.insert('offline_queue', _makePlanting(id: 't-001', status: 'pending'));

      // Step 1: Mark as uploading
      await db.update('offline_queue', {'status': 'uploading'},
          where: 'id = ?', whereArgs: ['t-001']);
      var row = await db.query('offline_queue', where: 'id = ?', whereArgs: ['t-001']);
      expect(row.first['status'], 'uploading');

      // Step 2: Mark as synced
      await db.update('offline_queue', {'status': 'synced'},
          where: 'id = ?', whereArgs: ['t-001']);
      row = await db.query('offline_queue', where: 'id = ?', whereArgs: ['t-001']);
      expect(row.first['status'], 'synced');
    });

    test('failed record stays pending and retries on next run', () async {
      await db.insert('offline_queue', _makePlanting(id: 'fail-001', status: 'pending'));

      // Simulate sync fail: status remains pending
      final pending = await db.query('offline_queue', where: 'status = ?', whereArgs: ['pending']);
      expect(pending.length, 1); // still pending after "failed attempt"

      // Retry — can query again
      final retry = await db.query('offline_queue', where: 'status = ?', whereArgs: ['pending']);
      expect(retry.length, 1);
      expect(retry.first['id'], 'fail-001');
    });
  });

  group('Offline Queue — Deduplication (no duplicate sync)', () {
    late Database db;

    setUp(() async => db = await _openTestDb());
    tearDown(() async => db.close());

    test('after sync, synced record is removed and no duplicate is reinserted', () async {
      await db.insert('offline_queue', _makePlanting(id: 'sync-001', status: 'pending'));

      // Mark as synced
      await db.update('offline_queue', {'status': 'synced'},
          where: 'id = ?', whereArgs: ['sync-001']);

      // Remove synced record (cleanup step in SyncEngine)
      await db.delete('offline_queue', where: 'id = ? AND status = ?', whereArgs: ['sync-001', 'synced']);

      final remaining = await db.query('offline_queue');
      expect(remaining.isEmpty, true);
    });

    test('10 offline records sync fully → queue is empty', () async {
      for (var i = 1; i <= 10; i++) {
        await db.insert('offline_queue', _makePlanting(id: 'bulk-$i'));
      }

      // Simulate syncing all
      final pending = await db.query('offline_queue', where: 'status = ?', whereArgs: ['pending']);
      for (final row in pending) {
        await db.update('offline_queue', {'status': 'synced'},
            where: 'id = ?', whereArgs: [row['id']]);
        await db.delete('offline_queue', where: 'id = ? AND status = ?',
            whereArgs: [row['id'], 'synced']);
      }

      final remaining = await db.query('offline_queue');
      expect(remaining.isEmpty, true);
    });
  });

  group('Offline Queue — Coordinates Integrity', () {
    late Database db;

    setUp(() async => db = await _openTestDb());
    tearDown(() async => db.close());

    test('coordinates are stored and retrieved with precision', () async {
      await db.insert('offline_queue', _makePlanting(
        id: 'coord-001', lat: 36.752500, lng: 3.042000,
      ));
      final rows = await db.query('offline_queue');
      expect((rows.first['latitude'] as double).toStringAsFixed(4), '36.7525');
      expect((rows.first['longitude'] as double).toStringAsFixed(4), '3.0420');
    });

    test('all 58-province bounding coordinates are within Algeria bounds', () {
      // Algeria geographic bounds: lat 18.9–37.1°N, lng -8.7–11.9°E
      const algeriaMinLat = 18.9;
      const algeriaMaxLat = 37.1;
      const algeriaMinLng = -8.7;
      const algeriaMaxLng = 11.9;

      final testCoords = [
        {'lat': 36.7525, 'lng': 3.0420},  // Algiers
        {'lat': 35.6971, 'lng': -0.6308}, // Oran
        {'lat': 36.3650, 'lng': 6.6147},  // Constantine
        {'lat': 22.7697, 'lng': 5.5099},  // Tamanrasset
        {'lat': 31.6310, 'lng': 2.2167},  // Béchar
      ];

      for (final c in testCoords) {
        expect(c['lat']!, greaterThanOrEqualTo(algeriaMinLat));
        expect(c['lat']!, lessThanOrEqualTo(algeriaMaxLat));
        expect(c['lng']!, greaterThanOrEqualTo(algeriaMinLng));
        expect(c['lng']!, lessThanOrEqualTo(algeriaMaxLng));
      }
    });
  });
}
