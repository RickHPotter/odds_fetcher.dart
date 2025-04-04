import "dart:async";
import "dart:io" show Platform;

import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart" show FontAwesomeIcons;
import "package:google_fonts/google_fonts.dart" show GoogleFonts;

import "package:intl/date_symbol_data_local.dart" show initializeDateFormatting;
import "package:intl/intl.dart" show DateFormat;

import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/team.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league_folder.dart";
import "package:odds_fetcher/jobs/records_fetcher.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/utils/parse_utils.dart" show humaniseNumber, humaniseTime;
import "package:odds_fetcher/widgets/criteria_filter.dart" show CriteriaFilterButton, CriteriaFilterModal;
import "package:odds_fetcher/widgets/filter_select.dart" show FilterSelectButton;
import "package:odds_fetcher/widgets/leagues_folders_filter.dart" show LeaguesFoldersFilterButton;
import "package:odds_fetcher/widgets/odds_filter.dart" show OddsFilterButton;
import "package:odds_fetcher/widgets/overlay_message.dart" show MessageType, showOverlayMessage;
import "package:odds_fetcher/widgets/teams_filter.dart" show TeamsFilterButton;

abstract class BaseAnalysisScreen extends StatefulWidget {
  const BaseAnalysisScreen({super.key});
}

abstract class BaseAnalysisScreenState<T extends BaseAnalysisScreen> extends State<T> {
  Stream<Record> fetchRecords(Filter filter);

  late Future<List<Record>>? records;
  late List<Record> pivotRecords = [];
  late List<Team> teams = [];
  late List<League> leagues = [];
  late List<Folder> folders = [];
  late List<LeagueFolder> leaguesFolders = [];

  late RecordFetcher fetcher;
  late int pivotRecordsCount = 0;
  String currentDate = DateTime.now().toString();
  int progress = 0;
  bool isFetchingPast = false;
  bool isFetchingPivot = false;
  bool isLoading = false;
  bool isCancelled = false;
  bool isCreatingFilter = false;
  bool isUpdatingFilter = false;

  int? selectedMatchId;
  int? pivotRecordIndex;

  bool showFilters = true;
  bool hideFiltersOnFutureRecordSelect = Platform.isLinux ? false : true;

  // <-- FILTERS
  late Filter filter = Filter(filterName: "FILTRO PADRÃO");
  late Filter placeholderFilter = filter.copyWith();

  late Map<Odds, bool> selectedOddsMap = {
    Odds.earlyOdds1: filter.futureSameEarlyHome,
    Odds.earlyOddsX: filter.futureSameEarlyDraw,
    Odds.earlyOdds2: filter.futureSameEarlyAway,
    Odds.finalOdds1: filter.futureSameFinalHome,
    Odds.finalOddsX: filter.futureSameFinalDraw,
    Odds.finalOdds2: filter.futureSameFinalAway,
  };
  // FILTERS -->

  StreamSubscription<Record>? _recordSubscription;

  Future<void> fetchFromMaxMatchDate() async {
    final DateTime minDateToFetch = await DatabaseService.fetchFromMaxMatchDate();

    if (minDateToFetch != DateTime.now()) {
      startFetching(minDate: minDateToFetch);
    }

    startFetchingFuture();
  }

  void loadFutureMatches() {
    _recordSubscription?.cancel();

    setState(() {
      isLoading = true;
      pivotRecords.clear();
      selectedMatchId = null;
      pivotRecordIndex = null;
      records = Future.value([]);
    });

    _recordSubscription = fetchRecords(filter).listen(
      (record) {
        setState(() {
          pivotRecords.add(record);
          if (pivotRecordIndex == null) {
            loadPastMatches(record.id, 0);
          }
        });
      },
      onDone: () {
        setState(() {
          isLoading = false;
          pivotRecordIndex ??= 0;
        });
      },
    );
  }

  void loadPastMatches(int? id, int? index) async {
    setState(() {
      selectedMatchId = id;
      pivotRecordIndex = index;

      if (id != null && index != null && pivotRecords.isNotEmpty) {
        final Record futurePivotRecord = pivotRecords[index];
        records = DatabaseService.fetchRecords(filter: filter, futureRecord: futurePivotRecord);
      }
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

    updateOddsFilter();
    loadFutureMatches();
  }

  void updateOddsFilter() {
    filter.updateOdds();

    selectedOddsMap = {
      Odds.earlyOdds1: filter.futureSameEarlyHome,
      Odds.earlyOddsX: filter.futureSameEarlyDraw,
      Odds.earlyOdds2: filter.futureSameEarlyAway,
      Odds.finalOdds1: filter.futureSameFinalHome,
      Odds.finalOddsX: filter.futureSameFinalDraw,
      Odds.finalOdds2: filter.futureSameFinalAway,
    };
  }

  void updateFutureSameOddsTypes() {
    updateOddsFilter();

    setState(() => filter = filter);
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting("pt-BR");

    fetcher = RecordFetcher();
    fetcher.progressStream.listen((value) {
      setState(() => progress = value);
    });
    fetcher.currentDateStream.listen((value) {
      setState(() => currentDate = value);
    });

    records = Future.value([]);

    fetchFromMaxMatchDate();
    loadTeamsAndLeaguesAndFolders();

    retrieveFilter(0);
  }

  @override
  void dispose() {
    fetcher.dispose();
    _recordSubscription?.cancel();
    super.dispose();
  }

  void startFetching({DateTime? minDate, DateTime? maxDate}) async {
    minDate ??= DateTime.parse("2008-01-01");
    maxDate ??= DateTime.now().subtract(Duration(days: 1));

    setState(() {
      isFetchingPast = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertRecords(minDate: minDate, maxDate: maxDate, isCancelledCallback: () => isCancelled);

    if (mounted) {
      if (isCancelled) {
        showOverlayMessage(context, "Operação cancelada!", type: MessageType.info);
      } else {
        showOverlayMessage(context, "Jogos passados buscados com sucesso!");
      }
    }

    setState(() => isFetchingPast = false);
  }

  void startFetchingFuture() async {
    setState(() {
      isFetchingPivot = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertFutureRecords(isCancelledCallback: () => isCancelled);

    if (mounted && !isCancelled) showOverlayMessage(context, "Jogos futuros buscados com sucesso!");

    setState(() => isFetchingPivot = false);
  }

  // FILTERS
  void filterHistoryMatches(TextEditingController yearController, {int? time, int? specificYear}) {
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

    loadFutureMatches();
  }

  void filterUpcomingMatches(int duration) {
    setState(() => filter.futureNextMinutes = duration);

    loadFutureMatches();
  }

  void filterMatchesBySimiliarity(Odds oddType) {
    setState(() {
      switch (oddType) {
        case Odds.earlyOdds1:
          filter.futureSameEarlyHome = !filter.futureSameEarlyHome;
          break;
        case Odds.earlyOddsX:
          filter.futureSameEarlyDraw = !filter.futureSameEarlyDraw;
          break;
        case Odds.earlyOdds2:
          filter.futureSameEarlyAway = !filter.futureSameEarlyAway;
          break;
        case Odds.finalOdds1:
          filter.futureSameFinalHome = !filter.futureSameFinalHome;
          break;
        case Odds.finalOddsX:
          filter.futureSameFinalDraw = !filter.futureSameFinalDraw;
          break;
        case Odds.finalOdds2:
          filter.futureSameFinalAway = !filter.futureSameFinalAway;
          break;
      }

      updateOddsFilter();

      setState(() => filter = filter);

      if (filter.anyFutureMinPercent()) {
        loadFutureMatches();
      } else {
        loadPastMatches(selectedMatchId, pivotRecordIndex);
      }
    });
  }

  void filterMatchesBySameLeague() {
    filter.futureOnlySameLeague = !filter.futureOnlySameLeague;
    if (filter.futureOnlySameLeague) {
      filter.leagues.clear();
      filter.folders.clear();
    }

    setState(() {
      filter = filter;
    });

    loadPastMatches(selectedMatchId, pivotRecordIndex);
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

  // WIDGETS
  Widget pivotFilters(IconData icon, List<int> minutesList, double buttonSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(icon)),
          for (final int minutes in minutesList)
            SizedBox(
              width: buttonSize,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                child: ElevatedButton(
                  onPressed: () => filterUpcomingMatches(minutes),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    shadowColor: Colors.purple,
                    backgroundColor: minutes == filter.futureNextMinutes ? Colors.indigoAccent : null,
                  ),
                  child: Text(
                    humaniseTime(minutes, short: true),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: minutes == filter.futureNextMinutes ? Colors.white : null,
                    ),
                  ),
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
    );
  }

  Widget bothFilters(double buttonSize, double smallButtonSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.tune)),
          ...[Odds.earlyOdds1, Odds.earlyOddsX, Odds.earlyOdds2, Odds.finalOdds1, Odds.finalOddsX, Odds.finalOdds2].map(
            (oddsType) {
              final bool isSelected = selectedOddsMap[oddsType] ?? false;

              return SizedBox(
                width: smallButtonSize,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    onPressed: () => filterMatchesBySimiliarity(oddsType),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      shadowColor: Colors.purple,
                      backgroundColor: isSelected ? Colors.indigoAccent : null,
                    ),
                    child: Text(
                      oddsType.shortName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(
            width: buttonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: OddsFilterButton(
                filter: filter,
                onApplyCallback: () {
                  updateFutureSameOddsTypes();
                  loadFutureMatches();
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
                  loadFutureMatches();
                },
              ),
            ),
          ),
          SizedBox(
            width: buttonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: ElevatedButton(
                onPressed: () => filterMatchesBySameLeague(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  shadowColor: Colors.purple,
                  backgroundColor: filter.futureOnlySameLeague ? Colors.indigoAccent : null,
                ),
                child: Text(
                  "MESMA LIGA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: filter.futureOnlySameLeague ? Colors.white : null,
                  ),
                ),
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
                  loadFutureMatches();
                },
              ),
            ),
          ),
          SizedBox(
            width: buttonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CriteriaFilterButton(filter: filter, onApplyCallback: () => loadFutureMatches()),
            ),
          ),
          SizedBox(
            width: buttonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  if (filter.futureMinHomeWinPercentage == 52 &&
                      filter.futureMinDrawPercentage == 52 &&
                      filter.futureMinAwayWinPercentage == 52) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CriteriaFilterModal(filter: filter, onApplyCallback: () => loadFutureMatches());
                      },
                    );
                  } else {
                    filter.futureMinHomeWinPercentage = 52;
                    filter.futureMinDrawPercentage = 52;
                    filter.futureMinAwayWinPercentage = 52;

                    setState(() => filter = filter);

                    loadFutureMatches();
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  shadowColor: Colors.purple,
                  backgroundColor: filter.allFutureMinPercentSpecificValue(52) ? Colors.indigoAccent : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list, color: filter.allFutureMinPercentSpecificValue(52) ? Colors.white : null),
                    const SizedBox(width: 1),
                    Text(
                      "52 %",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: filter.allFutureMinPercentSpecificValue(52) ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget footerControls(BuildContext context, TextEditingController filterNameController) {
    return Padding(
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
                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: Row(
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
                        showOverlayMessage(context, "Filtro precisa de um nome diferente!", type: MessageType.error);
                      }
                    },
                    child: Icon(FontAwesomeIcons.solidFloppyDisk, color: Colors.black87),
                  ),
                ),
                Tooltip(
                  message:
                      isCreatingFilter || isUpdatingFilter ? "Cancelar Criação/Edição de Filtro" : "Resetar Filtro",
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
                          updateOddsFilter();
                          loadFutureMatches();
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
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${humaniseNumber(pivotRecordsCount)} JOGOS PIVÔS TOTAIS.",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "${humaniseNumber(pivotRecords.length)} JOGOS PIVÔS FILTRADOS.",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                isLoading
                    ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator())
                    : SizedBox(width: 20, height: 20),
              ],
            ),
          ),
          // Fetch Controls
          ElevatedButton(
            onPressed: () => setState(() => showFilters = !showFilters),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
            child: Text(
              showFilters ? "OCULTAR FILTROS" : "MOSTRAR FILTROS",
              style: GoogleFonts.martianMono(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child:
                isFetchingPast || isFetchingPivot
                    ? SizedBox(
                      width: MediaQuery.of(context).size.width * 0.18,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: progress / 100),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Tooltip(
                                  message: "Cancelar",
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isCancelled = true;
                                        isFetchingPast = false;
                                        isFetchingPivot = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                    ),
                                    child: const Icon(FontAwesomeIcons.ban, size: 14, color: Colors.red),
                                  ),
                                ),
                                Text(currentDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  ),
                                  child: Text("$progress%"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    : SizedBox(
                      width: MediaQuery.of(context).size.width * 0.18,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "past") {
                            startFetching();
                          } else if (value == "future") {
                            startFetchingFuture();
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(value: "past", child: Text("ATUALIZAR PASSADO")),
                              PopupMenuItem(value: "future", child: Text("ATUALIZAR FUTURO")),
                            ],
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Theme.of(context).primaryColor,
                            disabledForegroundColor: Colors.white,
                          ),
                          onPressed: null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "ATUALIZAR",
                                style: GoogleFonts.martianMono(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
