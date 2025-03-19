import "dart:io";
import "package:flutter/foundation.dart" show ByteData, debugPrint;
import "package:flutter/services.dart" show rootBundle;
import "package:path_provider/path_provider.dart" show getApplicationSupportDirectory;
import "package:sqflite/sqflite.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:path/path.dart" show join;
import "package:archive/archive.dart";
import "package:archive/archive_io.dart";

import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/record.dart";

import "package:odds_fetcher/utils/date_utils.dart" show parseRawDate;

class DatabaseService {
  static Database? _db;
  static const String dbName = "odds_fetcher.db";
  static const String assetDbZipPath = "assets/db.zip";

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDb();
    _db?.execute("PRAGMA foreign_keys = ON;");

    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath =
        Platform.isWindows ? await getApplicationSupportDirectory().then((dir) => dir.path) : await getDatabasesPath();
    final path = join(dbPath, dbName);

    final dbDir = Directory(dbPath);
    if (!dbDir.existsSync()) {
      debugPrint("Creating database directory: $dbPath");
      await dbDir.create(recursive: true);
    }

    final dbExists = await databaseExists(path);

    if (!dbExists) {
      debugPrint("Database does not exist, copying and unzipping from assets...");
      try {
        ByteData data = await rootBundle.load(assetDbZipPath);
        List<int> bytes = data.buffer.asUint8List();

        // Unzip
        final archive = ZipDecoder().decodeBytes(bytes);
        bool dbCopied = false;
        for (var file in archive) {
          if (file.isFile) {
            final filename = file.name;
            if (filename == dbName) {
              final dbFile = File(path);
              await dbFile.writeAsBytes(file.content, flush: true);
              dbCopied = true;
              debugPrint("Database unzipped successfully to $path");
              break;
            }
          }
        }

        if (!dbCopied) {
          throw Exception("Database file not found in zip!");
        }
      } catch (e) {
        debugPrint("Error copying and unzipping database: $e");
        rethrow;
      }
    } else {
      debugPrint("Database already exists at: $path");
    }

    // Verify the file exists and has content
    final dbFile = File(path);
    if (!dbFile.existsSync() || dbFile.lengthSync() < 1024) {
      throw Exception("Unzipped database is too small or missing.");
    }

    return await openDatabase(path, version: 1);
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
    ORDER BY MatchDate, ID
  """);

    if (filter != null && filter.futureMinHomeWinPercentage == 1) {
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
    SELECT MAX(MatchDate) AS MatchDate
    FROM Records
    WHERE FINISHED = 1
    LIMIT 1;
    """);

    if (result.isEmpty || result.first["MatchDate"] == null) {
      return DateTime.parse("2008-01-01");
    }

    String matchDateStr = result.first["MatchDate"].toString();
    return parseRawDate(matchDateStr);
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
