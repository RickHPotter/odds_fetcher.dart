import "dart:async";
import "dart:io" show Platform;

import "package:flutter/gestures.dart" show PointerScrollEvent;
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
import "package:odds_fetcher/widgets/datetime_picker.dart";
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
  String currentDate = DateTime.now().toString().substring(0, 10);
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
  bool hideFiltersOnPivotRecordSelect = Platform.isLinux ? false : true;

  // <-- FILTERS
  late Filter filter = Filter.base("FILTRO PADRÃO");
  late Filter placeholderFilter = filter.copyWith();

  late Map<Odds, bool> selectedOddsMap = {
    Odds.earlyOdds1: filter.pivotSameEarlyHome,
    Odds.earlyOddsX: filter.pivotSameEarlyDraw,
    Odds.earlyOdds2: filter.pivotSameEarlyAway,
    Odds.finalOdds1: filter.pivotSameFinalHome,
    Odds.finalOddsX: filter.pivotSameFinalDraw,
    Odds.finalOdds2: filter.pivotSameFinalAway,
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

  void loadPivotMatches() {
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
        final Record pivotRecord = pivotRecords[index];
        records = DatabaseService.fetchRecords(filter: filter, pivotRecord: pivotRecord);
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
    loadPivotMatches();
  }

  void updateOddsFilter() {
    filter.updateOdds();

    selectedOddsMap = {
      Odds.earlyOdds1: filter.pivotSameEarlyHome,
      Odds.earlyOddsX: filter.pivotSameEarlyDraw,
      Odds.earlyOdds2: filter.pivotSameEarlyAway,
      Odds.finalOdds1: filter.pivotSameFinalHome,
      Odds.finalOddsX: filter.pivotSameFinalDraw,
      Odds.finalOdds2: filter.pivotSameFinalAway,
    };
  }

  void updatePivotSameOddsTypes() {
    filter.lastAction = LastAction.manualOddsChange;
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
  void filterHistoryMatches({int? time, DateTime? minDate, DateTime? maxDate}) {
    if (time == null && (minDate == null || maxDate == null)) {
      showOverlayMessage(context, "Filtro de Tempo Passado preenchido incompletamente!", type: MessageType.warning);
      return;
    }

    if (time != null) {
      filter.pastYears = time;
      filter.specificMinDate = null;
      filter.specificMaxDate = null;
    } else if (minDate != null || maxDate != null) {
      filter.pastYears = null;
      filter.specificMinDate = minDate;
      filter.specificMaxDate = maxDate;
    }

    setState(() => filter = filter);

    loadPivotMatches();
  }

  void filterUpcomingMatches(int duration) {
    setState(() => filter.pivotNextMinutes = duration);

    loadPivotMatches();
  }

  void filterMatchesBySimiliarity(Odds oddType) {
    setState(() {
      filter.lastAction = LastAction.pivotChange;

      switch (oddType) {
        case Odds.earlyOdds1:
          filter.pivotSameEarlyHome = !filter.pivotSameEarlyHome;
          break;
        case Odds.earlyOddsX:
          filter.pivotSameEarlyDraw = !filter.pivotSameEarlyDraw;
          break;
        case Odds.earlyOdds2:
          filter.pivotSameEarlyAway = !filter.pivotSameEarlyAway;
          break;
        case Odds.finalOdds1:
          filter.pivotSameFinalHome = !filter.pivotSameFinalHome;
          break;
        case Odds.finalOddsX:
          filter.pivotSameFinalDraw = !filter.pivotSameFinalDraw;
          break;
        case Odds.finalOdds2:
          filter.pivotSameFinalAway = !filter.pivotSameFinalAway;
          break;
      }

      updateOddsFilter();

      setState(() => filter = filter);

      loadPivotMatches();
      loadPastMatches(selectedMatchId, pivotRecordIndex);
    });
  }

  void filterMatchesBySameLeague() {
    filter.pivotOnlySameLeague = !filter.pivotOnlySameLeague;
    if (filter.pivotOnlySameLeague) {
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
  Widget pastFilters(double buttonSize, List<int> pastYearsList) {
    return Padding(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: (4.0)),
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.calendar_today,
                  color: (filter.specificMinDate != null || filter.specificMaxDate != null) ? Colors.white : null,
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  shadowColor: Colors.purple,
                  backgroundColor:
                      (filter.specificMinDate != null || filter.specificMaxDate != null) ? Colors.indigoAccent : null,
                ),
                label: Text(
                  "Data",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (filter.specificMinDate != null || filter.specificMaxDate != null) ? Colors.white : null,
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Selecionar Data e Hora"),
                        content: DateTimePickerWidget(filter: filter, onApplyCallback: filterHistoryMatches),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                    backgroundColor: minutes == filter.pivotNextMinutes ? Colors.indigoAccent : null,
                  ),
                  child: Text(
                    humaniseTime(minutes, short: true),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: minutes == filter.pivotNextMinutes ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.042,
            child: Switch(
              value: hideFiltersOnPivotRecordSelect,
              activeColor: Colors.indigoAccent,
              onChanged: (bool value) {
                setState(() {
                  hideFiltersOnPivotRecordSelect = value;
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
                  updatePivotSameOddsTypes();
                  loadPivotMatches();
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
                  loadPivotMatches();
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
                  backgroundColor: filter.pivotOnlySameLeague ? Colors.indigoAccent : null,
                ),
                child: Text(
                  "MESMA LIGA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: filter.pivotOnlySameLeague ? Colors.white : null,
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
                  if (filter.pivotOnlySameLeague && (filter.leagues.isNotEmpty || filter.folders.isNotEmpty)) {
                    setState(() => filter.pivotOnlySameLeague = false);
                  }
                  loadPivotMatches();
                },
              ),
            ),
          ),
          SizedBox(
            width: buttonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CriteriaFilterButton(filter: filter, onApplyCallback: () => loadPivotMatches()),
            ),
          ),
          SizedBox(
            width: buttonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  if (filter.pivotMinHomeWinPercentage == 52 &&
                      filter.pivotMinDrawPercentage == 52 &&
                      filter.pivotMinAwayWinPercentage == 52) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CriteriaFilterModal(filter: filter, onApplyCallback: () => loadPivotMatches());
                      },
                    );
                  } else {
                    filter.pivotMinHomeWinPercentage = 52;
                    filter.pivotMinDrawPercentage = 52;
                    filter.pivotMinAwayWinPercentage = 52;

                    setState(() => filter = filter);

                    loadPivotMatches();
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  shadowColor: Colors.purple,
                  backgroundColor: filter.allPivotMinPercentSpecificValue(52) ? Colors.indigoAccent : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list, color: filter.allPivotMinPercentSpecificValue(52) ? Colors.white : null),
                    const SizedBox(width: 1),
                    Text(
                      "52 %",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: filter.allPivotMinPercentSpecificValue(52) ? Colors.white : null,
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

  Widget pivotMatchesCarousel(List<Record> pivotRecords, ScrollController scrollController) {
    return SizedBox(
      height: 66.6,
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            scrollController.jumpTo(scrollController.offset + event.scrollDelta.dy);
          }
        },
        child: Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          trackVisibility: true,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            itemCount: pivotRecords.length,
            itemBuilder: (BuildContext context, int index) {
              final Record match = pivotRecords[index];

              final List<Color> colors = [];

              if (match.anyPercentageHigherThan(80)) {
                colors.add(Colors.red[300] as Color);
              } else if (match.anyPercentageHigherThan(65)) {
                colors.add(Colors.orange[300] as Color);
              } else if (match.anyPercentageHigherThan(52)) {
                colors.add(Colors.amber[300] as Color);
              }

              if (selectedMatchId == match.id) {
                colors.add(Colors.grey[300] as Color);
                if (colors.length == 2) {
                  colors.add(colors.first);
                }
              }

              if (colors.isEmpty) {
                colors.add(Colors.grey[100] as Color);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors, stops: colors.length == 1 ? [0.0] : [0.2, 0.4, 0.8]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 0.7),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        if (hideFiltersOnPivotRecordSelect) showFilters = false;
                        loadPastMatches(match.id as int, index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              match.homeTeam.name,
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat.MMMMd("pt-BR").format(match.matchDate),
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  DateFormat.Hm("pt-BR").format(match.matchDate),
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                            Text(
                              match.awayTeam.name,
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
                          loadPivotMatches();
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
