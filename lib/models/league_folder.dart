import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";

class LeagueFolder {
  final int id;
  final League league;
  final Folder folder;

  LeagueFolder({required this.id, required this.league, required this.folder});

  factory LeagueFolder.fromMap(Map<String, dynamic> map) {
    return LeagueFolder(
      id: map["id"],
      league: League(id: map["leagueId"], name: map["leagueName"], code: map["leagueCode"]),
      folder: Folder(id: map["folderId"], name: map["folderName"]),
    );
  }
}
