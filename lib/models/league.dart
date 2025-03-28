class League {
  final int id;
  final String code;
  final String name;

  League({required this.code, required this.id, required this.name});

  factory League.fromMap(Map<String, dynamic> map) {
    return League(id: map["id"], code: map["leagueCode"], name: map["leagueName"]);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{"id": id, "leagueCode": code, "leagueName": name};
  }
}
