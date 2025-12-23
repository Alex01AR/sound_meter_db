import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sound_meter_v2.db'); // New version
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Session Summary Table
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER,
        avg_db REAL,
        max_db REAL,
        duration INTEGER,
        label TEXT
      )
    ''');

    // Raw Data Points Table
    await db.execute('''
      CREATE TABLE measurements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        timestamp INTEGER,
        decibel REAL,
        FOREIGN KEY(session_id) REFERENCES history(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertSession(Map<String, dynamic> session, List<double> points) async {
    Database db = await database;
    
    // Insert Summary
    int sessionId = await db.insert('history', session);

    // Bulk Insert Points (Batch for performance)
    Batch batch = db.batch();
    for (int i = 0; i < points.length; i++) {
      // Store every 5th point to save space, or all if short duration
      // For now, let's store all points but be mindful of size
      batch.insert('measurements', {
        'session_id': sessionId,
        'timestamp': session['timestamp'] + (i * 100), // Approx 100ms interval
        'decibel': points[i]
      });
    }
    await batch.commit(noResult: true);
    
    return sessionId;
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    Database db = await database;
    return await db.query('history', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getSessionPoints(int sessionId) async {
    Database db = await database;
    return await db.query(
      'measurements',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
  }

  Future<int> deleteSession(int id) async {
    Database db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    Database db = await database;
    await db.delete('history'); // Cascade should delete measurements
  }
}
