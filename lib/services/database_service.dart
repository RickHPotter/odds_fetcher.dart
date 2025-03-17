import "dart:io";

import "package:flutter/foundation.dart" show ByteData, debugPrint;
import "package:flutter/services.dart" show rootBundle;
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";
import "package:sqflite/sqflite.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:path/path.dart" show join;
//import "package:path_provider/path_provider.dart";
import "package:odds_fetcher/models/record.dart";

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
    }

    return await openDatabase(path, version: 1);
  }

  //static Future<Database> _initDb() async {
  //  final appSupportDir = await getApplicationSupportDirectory();
  //  final path = join(appSupportDir.path, dbName);
  //
  //  if (!await File(path).exists()) {
  //    final byteData = await rootBundle.load(assetDbPath);
  //    final buffer = byteData.buffer;
  //    await File(path).writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  //  }
  //
  //  return await databaseFactory.openDatabase(path);
  //}

  static Future<void> executeSchema(Database db, String version) async {
    final script = await rootBundle.loadString("assets/migrations/$version.sql");
    final statements = script.split(";");
    for (final statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  static Stream<Record> fetchFutureRecords({Filter? filter}) async* {
    final db = await DatabaseService.database;

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
    ${filter?.whereClauseFuture() ?? ""}
  """);

    if (filter != null && filter.futureMinHomeWinPercentage == 1) {
      debugPrint(result.length.toString());
      for (var row in result) {
        Record futureRecord = Record.fromMap(row);

        final percentageResult = await db.rawQuery("""
        SELECT
          COUNT(*) AS recordsCount,
          SUM(homeWin) AS homeWins,
          SUM(draw) AS draws,
          SUM(awayWin) AS awayWins
        FROM Records r
        ${filter.whereClause(futureRecord: futureRecord)}
      """);

        final Map<String, dynamic> res = percentageResult[0];
        final int recordsCount = res["recordsCount"] as int;

        if (recordsCount > 0) {
          final int homeWins = res["homeWins"] as int;
          final int draws = res["draws"] as int;
          final int awayWins = res["awayWins"] as int;

          double homeWinPercentage = (homeWins / recordsCount) * 100;
          double drawPercentage = (draws / recordsCount) * 100;
          double awayWinPercentage = (awayWins / recordsCount) * 100;

          if (homeWinPercentage >= 52 || drawPercentage >= 52 || awayWinPercentage >= 52) {
            futureRecord.pastRecordsCount = recordsCount;
            futureRecord.homeWinPercentage = homeWinPercentage;
            futureRecord.drawPercentage = drawPercentage;
            futureRecord.awayWinPercentage = awayWinPercentage;
            yield futureRecord;
          }
        }
      }
    } else {
      for (var row in result) {
        yield Record.fromMap(row);
      }
    }
  }

  static Future<List<Record>> fetchRecords({Filter? filter, Record? futureRecord}) async {
    final db = await database;
    late String whereClause;

    if (filter == null) {
      whereClause = "WHERE 1 = 1";
    } else {
      whereClause = filter.whereClause(futureRecord: futureRecord);
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

  static Future<DateTime> fetchFromMaxMatchDate() async {
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
    await _db?.insert("Records", record.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> insertRecordsBatch(List<Record> records) async {
    if (_db == null || records.isEmpty) return;

    Batch batch = _db!.batch();

    for (Record record in records) {
      batch.insert("Records", record.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    try {
      await batch.commit(noResult: true);
    } catch (e) {
      // ignore
    }
  }

  static Future<int> getOrCreateLeague(String leagueCode, String? leagueName) async {
    final db = await database;

    String whereClause = "leagueCode = ?";
    List<String> whereArgs = [leagueCode];

    if (leagueName != null) {
      whereClause += " AND leagueName = ?";
      whereArgs.add(leagueName);
    }

    final result = await db.query("Leagues", where: whereClause, whereArgs: whereArgs);

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
    final result = await db.query("Teams", where: "teamName = ?", whereArgs: [teamName]);

    if (result.isNotEmpty) {
      return result.first["id"] as int;
    }

    return await db.insert("Teams", {"teamName": teamName}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int>? deleteOldFutureRecords() {
    return _db?.delete("Records", where: "finished = ?", whereArgs: [0]);
  }

  static Future<List<League>> fetchLeagues() async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT GROUP_CONCAT(id, ',') ids, leagueCode, GROUP_CONCAT(leagueName, ',') AS leagueName FROM Leagues GROUP BY leagueCode ORDER BY leagueCode;",
    );

    return result.map((row) => League.fromMap(row)).toList();
  }

  static Future<List<Folder>> fetchFoldersWithLeagues() async {
    final db = await database;

    final result = await db.rawQuery("""
      SELECT
      lf.id,
      l.id as leagueId, l.leagueName, l.leagueCode,
      f.id as folderId, f.folderName
      FROM LeaguesFolders lf
      INNER JOIN Leagues l ON l.id = lf.leagueId
      INNER JOIN Folders f ON f.id = lf.folderId
      ORDER BY lf.folderId;""");

    final List<Folder> folders = [];

    for (var row in result) {
      final league = League(
        id: row["leagueId"] as int,
        code: row["leagueCode"] as String,
        name: row["leagueName"] as String,
      );

      final int folderId = row["folderId"] as int;
      final String folderName = row["folderName"] as String;

      final int index = folders.indexWhere((folder) => folder.id == folderId);

      if (index != -1) {
        folders[index].leagues.add(league);
      } else {
        final Folder folder = Folder(id: folderId, name: folderName);
        folder.leagues.add(league);
        folders.add(folder);
      }
    }

    return folders;
  }
}
