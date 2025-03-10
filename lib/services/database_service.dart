import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:odds_fetcher/models/record.dart';

class DatabaseService {
  static Database? _db;
  static const String dbName = "odds_fetcher.db";

  // Singleton pattern to make sure only one database instance exists
  static Future<Database> get database async {
    if (_db != null) return _db!;

    // Initialize the database if it hasn't been initialized
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    // Get the path to the database in the device's file system
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    // Open or create the database
    return await openDatabase(
      path,
      version: 1, // Adjust version if necessary
      onCreate: (db, version) async {
        return db.execute(
          """CREATE TABLE records(
               id INTEGER PRIMARY KEY,
               bettingHouse INTEGER,
               matchDate TEXT,
               league TEXT,
               leagueName TEXT,
               homeTeam TEXT,
               awayTeam TEXT,
               earlyOdds1 TEXT,
               earlyOddsX TEXT,
               earlyOdds2 TEXT,
               finalOdds1 TEXT,
               finalOddsX TEXT,
               finalOdds2 TEXT,
               homeFirstHalfScore INTEGER,
               homeSecondHalfScore INTEGER,
               awayFirstHalfScore INTEGER,
               awaySecondHalfScore INTEGER
             )""",
        );
      },
    );
  }

  // Fetch records from the DB
  static Future<List<Record>> fetchRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('records');

    return List.generate(maps.length, (i) {
      return Record.fromJson(maps[i]);
    });
  }

  static Future<void> insertRecord(Record record) async {
    await _db?.insert(
      "records",
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
