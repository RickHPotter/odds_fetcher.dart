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
  final int? homeFirstHalfScore;
  final int? awayFirstHalfScore;
  final int? homeSecondHalfScore;
  final int? awaySecondHalfScore;
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
    this.homeFirstHalfScore,
    this.awayFirstHalfScore,
    this.homeSecondHalfScore,
    this.awaySecondHalfScore,
    this.homeWin,
    this.draw,
    this.awayWin,
    this.finished = true,
  });

  String get firstHalfScore {
    if (homeFirstHalfScore == null || awayFirstHalfScore == null) {
      return "";
    }

    return "$homeFirstHalfScore - $awayFirstHalfScore";
  }

  String get secondHalfScore {
    if (homeSecondHalfScore == null || awaySecondHalfScore == null) {
      return "";
    }

    return "$homeSecondHalfScore - $awaySecondHalfScore";
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
      homeFirstHalfScore: map["homeFirstHalfScore"],
      awayFirstHalfScore: map["awayFirstHalfScore"],
      homeSecondHalfScore: map["homeSecondHalfScore"],
      awaySecondHalfScore: map["awaySecondHalfScore"],
      homeWin: map["homeWin"],
      draw: map["draw"],
      awayWin: map["awayWin"],
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
      "homeFirstHalfScore": homeFirstHalfScore,
      "homeSecondHalfScore": homeSecondHalfScore,
      "awayFirstHalfScore": awayFirstHalfScore,
      "awaySecondHalfScore": awaySecondHalfScore,
      "earlyOdds1": earlyOdds1,
      "earlyOddsX": earlyOddsX,
      "earlyOdds2": earlyOdds2,
      "finalOdds1": finalOdds1,
      "finalOddsX": finalOddsX,
      "finalOdds2": finalOdds2,
      "finished": finished == true ? 1 : 0,
    };
  }

  static Future<void> updatePivotRecord(Record pivotRecord, Filter filter) async {
    if (pivotRecord.pastRecordsCount <= 0) {
      Record? updatedPivotRecord = await DatabaseService.fetchPivotRecord(pivotRecord, filter);
      if (updatedPivotRecord != null) pivotRecord = updatedPivotRecord;
    }
  }

  static Map<String, double> calculateScoreMatchPercentages(Record futureRecord, List<Record> records) {
    if (futureRecord.pastRecordsCount > 0) {
      return {
        "homeWins": futureRecord.homeWinPercentage,
        "draws": futureRecord.drawPercentage,
        "awayWins": futureRecord.awayWinPercentage,
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

  static Map<String, double> calculateGoalsMatchPercentages(Record futureRecord, List<Record> records) {
    if (futureRecord.pastRecordsCount > 0) {
      double underFirstPercentage = 100 - futureRecord.overFirstPercentage;
      double underSecondPercentage = 100 - futureRecord.overSecondPercentage;
      double underFullPercentage = 100 - futureRecord.overFullPercentage;

      return {
        "overFirst": futureRecord.overFirstPercentage,
        "underFirst": underFirstPercentage,

        "overSecond": futureRecord.overSecondPercentage,
        "underSecond": underSecondPercentage,

        "overFull": futureRecord.overFullPercentage,
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
      int firstHalfScore = (record.homeFirstHalfScore ?? 0) + (record.awayFirstHalfScore ?? 0);
      int secondHalfScore = (record.homeSecondHalfScore ?? 0) + (record.awaySecondHalfScore ?? 0);

      if (firstHalfScore > 1) {
        overFirst++;
      } else if (secondHalfScore - firstHalfScore > 1) {
        overSecond++;
      } else if (secondHalfScore > 3) {
        overFull++;
      }
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
