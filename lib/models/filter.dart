import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/team.dart";
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
  DateTime minDate;
  DateTime maxDate;

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
  int? futureOnlySameLeague;
  int? futureSameEarlyHome;
  int? futureSameEarlyDraw;
  int? futureSameEarlyAway;
  int? futureSameFinalHome;
  int? futureSameFinalDraw;
  int? futureSameFinalAway;
  int? futureMinHomeWinPercentage; // TODO: Missing
  int? futureMinDrawPercentage; // TODO: Missing
  int? futureMinAwayWinPercentage; // TODO: Missing

  bool filterPastRecordsByTeams = true;
  bool filterFutureRecordsByTeams = true;

  bool filterPastRecordsByLeagues = true;
  bool filterFutureRecordsByLeagues = true;

  List<Team> teams;
  List<League> leagues;
  List<Folder> folders;

  Filter({
    this.id,
    required this.filterName,
    required this.minDate,
    required this.maxDate,
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
    this.futureOnlySameLeague,
    this.futureSameEarlyHome,
    this.futureSameEarlyDraw,
    this.futureSameEarlyAway,
    this.futureSameFinalHome,
    this.futureSameFinalDraw,
    this.futureSameFinalAway,
    this.futureMinHomeWinPercentage,
    this.futureMinDrawPercentage,
    this.futureMinAwayWinPercentage,
    required this.teams,
    required this.leagues,
    required this.folders,
    this.futureNextMinutes,
  });

  factory Filter.fromMap(Map<String, dynamic> map) {
    return Filter(
      filterName: map["filterName"],
      minDate: DateTime.parse(
        "${map["minDateYear"]}-${map["minDateMonth"]}-${map["minDateDay"]} ${map["minDateHour"]}:${map["minDateMinute"]}:00",
      ),
      maxDate: DateTime.parse(
        "${map["maxDateYear"]}-${map["maxDateMonth"]}-${map["maxDateDay"]} ${map["maxDateHour"]}:${map["maxDateMinute"]}:00",
      ),
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
      futureOnlySameLeague: map["futureOnlySameLeague"],
      futureSameEarlyHome: map["futureSameEarlyHome"],
      futureSameEarlyDraw: map["futureSameEarlyDraw"],
      futureSameEarlyAway: map["futureSameEarlyAway"],
      futureSameFinalHome: map["futureSameFinalHome"],
      futureSameFinalDraw: map["futureSameFinalDraw"],
      futureSameFinalAway: map["futureSameFinalAway"],
      futureMinHomeWinPercentage: map["futureMinHomeWinPercentage"],
      futureMinDrawPercentage: map["futureMinDrawPercentage"],
      futureMinAwayWinPercentage: map["futureMinAwayWinPercentage"],

      teams: map["teams"].map((t) => Team.fromMap(t)).toList(),
      leagues: map["leagues"].map((l) => League.fromMap(l)).toList(),
      folders: map["folders"].map((f) => Folder.fromMap(f)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "filterName": filterName,
      "minDateYear": minDate.year,
      "minDateMonth": minDate.month,
      "minDateDay": minDate.day,
      "minDateHour": minDate.hour,
      "minDateMinute": minDate.minute,
      "maxDateYear": maxDate.year,
      "maxDateMonth": maxDate.month,
      "maxDateDay": maxDate.day,
      "maxDateHour": maxDate.hour,
      "maxDateMinute": maxDate.minute,
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
      "futureOnlySameLeague": futureOnlySameLeague,
      "futureSameEarlyHome": futureSameEarlyHome,
      "futureSameEarlyDraw": futureSameEarlyDraw,
      "futureSameEarlyAway": futureSameEarlyAway,
      "futureSameFinalHome": futureSameFinalHome,
      "futureSameFinalDraw": futureSameFinalDraw,
      "futureSameFinalAway": futureSameFinalAway,
      "futureMinHomeWinPercentage": futureMinHomeWinPercentage,
      "futureMinDrawPercentage": futureMinDrawPercentage,
      "futureMinAwayWinPercentage": futureMinAwayWinPercentage,
      "teams": teams.map((t) => t.toMap()).toList(),
      "leagues": leagues.map((l) => l.toMap()).toList(),
      "folders": folders.map((f) => f.toMap()).toList(),
    };
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

  void update({int? pastYears, int? futureNextMinutes}) {
    if (pastYears != null) {
      minDate = DateTime.now().subtract(Duration(days: pastYears * 365));
    }

    maxDate = DateTime.now();
    this.futureNextMinutes = futureNextMinutes;
  }

  List<int> leaguesIds() {
    final List<int> leagueIds =
        leagues.map((l) => l.id != null ? [l.id!] : l.ids ?? []).expand((idList) => idList).toList();
    final List<int> folderIds =
        folders.expand((folder) => folder.leagues).where((l) => l.id != null).map((l) => l.id as int).toList();

    return leagueIds + folderIds;
  }

  List<int> teamsIds() {
    final List<int> teamIds = teams.map((t) => t.id).toList();

    return teamIds;
  }

  String whereClause({Record? futureRecord}) {
    fillInAllRangeOdds();

    late String whereClause = "WHERE finished = 1";

    whereClause += " AND MatchDate >= ${rawDateTime(minDate)}";
    whereClause += " AND MatchDate <= ${rawDateTime(maxDate)}";

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
      whereClause += " AND leagueId IN (${leaguesIds().join(', ')}) ";
    } else if (futureOnlySameLeague == 1 && futureRecord?.league.id != null) {
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

  String whereClauseFuture() {
    fillInAllRangeOdds();

    late String whereClause = "WHERE finished = 0";

    if (futureNextMinutes == null) {
      return whereClause;
    }

    final DateTime maxDate = DateTime.now().add(Duration(minutes: futureNextMinutes as int));

    whereClause += " AND MatchDate >= ${rawDateTime(DateTime.now())}";
    whereClause += " AND MatchDate <= ${rawDateTime(maxDate)}";

    if (filterFutureRecordsByTeams && teams.isNotEmpty) {
      final String teamsIdsString = teamsIds().join(", ");
      whereClause += " AND (homeTeamId IN ($teamsIdsString) OR awayTeamId IN ($teamsIdsString))";
    }

    if (filterFutureRecordsByLeagues && (leagues.isNotEmpty || folders.isNotEmpty)) {
      whereClause += " AND leagueId IN (${leaguesIds().join(', ')}) ";
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
