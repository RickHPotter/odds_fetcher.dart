class Filter {
  DateTime startDate;
  DateTime endDate;
  String league;
  String leagueName;
  String homeTeam;
  String awayTeam;

  Filter({
    required this.startDate,
    required this.endDate,
    required this.league,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
  });
}
