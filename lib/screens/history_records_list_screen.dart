import "dart:async";

import "package:async/async.dart" show CancelableOperation;
import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:font_awesome_flutter/font_awesome_flutter.dart";

import "package:intl/date_symbol_data_local.dart" show initializeDateFormatting;

import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/team.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league_folder.dart";
import "package:odds_fetcher/services/database_service.dart";

import "package:odds_fetcher/widgets/overlay_message.dart" show MessageType, showOverlayMessage;
import "package:odds_fetcher/widgets/teams_filter.dart" show TeamsFilterButton;
import "package:odds_fetcher/widgets/leagues_folders_filter.dart" show LeaguesFoldersFilterButton;
import "package:odds_fetcher/widgets/odds_filter.dart" show OddsFilterButton;
import "package:odds_fetcher/widgets/match_card.dart" show MatchCard;
import "package:odds_fetcher/widgets/past_matches_datatable.dart" show PastMachDataTable;

class HistoryRecordsScreen extends StatefulWidget {
  const HistoryRecordsScreen({super.key});

  @override
  State<HistoryRecordsScreen> createState() => _HistoryRecordsScreenState();
}

class _HistoryRecordsScreenState extends State<HistoryRecordsScreen> {
  CancelableOperation<List<Record>>? _operation;

  late List<Record> records;
  late List<Team> teams = [];
  late List<League> leagues = [];
  late List<Folder> folders = [];
  late List<LeagueFolder> leaguesFolders = [];

  bool isLoading = false;

  late Filter filter = Filter(filterName: "FILTRO PADRÃO");

  final List<int> pastYearsList = [1, 2, 3, 4, 5, 8, 10, 15, 20];

  late TextEditingController yearController = TextEditingController();
  late TextEditingController filterNameController = TextEditingController();

  void loadMatches() {
    setState(() {
      isLoading = true;
      records = [];
    });

    _operation = CancelableOperation.fromFuture(
      DatabaseService.fetchRecords(filter: filter),
      onCancel: () {
        setState(() {
          isLoading = false;
        });
      },
    );

    _operation!.value
        .then((fetchedRecords) {
          if (!_operation!.isCanceled) {
            setState(() {
              isLoading = false;
              records = fetchedRecords;
            });
          }
        })
        .catchError((error) {
          if (!_operation!.isCanceled) {
            setState(() {
              isLoading = false;
            });
            debugPrint("Error fetching records: $error");
          }
        });
  }

  void cancelLoading() {
    _operation?.cancel();
  }

  void loadTeamsAndLeaguesAndFolders() async {
    final List<Team> fetchedTeams = await DatabaseService.fetchTeams();
    final List<League> fetchedLeagues = await DatabaseService.fetchLeagues();
    final List<Folder> fetchedFolders = await DatabaseService.fetchFoldersWithLeagues();

    setState(() {
      teams = fetchedTeams;
      leagues = fetchedLeagues;
      folders = fetchedFolders;
    });
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting("pt-BR");

    records = [];

    loadTeamsAndLeaguesAndFolders();
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.087;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.history)),
                for (final int time in pastYearsList)
                  SizedBox(
                    width: buttonSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                      child: ElevatedButton(
                        onPressed: () => filterHistoryMatches(time: time),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: time == filter.pastYears ? Colors.indigoAccent : null,
                        ),
                        child: Text(
                          time <= 1 ? "$time Ano" : "$time Anos",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: time == filter.pastYears ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: buttonSize,
                  height: MediaQuery.of(context).size.height * 0.042,
                  child: TextFormField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null ? "ANO INVÁLIDO" : null,
                    decoration: InputDecoration(
                      labelText: "ANO",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^\d*\.?\d*"))],
                    onChanged: (value) => filterHistoryMatches(specificYear: value.isEmpty ? null : int.parse(value)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.tune)),
                SizedBox(
                  width: buttonSize,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OddsFilterButton(
                      filter: filter,
                      onApplyCallback: () {
                        loadMatches();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonSize,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TeamsFilterButton(
                      filter: filter,
                      teams: teams,
                      onApplyCallback: () {
                        loadMatches();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonSize,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: LeaguesFoldersFilterButton(
                      filter: filter,
                      leagues: leagues,
                      folders: folders,
                      onApplyCallback: () {
                        if (filter.futureOnlySameLeague && (filter.leagues.isNotEmpty || filter.folders.isNotEmpty)) {
                          setState(() => filter.futureOnlySameLeague = false);
                        }
                        loadMatches();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonSize,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: () {
                        setState(() {
                          filter = Filter(filterName: "FILTRO PADRÃO");
                          loadMatches();
                          showOverlayMessage(context, "Filtro resetado com sucesso!", type: MessageType.info);
                        });
                      },
                      child: Row(
                        children: const [
                          Icon(FontAwesomeIcons.rotateLeft, color: Colors.purpleAccent),
                          SizedBox(width: 3),
                          Text("Resetar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonSize,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: () {
                        setState(() {
                          cancelLoading();
                          showOverlayMessage(context, "Busca cancelada com sucesso!", type: MessageType.info);
                        });
                      },
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.ban, color: Colors.red),
                          SizedBox(width: 3),
                          Text("Abortar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                isLoading
                    ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator())
                    : SizedBox(width: 20, height: 20),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: MatchCard(records: Future.value(records), pivotRecord: records.first),
            ),
          PastMachDataTable(records: Future.value(records)),
        ],
      ),
    );
  }

  // FILTERS
  void filterHistoryMatches({int? time, int? specificYear}) {
    if (time == null && specificYear == null) {
      showOverlayMessage(context, "Filtro de Tempo Passado preenchido incompletamente!", type: MessageType.warning);
      return;
    }

    if (time != null) {
      filter.pastYears = time;
      yearController.clear();
    } else if (specificYear != null) {
      filter.pastYears = null;
      filter.specificYears = specificYear;
    }

    setState(() => filter = filter);

    loadMatches();
  }
}
