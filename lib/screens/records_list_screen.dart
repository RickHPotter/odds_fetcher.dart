import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:intl/intl.dart";
import "package:odds_fetcher/jobs/records_fetcher.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/models/record.dart";
import "package:pluto_grid/pluto_grid.dart";

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  Future<List<Record>>? records;
  late List<Record> pivotRecords = [];

  late int filterPastYears = 1;
  late int filterFutureNextMinutes = 60;
  late Filter filter = Filter(
    filterName: "Filtro Padrão",
    startDate: DateTime.now(),
    endDate: DateTime.now(),
  );

  late RecordFetcher fetcher;
  String currentDate = DateTime.now().toString();
  int progress = 0;
  bool isFetching = false;
  bool isCancelled = false;

  int? selectedMatchId;

  late PlutoGridStateManager stateManager;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> loadMaxMatchDate() async {
    final startDateToFetch = await DatabaseService.loadMaxMatchDate();

    if (startDateToFetch != DateTime.now()) {
      startFetching(startDate: startDateToFetch);
    }

    startFetchingFuture();
  }

  void loadFutureMatches() async {
    final fetchedRecords = await DatabaseService.fetchFutureRecords(
      filter: filter,
    );

    debugPrint(fetchedRecords.length.toString());

    setState(() => pivotRecords = fetchedRecords);
  }

  void loadPastMatches(int id) async {
    final fetchedRecords = DatabaseService.fetchRecords(id: id, filter: filter);

    setState(() {
      selectedMatchId = id;
      records = fetchedRecords;
    });
  }

  @override
  void initState() {
    initializeDateFormatting("pt-BR");
    filter.update(
      futureNextMinutes: filterFutureNextMinutes,
      pastYears: filterPastYears,
    );

    fetcher = RecordFetcher();
    fetcher.progressStream.listen((value) {
      setState(() => progress = value);
    });
    fetcher.currentDateStream.listen((value) {
      setState(() => currentDate = value);
    });

    //loadMaxMatchDate();
    startFetchingFuture();
    loadFutureMatches();

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

    await fetcher.fetchAndInsertRecords(
      startDate: startDate,
      endDate: endDate,
      isCancelledCallback: () => isCancelled,
    );

    if (!isCancelled) showSuccessDialog("Jogos passados buscados com sucesso!");
    setState(() => isFetching = false);
  }

  void startFetchingFuture() async {
    setState(() {
      isFetching = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertFutureRecords(
      isCancelledCallback: () => isCancelled,
    );

    if (!isCancelled) showSuccessDialog("Jogos futuros buscados com sucesso!");
    setState(() => isFetching = false);
  }

  void showSuccessDialog(String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sucesso!"),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // FILTERS
  void filterHistoryMatches(int time) {
    filterPastYears = time;
    filter.startDate = DateTime.now().subtract(Duration(days: time * 365));
    loadFutureMatches();
  }

  void filterUpcomingMatches(int duration) {
    filterFutureNextMinutes = duration;
    filter.futureNextMinutes = duration;
    loadFutureMatches();
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(20),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      "${pivotRecords.length} jogos futuros encontrados.",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    FutureBuilder<List<Record>>(
                      future: records,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            "Carregando jogos passados...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            "Erro ao carregar jogos passados.",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text(
                            "0 jogos passados encontrados.",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return Text(
                          "${snapshot.data!.length} jogos passados encontrados.",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Fetch Controls
                SizedBox(
                  width: 400,
                  height: 140,
                  child:
                      isFetching
                          ? Padding(
                            padding: const EdgeInsetsDirectional.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentDate.split(" ")[0],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: const Text(
                                    "Abort",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Row(
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.all(10),
                                child: ElevatedButton(
                                  onPressed: startFetching,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                  ),
                                  child: const Text("Buscar Jogos"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.all(10),
                                child: ElevatedButton(
                                  onPressed: startFetchingFuture,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                  ),
                                  child: const Text("Buscar Jogos Futuros"),
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Past Matches Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: const Text(
                    "Jogos Passados:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                for (var time in [1, 2, 3, 5, 8, 10, 15, 20])
                  SizedBox(
                    width: 180,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () => filterHistoryMatches(time),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadowColor: Colors.purple,
                          backgroundColor:
                              time == filterPastYears
                                  ? Colors.blueAccent
                                  : null,
                        ),
                        child: Text(
                          time <= 1 ? "$time ano" : "$time anos",
                          style: TextStyle(
                            color:
                                time == filterPastYears ? Colors.white : null,
                          ),
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
                  width: 180,
                  child: const Text(
                    "Jogos Futuros:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                for (var minutes in [10, 30, 60, 60 * 3, 60 * 6, 60 * 12])
                  SizedBox(
                    width: 180,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: (8.0)),
                      child: ElevatedButton(
                        onPressed: () => filterUpcomingMatches(minutes),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadowColor: Colors.purple,
                          backgroundColor:
                              minutes == filterFutureNextMinutes
                                  ? Colors.blueAccent
                                  : null,
                        ),
                        child: Text(
                          minutes < 60
                              ? "$minutes minutos"
                              : minutes == 60
                              ? "${minutes ~/ 60} hora"
                              : "${minutes ~/ 60} horas",
                          style: TextStyle(
                            color:
                                minutes == filterFutureNextMinutes
                                    ? Colors.white
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
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
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton(
                        onPressed: () => loadPastMatches(match.id as int),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              selectedMatchId == match.id
                                  ? Colors.grey[400]
                                  : Colors.grey[100],
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
                            const Text(
                              "x",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                  DateFormat.MMMMd(
                                    "pt-BR",
                                  ).format(match.matchDate),
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat.Hm(
                                    "pt-BR",
                                  ).format(match.matchDate),
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 12,
                                  ),
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
            const SizedBox(height: 20),

            // Match Details
            if (selectedMatchId != null)
              Text(
                "Details for Match ID: $selectedMatchId",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

            // Past Matches DataTable
            Expanded(
              child: FutureBuilder<List<Record>>(
                future: records,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No past matches found."));
                  }

                  final records = snapshot.data!;
                  return PlutoGrid(
                    columns: getColumns(),
                    rows: getRows(records),
                    onLoaded: (event) {
                      stateManager = event.stateManager;
                      stateManager.setShowColumnFilter(true);
                    },
                    configuration: PlutoGridConfiguration(
                      scrollbar: const PlutoGridScrollbarConfig(
                        isAlwaysShown: true,
                        draggableScrollbar: true,
                      ),
                      style: PlutoGridStyleConfig(
                        gridBorderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //List<PlutoColumnGroup> getFirstRow() {
  //  if (records.isEmpty) {
  //    return [];
  //  }
  //
  //  final Record record = records.first;
  //
  //  return [
  //    PlutoColumnGroup(
  //      title: record.matchDate.toString().split(".")[0],
  //      fields: ["dia"],
  //    ),
  //    PlutoColumnGroup(title: record.league.code, fields: ["liga"]),
  //    PlutoColumnGroup(title: record.homeTeam.name, fields: ["home"]),
  //    PlutoColumnGroup(title: record.awayTeam.name, fields: ["away"]),
  //    PlutoColumnGroup(title: record.firstHalfScore, fields: ["intervalo"]),
  //    PlutoColumnGroup(title: record.secondHalfScore, fields: ["placar"]),
  //    PlutoColumnGroup(
  //      title: record.earlyOdds1 == null ? "" : record.earlyOdds1.toString(),
  //      fields: ["early_home"],
  //    ),
  //    PlutoColumnGroup(
  //      title: record.earlyOddsX == null ? "" : record.earlyOddsX.toString(),
  //      fields: ["early_draw"],
  //    ),
  //    PlutoColumnGroup(
  //      title: record.earlyOdds2 == null ? "" : record.earlyOdds2.toString(),
  //      fields: ["early_away"],
  //    ),
  //    PlutoColumnGroup(
  //      title: record.finalOdds1 == null ? "" : record.finalOdds1.toString(),
  //      fields: ["final_home"],
  //    ),
  //    PlutoColumnGroup(
  //      title: record.finalOddsX == null ? "" : record.finalOddsX.toString(),
  //      fields: ["final_draw"],
  //    ),
  //    PlutoColumnGroup(
  //      title: record.finalOdds2 == null ? "" : record.finalOdds2.toString(),
  //      fields: ["final_away"],
  //    ),
  //  ];
  //}

  List<PlutoColumn> getColumns() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate dynamic width based on screen size
    final baseWidth = screenWidth * 0.06; // 5% of screen width
    final largerWidth = screenWidth * 0.12; // 10% for more important columns

    return [
      PlutoColumn(
        title: "DIA",
        field: "dia",
        type: PlutoColumnType.date(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "LIGA",
        field: "liga",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: largerWidth,
      ),
      PlutoColumn(
        title: "HOME",
        field: "home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: largerWidth,
      ),
      PlutoColumn(
        title: "AWAY",
        field: "away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: largerWidth,
      ),
      PlutoColumn(
        title: "INTERVALO",
        field: "intervalo",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FIM DE JOGO",
        field: "placar",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "EARLY 1",
        field: "early_home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "EARLY X",
        field: "early_draw",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "EARLY 2",
        field: "early_away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FINAL 1",
        field: "final_home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FINAL X",
        field: "final_draw",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FINAL 2",
        field: "final_away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
    ];
  }

  List<PlutoRow> getRows(List<Record> records) {
    return records.map((record) {
      return PlutoRow(
        cells: {
          "dia": PlutoCell(value: record.matchDate.toString()),
          "liga": PlutoCell(value: record.league.code),
          "home": PlutoCell(value: record.homeTeam.name),
          "away": PlutoCell(value: record.awayTeam.name),
          "intervalo": PlutoCell(value: record.firstHalfScore),
          "placar": PlutoCell(value: record.secondHalfScore),
          "early_home": PlutoCell(value: record.earlyOdds1?.toString() ?? ""),
          "early_draw": PlutoCell(value: record.earlyOddsX?.toString() ?? ""),
          "early_away": PlutoCell(value: record.earlyOdds2?.toString() ?? ""),
          "final_home": PlutoCell(value: record.finalOdds1?.toString() ?? ""),
          "final_draw": PlutoCell(value: record.finalOddsX?.toString() ?? ""),
          "final_away": PlutoCell(value: record.finalOdds2?.toString() ?? ""),
        },
      );
    }).toList();
  }
}
