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

  void updateFilter({int? pastYears, int? futureNextMinutes}) {
    if (pastYears != null) {
      startDate = DateTime.now().subtract(Duration(days: pastYears * 365));
    }

    endDate = DateTime.now();
    this.futureNextMinutes = futureNextMinutes;
  }
}
