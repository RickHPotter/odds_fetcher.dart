import "dart:async";

import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:intl/date_symbol_data_local.dart";
import "package:intl/intl.dart";
import "package:odds_fetcher/jobs/records_fetcher.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/league_folder.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/widgets/leagues_folders_filter.dart" show LeaguesFoldersFilterButton;
import "package:odds_fetcher/widgets/match_card.dart";
import "package:odds_fetcher/widgets/odds_filter.dart" show OddsFilterButton;
import "package:odds_fetcher/widgets/past_matches_datatable.dart";
import "package:odds_fetcher/utils/parse_utils.dart" show humaniseNumber, humaniseTime;
import "package:odds_fetcher/widgets/overlay_message.dart" show MessageType, showOverlayMessage;

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  Future<List<Record>>? records;
  late List<Record> pivotRecords = [];
  late List<League> leagues = [];
  late List<Folder> folders = [];
  late List<LeagueFolder> leaguesFolders = [];

  late int filterPastYears = 1;
  late int filterFutureNextMinutes = 60;
  late Filter filter = Filter(
    filterName: "Filtro Padrão",
    minDate: DateTime.now(),
    maxDate: DateTime.now(),
    leagues: [],
    folders: [],
    futureMinHomeWinPercentage: 1,
  );

  late RecordFetcher fetcher;
  String currentDate = DateTime.now().toString();
  int progress = 0;
  bool isFetching = false;
  bool isCancelled = false;
  bool isLoading = false;

  late Map<Odds, bool> selectedOddsMap;

  bool isEarly1 = true;
  bool isEarlyX = false;
  bool isEarly2 = true;
  bool isFinal1 = false;
  bool isFinalX = false;
  bool isFinal2 = false;
  bool isSameLeague = false;

  int? selectedMatchId;
  int? pivotRecordIndex;

  bool showFilters = true;

  final List<int> futureMatchesMinutesList = [10, 30, 60, 60 * 3, 60 * 6, 60 * 12, 60 * 24, 60 * 24 * 2, 60 * 24 * 3];
  final List<int> pastYearsList = [1, 2, 3, 4, 5, 8, 10, 15, 20];

  StreamSubscription<Record>? _recordSubscription;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController yearController = TextEditingController();

  bool? hideFiltersOnFutureRecordSelect = true;

  void updateOddsFilter() {
    selectedOddsMap = {
      Odds.earlyOdds1: isEarly1,
      Odds.earlyOddsX: isEarlyX,
      Odds.earlyOdds2: isEarly2,
      Odds.finalOdds1: isFinal1,
      Odds.finalOddsX: isFinalX,
      Odds.finalOdds2: isFinal2,
    };

    filter.futureSameEarlyHome = isEarly1 ? 1 : 0;
    filter.futureSameEarlyDraw = isEarlyX ? 1 : 0;
    filter.futureSameEarlyAway = isEarly2 ? 1 : 0;

    filter.futureSameFinalHome = isFinal1 ? 1 : 0;
    filter.futureSameFinalDraw = isFinalX ? 1 : 0;
    filter.futureSameFinalAway = isFinal2 ? 1 : 0;
  }

  void updateTimeFilter() {
    filter.update(pastYears: filterPastYears, futureNextMinutes: filterFutureNextMinutes);
  }

  Future<void> fetchFromMaxMatchDate() async {
    final DateTime minDateToFetch = await DatabaseService.fetchFromMaxMatchDate();

    if (minDateToFetch != DateTime.now()) {
      startFetching(minDate: minDateToFetch);
    }

    startFetchingFuture();
  }

  void updateFutureSameOddsTypes() {
    if (filter.anySpecificOddsPresent()) {
      isEarly1 = filter.minEarlyHome != null ? false : isEarly1;
      isEarlyX = filter.minEarlyDraw != null ? false : isEarlyX;
      isEarly2 = filter.minEarlyAway != null ? false : isEarly2;
      isFinal1 = filter.minFinalHome != null ? false : isFinal1;
      isFinalX = filter.minFinalDraw != null ? false : isFinalX;
      isFinal2 = filter.minFinalAway != null ? false : isFinal2;

      updateOddsFilter();
    }

    setState(() {
      filter = filter;
      isEarly1 = isEarly1;
      isEarlyX = isEarlyX;
      isEarly2 = isEarly2;
      isFinal1 = isFinal1;
      isFinalX = isFinalX;
      isFinal2 = isFinal2;
    });
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

    _recordSubscription = DatabaseService.fetchFutureRecords(filter: filter).listen(
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

  void loadLeaguesAndFolders() async {
    final List<League> fetchedLeagues = await DatabaseService.fetchLeagues();
    final List<Folder> fetchedFolders = await DatabaseService.fetchFoldersWithLeagues();

    setState(() {
      leagues = fetchedLeagues;
      folders = fetchedFolders;
    });
  }

  @override
  void initState() {
    initializeDateFormatting("pt-BR");

    updateOddsFilter();
    updateTimeFilter();

    fetcher = RecordFetcher();
    fetcher.progressStream.listen((value) {
      setState(() => progress = value);
    });
    fetcher.currentDateStream.listen((value) {
      setState(() => currentDate = value);
    });

    fetchFromMaxMatchDate();
    loadFutureMatches();
    loadLeaguesAndFolders();

    super.initState();
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
      isFetching = true;
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

    setState(() => isFetching = false);
  }

  void startFetchingFuture() async {
    setState(() {
      isFetching = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertFutureRecords(isCancelledCallback: () => isCancelled);

    if (mounted && !isCancelled) showOverlayMessage(context, "Jogos futuros buscados com sucesso!");

    setState(() => isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (showFilters)
            // Past Matches Filter
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.history)),
                  for (var time in pastYearsList)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.085,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                        child: ElevatedButton(
                          onPressed: () => filterHistoryMatches(time: time),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: time == filterPastYears ? Colors.blueAccent : null,
                          ),
                          child: Text(
                            time <= 1 ? "$time ano" : "$time anos",
                            style: TextStyle(color: time == filterPastYears ? Colors.white : null),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.085,
                    height: MediaQuery.of(context).size.height * 0.042,
                    child: TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null ? "Ano Inválido" : null,
                      decoration: InputDecoration(
                        labelText: "Ano",
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
            // Future Matches Filter
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.update)),
                  for (var minutes in futureMatchesMinutesList)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.085,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                        child: ElevatedButton(
                          onPressed: () => filterUpcomingMatches(minutes),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: minutes == filterFutureNextMinutes ? Colors.blueAccent : null,
                          ),
                          child: Text(
                            humaniseTime(minutes, short: true),
                            style: TextStyle(color: minutes == filterFutureNextMinutes ? Colors.white : null),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.085,
                    height: MediaQuery.of(context).size.height * 0.042,
                    child: TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null ? "Ano Inválido" : null,
                      decoration: InputDecoration(
                        labelText: "Ano",
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
            // Both Matches Filter
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.tune)),
                  ...[
                    Odds.earlyOdds1,
                    Odds.earlyOddsX,
                    Odds.earlyOdds2,
                    Odds.finalOdds1,
                    Odds.finalOddsX,
                    Odds.finalOdds2,
                  ].map((oddsType) {
                    final isSelected = selectedOddsMap[oddsType] ?? false;

                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.085,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () => filterMatchesBySimiliarity(oddsType),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: isSelected ? Colors.blueAccent : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dehaze, color: isSelected ? Colors.white : null),
                              const SizedBox(width: 1),
                              Text(oddsType.shortName, style: TextStyle(color: isSelected ? Colors.white : null)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.085,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => filterMatchesBySameLeague(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: isSameLeague ? Colors.blueAccent : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dehaze, color: isSameLeague ? Colors.white : null),
                            const SizedBox(width: 1),
                            Text("Liga", style: TextStyle(color: isSameLeague ? Colors.white : null)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.085,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: LeaguesFoldersFilterButton(
                        filter: filter,
                        leagues: leagues,
                        folders: folders,
                        onApplyCallback: () {
                          loadFutureMatches();
                          if (isSameLeague && (filter.leagues.isNotEmpty || filter.folders.isNotEmpty)) {
                            setState(() => isSameLeague = false);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.085,
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
                    width: MediaQuery.of(context).size.width * 0.085,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            filter.futureMinHomeWinPercentage = filter.futureMinHomeWinPercentage == 1 ? 0 : 1;
                            loadFutureMatches();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: filter.futureMinHomeWinPercentage == 1 ? Colors.blueAccent : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: filter.futureMinHomeWinPercentage == 1 ? Colors.white : null,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              "52%",
                              style: TextStyle(color: filter.futureMinHomeWinPercentage == 1 ? Colors.white : null),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: hideFiltersOnFutureRecordSelect,
                    onChanged: (bool? value) {
                      setState(() {
                        hideFiltersOnFutureRecordSelect = value;
                      });
                    },
                  ),
                  const Text("Ocultar Filtros"),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Future Matches Carousel
          SizedBox(
            height: 66,
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _scrollController.jumpTo(_scrollController.offset + event.scrollDelta.dy);
                }
              },
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                trackVisibility: true,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  itemCount: pivotRecords.length,
                  itemBuilder: (context, index) {
                    final match = pivotRecords[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          showFilters =
                              hideFiltersOnFutureRecordSelect != null && hideFiltersOnFutureRecordSelect!
                                  ? false
                                  : showFilters;
                          loadPastMatches(match.id as int, index);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              selectedMatchId == match.id
                                  ? Colors.grey[300]
                                  : match.anyPercentageHigherThan(80)
                                  ? Colors.red[300]
                                  : match.anyPercentageHigherThan(65)
                                  ? Colors.orange[300]
                                  : match.anyPercentageHigherThan(52)
                                  ? Colors.amber[300]
                                  : Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                            side: const BorderSide(color: Colors.black),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              match.homeTeam.name,
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat.MMMMd("pt-BR").format(match.matchDate), style: TextStyle(fontSize: 12)),
                                SizedBox(width: 10),
                                Text(DateFormat.Hm("pt-BR").format(match.matchDate), style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Text(
                              match.awayTeam.name,
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (selectedMatchId != null && pivotRecords.isNotEmpty && pivotRecordIndex != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: MatchCard(records: records, pivotRecord: pivotRecords[pivotRecordIndex as int]),
            ),
          PastMachDataTable(records: records),
          const Divider(),
          // Footer and Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () {},
                  child: Text(
                    filter.filterName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                isLoading
                    ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator())
                    : SizedBox(width: 20, height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${humaniseNumber(pivotRecords.length)} jogos futuros encontrados.",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
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
                            "0 jogos passados encontrados.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        }
                        return Text(
                          "${humaniseNumber(snapshot.data!.length)} jogos passados encontrados.",
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
                  child: Text(showFilters ? "Ocultar Filtros" : "Mostrar Filtros"),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      isFetching
                          ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.32,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(value: progress / 100),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            isCancelled = true;
                                            isFetching = false;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                        ),
                                        child: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                      ),
                                      Text(
                                        currentDate,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
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
                          : Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: ElevatedButton(
                                  onPressed: startFetching,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  ),
                                  child: const Text("Buscar Jogos Passados"),
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: ElevatedButton(
                                  onPressed: startFetchingFuture,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  ),
                                  child: const Text("Buscar Jogos Futuros"),
                                ),
                              ),
                            ],
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
      showOverlayMessage(context, "Filtro de Tempo Passado preenchido incompletamente!", type: MessageType.info);
      return;
    }

    if (time != null && specificYear == null) {
      filterPastYears = time;
      filter.minDate = DateTime.now().subtract(Duration(days: time * 365));
    } else if (time == null && specificYear != null) {
      filterPastYears = 0;
      filter.minDate = DateTime(specificYear, 1, 1);
      filter.maxDate = DateTime(specificYear, 12, 31);
    }

    loadPastMatches(selectedMatchId, pivotRecordIndex);

    setState(() {
      filterPastYears = filterPastYears;
    });
  }

  void filterUpcomingMatches(int duration) {
    filterFutureNextMinutes = duration;
    filter.futureNextMinutes = duration;

    loadFutureMatches();
  }

  void filterMatchesBySimiliarity(Odds oddType) {
    setState(() {
      switch (oddType) {
        case Odds.earlyOdds1:
          isEarly1 = !isEarly1;
          break;
        case Odds.earlyOddsX:
          isEarlyX = !isEarlyX;
          break;
        case Odds.earlyOdds2:
          isEarly2 = !isEarly2;
          break;
        case Odds.finalOdds1:
          isFinal1 = !isFinal1;
          break;
        case Odds.finalOddsX:
          isFinalX = !isFinalX;
          break;
        case Odds.finalOdds2:
          isFinal2 = !isFinal2;
          break;
      }

      updateOddsFilter();

      if (filter.futureMinHomeWinPercentage == 1) {
        loadFutureMatches();
      } else {
        loadPastMatches(selectedMatchId, pivotRecordIndex);
      }
    });
  }

  void filterMatchesBySameLeague() {
    isSameLeague = !isSameLeague;

    filter.futureOnlySameLeague = isSameLeague ? 1 : 0;

    filter.leagues.clear();

    setState(() {
      isSameLeague = isSameLeague;
      filter = filter;
    });

    loadPastMatches(selectedMatchId, pivotRecordIndex);
  }
}
