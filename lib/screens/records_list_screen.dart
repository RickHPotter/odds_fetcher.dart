import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:intl/intl.dart";
import "package:odds_fetcher/jobs/records_fetcher.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/widgets/leagues_folders_filter.dart" show LeagueFolderFilterButton;
import "package:odds_fetcher/widgets/match_card.dart";
import "package:odds_fetcher/widgets/past_matches_datatable.dart";
import "package:odds_fetcher/utils/parse_utils.dart" show humanisedTime;
//import "package:odds_fetcher/widgets/success_dialog.dart" show showSuccessDialog;

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

  late int filterPastYears = 1;
  late int filterFutureNextMinutes = 60;
  late Filter filter = Filter(filterName: "Filtro Padrão", startDate: DateTime.now(), endDate: DateTime.now());

  late RecordFetcher fetcher;
  String currentDate = DateTime.now().toString();
  int progress = 0;
  bool isFetching = false;
  bool isCancelled = false;
  bool isEarly = true;
  bool isFinal = false;
  bool isSameLeague = false;

  int? selectedMatchId;
  int? pivotRecordIndex;

  final futureMatchesMinutesList = [10, 30, 60, 60 * 3, 60 * 6, 60 * 12, 60 * 24, 60 * 24 * 2];
  final pastYearsList = [1, 2, 3, 5, 8, 10, 15, 20];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void updateFilter() {
    filter.update(pastYears: filterPastYears, futureNextMinutes: filterFutureNextMinutes);

    int isEarlyBoolInt = isEarly ? 1 : 0;
    int isFinalBoolInt = isFinal ? 1 : 0;

    filter
      ..futureSameEarlyHome = isEarlyBoolInt
      ..futureSameEarlyDraw = isEarlyBoolInt
      ..futureSameEarlyAway = isEarlyBoolInt
      ..futureSameFinalHome = isFinalBoolInt
      ..futureSameFinalDraw = isFinalBoolInt
      ..futureSameFinalAway = isFinalBoolInt;
  }

  Future<void> fetchFromMaxMatchDate() async {
    final startDateToFetch = await DatabaseService.fetchFromMaxMatchDate();

    if (startDateToFetch != DateTime.now()) {
      startFetching(startDate: startDateToFetch);
    }

    startFetchingFuture();
  }

  void loadFutureMatches() async {
    final fetchedRecords = await DatabaseService.fetchFutureRecords(filter: filter);

    if (pivotRecords.isNotEmpty && pivotRecordIndex != null) {
      Record pivotRecord = pivotRecords[pivotRecordIndex as int];
      pivotRecordIndex = fetchedRecords.indexWhere((record) => record.id == pivotRecord.id);

      if (pivotRecordIndex == -1) {
        pivotRecordIndex = null;
      }
    } else {
      pivotRecordIndex = 0;
    }

    setState(() {
      pivotRecords = fetchedRecords;
      pivotRecordIndex = pivotRecordIndex;
    });
  }

  void loadPastMatches(int? id, int? index) async {
    if (id == null || index == null) {
      return;
    }

    final futurePivotRecord = pivotRecords[index];
    final fetchedRecords = DatabaseService.fetchRecords(
      filter: filter,
      early1: futurePivotRecord.earlyOdds1,
      earlyX: futurePivotRecord.earlyOddsX,
      early2: futurePivotRecord.earlyOdds2,
      final1: futurePivotRecord.finalOdds1,
      finalX: futurePivotRecord.finalOddsX,
      final2: futurePivotRecord.finalOdds2,
    );

    setState(() {
      selectedMatchId = id;
      records = fetchedRecords;
      pivotRecordIndex = index;
    });
  }

  void loadLeaguesAndFolders() async {
    final fetchedLeagues = await DatabaseService.fetchLeagues();
    final fetchedFolders = await DatabaseService.fetchFolders();

    setState(() {
      leagues = fetchedLeagues;
      folders = fetchedFolders;
    });
  }

  @override
  void initState() {
    initializeDateFormatting("pt-BR");

    updateFilter();

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
    super.dispose();
  }

  void startFetching({DateTime? startDate, DateTime? endDate}) async {
    startDate ??= DateTime.parse("2008-01-01");
    endDate ??= DateTime.now().subtract(Duration(days: 1));

    setState(() {
      isFetching = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertRecords(startDate: startDate, endDate: endDate, isCancelledCallback: () => isCancelled);

    //if (mounted && !isCancelled) showSuccessDialog(context, "Jogos passados buscados com sucesso!");

    setState(() => isFetching = false);
  }

  void startFetchingFuture() async {
    setState(() {
      isFetching = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertFutureRecords(isCancelledCallback: () => isCancelled);

    //if (mounted && !isCancelled) showSuccessDialog(context, "Jogos futuros buscados com sucesso!");

    setState(() => isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Filtro: ${filter.filterName}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            // Header and Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filter.filterName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    Text(
                      "${pivotRecords.length} jogos futuros encontrados.",
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
                          "${snapshot.data!.length} jogos passados encontrados.",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
                // Fetch Controls
                SizedBox(
                  width: 400,
                  height: 125,
                  child:
                      isFetching
                          ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentDate.split(" ")[0],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                LinearProgressIndicator(value: progress / 100),
                                const SizedBox(height: 5),
                                Text("$progress%"),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      isCancelled = true;
                                      isFetching = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: const Text("Abort", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                          : Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ElevatedButton(
                                  onPressed: startFetching,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                  ),
                                  child: const Text("Buscar Jogos"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ElevatedButton(
                                  onPressed: startFetchingFuture,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                  ),
                                  child: const Text("Buscar Jogos Futuros"),
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
            // Past Matches Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: const Text("Jogos Passados:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                for (var time in pastYearsList)
                  SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () => filterHistoryMatches(time),
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
              ],
            ),
            const SizedBox(height: 10),
            // Future Matches Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: const Text("Jogos Futuros:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                for (var minutes in futureMatchesMinutesList)
                  SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: (8.0)),
                      child: ElevatedButton(
                        onPressed: () => filterUpcomingMatches(minutes),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: minutes == filterFutureNextMinutes ? Colors.blueAccent : null,
                        ),
                        child: Text(
                          humanisedTime(minutes),
                          style: TextStyle(color: minutes == filterFutureNextMinutes ? Colors.white : null),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: const Text("Similaridade:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () => filterMatchesBySimiliarity("early"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        shadowColor: Colors.purple,
                        backgroundColor: isEarly ? Colors.blueAccent : null,
                      ),
                      child: Text("Early", style: TextStyle(color: isEarly ? Colors.white : null)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () => filterMatchesBySimiliarity("final"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        shadowColor: Colors.purple,
                        backgroundColor: isFinal ? Colors.blueAccent : null,
                      ),
                      child: Text("Final", style: TextStyle(color: isFinal ? Colors.white : null)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          const SizedBox(width: 2),
                          Text("Mesma Liga", style: TextStyle(color: isSameLeague ? Colors.white : null)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: LeagueFolderFilterButton(folders: folders, leagues: leagues),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Future Matches Carrousel
            SizedBox(
              height: 100,
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _scrollController.jumpTo(_scrollController.offset + event.scrollDelta.dy);
                  }
                },
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    itemCount: pivotRecords.length,
                    itemBuilder: (context, index) {
                      final match = pivotRecords[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () => loadPastMatches(match.id as int, index),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedMatchId == match.id ? Colors.grey[400] : Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                match.homeTeam.name,
                                style: TextStyle(color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text("x", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(
                                match.awayTeam.name,
                                style: TextStyle(color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    DateFormat.MMMMd("pt-BR").format(match.matchDate),
                                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    DateFormat.Hm("pt-BR").format(match.matchDate),
                                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                                  ),
                                ],
                              ),
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
            if (selectedMatchId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: MatchCard(records: records, pivotRecord: pivotRecords[pivotRecordIndex as int]),
              ),
            PastMachDataTable(records: records),
          ],
        ),
      ),
    );
  }

  // FILTERS
  void filterHistoryMatches(int time) {
    filterPastYears = time;
    filter.startDate = DateTime.now().subtract(Duration(days: time * 365));

    loadPastMatches(selectedMatchId, pivotRecordIndex);
  }

  void filterUpcomingMatches(int duration) {
    filterFutureNextMinutes = duration;
    filter.futureNextMinutes = duration;

    loadFutureMatches();
  }

  void filterMatchesBySimiliarity(String option) {
    if (option == "early") {
      isEarly = !isEarly;
      int sqliteBool = isEarly ? 1 : 0;

      filter
        ..futureSameEarlyHome = sqliteBool
        ..futureSameEarlyDraw = sqliteBool
        ..futureSameEarlyAway = sqliteBool;
    }

    if (option == "final") {
      isFinal = !isFinal;
      int sqliteBool = isFinal ? 1 : 0;

      filter
        ..futureSameFinalHome = sqliteBool
        ..futureSameFinalDraw = sqliteBool
        ..futureSameFinalAway = sqliteBool;
    }

    setState(() {
      isEarly = isEarly;
      isFinal = isFinal;
      filter = filter;
    });

    loadPastMatches(selectedMatchId, pivotRecordIndex);
  }

  void filterMatchesBySameLeague() {
    isSameLeague = !isSameLeague;

    filter.futureOnlySameLeague = isSameLeague ? 1 : 0;

    setState(() {
      isSameLeague = isSameLeague;
      filter = filter;
    });

    loadPastMatches(selectedMatchId, pivotRecordIndex);
  }
}
