class Record {
  int bettingHouse;
  final String matchDate;
  final String league;
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  int? homeFirstHalfScore;
  int? awayFirstHalfScore;
  final int homeSecondHalfScore;
  final int awaySecondHalfScore;
  final double earlyOdds1;
  final double earlyOddsX;
  final double earlyOdds2;
  double? finalOdds1;
  double? finalOddsX;
  double? finalOdds2;

  Record({
    required this.bettingHouse,
    required this.matchDate,
    required this.league,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeSecondHalfScore,
    required this.awaySecondHalfScore,
    required this.earlyOdds1,
    required this.earlyOddsX,
    required this.earlyOdds2,

    this.homeFirstHalfScore,
    this.awayFirstHalfScore,
    this.finalOdds1,
    this.finalOddsX,
    this.finalOdds2,
  });

  String get score {
    return "$homeFirstHalfScore:$homeSecondHalfScore - $awayFirstHalfScore:$awaySecondHalfScore";
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      bettingHouse: json['BettingHouse'],
      matchDate: json['MatchDate'],
      league: json['League'],
      leagueName: json['LeagueName'],
      homeTeam: json['HomeTeam'],
      awayTeam: json['AwayTeam'],
      homeFirstHalfScore: json['HomeFirstHalfScore'],
      homeSecondHalfScore: json['HomeSecondHalfScore'],
      awayFirstHalfScore: json['AwayFirstHalfScore'],
      awaySecondHalfScore: json['AwaySecondHalfScore'],
      earlyOdds1: json['EarlyOdds1'],
      earlyOddsX: json['EarlyOddsX'],
      earlyOdds2: json['EarlyOdds2'],
      finalOdds1: json['FinalOdds1'],
      finalOddsX: json['FinalOddsX'],
      finalOdds2: json['FinalOdds2'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'BettingHouse': bettingHouse,
      'MatchDate': matchDate,
      'League': league,
      'LeagueName': leagueName,
      'HomeTeam': homeTeam,
      'AwayTeam': awayTeam,
      'HomeFirstHalfScore': homeFirstHalfScore,
      'HomeSecondHalfScore': homeSecondHalfScore,
      'AwayFirstHalfScore': awayFirstHalfScore,
      'AwaySecondHalfScore': awaySecondHalfScore,
      'EarlyOdds1': earlyOdds1,
      'EarlyOddsX': earlyOddsX,
      'EarlyOdds2': earlyOdds2,
      'FinalOdds1': finalOdds1,
      'FinalOddsX': finalOddsX,
      'FinalOdds2': finalOdds2,
    };
  }
}
