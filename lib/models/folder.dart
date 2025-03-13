class Folder {
  final int id;
  final String name;

  Folder({required this.id, required this.name});

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(id: map["id"], name: map["folderName"]);
  }
}
