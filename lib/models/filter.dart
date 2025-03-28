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

  int? futureNextMinutes;
  int? futureDismissNoEarlyOdds; // TODO: Missing
  int? futureDismissNoFinalOdds; // TODO: Missing
  int? futureDismissNoHistory; // TODO: Missing
  bool futureOnlySameLeague;
  int? futureSameEarlyHome;
  int? futureSameEarlyDraw;
  int? futureSameEarlyAway;
  int? futureSameFinalHome;
  int? futureSameFinalDraw;
  int? futureSameFinalAway;
  int? futureMinHomeWinPercentage; // TODO: Missing
  int? futureMinDrawPercentage; // TODO: Missing
  int? futureMinAwayWinPercentage; // TODO: Missing

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
    this.pastYears,
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
    this.futureDismissNoEarlyOdds,
    this.futureDismissNoFinalOdds,
    this.futureDismissNoHistory,
    this.futureOnlySameLeague = false,
    this.futureSameEarlyHome,
    this.futureSameEarlyDraw,
    this.futureSameEarlyAway,
    this.futureSameFinalHome,
    this.futureSameFinalDraw,
    this.futureSameFinalAway,
    this.futureMinHomeWinPercentage,
    this.futureMinDrawPercentage,
    this.futureMinAwayWinPercentage,
    this.filterPastRecordsByTeams = true,
    this.filterFutureRecordsByTeams = true,
    this.filterPastRecordsByLeagues = true,
    this.filterFutureRecordsByLeagues = true,
    required this.teams,
    required this.leagues,
    required this.folders,
    this.futureNextMinutes,
  }) : assert(pastYears != null || specificYears != null);

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
      futureDismissNoEarlyOdds: map["futureDismissNoEarlyOdds"],
      futureDismissNoFinalOdds: map["futureDismissNoFinalOdds"],
      futureDismissNoHistory: map["futureDismissNoHistory"],
      futureOnlySameLeague: map["futureOnlySameLeague"] == 1,
      futureSameEarlyHome: map["futureSameEarlyHome"],
      futureSameEarlyDraw: map["futureSameEarlyDraw"],
      futureSameEarlyAway: map["futureSameEarlyAway"],
      futureSameFinalHome: map["futureSameFinalHome"],
      futureSameFinalDraw: map["futureSameFinalDraw"],
      futureSameFinalAway: map["futureSameFinalAway"],
      futureMinHomeWinPercentage: map["futureMinHomeWinPercentage"],
      futureMinDrawPercentage: map["futureMinDrawPercentage"],
      futureMinAwayWinPercentage: map["futureMinAwayWinPercentage"],
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
      "futureDismissNoEarlyOdds": futureDismissNoEarlyOdds,
      "futureDismissNoFinalOdds": futureDismissNoFinalOdds,
      "futureDismissNoHistory": futureDismissNoHistory,
      "futureOnlySameLeague": futureOnlySameLeague ? 1 : 0,
      "futureSameEarlyHome": futureSameEarlyHome,
      "futureSameEarlyDraw": futureSameEarlyDraw,
      "futureSameEarlyAway": futureSameEarlyAway,
      "futureSameFinalHome": futureSameFinalHome,
      "futureSameFinalDraw": futureSameFinalDraw,
      "futureSameFinalAway": futureSameFinalAway,
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

    final List<int> leagueIds = await DatabaseService.fetchLeagueIds(leagues);

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

    if (futureSameEarlyHome == 1 && futureRecord?.earlyOdds1 != null) {
      whereClause += " AND earlyOdds1 = ${futureRecord?.earlyOdds1}";
    }

    if (futureSameEarlyDraw == 1 && futureRecord?.earlyOddsX != null) {
      whereClause += " AND earlyOddsX = ${futureRecord?.earlyOddsX}";
    }

    if (futureSameEarlyAway == 1 && futureRecord?.earlyOdds2 != null) {
      whereClause += " AND earlyOdds2 = ${futureRecord?.earlyOdds2}";
    }

    if (futureSameFinalHome == 1 && futureRecord?.finalOdds1 != null) {
      whereClause += " AND finalOdds1 = ${futureRecord?.finalOdds1}";
    }

    if (futureSameFinalDraw == 1 && futureRecord?.finalOddsX != null) {
      whereClause += " AND finalOddsX = ${futureRecord?.finalOddsX}";
    }

    if (futureSameFinalAway == 1 && futureRecord?.finalOdds2 != null) {
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

    if (futureNextMinutes == null) {
      return whereClause;
    }

    final DateTime futureMaxDate = DateTime.now().add(Duration(minutes: futureNextMinutes as int));

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

  static Filter base() {
    return Filter(
      filterName: "FILTRO PADRÃO",
      pastYears: 1,
      teams: [],
      leagues: [],
      folders: [],
      futureNextMinutes: 60,
      futureMinHomeWinPercentage: 1,
      futureSameEarlyHome: 1,
      futureSameEarlyAway: 1,
    );
  }

  Filter copyWith() {
    Filter filter = Filter.fromMap(toMap());

    //filter.bettingHouses = bettingHouses;
    filter.teams = teams;
    filter.leagues = leagues;
    filter.folders = folders;

    return filter;
  }
}
