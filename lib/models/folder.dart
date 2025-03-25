import "package:odds_fetcher/models/league.dart";

class Folder {
  final int id;
  final String name;
  late List<League> leagues = [];

  Folder({required this.id, required this.name});

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(id: map["id"], name: map["folderName"]);
  }

  @override
  String toString() {
    return "Pasta";
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "folderName": name};
  }
}
