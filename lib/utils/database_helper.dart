import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mood_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'love_diary.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL,
        mood INTEGER NOT NULL,
        note TEXT,
        imageUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isActive BOOLEAN DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE(habitId, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        coupleName TEXT,
        partnerName TEXT,
        relationshipStartDate TEXT,
        enableNotifications BOOLEAN DEFAULT 1,
        themeMode INTEGER DEFAULT 0
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'id': 1,
      'coupleName': 'My Love Diary',
      'partnerName': 'Partner',
      'relationshipStartDate': DateTime.now().toIso8601String().split('T')[0],
      'enableNotifications': 1,
      'themeMode': 0, // 0: system, 1: light, 2: dark
    });
  }

  // Mood Entries
  Future<int> insertMoodEntry(MoodEntry entry) async {
    final db = await database;
    return await db.insert(
      'mood_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MoodEntry>> getAllMoodEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_entries',
      orderBy: 'date DESC'
    );

    return List.generate(maps.length, (i) {
      return MoodEntry.fromMap(maps[i]);
    });
  }

  Future<MoodEntry?> getMoodEntryByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_entries',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return MoodEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteMoodEntry(int id) async {
    final db = await database;
    return await db.delete(
      'mood_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings
  Future<int> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    return await db.update(
      'settings',
      settings,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}