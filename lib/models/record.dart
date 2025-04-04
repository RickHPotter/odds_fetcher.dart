import "package:odds_fetcher/models/filter.dart" show Filter;
import "package:odds_fetcher/models/league.dart" show League;
import "package:odds_fetcher/models/team.dart" show Team;
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/utils/date_utils.dart" show parseRawDateTime, rawDateTime;

class Record {
  final int? id;
  final int bettingHouseId;
  final DateTime matchDate;
  final League league;
  final Team homeTeam;
  final Team awayTeam;
  final double? earlyOdds1;
  final double? earlyOddsX;
  final double? earlyOdds2;
  final double? finalOdds1;
  final double? finalOddsX;
  final double? finalOdds2;
  final int? homeHalfTimeScore;
  final int? awayHalfTimeScore;
  final int? homeFullTimeScore;
  final int? awayFullTimeScore;
  final int? homeWin;
  final int? draw;
  final int? awayWin;
  final bool? finished;

  late int pastRecordsCount = 0;
  late double homeWinPercentage = 0.00;
  late double drawPercentage = 0.00;
  late double awayWinPercentage = 0.00;
  late double overFirstPercentage = 0.00;
  late double overSecondPercentage = 0.00;
  late double overFullPercentage = 0.00;

  Record({
    this.id,
    required this.bettingHouseId,
    required this.matchDate,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.earlyOdds1,
    this.earlyOddsX,
    this.earlyOdds2,
    this.finalOdds1,
    this.finalOddsX,
    this.finalOdds2,
    this.homeHalfTimeScore,
    this.awayHalfTimeScore,
    this.homeFullTimeScore,
    this.awayFullTimeScore,
    this.homeWin,
    this.draw,
    this.awayWin,
    this.finished = true,
  });

  String get halfTimeScore {
    if (homeHalfTimeScore == null || awayHalfTimeScore == null) {
      return "";
    }

    return "$homeHalfTimeScore - $awayHalfTimeScore";
  }

  String get fullTimeScore {
    if (homeFullTimeScore == null || awayFullTimeScore == null) {
      return "";
    }

    return "$homeFullTimeScore - $awayFullTimeScore";
  }

  bool anyPercentageHigherThan(double percentage) {
    return homeWinPercentage > percentage || drawPercentage > percentage || awayWinPercentage > percentage;
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    DateTime formattedDateString = parseRawDateTime(map["matchDate"].toString());

    return Record(
      id: map["id"],
      bettingHouseId: map["bettingHouseId"] ?? 17, // Default to 17
      matchDate: formattedDateString,
      league: League(id: map["leagueId"], code: map["leagueCode"], name: map["leagueName"]),
      homeTeam: Team(id: map["homeTeamId"], name: map["homeTeamName"]),
      awayTeam: Team(id: map["awayTeamId"], name: map["awayTeamName"]),
      earlyOdds1: map["earlyOdds1"] != null ? double.tryParse(map["earlyOdds1"]) : null,
      earlyOddsX: map["earlyOddsX"] != null ? double.tryParse(map["earlyOddsX"]) : null,
      earlyOdds2: map["earlyOdds2"] != null ? double.tryParse(map["earlyOdds2"]) : null,
      finalOdds1: map["finalOdds1"] != null ? double.tryParse(map["finalOdds1"]) : null,
      finalOddsX: map["finalOddsX"] != null ? double.tryParse(map["finalOddsX"]) : null,
      finalOdds2: map["finalOdds2"] != null ? double.tryParse(map["finalOdds2"]) : null,
      homeHalfTimeScore: map["homeHalfTimeScore"],
      awayHalfTimeScore: map["awayHalfTimeScore"],
      homeFullTimeScore: map["homeFullTimeScore"],
      awayFullTimeScore: map["awayFullTimeScore"],
      homeWin: map["homeWin"] ?? 0,
      draw: map["draw"] ?? 0,
      awayWin: map["awayWin"] ?? 0,
      finished: map["finished"].toString() == "1",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bettingHouseId": bettingHouseId,
      "matchDate": rawDateTime(matchDate),
      "leagueId": league.id,
      "homeTeamId": homeTeam.id,
      "awayTeamId": awayTeam.id,
      "earlyOdds1": earlyOdds1,
      "earlyOddsX": earlyOddsX,
      "earlyOdds2": earlyOdds2,
      "finalOdds1": finalOdds1,
      "finalOddsX": finalOddsX,
      "finalOdds2": finalOdds2,
      "homeHalfTimeScore": homeHalfTimeScore,
      "homeFullTimeScore": homeFullTimeScore,
      "awayHalfTimeScore": awayHalfTimeScore,
      "awayFullTimeScore": awayFullTimeScore,
      "homeWin": homeWin ?? 0,
      "draw": draw ?? 0,
      "awayWin": awayWin ?? 0,
      "finished": finished == true ? 1 : 0,
    };
  }

  static Future<void> updatePivotRecord(Record pivotRecord, Filter filter) async {
    if (pivotRecord.pastRecordsCount <= 0) {
      Record? updatedPivotRecord = await DatabaseService.fetchPivotRecord(pivotRecord, filter);
      if (updatedPivotRecord != null) pivotRecord = updatedPivotRecord;
    }
  }

  static Map<String, double> calculateScoreMatchPercentages(Record pivotRecord, List<Record> records) {
    if (pivotRecord.pastRecordsCount > 0) {
      return {
        "homeWins": pivotRecord.homeWinPercentage,
        "draws": pivotRecord.drawPercentage,
        "awayWins": pivotRecord.awayWinPercentage,
      };
    }

    if (records.isEmpty) {
      return {"homeWins": 0.0, "draws": 0.0, "awayWins": 0.0};
    }

    // TODO: delegate this sql
    final int recordsCount = records.length;
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;

    for (Record record in records) {
      if (record.homeWin == 1) {
        homeWins++;
      } else if (record.draw == 1) {
        draws++;
      } else if (record.awayWin == 1) {
        awayWins++;
      }
    }

    double homeWinPercentage = homeWins / recordsCount * 100;
    double drawPercentage = draws / recordsCount * 100;
    double awayWinPercentage = awayWins / recordsCount * 100;

    return {"homeWins": homeWinPercentage, "draws": drawPercentage, "awayWins": awayWinPercentage};
  }

  static Map<String, double> calculateGoalsMatchPercentages(Record pivotRecord, List<Record> records, Filter filter) {
    if (pivotRecord.pastRecordsCount > 0) {
      double underFirstPercentage = 100 - pivotRecord.overFirstPercentage;
      double underSecondPercentage = 100 - pivotRecord.overSecondPercentage;
      double underFullPercentage = 100 - pivotRecord.overFullPercentage;

      return {
        "overFirst": pivotRecord.overFirstPercentage,
        "underFirst": underFirstPercentage,

        "overSecond": pivotRecord.overSecondPercentage,
        "underSecond": underSecondPercentage,

        "overFull": pivotRecord.overFullPercentage,
        "underFull": underFullPercentage,
      };
    }

    if (records.isEmpty) {
      return {
        "underFirst": 0.0,
        "overFirst": 0.0,
        "underSecond": 0.0,
        "overSecond": 0.0,
        "underFull": 0.0,
        "overFull": 0.0,
      };
    }

    // TODO: delegate this sql
    final int recordsCount = records.length;
    int overFirst = 0;
    int overSecond = 0;
    int overFull = 0;

    for (Record record in records) {
      int firstHalfGoals = (record.homeHalfTimeScore ?? 0) + (record.awayHalfTimeScore ?? 0);
      int fullTimeGoals = (record.homeFullTimeScore ?? 0) + (record.awayFullTimeScore ?? 0);
      int secondHalfGoals = fullTimeGoals - firstHalfGoals;

      if (firstHalfGoals > filter.milestoneGoalsFirstHalf) overFirst++;
      if (secondHalfGoals > filter.milestoneGoalsSecondHalf) overSecond++;
      if (fullTimeGoals > filter.milestoneGoalsFullTime) overFull++;
    }

    double overFirstPercentage = (overFirst / recordsCount) * 100;
    double overSecondPercentage = (overSecond / recordsCount) * 100;
    double overFullPercentage = (overFull / recordsCount) * 100;

    double underFirstPercentage = 100 - overFirstPercentage;
    double underSecondPercentage = 100 - overSecondPercentage;
    double underFullPercentage = 100 - overFullPercentage;

    return {
      "overFirst": overFirstPercentage,
      "underFirst": underFirstPercentage,

      "overSecond": overSecondPercentage,
      "underSecond": underSecondPercentage,

      "overFull": overFullPercentage,
      "underFull": underFullPercentage,
    };
  }
}

enum Odds { earlyOdds1, earlyOddsX, earlyOdds2, finalOdds1, finalOddsX, finalOdds2 }

extension OddsExtension on Odds {
  String get name {
    switch (this) {
      case Odds.earlyOdds1:
        return "Early Home";
      case Odds.earlyOddsX:
        return "Early Draw";
      case Odds.earlyOdds2:
        return "Early Away";
      case Odds.finalOdds1:
        return "Final Home";
      case Odds.finalOddsX:
        return "Final Draw";
      case Odds.finalOdds2:
        return "Final Away";
    }
  }

  String get shortName {
    switch (this) {
      case Odds.earlyOdds1:
        return "E1";
      case Odds.earlyOddsX:
        return "EX";
      case Odds.earlyOdds2:
        return "E2";
      case Odds.finalOdds1:
        return "F1";
      case Odds.finalOddsX:
        return "FX";
      case Odds.finalOdds2:
        return "F2";
    }
  }
}
