import "package:odds_fetcher/models/league.dart" show League;
import "package:odds_fetcher/models/team.dart" show Team;

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
  final bool? finished;

  late int? pastRecordsCount = 0;
  late double? homeWinPercentage = 0.00;
  late double? drawPercentage = 0.00;
  late double? awayWinPercentage = 0.00;

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
    if (homeWinPercentage == null || drawPercentage == null || awayWinPercentage == null) {
      return false;
    }

    return homeWinPercentage as double > percentage ||
        drawPercentage as double > percentage ||
        awayWinPercentage as double > percentage;
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map["id"],
      bettingHouseId: map["bettingHouseId"] ?? 17, // Default to 17
      matchDate: DateTime(
        map["matchDateYear"],
        map["matchDateMonth"],
        map["matchDateDay"],
        map["matchDateHour"] ?? 0,
        map["matchDateMinute"] ?? 0,
      ),
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
      finished: map["finished"].toString() == "1",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bettingHouseId": bettingHouseId,
      "matchDateYear": matchDate.year,
      "matchDateMonth": matchDate.month,
      "matchDateDay": matchDate.day,
      "matchDateHour": matchDate.hour,
      "matchDateMinute": matchDate.minute,
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

  static Map<String, double> calculateScoreMatchPercentages(List<Record> records) {
    if (records.isEmpty) return {"homeWins": 0, "draws": 0, "awayWins": 0};

    int totalMatches = records.length;
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;

    for (var record in records) {
      int home = record.homeSecondHalfScore ?? 0;
      int away = record.awaySecondHalfScore ?? 0;

      if (home == away) {
        draws++;
      } else if (home > away) {
        homeWins++;
      } else {
        awayWins++;
      }
    }

    return {
      "homeWins": ((homeWins / totalMatches) * 100).roundToDouble(),
      "draws": ((draws / totalMatches) * 100).roundToDouble(),
      "awayWins": ((awayWins / totalMatches) * 100).roundToDouble(),
    };
  }

  static Map<String, double> calculateGoalsMatchPercentages(List<Record> records) {
    if (records.isEmpty) return {"homeWins": 0, "draws": 0, "awayWins": 0};

    int totalMatches = records.length;
    int underHalf = 0;
    int overHalf = 0;
    int underFull = 0;
    int overFull = 0;

    for (var record in records) {
      int half = (record.homeFirstHalfScore ?? 0) + (record.awayFirstHalfScore ?? 0);
      int full = (record.homeSecondHalfScore ?? 0) + (record.awaySecondHalfScore ?? 0);

      if (half < 1) {
        underHalf++;
      } else {
        overHalf++;
      }

      if (full < 2) {
        underFull++;
      } else {
        overFull++;
      }
    }

    return {
      "underHalf": ((underHalf / totalMatches) * 100).roundToDouble(),
      "overHalf": ((overHalf / totalMatches) * 100).roundToDouble(),
      "underFull": ((underFull / totalMatches) * 100).roundToDouble(),
      "overFull": ((overFull / totalMatches) * 100).roundToDouble(),
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
