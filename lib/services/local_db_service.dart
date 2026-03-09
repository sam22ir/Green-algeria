import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'green_algeria_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
    debugPrint('Created offline_queue table');
  }

  /// Insert a planting record into the offline queue
  Future<void> enqueuePlanting(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert(
      'offline_queue', 
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Enqueued offline planting record: ${record['id']}');
  }

  /// Get pending records
  Future<List<Map<String, dynamic>>> getPendingPlantings() async {
    final db = await database;
    return await db.query(
      'offline_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  /// Update the status of a specific record
  Future<void> updateRecordStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'offline_queue',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Updated offline record $id to status: $status');
  }

  /// Remove a successfully synced record
  Future<void> removeSyncedRecord(String id) async {
    final db = await database;
    await db.delete(
      'offline_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Removed synced offline record $id');
  }
}
