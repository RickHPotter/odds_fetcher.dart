import "dart:convert";

import "package:flutter/foundation.dart" show debugPrint;
import "package:http/http.dart" as http;
import "package:odds_fetcher/models/league.dart" show League;
import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/team.dart" show Team;
import "package:odds_fetcher/services/database_service.dart" show DatabaseService;
import "package:odds_fetcher/utils/date_utils.dart" show parseRawDateTime;
import "package:odds_fetcher/utils/parse_utils.dart";

class ApiService {
  static const String baseUrl = "https://px-1x2.7mdt.com/data/history/en/";
  static const String liveUrl = "https://px-1x2.7mdt.com/data/played_en";
  static const String futureUrl = "https://px-1x2.7mdt.com/data/company/en/";

  Future<List<Record>> fetchData(String date) async {
    const int bettingHouseId = 17;
    final String resultMessage = "$date == ";

    final Uri url = Uri.parse("$baseUrl$date/$bettingHouseId.js?nocache=${DateTime.now().millisecondsSinceEpoch}");
    final http.Response response = await http.get(url);

    if (response.statusCode != 200) {
      return Future.error("$resultMessage Failed to fetch data. Status: ${response.statusCode}");
    }

    String bodyStr = await _sanitizeData(utf8.decode(response.bodyBytes));

    List<dynamic> recordsArray;
    try {
      recordsArray = json.decode(bodyStr);
    } catch (e) {
      bodyStr = _sanitizeUffef(bodyStr);
      try {
        recordsArray = json.decode(bodyStr);
      } catch (e) {
        return Future.error("$resultMessage Failed to parse sanitized data. Error: $e");
      }
    }

    final List<Record> records = [];
    for (final String recordData in recordsArray) {
      final List<String> fields = recordData.split("|");
      if (fields.length < 17) {
        return Future.error("$resultMessage Invalid data structure");
      }

      DateTime matchDate;

      try {
        matchDate = parseRawDateTime(fields[1].trim().replaceAll(",", "")).subtract(Duration(hours: 11));
      } catch (e) {
        debugPrint(e.toString());
        matchDate = DateTime.now();
      }

      try {
        String firstHalfScore = fields[10].trim();
        int? homeHalfTimeScore;
        int? awayHalfTimeScore;

        if (firstHalfScore.isNotEmpty && firstHalfScore.contains("-")) {
          final List<String> scores = firstHalfScore.split("-");
          if (scores.length == 2) {
            homeHalfTimeScore = int.tryParse(scores[0]);
            awayHalfTimeScore = int.tryParse(scores[1]);
          }
        }
        final String leagueCode = fields[3].split(",")[0];
        final String leagueName = fields[3].split(",")[1];

        final int leagueId = await DatabaseService.getOrCreateLeague(leagueCode, leagueName);
        final int homeTeamId = await DatabaseService.getOrCreateTeam(fields[6]);
        final int awayTeamId = await DatabaseService.getOrCreateTeam(fields[7]);

        int homeFullTimeScore = parseInteger(fields[8]);
        int awayFullTimeScore = parseInteger(fields[9]);

        int home = 0;
        int draw = 0;
        int away = 0;

        if (homeFullTimeScore == awayFullTimeScore) {
          draw = 1;
        } else if (homeFullTimeScore > awayFullTimeScore) {
          home = 1;
        } else {
          away = 1;
        }

        final Record record = Record(
          bettingHouseId: bettingHouseId,
          matchDate: matchDate,
          league: League(id: leagueId, code: leagueCode, name: leagueName),
          homeTeam: Team(id: homeTeamId, name: fields[6]),
          awayTeam: Team(id: awayTeamId, name: fields[7]),
          earlyOdds1: parseDouble(fields[11]),
          earlyOddsX: parseDouble(fields[12]),
          earlyOdds2: parseDouble(fields[13]),
          finalOdds1: double.tryParse(fields[14]),
          finalOddsX: double.tryParse(fields[15]),
          finalOdds2: double.tryParse(fields[16]),
          homeHalfTimeScore: homeHalfTimeScore,
          awayHalfTimeScore: awayHalfTimeScore,
          homeFullTimeScore: homeFullTimeScore,
          awayFullTimeScore: awayFullTimeScore,
          homeWin: home,
          draw: draw,
          awayWin: away,
        );

        records.add(record);
      } catch (e) {
        debugPrint("Error parsing record: $e");
        debugPrint("Problematic fields: $fields");
      }
    }

    return records;
  }

  Future<List<Record>> fetchLiveData() async {
    const int bettingHouseId = 17;

    final Uri url = Uri.parse("$liveUrl.js?nocache=${DateTime.now().millisecondsSinceEpoch}");
    final http.Response response = await http.get(url);

    if (response.statusCode != 200) {
      return Future.error("Failed to fetch live data. Status: ${response.statusCode}");
    }

    String bodyStr = await _sanitizeData(utf8.decode(response.bodyBytes));

    List<dynamic> recordsArray;
    try {
      recordsArray = json.decode(bodyStr);
    } catch (e) {
      bodyStr = _sanitizeUffef(bodyStr);
      try {
        recordsArray = json.decode(bodyStr);
      } catch (e) {
        return Future.error("Failed to parse sanitized live data. Error: $e");
      }
    }

    final List<Record> records = [];
    for (final String recordData in recordsArray) {
      final List<String> fields = recordData.split("|");
      if (fields.length < 17) {
        return Future.error("Invalid live data structure");
      }

      DateTime matchDate;

      try {
        matchDate = parseRawDateTime(fields[1].trim().replaceAll(",", "")).subtract(Duration(hours: 11));
      } catch (e) {
        debugPrint(e.toString());
        matchDate = DateTime.now();
      }

      fields.removeAt(2);

      try {
        String firstHalfScore = fields[10].trim();
        int? homeHalfTimeScore;
        int? awayHalfTimeScore;

        if (firstHalfScore.isNotEmpty && firstHalfScore.contains("-")) {
          final List<String> scores = firstHalfScore.split("-");
          if (scores.length == 2) {
            homeHalfTimeScore = int.tryParse(scores[0]);
            awayHalfTimeScore = int.tryParse(scores[1]);
          }
        }

        final String leagueCode = fields[3];
        final int leagueId = await DatabaseService.getOrCreateLeague(leagueCode, null);
        final int homeTeamId = await DatabaseService.getOrCreateTeam(fields[6]);
        final int awayTeamId = await DatabaseService.getOrCreateTeam(fields[7]);

        int homeFullTimeScore = parseInteger(fields[8]);
        int awayFullTimeScore = parseInteger(fields[9]);

        int home = 0;
        int draw = 0;
        int away = 0;

        if (homeFullTimeScore == awayFullTimeScore) {
          draw = 1;
        } else if (homeFullTimeScore > awayFullTimeScore) {
          home = 1;
        } else {
          away = 1;
        }

        final Record record = Record(
          bettingHouseId: bettingHouseId,
          matchDate: matchDate,
          league: League(id: leagueId, code: leagueCode, name: leagueCode),
          homeTeam: Team(id: homeTeamId, name: fields[6]),
          awayTeam: Team(id: awayTeamId, name: fields[7]),
          earlyOdds1: parseDouble(fields[11]),
          earlyOddsX: parseDouble(fields[12]),
          earlyOdds2: parseDouble(fields[13]),
          finalOdds1: double.tryParse(fields[14]),
          finalOddsX: double.tryParse(fields[15]),
          finalOdds2: double.tryParse(fields[16]),
          homeHalfTimeScore: homeHalfTimeScore,
          awayHalfTimeScore: awayHalfTimeScore,
          homeFullTimeScore: homeFullTimeScore,
          awayFullTimeScore: awayFullTimeScore,
          homeWin: home,
          draw: draw,
          awayWin: away,
          finished: false,
        );

        records.add(record);
      } catch (e) {
        debugPrint("Error parsing record: $e");
        debugPrint("Problematic fields: $fields");
      }
    }

    return records;
  }

  Future<List<Record>> fetchFutureData() async {
    const int bettingHouseId = 17;

    final Uri url = Uri.parse(
      "${ApiService.futureUrl}$bettingHouseId.js?nocache=${DateTime.now().millisecondsSinceEpoch}",
    );

    final http.Response response = await http.get(url);

    if (response.statusCode != 200) {
      return Future.error("Failed to fetch future data. Status: ${response.statusCode}");
    }

    String bodyStr = await _sanitizeData(utf8.decode(response.bodyBytes));

    List<dynamic> recordsArray;
    try {
      recordsArray = json.decode(bodyStr);
    } catch (e) {
      bodyStr = _sanitizeUffef(bodyStr);
      try {
        recordsArray = json.decode(bodyStr);
      } catch (e) {
        return Future.error("Failed to parse sanitized future data. Error: $e");
      }
    }

    final List<Record> records = [];
    for (final String recordData in recordsArray) {
      final List<String> fields = recordData.split("|");
      if (fields.length < 17) {
        return Future.error("Invalid future data structure");
      }

      DateTime matchDate;

      try {
        matchDate = parseRawDateTime(fields[1].trim().replaceAll(",", "")).subtract(Duration(hours: 11));
      } catch (e) {
        debugPrint(e.toString());
        matchDate = DateTime.now();
      }

      try {
        final String leagueCode = fields[3];
        final int leagueId = await DatabaseService.getOrCreateLeague(leagueCode, null);
        final int homeTeamId = await DatabaseService.getOrCreateTeam(fields[6]);
        final int awayTeamId = await DatabaseService.getOrCreateTeam(fields[7]);

        final Record record = Record(
          bettingHouseId: bettingHouseId,
          matchDate: matchDate,
          league: League(id: leagueId, code: leagueCode, name: leagueCode),
          homeTeam: Team(id: homeTeamId, name: fields[6]),
          awayTeam: Team(id: awayTeamId, name: fields[7]),
          earlyOdds1: parseDouble(fields[8]),
          earlyOddsX: parseDouble(fields[9]),
          earlyOdds2: parseDouble(fields[10]),
          finalOdds1: double.tryParse(fields[11]),
          finalOddsX: double.tryParse(fields[12]),
          finalOdds2: double.tryParse(fields[13]),
          homeHalfTimeScore: null,
          awayHalfTimeScore: null,
          homeFullTimeScore: null,
          awayFullTimeScore: null,
          finished: false,
        );

        records.add(record);
      } catch (e) {
        debugPrint("Error parsing record: $e");
        debugPrint("Problematic fields: $fields");
      }
    }

    return records;
  }

  Future<String> _sanitizeData(String rawData) async {
    rawData = rawData.replaceFirst("\xef\xbb\xbf", "");
    rawData = rawData.replaceFirst("var dt = ", "");
    rawData = rawData.replaceAll("\\'", "'");
    rawData = rawData.replaceAll("\t", " ");
    rawData = rawData.replaceAll(";", " ");
    return rawData;
  }

  String _sanitizeUffef(String rawData) {
    return rawData.replaceFirst("\ufeff", "");
  }
}
