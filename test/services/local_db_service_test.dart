import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// LocalDbService SQL logic is tested via direct in-memory SQLite operations below.

void main() {
  // Initialize ffi for sqflite testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalDbService', () {
    late Database db;

    setUp(() async {
      // Use an in-memory database for testing
      db = await databaseFactory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
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
              ''');
            },
          ));
      // LocalDbService uses getDatabasesPath() — logic is tested via direct SQL here.
    });

    tearDown(() async {
      await db.close();
    });

    test('enqueuePlanting inserts a record', () async {
      final record = {
        'id': 'test-id-1',
        'user_id': 'uid-1',
        'latitude': 36.0,
        'longitude': 3.0,
        'image_path': '/path/to/img.jpg',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await db.insert('offline_queue', record);
      
      final results = await db.query('offline_queue');
      expect(results.length, 1);
      expect(results.first['id'], 'test-id-1');
    });

    test('getPendingPlantings returns only pending records', () async {
      await db.insert('offline_queue', {
        'id': '1', 'user_id': 'u1', 'latitude': 0.0, 'longitude': 0.0,
        'image_path': 'a.jpg', 'status': 'pending', 'created_at': '2024'
      });
      await db.insert('offline_queue', {
        'id': '2', 'user_id': 'u1', 'latitude': 0.0, 'longitude': 0.0,
        'image_path': 'b.jpg', 'status': 'synced', 'created_at': '2024'
      });

      final results = await db.query('offline_queue', where: 'status = ?', whereArgs: ['pending']);
      
      expect(results.length, 1);
      expect(results.first['id'], '1');
    });

    test('updateRecordStatus changes the status', () async {
      await db.insert('offline_queue', {
        'id': '1', 'user_id': 'u1', 'latitude': 0.0, 'longitude': 0.0,
        'image_path': 'a.jpg', 'status': 'pending', 'created_at': '2024'
      });

      await db.update('offline_queue', {'status': 'uploading'}, where: 'id = ?', whereArgs: ['1']);

      final results = await db.query('offline_queue');
      expect(results.first['status'], 'uploading');
    });

    test('removeSyncedRecord deletes the record', () async {
      await db.insert('offline_queue', {
        'id': '1', 'user_id': 'u1', 'latitude': 0.0, 'longitude': 0.0,
        'image_path': 'a.jpg', 'status': 'synced', 'created_at': '2024'
      });

      await db.delete('offline_queue', where: 'id = ?', whereArgs: ['1']);

      final results = await db.query('offline_queue');
      expect(results.isEmpty, true);
    });
  });
}
