import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/team.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/utils/date_utils.dart" show parseRawDateTime, rawDateTime;

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
  int pivotNextMinutes;
  int? pastYears;
  DateTime? specificMinDate;
  DateTime? specificMaxDate;

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

  bool pivotDismissNoEarlyOdds;
  bool pivotDismissNoFinalOdds;

  bool pivotOnlySameLeague;

  bool pivotSameEarlyHome;
  bool pivotSameEarlyDraw;
  bool pivotSameEarlyAway;
  bool pivotSameFinalHome;
  bool pivotSameFinalDraw;
  bool pivotSameFinalAway;

  int milestoneGoalsFirstHalf;
  int milestoneGoalsSecondHalf;
  int milestoneGoalsFullTime;

  int pivotMinOverFirstPercentage;
  int pivotMinOverSecondPercentage;
  int pivotMinOverFullPercentage;

  int pivotMinHomeWinPercentage;
  int pivotMinDrawPercentage;
  int pivotMinAwayWinPercentage;

  bool filterPastRecordsByTeams;
  bool filterPivotRecordsByTeams;
  bool filterPastRecordsByLeagues;
  bool filterPivotRecordsByLeagues;
  bool filterPastRecordsBySpecificOdds;
  bool filterPivotRecordsBySpecificOdds;

  List<Team> teams;
  List<League> leagues;
  List<Folder> folders;

  bool showPivotOptions;

  Filter({
    this.id,
    required this.filterName,
    this.pivotNextMinutes = 60,
    this.pastYears = 1,
    this.specificMinDate,
    this.specificMaxDate,
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
    this.milestoneGoalsFirstHalf = 1,
    this.milestoneGoalsSecondHalf = 1,
    this.milestoneGoalsFullTime = 3,
    this.pivotDismissNoEarlyOdds = true,
    this.pivotDismissNoFinalOdds = false,
    this.pivotOnlySameLeague = false,
    this.pivotSameEarlyHome = true,
    this.pivotSameEarlyDraw = true,
    this.pivotSameEarlyAway = true,
    this.pivotSameFinalHome = false,
    this.pivotSameFinalDraw = false,
    this.pivotSameFinalAway = false,
    this.pivotMinHomeWinPercentage = 52,
    this.pivotMinDrawPercentage = 52,
    this.pivotMinAwayWinPercentage = 52,
    this.pivotMinOverFirstPercentage = 0,
    this.pivotMinOverSecondPercentage = 0,
    this.pivotMinOverFullPercentage = 0,
    this.filterPastRecordsByTeams = true,
    this.filterPivotRecordsByTeams = true,
    this.filterPastRecordsByLeagues = true,
    this.filterPivotRecordsByLeagues = true,
    this.filterPastRecordsBySpecificOdds = true,
    this.filterPivotRecordsBySpecificOdds = false,

    required this.teams,
    required this.leagues,
    required this.folders,

    this.showPivotOptions = true,
  }) : assert(pastYears != null || specificMinDate != null || specificMaxDate != null);

  Filter copyWith() {
    Filter filter = Filter.fromMap(toMap());

    // filter.bettingHouses = List<BettingHouse>.from(bettingHouses.map((bh) => bh));
    filter.teams = List.from(teams.map((team) => team.copyWith()));
    filter.leagues = List.from(leagues.map((league) => league.copyWith()));
    filter.folders = List.from(folders.map((folder) => folder.copyWith()));

    return filter;
  }

  factory Filter.fromMap(Map<String, dynamic> map) {
    DateTime? formattedMinDateString =
        map["specificMinDate"] == null ? null : parseRawDateTime(map["specificMinDate"].toString());
    DateTime? formattedMaxDateString =
        map["specificMaxDate"] == null ? null : parseRawDateTime(map["specificMaxDate"].toString());

    return Filter(
      id: map["id"],
      filterName: map["filterName"],
      pivotNextMinutes: map["pivotNextMinutes"],
      pastYears: map["pastYears"],
      specificMinDate: formattedMinDateString,
      specificMaxDate: formattedMaxDateString,

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

      pivotDismissNoEarlyOdds: map["pivotDismissNoEarlyOdds"] == 1,
      pivotDismissNoFinalOdds: map["pivotDismissNoFinalOdds"] == 1,

      pivotOnlySameLeague: map["pivotOnlySameLeague"] == 1,

      pivotSameEarlyHome: map["pivotSameEarlyHome"] == 1,
      pivotSameEarlyDraw: map["pivotSameEarlyDraw"] == 1,
      pivotSameEarlyAway: map["pivotSameEarlyAway"] == 1,
      pivotSameFinalHome: map["pivotSameFinalHome"] == 1,
      pivotSameFinalDraw: map["pivotSameFinalDraw"] == 1,
      pivotSameFinalAway: map["pivotSameFinalAway"] == 1,

      milestoneGoalsFirstHalf: map["milestoneGoalsFirstHalf"],
      milestoneGoalsSecondHalf: map["milestoneGoalsSecondHalf"],
      milestoneGoalsFullTime: map["milestoneGoalsFullTime"],

      pivotMinOverFirstPercentage: map["pivotMinOverFirstPercentage"],
      pivotMinOverSecondPercentage: map["pivotMinOverSecondPercentage"],
      pivotMinOverFullPercentage: map["pivotMinOverFullPercentage"],

      pivotMinHomeWinPercentage: map["pivotMinHomeWinPercentage"],
      pivotMinDrawPercentage: map["pivotMinDrawPercentage"],
      pivotMinAwayWinPercentage: map["pivotMinAwayWinPercentage"],

      filterPastRecordsByTeams: map["filterPastRecordsByTeams"] == 1,
      filterPivotRecordsByTeams: map["filterPivotRecordsByTeams"] == 1,
      filterPastRecordsByLeagues: map["filterPastRecordsByLeagues"] == 1,
      filterPivotRecordsByLeagues: map["filterPivotRecordsByLeagues"] == 1,
      filterPastRecordsBySpecificOdds: map["filterPastRecordsBySpecificOdds"] == 1,
      filterPivotRecordsBySpecificOdds: map["filterPivotRecordsBySpecificOdds"] == 1,

      teams: map["teams"] == null ? [] : map["teams"].map((t) => Team.fromMap(t)).toList(),
      leagues: map["leagues"] == null ? [] : map["leagues"].map((l) => League.fromMap(l)).toList(),
      folders: map["folders"] == null ? [] : map["folders"].map((f) => Folder.fromMap(f)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "filterName": filterName,
      "pivotNextMinutes": pivotNextMinutes,
      "pastYears": pastYears,
      "specificMinDate": specificMinDate == null ? null : rawDateTime(specificMinDate as DateTime),
      "specificMaxDate": specificMaxDate == null ? null : rawDateTime(specificMaxDate as DateTime),

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

      "pivotDismissNoEarlyOdds": pivotDismissNoEarlyOdds ? 1 : 0,
      "pivotDismissNoFinalOdds": pivotDismissNoFinalOdds ? 1 : 0,

      "pivotOnlySameLeague": pivotOnlySameLeague ? 1 : 0,

      "pivotSameEarlyHome": pivotSameEarlyHome ? 1 : 0,
      "pivotSameEarlyDraw": pivotSameEarlyDraw ? 1 : 0,
      "pivotSameEarlyAway": pivotSameEarlyAway ? 1 : 0,
      "pivotSameFinalHome": pivotSameFinalHome ? 1 : 0,
      "pivotSameFinalDraw": pivotSameFinalDraw ? 1 : 0,
      "pivotSameFinalAway": pivotSameFinalAway ? 1 : 0,

      "milestoneGoalsFirstHalf": milestoneGoalsFirstHalf,
      "milestoneGoalsSecondHalf": milestoneGoalsSecondHalf,
      "milestoneGoalsFullTime": milestoneGoalsFullTime,

      "pivotMinOverFirstPercentage": pivotMinOverFirstPercentage,
      "pivotMinOverSecondPercentage": pivotMinOverSecondPercentage,
      "pivotMinOverFullPercentage": pivotMinOverFullPercentage,

      "pivotMinHomeWinPercentage": pivotMinHomeWinPercentage,
      "pivotMinDrawPercentage": pivotMinDrawPercentage,
      "pivotMinAwayWinPercentage": pivotMinAwayWinPercentage,

      "filterPastRecordsByTeams": filterPastRecordsByTeams ? 1 : 0,
      "filterPivotRecordsByTeams": filterPivotRecordsByTeams ? 1 : 0,
      "filterPastRecordsByLeagues": filterPastRecordsByLeagues ? 1 : 0,
      "filterPivotRecordsByLeagues": filterPivotRecordsByLeagues ? 1 : 0,
      "filterPastRecordsBySpecificOdds": filterPastRecordsBySpecificOdds ? 1 : 0,
      "filterPivotRecordsBySpecificOdds": filterPivotRecordsBySpecificOdds ? 1 : 0,
    };
  }

  static Filter base(String filterName, {showPivotOptions = true}) {
    return Filter(filterName: filterName, teams: [], leagues: [], folders: [], showPivotOptions: showPivotOptions);
  }

  DateTime minDate() {
    if (pastYears != null) {
      return DateTime.now().subtract(Duration(days: (pastYears as int) * 365));
    } else if (specificMinDate != null) {
      return specificMinDate as DateTime;
    } else {
      return DateTime.parse("2008-01-01");
    }
  }

  DateTime maxDate() {
    if (pastYears != null) {
      return DateTime.now();
    } else if (specificMaxDate != null) {
      return specificMaxDate as DateTime;
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

  bool anyPivotMinPercent() {
    return pivotMinHomeWinPercentage > 0 ||
        pivotMinDrawPercentage > 0 ||
        pivotMinAwayWinPercentage > 0 ||
        pivotMinOverFirstPercentage > 0 ||
        pivotMinOverSecondPercentage > 0 ||
        pivotMinOverFullPercentage > 0;
  }

  bool allPivotMinPercentSpecificValue(int percentage) {
    return pivotMinHomeWinPercentage == percentage &&
        pivotMinDrawPercentage == percentage &&
        pivotMinAwayWinPercentage == percentage;
  }

  void updateOdds() {
    fillInAllRangeOdds();

    if (minEarlyHome != null && maxEarlyHome == null) pivotSameEarlyHome = false;
    if (minEarlyDraw != null && maxEarlyDraw == null) pivotSameEarlyDraw = false;
    if (minEarlyAway != null && maxEarlyAway == null) pivotSameEarlyAway = false;
    if (minFinalHome != null && maxFinalHome == null) pivotSameFinalHome = false;
    if (minFinalDraw != null && maxFinalDraw == null) pivotSameFinalDraw = false;
    if (minFinalAway != null && maxFinalAway == null) pivotSameFinalAway = false;

    if (pivotSameEarlyHome) {
      minEarlyHome = null;
      maxEarlyHome = null;
    }

    if (pivotSameEarlyDraw) {
      minEarlyDraw = null;
      maxEarlyDraw = null;
    }
    if (pivotSameEarlyAway) {
      minEarlyAway = null;
      maxEarlyAway = null;
    }
    if (pivotSameFinalHome) {
      minFinalHome = null;
      maxFinalHome = null;
    }
    if (pivotSameFinalDraw) {
      minFinalDraw = null;
      maxFinalDraw = null;
    }
    if (pivotSameFinalAway) {
      minFinalAway = null;
      maxFinalAway = null;
    }
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

  Future<String> whereClause({Record? pivotRecord}) async {
    fillInAllRangeOdds();

    late String whereClause = "WHERE finished = 1";

    whereClause += " AND MatchDate >= ${rawDateTime(minDate())}";
    whereClause += " AND MatchDate <= ${rawDateTime(maxDate())}";

    if (pivotSameEarlyHome && pivotRecord?.earlyOdds1 != null) {
      whereClause += " AND earlyOdds1 = ${pivotRecord?.earlyOdds1}";
    }

    if (pivotSameEarlyDraw && pivotRecord?.earlyOddsX != null) {
      whereClause += " AND earlyOddsX = ${pivotRecord?.earlyOddsX}";
    }

    if (pivotSameEarlyAway && pivotRecord?.earlyOdds2 != null) {
      whereClause += " AND earlyOdds2 = ${pivotRecord?.earlyOdds2}";
    }

    if (pivotSameFinalHome && pivotRecord?.finalOdds1 != null) {
      whereClause += " AND finalOdds1 = ${pivotRecord?.finalOdds1}";
    }

    if (pivotSameFinalDraw && pivotRecord?.finalOddsX != null) {
      whereClause += " AND finalOddsX = ${pivotRecord?.finalOddsX}";
    }

    if (pivotSameFinalAway && pivotRecord?.finalOdds2 != null) {
      whereClause += " AND finalOdds2 = ${pivotRecord?.finalOdds2}";
    }

    if (filterPastRecordsByTeams && teams.isNotEmpty) {
      final String teamsIdsString = teamsIds().join(", ");
      whereClause += " AND (homeTeamId IN ($teamsIdsString) OR awayTeamId IN ($teamsIdsString))";
    }

    if (filterPastRecordsByLeagues && (leagues.isNotEmpty || folders.isNotEmpty)) {
      final List<int> leagueIdsList = await leaguesIds();
      whereClause += " AND leagueId IN (${leagueIdsList.join(', ')}) ";
    } else if (pivotOnlySameLeague && pivotRecord?.league.id != null) {
      whereClause += " AND leagueId = ${pivotRecord?.league.id}";
    }

    if (pivotDismissNoEarlyOdds) {
      whereClause += " AND earlyOdds1 IS NOT NULL AND earlyOddsX IS NOT NULL AND earlyOdds2 IS NOT NULL";
    }

    if (pivotDismissNoFinalOdds) {
      whereClause += " AND finalOdds1 IS NOT NULL AND finalOddsX IS NOT NULL AND finalOdds2 IS NOT NULL";
    }

    if (filterPastRecordsBySpecificOdds) {
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
    }

    return whereClause;
  }

  Future<String> whereClausePivot({bool unfinishedOnly = true}) async {
    fillInAllRangeOdds();

    late String whereClause = unfinishedOnly ? "WHERE finished = 0" : "WHERE 1 = 1";

    final DateTime pivotMaxDate = DateTime.now().add(Duration(minutes: pivotNextMinutes));

    whereClause += " AND MatchDate >= ${rawDateTime(DateTime.now())}";
    whereClause += " AND MatchDate <= ${rawDateTime(pivotMaxDate)}";

    print(whereClause);

    if (filterPivotRecordsByTeams && teams.isNotEmpty) {
      final String teamsIdsString = teamsIds().join(", ");
      whereClause += " AND (homeTeamId IN ($teamsIdsString) OR awayTeamId IN ($teamsIdsString))";
    }

    if (filterPivotRecordsByLeagues && (leagues.isNotEmpty || folders.isNotEmpty)) {
      final List<int> leagueIdsList = await leaguesIds();
      whereClause += " AND leagueId IN (${leagueIdsList.join(', ')}) ";
    }

    if (pivotDismissNoEarlyOdds) {
      whereClause += " AND earlyOdds1 IS NOT NULL AND earlyOddsX IS NOT NULL AND earlyOdds2 IS NOT NULL";
    }

    if (pivotDismissNoFinalOdds) {
      whereClause += " AND finalOdds1 IS NOT NULL AND finalOddsX IS NOT NULL AND finalOdds2 IS NOT NULL";
    }

    if (filterPivotRecordsBySpecificOdds) {
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
    }

    return whereClause;
  }
}
