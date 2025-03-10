import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import "package:http/http.dart" as http;
import 'package:odds_fetcher/models/league.dart' show League;
import 'package:odds_fetcher/models/record.dart';
import 'package:odds_fetcher/models/team.dart' show Team;
import 'package:odds_fetcher/services/database_service.dart'
    show DatabaseService;
import 'package:odds_fetcher/utils/parse_utils.dart';

class ApiService {
  static const String baseUrl = 'https://px-1x2.7mdt.com/data/history/en/';

  Future<List<Record>> fetchData(String date) async {
    const bettingHouseId = 17;
    final resultMessage = "$date == ";

    final url = Uri.parse(
      '$baseUrl$date/$bettingHouseId.js?nocache=${DateTime.now().millisecondsSinceEpoch}',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      return Future.error(
        '$resultMessage Failed to fetch data. Status: ${response.statusCode}',
      );
    }

    String bodyStr = await _sanitizeData(response.body);

    // Try to decode the first JSON attempt
    List<dynamic> recordsArray;
    try {
      recordsArray = json.decode(bodyStr);
    } catch (e) {
      // If failed, sanitize for UTF-8 BOM and try again
      bodyStr = _sanitizeUffef(bodyStr);
      try {
        recordsArray = json.decode(bodyStr);
      } catch (e) {
        return Future.error(
          '$resultMessage Failed to parse sanitized data. Error: $e',
        );
      }
    }

    final List<Record> records = [];
    for (var recordData in recordsArray) {
      final fields = recordData.split("|");
      if (fields.length < 17) {
        return Future.error('$resultMessage Invalid data structure');
      }

      DateTime matchDate;
      try {
        matchDate = DateTime.parse(date);
      } catch (e) {
        matchDate = DateTime.now();
      }

      try {
        String firstHalfScore = fields[10].trim();
        int? homeFirstHalfScore;
        int? awayFirstHalfScore;

        if (firstHalfScore.isNotEmpty && firstHalfScore.contains("-")) {
          var scores = firstHalfScore.split("-");
          if (scores.length == 2) {
            homeFirstHalfScore = int.tryParse(scores[0]);
            awayFirstHalfScore = int.tryParse(scores[1]);
          }
        }
        final leagueCode = fields[3].split(",")[0];
        final leagueName = fields[3].split(",")[1];

        final leagueId = await DatabaseService.getOrCreateLeague(
          leagueCode,
          leagueName,
        );
        final homeTeamId = await DatabaseService.getOrCreateTeam(fields[6]);
        final awayTeamId = await DatabaseService.getOrCreateTeam(fields[7]);

        final record = Record(
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
          homeFirstHalfScore: homeFirstHalfScore,
          awayFirstHalfScore: awayFirstHalfScore,
          homeSecondHalfScore: parseInteger(fields[8]),
          awaySecondHalfScore: parseInteger(fields[9]),
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
    // Remove UTF-8 BOM and sanitize data as needed
    rawData = rawData.replaceFirst("\xef\xbb\xbf", ""); // Remove BOM
    rawData = rawData.replaceFirst(
      "var dt = ",
      "",
    ); // Remove JavaScript variable assignment
    rawData = rawData.replaceAll("\\'", "'"); // Fix escaped single quotes
    rawData = rawData.replaceAll("\t", " "); // Replace tabs with spaces
    rawData = rawData.replaceAll(";", " "); // Replace end semicolon with space
    return rawData;
  }

  String _sanitizeUffef(String rawData) {
    return rawData.replaceFirst("\ufeff", ""); // Remove BOM (UFFEF)
  }
}
