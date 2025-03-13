import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:odds_fetcher/models/filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:odds_fetcher/models/record.dart';

class DatabaseService {
  static Database? _db;
  static const String dbName = "odds_fetcher.db";
  static const String assetDbPath = "assets/odds_fetcher_template.db";

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDb();
    _db?.execute("PRAGMA foreign_keys = ON;");

    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    final dbDir = Directory(dbPath);
    if (!dbDir.existsSync()) {
      debugPrint("Creating database directory: $dbPath");
      await dbDir.create(recursive: true);
    }

    final dbExists = await databaseExists(path);

    if (!dbExists) {
      debugPrint("Database does not exist, copying from assets...");
      try {
        ByteData data = await rootBundle.load(assetDbPath);
        List<int> bytes = data.buffer.asUint8List();

        await File(path).writeAsBytes(bytes, flush: true);
        debugPrint("Database copied successfully.");
      } catch (e) {
        debugPrint("Error copying database: $e");
      }
    } else {
      debugPrint("Database already exists.");
    }

    return await openDatabase(path, version: 1);
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

  static Future<List<Record>> fetchFutureRecords({Filter? filter}) async {
    final db = await database;
    late String whereClause;

    if (filter == null) {
      whereClause = "WHERE 1 = 1";
    } else {
      whereClause = filter.whereClauseFuture();
    }

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
    $whereClause
    ;
    """);

    return result.map((row) => Record.fromMap(row)).toList();
  }

  static Future<List<Record>> fetchRecords({
    Filter? filter,
    double? early1,
    double? earlyX,
    double? early2,
    double? final1,
    double? finalX,
    double? final2,
  }) async {
    final db = await database;
    late String whereClause;

    if (filter == null) {
      whereClause = "WHERE 1 = 1";
    } else {
      whereClause = filter.whereClause(
        early1: early1,
        earlyX: earlyX,
        early2: early2,
        final1: final1,
        finalX: finalX,
        final2: final2,
      );
    }

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
    $whereClause
    ;
    """);

    return result.map((row) => Record.fromMap(row)).toList();
  }

  static Future<DateTime> loadMaxMatchDate() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery("""
    SELECT
      MAX(
        MatchDateYear ||
        printf('%02d', MatchDateMonth) ||
        printf('%02d', MatchDateDay)
      ) AS MatchDate,
      MatchDateYear || '-' ||
      printf('%02d', MatchDateMonth) || '-' ||
      printf('%02d', MatchDateDay) As MatchDateStr
    FROM Records
    LIMIT 1;
    """);

    if (result.isEmpty || result.first["MatchDateStr"] == null) {
      return DateTime.parse("2008-01-01");
    }

    return DateTime.parse(result.first["MatchDateStr"]);
  }

  static Future<void> insertRecord(Record record) async {
    await _db?.insert(
      "Records",
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> insertRecordsBatch(List<Record> records) async {
    if (_db == null || records.isEmpty) return;

    Batch batch = _db!.batch();

    for (Record record in records) {
      batch.insert(
        "Records",
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
    String? leagueName,
  ) async {
    final db = await database;

    String whereClause = "leagueCode = ?";
    List<String> whereArgs = [leagueCode];

    if (leagueName != null) {
      whereClause += " AND leagueName = ?";
      whereArgs.add(leagueName);
    }

    final result = await db.query(
      "Leagues",
      where: whereClause,
      whereArgs: whereArgs,
    );

    if (result.isNotEmpty) {
      return result.first["id"] as int;
    }

    leagueName ??= leagueCode;

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

  static Future<int>? deleteOldFutureRecords() {
    return _db?.delete("Records", where: "finished = ?", whereArgs: [0]);
  }
}
