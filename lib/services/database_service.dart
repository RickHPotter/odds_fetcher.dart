import "dart:io";
import "package:flutter/foundation.dart" show ByteData, debugPrint;
import "package:flutter/services.dart" show rootBundle;
import "package:odds_fetcher/models/team.dart";
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
    _db?.execute("PRAGMA foreign_keys=ON;");
    _db?.execute("PRAGMA journal_mode=WAL;");

    return _db!;
  }

  static Future<Database> _initDb() async {
    final String dbPath =
        Platform.isWindows ? await getApplicationSupportDirectory().then((dir) => dir.path) : await getDatabasesPath();
    final String path = join(dbPath, dbName);

    final Directory dbDir = Directory(dbPath);
    if (!dbDir.existsSync()) {
      debugPrint("Creating database directory: $dbPath");
      await dbDir.create(recursive: true);
    }

    final bool dbExists = await databaseExists(path);

    if (!dbExists) {
      debugPrint("Database does not exist, copying and unzipping from assets...");
      try {
        ByteData data = await rootBundle.load(assetDbZipPath);
        List<int> bytes = data.buffer.asUint8List();

        final Archive archive = ZipDecoder().decodeBytes(bytes);
        bool dbCopied = false;
        for (final file in archive) {
          if (file.isFile) {
            final String filename = file.name;
            if (filename == dbName) {
              final File dbFile = File(path);
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
    }

    final File dbFile = File(path);
    if (!dbFile.existsSync() || dbFile.lengthSync() < 1024) {
      throw Exception("Unzipped database is too small or missing.");
    }

    return await openDatabase(path, version: 1);
  }

  static Stream<Record> fetchFutureRecords(Filter filter) async* {
    final Database db = await DatabaseService.database;

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
    ${await filter.whereClauseFuture()}
    ORDER BY MatchDate, ID
    """);

    final bool anyFutureMinPercentage =
        filter.futureMinHomeWinPercentage + filter.futureMinDrawPercentage + filter.futureMinAwayWinPercentage > 0;

    if (anyFutureMinPercentage) {
      for (final row in result) {
        Record futureRecord = Record.fromMap(row);

        final percentageResult = await db.rawQuery("""
        SELECT
          COUNT(*) AS recordsCount,
          SUM(homeWin) AS homeWins,
          SUM(draw) AS draws,
          SUM(awayWin) AS awayWins
        FROM Records r
        ${await filter.whereClause(futureRecord: futureRecord)}
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

          if (homeWinPercentage >= filter.futureMinHomeWinPercentage ||
              drawPercentage >= filter.futureMinDrawPercentage ||
              awayWinPercentage >= filter.futureMinAwayWinPercentage) {
            futureRecord.pastRecordsCount = recordsCount;
            futureRecord.homeWinPercentage = homeWinPercentage;
            futureRecord.drawPercentage = drawPercentage;
            futureRecord.awayWinPercentage = awayWinPercentage;
            yield futureRecord;
          }
        }
      }
    } else {
      for (final row in result) {
        yield Record.fromMap(row);
      }
    }
  }

  static Future<List<Record>> fetchRecords({Filter? filter, Record? futureRecord}) async {
    final Database db = await database;
    late String whereClause;

    if (filter == null) {
      whereClause = "WHERE 1 = 1";
    } else {
      whereClause = await filter.whereClause(futureRecord: futureRecord);
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
    ORDER BY MatchDate
    ;
    """);

    return result.map((row) => Record.fromMap(row)).toList();
  }

  static Future<DateTime> fetchFromMaxMatchDate() async {
    final Database db = await database;

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

  static Future<bool> insertFilter(Filter filter) async {
    final Database db = await database;

    int? filterId =
        filter.id ?? await db.insert("Filters", filter.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);

    if (filterId == 0) {
      return false;
    }

    await db.delete("FiltersTeams", where: "filterId = ?", whereArgs: [filterId]);
    await db.delete("FiltersLeagues", where: "filterId = ?", whereArgs: [filterId]);
    await db.delete("FiltersFolders", where: "filterId = ?", whereArgs: [filterId]);

    late List<int> leagueIds = filter.leagues.map((l) => l.ids).expand((l) => l).toList();
    if (filter.leagues.isEmpty) {
      leagueIds = await DatabaseService.fetchLeagueIds(filter.leagues);
    }

    for (Team team in filter.teams) {
      await db.insert("FiltersTeams", {
        "filterId": filterId,
        "teamId": team.id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (int leagueId in leagueIds) {
      await db.insert("FiltersLeagues", {
        "filterId": filterId,
        "leagueId": leagueId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (Folder folder in filter.folders) {
      await db.insert("FiltersFolders", {
        "filterId": filterId,
        "folderId": folder.id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    return true;
  }

  static Future<bool> updateFilter(Filter filter) async {
    final Database db = await database;

    try {
      await db.update(
        "Filters",
        filter.toMap(),
        where: "id = ?",
        whereArgs: [filter.id],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      return false;
    }

    return await insertFilter(filter);
  }

  static Future<int> getOrCreateLeague(String leagueCode, String? leagueName) async {
    final Database db = await database;

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
    final Database db = await database;
    final result = await db.query("Teams", where: "teamName = ?", whereArgs: [teamName]);

    if (result.isNotEmpty) {
      return result.first["id"] as int;
    }

    return await db.insert("Teams", {"teamName": teamName}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int>? deleteOldFutureRecords() {
    return _db?.delete("Records", where: "finished = ?", whereArgs: [0]);
  }

  static Future<List<Team>> fetchTeams() async {
    final Database db = await database;

    final result = await db.query("Teams");

    return result.map((row) => Team.fromMap(row)).toList();
  }

  static Future<List<League>> fetchLeagues() async {
    final Database db = await database;

    final result = await db.rawQuery("""
    SELECT
      leagueCode,
      MIN(id) AS id,
      GROUP_CONCAT(id, ',') ids,
      MIN(leagueName) AS leagueName
    FROM Leagues
    GROUP BY leagueCode
    ORDER BY leagueCode;""");

    return result.map((row) => League.fromMap(row)).toList();
  }

  static Future<List<int>> fetchLeagueIds(List<League> leagues) async {
    final String leagueCodes = leagues.map((l) => "'${l.code}'").join(", ");
    final result = await _db?.rawQuery("SELECT id FROM Leagues WHERE leagueCode IN ($leagueCodes);");
    final List<int> leagueIds = result?.map((row) => row["id"] as int).toList() ?? [];

    return leagueIds;
  }

  static Future<List<Folder>> fetchFoldersWithLeagues() async {
    final Database db = await database;

    final result = await db.rawQuery("""
    SELECT
      MIN(lf.id) AS id,
      GROUP_CONCAT(l.id, ',') ids,
      MIN(l.id) AS leagueId,
      GROUP_CONCAT(l.leagueName, ',') AS leagueName,
      l.leagueCode,
      f.id as folderId,
      f.folderName
    FROM LeaguesFolders lf
    INNER JOIN Leagues l ON l.id = lf.leagueId
    INNER JOIN Folders f ON f.id = lf.folderId
    GROUP BY l.leagueCode, f.id, f.folderName
    ORDER BY lf.folderId;""");

    final List<Folder> folders = [];

    for (final row in result) {
      final League league = League(
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
        final Folder folder = Folder(id: folderId, name: folderName, leagues: [league]);
        folders.add(folder);
      }
    }

    return folders;
  }

  static Future<List<Filter>> fetchFilters() async {
    final Database db = await database;

    final result = await db.query("Filters");

    return result.map((row) => Filter.fromMap(row)).toList();
  }

  static Future<Filter> fetchFilter(int id) async {
    final Database db = await database;

    final filterResult =
        (id != 0)
            ? await db.query("Filters", where: "id = ?", whereArgs: [id])
            : await db.rawQuery("SELECT * FROM Filters ORDER BY ID LIMIT 1");

    if (filterResult.isEmpty) {
      debugPrint("fallback to base filter");
      return Filter.base();
    }

    final Filter filter = Filter.fromMap(filterResult.first);
    final int filterId = filter.id!;

    final teamResults = await db.rawQuery(
      """
    SELECT t.* FROM Teams t
    INNER JOIN FiltersTeams ft ON t.id = ft.teamId
    WHERE ft.filterId = ?;
    """,
      [filterId],
    );

    filter.teams = teamResults.map((t) => Team.fromMap(t)).toList();

    final leagueResults = await db.rawQuery(
      """
    SELECT
      MIN(l.id) AS id,
      leagueCode,
      GROUP_CONCAT(l.id, ',') ids,
      GROUP_CONCAT(l.leagueName, ',') AS leagueName
    FROM Leagues l
    INNER JOIN FiltersLeagues fl ON l.id = fl.leagueId
    WHERE fl.filterId = ?
    GROUP BY l.leagueCode
    ORDER BY l.leagueCode;""",
      [filterId],
    );

    filter.leagues = leagueResults.map((l) => League.fromMap(l)).toList();

    final folderResults = await db.rawQuery(
      """
    SELECT
      f.id AS id,
      f.folderName,
      MIN(l.id) AS leagueId,
      GROUP_CONCAT(l.id, ',') AS leagueIds,
      l.leagueCode AS leagueCode,
      GROUP_CONCAT(l.leagueName, ',') AS leagueName
    FROM Folders f
    INNER JOIN FiltersFolders ff ON f.id = ff.folderId
    INNER JOIN LeaguesFolders lf ON f.id = lf.folderId
    INNER JOIN Leagues l         ON lf.leagueId = l.id
    WHERE ff.filterId = ?
    GROUP BY f.id, f.folderName, l.leagueCode;
    """,
      [filterId],
    );

    final List<Folder> folders = [];

    for (final row in folderResults) {
      List<int> leagueIds = row["leagueIds"].toString().split(",").map((id) => int.parse(id)).toList();

      final League league = League(
        id: row["leagueId"] as int,
        ids: leagueIds,
        code: row["leagueCode"] as String,
        name: row["leagueName"] as String,
      );

      final int folderId = row["id"] as int;
      final String folderName = row["folderName"] as String;

      final int index = folders.indexWhere((folder) => folder.id == folderId);

      if (index != -1) {
        folders[index].leagues.add(league);
      } else {
        final Folder folder = Folder(id: folderId, name: folderName, leagues: [league]);
        folders.add(folder);
      }
    }

    filter.folders = folders;

    return filter;
  }
}
