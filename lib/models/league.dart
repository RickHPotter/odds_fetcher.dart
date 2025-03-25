class League {
  final int? id;
  final List<int>? ids;
  final String code;
  final String name;

  League({this.id, this.ids, required this.code, required this.name})
    : assert(id != null || ids != null, "Either id or ids must be provided.");

  factory League.fromMap(Map<String, dynamic> map) {
    int? id;
    List<int>? ids;

    if (map["id"] == null) {
      if (map["ids"] is String) {
        ids = (map["ids"] as String).split(",").map((id) => int.parse(id)).toList();
      } else if (map["ids"] is List) {
        ids = (map["ids"] as List).map((id) => int.parse(id.toString())).toList();
      } else {
        throw ArgumentError("Invalid ids format: ${map["ids"]}");
      }
    } else if (map["ids"] == null) {
      id = int.parse(map["id"].toString());
    }

    return League(id: id, ids: ids, code: map["leagueCode"], name: map["leagueName"]);
  }

  @override
  String toString() {
    return "Liga";
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "leagueCode": code, "leagueName": name};
  }
}
