class League {
  final int id;
  final String code;
  final String name;
  late List<int> ids;

  League({required this.code, required this.id, required this.name, this.ids = const []});

  factory League.fromMap(Map<String, dynamic> map) {
    List<int> ids = map["ids"].toString().split(",").map((id) => int.parse(id)).toList();
    return League(id: map["id"], code: map["leagueCode"], name: map["leagueName"], ids: ids);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{"id": id, "leagueCode": code, "leagueName": name};
  }

  League copyWith() {
    return League.fromMap(toMap());
  }
}
