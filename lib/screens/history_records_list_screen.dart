import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:google_fonts/google_fonts.dart";

import "package:intl/intl.dart" show DateFormat;
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
import "package:odds_fetcher/widgets/filter_select.dart" show FilterSelectButton;

import "package:odds_fetcher/utils/parse_utils.dart" show humaniseNumber;

class HistoryRecordsScreen extends StatefulWidget {
  const HistoryRecordsScreen({super.key});

  @override
  State<HistoryRecordsScreen> createState() => _HistoryRecordsScreenState();
}

class _HistoryRecordsScreenState extends State<HistoryRecordsScreen> {
  late Future<List<Record>>? records;
  late List<Team> teams = [];
  late List<League> leagues = [];
  late List<Folder> folders = [];
  late List<LeagueFolder> leaguesFolders = [];

  bool isLoading = false;
  bool isCreatingFilter = false;
  bool isUpdatingFilter = false;

  bool showFilters = true;
  bool hideFiltersOnFutureRecordSelect = true;

  // <-- FILTERS
  late Filter filter = Filter(filterName: "FILTRO PADRÃO");
  late Filter placeholderFilter = filter.copyWith();
  // FILTERS -->

  final List<int> pastYearsList = [1, 2, 3, 4, 5, 8, 10, 15, 20];

  late TextEditingController yearController = TextEditingController();
  late TextEditingController filterNameController = TextEditingController();

  void loadMatches() {
    setState(() {
      isLoading = true;
      records = Future.value([]);
    });
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

  void retrieveFilter(int id) async {
    filter = await DatabaseService.fetchFilter(id);

    setState(() {
      filter = filter;
      placeholderFilter = filter.copyWith();
    });
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting("pt-BR");

    records = Future.value([]);

    loadTeamsAndLeaguesAndFolders();

    retrieveFilter(0);
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.087;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (showFilters)
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
          if (showFilters)
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
                    height: MediaQuery.of(context).size.height * 0.042,
                    child: Switch(
                      value: hideFiltersOnFutureRecordSelect,
                      activeColor: Colors.indigoAccent,
                      onChanged: (bool value) {
                        setState(() {
                          hideFiltersOnFutureRecordSelect = value;
                        });
                      },
                    ),
                  ),
                  const Text("OCULTAR FILTROS AO PESQUISAR"),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: MatchCard(records: records, pivotRecord: null),
            ),
          PastMachDataTable(records: records),
          const Divider(),
          // Footer and Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Tooltip(
                    message: filter.filterName,
                    child:
                        isCreatingFilter || isUpdatingFilter
                            ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.05,
                              child: TextField(
                                controller: filterNameController,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Adjust padding
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  hintText: "Informe um Nome...",
                                ),
                                onChanged: (value) => filter.filterName = value,
                              ),
                            )
                            : FilterSelectButton(
                              filter: filter,
                              onApplyCallback: () {
                                retrieveFilter(filter.id as int);
                              },
                            ),
                  ),
                ),
                Row(
                  children: [
                    Tooltip(
                      message: "Novo Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          backgroundColor: isCreatingFilter ? Colors.grey[300] : Colors.grey[100],
                        ),
                        onPressed: () {
                          setState(() {
                            isCreatingFilter = true;
                            filter.id = null;
                            filter.filterName = "Novo Filtro Data: ${DateFormat.MMMMd("pt-BR").format(DateTime.now())}";
                            filterNameController.text = filter.filterName;
                          });
                        },
                        child: Icon(FontAwesomeIcons.squarePlus, color: Colors.black),
                      ),
                    ),
                    Tooltip(
                      message: "Editar Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          backgroundColor: isUpdatingFilter ? Colors.grey[300] : Colors.grey[100],
                        ),
                        onPressed: () {
                          if (isCreatingFilter || isUpdatingFilter) return;

                          setState(() {
                            isUpdatingFilter = true;
                            filterNameController.text = filter.filterName;
                          });
                        },
                        child: const Icon(FontAwesomeIcons.solidPenToSquare, color: Colors.black87),
                      ),
                    ),
                    Tooltip(
                      message: "Salvar Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        onPressed: () async {
                          final bool success = await saveFilter();

                          if (!context.mounted) return;
                          if (success) {
                            showOverlayMessage(context, "Filtro salvo com sucesso!", type: MessageType.success);
                          } else {
                            showOverlayMessage(
                              context,
                              "Filtro precisa de um nome diferente!",
                              type: MessageType.error,
                            );
                          }
                        },
                        child: Icon(FontAwesomeIcons.solidFloppyDisk, color: Colors.black87),
                      ),
                    ),
                    Tooltip(
                      message:
                          isCreatingFilter || isUpdatingFilter
                              ? "Cancelar Criação/Edição de Filtro"
                              : "Resetar Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        onPressed: () {
                          setState(() {
                            if (isCreatingFilter || isUpdatingFilter) {
                              isCreatingFilter = false;
                              isUpdatingFilter = false;
                              filter.filterName = placeholderFilter.filterName;

                              showOverlayMessage(
                                context,
                                "Criação/Edição de filtro cancelada com sucesso!",
                                type: MessageType.info,
                              );
                            } else {
                              filter = placeholderFilter.copyWith();
                              loadMatches();
                              showOverlayMessage(context, "Filtro resetado com sucesso!", type: MessageType.info);
                            }
                          });
                        },
                        child:
                            isCreatingFilter || isUpdatingFilter
                                ? Icon(FontAwesomeIcons.ban, color: Colors.red)
                                : Icon(FontAwesomeIcons.rotateLeft, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                isLoading
                    ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator())
                    : SizedBox(width: 20, height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<List<Record>>(
                      future: records,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            "Carregando jogos passados...",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            "Erro ao carregar jogos passados.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text(
                            "0 JOGOS PASSADOS.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        }
                        return Text(
                          "${humaniseNumber(snapshot.data!.length)} JOGOS PASSADOS.",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
                // Fetch Controls
                ElevatedButton(
                  onPressed: () => setState(() => showFilters = !showFilters),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: Text(
                    showFilters ? "OCULTAR FILTROS" : "MOSTRAR FILTROS",
                    style: GoogleFonts.martianMono(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
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

  Future<bool> saveFilter() async {
    late bool success;

    if (filter.id == null) {
      success = await DatabaseService.insertFilter(filter);
    } else {
      success = await DatabaseService.updateFilter(filter);
    }

    if (!success) return false;

    setState(() {
      placeholderFilter = filter.copyWith();
      isCreatingFilter = false;
      isUpdatingFilter = false;
    });

    return true;
  }
}
