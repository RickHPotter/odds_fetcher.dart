import "package:odds_fetcher/models/league.dart";

class Folder {
  final int id;
  final String name;
  late List<League> leagues = [];

  Folder({required this.id, required this.name, required this.leagues});

  factory Folder.fromMap(Map<String, dynamic> map) {
    final List<String> leagueIds = (map["leagueIds"] ?? "").split(",");
    final List<int> ids = leagueIds.where((e) => e.trim().isNotEmpty).map(int.parse).toList();

    final League league = League(code: map["leagueCode"], id: map["leagueId"], name: map["leagueName"], ids: ids);

    return Folder(id: map["id"], name: map["folderName"], leagues: [league]);
  }

  @override
  String toString() {
    return "Pasta";
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "folderName": name};
  }

  Folder copyWith() {
    return Folder(id: id, name: name, leagues: leagues);
  }
}
