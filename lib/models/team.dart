class Team {
  final int id;
  final String name;

  Team({required this.id, required this.name});

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(id: map["id"], name: map["teamName"]);
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "teamName": name};
  }

  Team copyWith() {
    return Team.fromMap(toMap());
  }
}
