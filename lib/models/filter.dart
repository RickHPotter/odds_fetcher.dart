class Filter {
  DateTime? startDate;
  DateTime? endDate;
  String? league;
  String? leagueName;
  String? homeTeam;
  String? awayTeam;
  Duration? futureNext;

  Filter({
    this.startDate,
    this.endDate,
    this.league,
    this.leagueName,
    this.homeTeam,
    this.awayTeam,
    this.futureNext,
  });

  void updateFilter({int? pastYears, Duration? futureNext}) {
    startDate = DateTime.now().subtract(Duration(days: pastYears! * 365));
    endDate = DateTime.now();
    this.futureNext = futureNext;
  }
}
