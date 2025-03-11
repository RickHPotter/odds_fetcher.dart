import 'package:flutter/services.dart' show rootBundle;
import 'package:odds_fetcher/models/filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:odds_fetcher/models/record.dart';

class DatabaseService {
  static Database? _db;
  static const String dbName = "odds_fetcher.db";

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDb();
    _db?.execute("PRAGMA foreign_keys = ON;");

    return _db!;
  }

  static Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "odds_fetcher.db");
    await databaseFactory.deleteDatabase(path);
  }

  static Future<void> executeSchema(Database db, String version) async {
    final script = await rootBundle.loadString(
      "assets/migrations/$version.sql",
    );
    final statements = script.split(";");
    for (final statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await executeSchema(db, version.toString().padLeft(4, "0"));
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var v = oldVersion + 1; v <= newVersion; v++) {
          await executeSchema(db, v.toString().padLeft(4, "0"));
        }
      },
    );
  }

  static Future<List<Record>> fetchRecords({Filter? filter}) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery("""
    SELECT
      r.*,
      l.id AS leagueId,
      l.leagueCode,
      l.leagueName,
      ht.id AS homeTeamId,
      ht.teamName AS homeTeamName,
      at.id AS awayTeamId,
      at.teamName AS awayTeamName
    FROM Records r
    JOIN Leagues l ON r.leagueId = l.id
    JOIN Teams ht ON r.homeTeamId = ht.id
    JOIN Teams at ON r.awayTeamId = at.id
    LIMIT 1000
    """);

    return result.map((row) => Record.fromMap(row)).toList();
  }

  static Future<void> insertRecord(Record record) async {
    await _db?.insert(
      "records",
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> insertRecordsBatch(List<Record> records) async {
    if (_db == null || records.isEmpty) return;

    Batch batch = _db!.batch();

    for (Record record in records) {
      batch.insert(
        "records",
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    try {
      await batch.commit(noResult: true);
    } catch (e) {
      // ignore
    }
  }

  static Future<int> getOrCreateLeague(
    String leagueCode,
    String leagueName,
  ) async {
    final db = await database;

    final result = await db.query(
      "Leagues",
      where: "leagueCode = ? AND leagueName = ?",
      whereArgs: [leagueCode, leagueName],
    );

    if (result.isNotEmpty) {
      return result.first["id"] as int;
    }

    return await db.insert("Leagues", {
      "leagueCode": leagueCode,
      "leagueName": leagueName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int> getOrCreateTeam(String teamName) async {
    final db = await database;
    final result = await db.query(
      "Teams",
      where: "teamName = ?",
      whereArgs: [teamName],
    );

    if (result.isNotEmpty) {
      return result.first["id"] as int;
    }

    return await db.insert("Teams", {
      "teamName": teamName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
