import 'package:intl/intl.dart';
import 'package:odds_fetcher/models/folder.dart';
import 'package:odds_fetcher/models/league.dart';
import 'package:odds_fetcher/models/team.dart';

class Filter {
  int? id;
  String filterName;
  DateTime startDate;
  DateTime endDate;

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

  int? minGoalsFirstHalf;
  int? maxGoalsFirstHalf;
  int? minGoalsSecondHalf;
  int? maxGoalsSecondHalf;
  int? minGoalsFullTime;
  int? maxGoalsFullTime;

  int? futureNextMinutes;
  int? futureDismissNoEarlyOdds;
  int? futureDismissNoFinalOdds;
  int? futureDismissNoHistory;
  int? futureOnlySameLeague;
  int? futureSameEarlyHome;
  int? futureSameEarlyDraw;
  int? futureSameEarlyAway;
  int? futureSameFinalHome;
  int? futureSameFinalDraw;
  int? futureSameFinalAway;
  int? futureMinHomeWinPercentage;
  int? futureMinDrawPercentage;
  int? futureMinAwayWinPercentage;

  List<Team>? teams;
  List<League>? leagues;
  List<Folder>? folders;

  Filter({
    required this.filterName,
    required this.startDate,
    required this.endDate,
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
    this.teams,
    this.leagues,
    this.folders,
    this.futureNextMinutes,
  });

  factory Filter.fromMap(Map<String, dynamic> map) {
    return Filter(
      filterName: map["filterName"],
      startDate: DateTime.parse(
        "${map["minDateYear"]}-${map["minDateMonth"]}-${map["minDateDay"]} ${map["minDateHour"]}:${map["minDateMinute"]}:00",
      ),
      endDate: DateTime.parse(
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
      folders: map["folders"].map((f) => Folder.fromMap(f)).toList(),
      leagues: map["leagues"].map((l) => League.fromMap(l)).toList(),
    );
  }

  void update({int? pastYears, int? futureNextMinutes}) {
    if (pastYears != null) {
      startDate = DateTime.now().subtract(Duration(days: pastYears * 365));
    }

    endDate = DateTime.now();
    this.futureNextMinutes = futureNextMinutes;
  }

  String whereClause({
    double? early1,
    double? earlyX,
    double? early2,
    double? final1,
    double? finalX,
    double? final2,
  }) {
    late String whereClause = "WHERE finished = 1";
    whereClause +=
        " AND (MatchDateYear > ${startDate.year} OR (MatchDateYear >= ${startDate.year} AND MatchDateMonth >= ${startDate.month} AND MatchDateDay >= ${startDate.day}))";
    whereClause +=
        " AND MatchDateYear <= ${endDate.year} AND MatchDateMonth <= ${endDate.month} AND MatchDateDay <= ${endDate.day}";

    if (early1 != null) {
      whereClause += " AND earlyOdds1 = $early1";
    }

    if (earlyX != null) {
      whereClause += " AND earlyOddsX = $earlyX";
    }

    if (early2 != null) {
      whereClause += " AND earlyOdds2 = $early2";
    }

    if (final1 != null) {
      whereClause += " AND finalOdds1 = $final1";
    }

    if (finalX != null) {
      whereClause += " AND finalOddsX = $finalX";
    }

    if (final2 != null) {
      whereClause += " AND finalOdds2 = $final2";
    }

    return whereClause;
  }

  String whereClauseFuture() {
    late String whereClause = "WHERE finished = 0";

    if (futureNextMinutes == null) {
      return whereClause;
    }

    final date = DateTime.now().add(
      Duration(minutes: futureNextMinutes as int),
    );

    final minDate = DateFormat("yyyyMMddHm").format(DateTime.now());
    final maxDate =
        "${date.year.toString().padLeft(4, '0')}"
        "${date.month.toString().padLeft(2, '0')}"
        "${date.day.toString().padLeft(2, '0')}"
        "${date.hour.toString().padLeft(2, '0')}"
        "${date.minute.toString().padLeft(2, '0')}";

    whereClause +=
        " AND printf('%04d%02d%02d%02d%02d', MatchDateYear, MatchDateMonth, MatchDateDay, MatchDateHour, MatchDateMinute) >= '$minDate'";
    whereClause +=
        " AND printf('%04d%02d%02d%02d%02d', MatchDateYear, MatchDateMonth, MatchDateDay, MatchDateHour, MatchDateMinute) <= '$maxDate'";

    return whereClause;
  }
}
