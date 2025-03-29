import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/team.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/utils/date_utils.dart" show rawDateTime;

enum MinMaxOdds {
  minEarlyHome,
  maxEarlyHome,
  minEarlyDraw,
  maxEarlyDraw,
  minEarlyAway,
  maxEarlyAway,
  minFinalHome,
  maxFinalHome,
  minFinalDraw,
  maxFinalDraw,
  minFinalAway,
  maxFinalAway,
}

class Filter {
  int? id;
  String filterName;
  int? pastYears;
  int? specificYears;

  double? minEarlyHome;
  double? maxEarlyHome;
  double? minEarlyDraw;
  double? maxEarlyDraw;
  double? minEarlyAway;
  double? maxEarlyAway;
  double? minFinalHome;
  double? maxFinalHome;
  double? minFinalDraw;
  double? maxFinalDraw;
  double? minFinalAway;
  double? maxFinalAway;

  int? minGoalsFirstHalf; // TODO: Missing
  int? maxGoalsFirstHalf; // TODO: Missing
  int? minGoalsSecondHalf; // TODO: Missing
  int? maxGoalsSecondHalf; // TODO: Missing
  int? minGoalsFullTime; // TODO: Missing
  int? maxGoalsFullTime; // TODO: Missing

  int futureNextMinutes;
  bool futureDismissNoEarlyOdds;
  bool futureDismissNoFinalOdds;
  int? futureDismissNoHistory; // TODO: Missing
  bool futureOnlySameLeague;
  bool futureSameEarlyHome;
  bool futureSameEarlyDraw;
  bool futureSameEarlyAway;
  bool futureSameFinalHome;
  bool futureSameFinalDraw;
  bool futureSameFinalAway;

  int futureMinHomeWinPercentage;
  int futureMinDrawPercentage;
  int futureMinAwayWinPercentage;

  bool filterPastRecordsByTeams;
  bool filterFutureRecordsByTeams;
  bool filterPastRecordsByLeagues;
  bool filterFutureRecordsByLeagues;

  List<Team> teams;
  List<League> leagues;
  List<Folder> folders;

  Filter({
    this.id,
    required this.filterName,
    this.pastYears = 1,
    this.specificYears,
    this.minEarlyHome,
    this.maxEarlyHome,
    this.minEarlyDraw,
    this.maxEarlyDraw,
    this.minEarlyAway,
    this.maxEarlyAway,
    this.minFinalHome,
    this.maxFinalHome,
    this.minFinalDraw,
    this.maxFinalDraw,
    this.minFinalAway,
    this.maxFinalAway,
    this.minGoalsFirstHalf,
    this.maxGoalsFirstHalf,
    this.minGoalsSecondHalf,
    this.maxGoalsSecondHalf,
    this.minGoalsFullTime,
    this.maxGoalsFullTime,
    this.futureNextMinutes = 60,
    this.futureDismissNoEarlyOdds = true,
    this.futureDismissNoFinalOdds = false,
    this.futureDismissNoHistory,
    this.futureOnlySameLeague = false,
    this.futureSameEarlyHome = true,
    this.futureSameEarlyDraw = true,
    this.futureSameEarlyAway = true,
    this.futureSameFinalHome = false,
    this.futureSameFinalDraw = false,
    this.futureSameFinalAway = false,
    this.futureMinHomeWinPercentage = 52,
    this.futureMinDrawPercentage = 52,
    this.futureMinAwayWinPercentage = 52,
    this.filterPastRecordsByTeams = true,
    this.filterFutureRecordsByTeams = true,
    this.filterPastRecordsByLeagues = true,
    this.filterFutureRecordsByLeagues = true,

    this.teams = const [],
    this.leagues = const [],
    this.folders = const [],
  }) : assert(pastYears != null || specificYears != null);

  Filter copyWith() {
    Filter filter = Filter.fromMap(toMap());

    //filter.bettingHouses = bettingHouses;
    filter.teams = teams;
    filter.leagues = leagues;
    filter.folders = folders;

    return filter;
  }

  factory Filter.fromMap(Map<String, dynamic> map) {
    return Filter(
      id: map["id"],
      filterName: map["filterName"],
      pastYears: map["pastYears"],
      specificYears: map["specificYears"],
      minEarlyHome: map["minEarlyHome"],
      maxEarlyHome: map["maxEarlyHome"],
      minEarlyDraw: map["minEarlyDraw"],
      maxEarlyDraw: map["maxEarlyDraw"],
      minEarlyAway: map["minEarlyAway"],
      maxEarlyAway: map["maxEarlyAway"],
      minFinalHome: map["minFinalHome"],
      maxFinalHome: map["maxFinalHome"],
      minFinalDraw: map["minFinalDraw"],
      maxFinalDraw: map["maxFinalDraw"],
      minFinalAway: map["minFinalAway"],
      maxFinalAway: map["maxFinalAway"],
      minGoalsFirstHalf: map["minGoalsFirstHalf"],
      maxGoalsFirstHalf: map["maxGoalsFirstHalf"],
      minGoalsSecondHalf: map["minGoalsSecondHalf"],
      maxGoalsSecondHalf: map["maxGoalsSecondHalf"],
      minGoalsFullTime: map["minGoalsFullTime"],
      maxGoalsFullTime: map["maxGoalsFullTime"],
      futureNextMinutes: map["futureNextMinutes"],
      futureDismissNoEarlyOdds: map["futureDismissNoEarlyOdds"] == 1,
      futureDismissNoFinalOdds: map["futureDismissNoFinalOdds"] == 1,
      futureDismissNoHistory: map["futureDismissNoHistory"],
      futureOnlySameLeague: map["futureOnlySameLeague"] == 1,
      futureSameEarlyHome: map["futureSameEarlyHome"] == 1,
      futureSameEarlyDraw: map["futureSameEarlyDraw"] == 1,
      futureSameEarlyAway: map["futureSameEarlyAway"] == 1,
      futureSameFinalHome: map["futureSameFinalHome"] == 1,
      futureSameFinalDraw: map["futureSameFinalDraw"] == 1,
      futureSameFinalAway: map["futureSameFinalAway"] == 1,
      futureMinHomeWinPercentage: map["futureMinHomeWinPercentage"] ?? 0,
      futureMinDrawPercentage: map["futureMinDrawPercentage"] ?? 0,
      futureMinAwayWinPercentage: map["futureMinAwayWinPercentage"] ?? 0,
      filterPastRecordsByTeams: map["filterPastRecordsByTeams"] == 1,
      filterFutureRecordsByTeams: map["filterFutureRecordsByTeams"] == 1,
      filterPastRecordsByLeagues: map["filterPastRecordsByLeagues"] == 1,
      filterFutureRecordsByLeagues: map["filterFutureRecordsByLeagues"] == 1,

      teams: map["teams"] == null ? [] : map["teams"].map((t) => Team.fromMap(t)).toList(),
      leagues: map["leagues"] == null ? [] : map["leagues"].map((l) => League.fromMap(l)).toList(),
      folders: map["folders"] == null ? [] : map["folders"].map((f) => Folder.fromMap(f)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "filterName": filterName,
      "pastYears": pastYears,
      "specificYears": specificYears,
      "minEarlyHome": minEarlyHome,
      "maxEarlyHome": maxEarlyHome,
      "minEarlyDraw": minEarlyDraw,
      "maxEarlyDraw": maxEarlyDraw,
      "minEarlyAway": minEarlyAway,
      "maxEarlyAway": maxEarlyAway,
      "minFinalHome": minFinalHome,
      "maxFinalHome": maxFinalHome,
      "minFinalDraw": minFinalDraw,
      "maxFinalDraw": maxFinalDraw,
      "minFinalAway": minFinalAway,
      "maxFinalAway": maxFinalAway,
      "minGoalsFirstHalf": minGoalsFirstHalf,
      "maxGoalsFirstHalf": maxGoalsFirstHalf,
      "minGoalsSecondHalf": minGoalsSecondHalf,
      "maxGoalsSecondHalf": maxGoalsSecondHalf,
      "minGoalsFullTime": minGoalsFullTime,
      "maxGoalsFullTime": maxGoalsFullTime,
      "futureNextMinutes": futureNextMinutes,
      "futureDismissNoEarlyOdds": futureDismissNoEarlyOdds ? 1 : 0,
      "futureDismissNoFinalOdds": futureDismissNoFinalOdds ? 1 : 0,
      "futureDismissNoHistory": futureDismissNoHistory,
      "futureOnlySameLeague": futureOnlySameLeague ? 1 : 0,
      "futureSameEarlyHome": futureSameEarlyHome ? 1 : 0,
      "futureSameEarlyDraw": futureSameEarlyDraw ? 1 : 0,
      "futureSameEarlyAway": futureSameEarlyAway ? 1 : 0,
      "futureSameFinalHome": futureSameFinalHome ? 1 : 0,
      "futureSameFinalDraw": futureSameFinalDraw ? 1 : 0,
      "futureSameFinalAway": futureSameFinalAway ? 1 : 0,
      "futureMinHomeWinPercentage": futureMinHomeWinPercentage,
      "futureMinDrawPercentage": futureMinDrawPercentage,
      "futureMinAwayWinPercentage": futureMinAwayWinPercentage,
      "filterPastRecordsByTeams": filterPastRecordsByTeams ? 1 : 0,
      "filterFutureRecordsByTeams": filterFutureRecordsByTeams ? 1 : 0,
      "filterPastRecordsByLeagues": filterPastRecordsByLeagues ? 1 : 0,
      "filterFutureRecordsByLeagues": filterFutureRecordsByLeagues ? 1 : 0,
    };
  }

  DateTime minDate() {
    if (pastYears != null) {
      return DateTime.now().subtract(Duration(days: (pastYears as int) * 365));
    } else if (specificYears != null) {
      return DateTime(specificYears as int, 1, 1);
    } else {
      return DateTime.parse("2008-01-01");
    }
  }

  DateTime maxDate() {
    if (pastYears != null) {
      return DateTime.now();
    } else if (specificYears != null) {
      return DateTime(specificYears as int, 12, 31);
    } else {
      return DateTime.now();
    }
  }

  bool anySpecificOddsPresent() {
    return minEarlyHome != null ||
        maxEarlyHome != null ||
        minEarlyDraw != null ||
        maxEarlyDraw != null ||
        minEarlyAway != null ||
        maxEarlyAway != null ||
        minFinalHome != null ||
        maxFinalHome != null ||
        minFinalDraw != null ||
        maxFinalDraw != null ||
        minFinalAway != null ||
        maxFinalAway != null;
  }

  bool anyFutureMinPercent() {
    return (futureMinHomeWinPercentage > 0 && futureMinHomeWinPercentage < 100) ||
        (futureMinDrawPercentage > 0 && futureMinDrawPercentage < 100) ||
        (futureMinAwayWinPercentage > 0 && futureMinAwayWinPercentage < 100);
  }

  void removeAllSpecificOdds() {
    minEarlyHome = null;
    maxEarlyHome = null;
    minEarlyDraw = null;
    maxEarlyDraw = null;
    minEarlyAway = null;
    maxEarlyAway = null;
    minFinalHome = null;
    maxFinalHome = null;
    minFinalDraw = null;
    maxFinalDraw = null;
    minFinalAway = null;
    maxFinalAway = null;
  }

  void fillInAllRangeOdds() {
    if (minEarlyHome != null && maxEarlyHome == null) {
      maxEarlyHome = minEarlyHome;
    }

    if (maxEarlyHome != null && minEarlyHome == null) {
      minEarlyHome = maxEarlyHome;
    }

    if (minEarlyDraw != null && maxEarlyDraw == null) {
      maxEarlyDraw = minEarlyDraw;
    }

    if (maxEarlyDraw != null && minEarlyDraw == null) {
      minEarlyDraw = maxEarlyDraw;
    }

    if (minEarlyAway != null && maxEarlyAway == null) {
      maxEarlyAway = minEarlyAway;
    }

    if (maxEarlyAway != null && minEarlyAway == null) {
      minEarlyAway = maxEarlyAway;
    }

    if (minFinalHome != null && maxFinalHome == null) {
      maxFinalHome = minFinalHome;
    }

    if (maxFinalHome != null && minFinalHome == null) {
      minFinalHome = maxFinalHome;
    }

    if (minFinalDraw != null && maxFinalDraw == null) {
      maxFinalDraw = minFinalDraw;
    }

    if (maxFinalDraw != null && minFinalDraw == null) {
      minFinalDraw = maxFinalDraw;
    }

    if (minFinalAway != null && maxFinalAway == null) {
      maxFinalAway = minFinalAway;
    }

    if (maxFinalAway != null && minFinalAway == null) {
      minFinalAway = maxFinalAway;
    }
  }

  Future<List<int>> leaguesIds() async {
    if (leagues.isEmpty && folders.isEmpty) return [];

    late List<int> leagueIds = leagues.map((l) => l.ids).expand((l) => l).toList();

    if (leagues.isEmpty) {
      leagueIds = await DatabaseService.fetchLeagueIds(leagues);
    }

    final List<int> folderIds = folders.expand((folder) => folder.leagues).map((l) => l.id).toList();

    return [...leagueIds, ...folderIds];
  }

  List<int> teamsIds() {
    final List<int> teamIds = teams.map((t) => t.id).toList();

    return teamIds;
  }

  Future<String> whereClause({Record? futureRecord}) async {
    fillInAllRangeOdds();

    late String whereClause = "WHERE finished = 1";

    whereClause += " AND MatchDate >= ${rawDateTime(minDate())}";
    whereClause += " AND MatchDate <= ${rawDateTime(maxDate())}";

    if (futureSameEarlyHome && futureRecord?.earlyOdds1 != null) {
      whereClause += " AND earlyOdds1 = ${futureRecord?.earlyOdds1}";
    }

    if (futureSameEarlyDraw && futureRecord?.earlyOddsX != null) {
      whereClause += " AND earlyOddsX = ${futureRecord?.earlyOddsX}";
    }

    if (futureSameEarlyAway && futureRecord?.earlyOdds2 != null) {
      whereClause += " AND earlyOdds2 = ${futureRecord?.earlyOdds2}";
    }

    if (futureSameFinalHome && futureRecord?.finalOdds1 != null) {
      whereClause += " AND finalOdds1 = ${futureRecord?.finalOdds1}";
    }

    if (futureSameFinalDraw && futureRecord?.finalOddsX != null) {
      whereClause += " AND finalOddsX = ${futureRecord?.finalOddsX}";
    }

    if (futureSameFinalAway && futureRecord?.finalOdds2 != null) {
      whereClause += " AND finalOdds2 = ${futureRecord?.finalOdds2}";
    }

    if (filterPastRecordsByTeams && teams.isNotEmpty) {
      final String teamsIdsString = teamsIds().join(", ");
      whereClause += " AND (homeTeamId IN ($teamsIdsString) OR awayTeamId IN ($teamsIdsString))";
    }

    if (filterPastRecordsByLeagues && (leagues.isNotEmpty || folders.isNotEmpty)) {
      final List<int> leagueIdsList = await leaguesIds();
      whereClause += " AND leagueId IN (${leagueIdsList.join(', ')}) ";
    } else if (futureOnlySameLeague && futureRecord?.league.id != null) {
      whereClause += " AND leagueId = ${futureRecord?.league.id}";
    }

    if (futureDismissNoEarlyOdds) {
      whereClause += " AND earlyOdds1 IS NOT NULL AND earlyOddsX IS NOT NULL AND earlyOdds2 IS NOT NULL";
    }

    if (futureDismissNoFinalOdds) {
      whereClause += " AND finalOdds1 IS NOT NULL AND finalOddsX IS NOT NULL AND finalOdds2 IS NOT NULL";
    }

    if (minEarlyHome != null) {
      whereClause += " AND earlyOdds1 BETWEEN $minEarlyHome AND $maxEarlyHome";
    }

    if (minEarlyDraw != null) {
      whereClause += " AND earlyOddsX BETWEEN $minEarlyDraw AND $maxEarlyDraw";
    }

    if (minEarlyAway != null) {
      whereClause += " AND earlyOdds2 BETWEEN $minEarlyAway AND $maxEarlyAway";
    }

    if (minFinalHome != null) {
      whereClause += " AND finalOdds1 BETWEEN $minFinalHome AND $maxFinalHome";
    }

    if (minFinalDraw != null) {
      whereClause += " AND finalOddsX BETWEEN $minFinalDraw AND $maxFinalDraw";
    }

    if (minFinalAway != null) {
      whereClause += " AND finalOdds2 BETWEEN $minFinalAway AND $maxFinalAway";
    }

    return whereClause;
  }

  Future<String> whereClauseFuture() async {
    fillInAllRangeOdds();

    late String whereClause = "WHERE finished = 0";

    final DateTime futureMaxDate = DateTime.now().add(Duration(minutes: futureNextMinutes));

    whereClause += " AND MatchDate >= ${rawDateTime(DateTime.now())}";
    whereClause += " AND MatchDate <= ${rawDateTime(futureMaxDate)}";

    if (filterFutureRecordsByTeams && teams.isNotEmpty) {
      final String teamsIdsString = teamsIds().join(", ");
      whereClause += " AND (homeTeamId IN ($teamsIdsString) OR awayTeamId IN ($teamsIdsString))";
    }

    if (filterFutureRecordsByLeagues && (leagues.isNotEmpty || folders.isNotEmpty)) {
      final List<int> leagueIdsList = await leaguesIds();
      whereClause += " AND leagueId IN (${leagueIdsList.join(', ')}) ";
    }

    if (futureDismissNoEarlyOdds) {
      whereClause += " AND earlyOdds1 IS NOT NULL AND earlyOddsX IS NOT NULL AND earlyOdds2 IS NOT NULL";
    }

    if (futureDismissNoFinalOdds) {
      whereClause += " AND finalOdds1 IS NOT NULL AND finalOddsX IS NOT NULL AND finalOdds2 IS NOT NULL";
    }

    if (minEarlyHome != null) {
      whereClause += " AND earlyOdds1 BETWEEN $minEarlyHome AND $maxEarlyHome";
    }

    if (minEarlyDraw != null) {
      whereClause += " AND earlyOddsX BETWEEN $minEarlyDraw AND $maxEarlyDraw";
    }

    if (minEarlyAway != null) {
      whereClause += " AND earlyOdds2 BETWEEN $minEarlyAway AND $maxEarlyAway";
    }

    if (minFinalHome != null) {
      whereClause += " AND finalOdds1 BETWEEN $minFinalHome AND $maxFinalHome";
    }

    if (minFinalDraw != null) {
      whereClause += " AND finalOddsX BETWEEN $minFinalDraw AND $maxFinalDraw";
    }

    if (minFinalAway != null) {
      whereClause += " AND finalOdds2 BETWEEN $minFinalAway AND $maxFinalAway";
    }

    return whereClause;
  }
}
