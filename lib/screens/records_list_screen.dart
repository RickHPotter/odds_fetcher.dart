import "package:flutter/material.dart";
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
  late List<Record> records = [];
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

  late PlutoGridStateManager stateManager;

  void _loadRecords() async {
    final fetchedRecords = await DatabaseService.fetchRecords(filter: filter);

    setState(() => records = fetchedRecords);
  }

  Future<void> loadMaxMatchDate() async {
    final startDateToFetch = await DatabaseService.loadMaxMatchDate();

    if (startDateToFetch != DateTime.now()) {
      startFetching(startDate: startDateToFetch);
    }
  }

  @override
  void initState() {
    filter.updateFilter(
      futureNextMinutes: filterFutureNextMinutes,
      pastYears: filterPastYears,
    );
    _loadRecords();

    fetcher = RecordFetcher();
    fetcher.progressStream.listen((value) {
      setState(() => progress = value);
    });

    fetcher.currentDateStream.listen((value) {
      setState(() => currentDate = value);
    });

    loadMaxMatchDate();

    super.initState();
  }

  @override
  void dispose() {
    fetcher.dispose();
    super.dispose();
  }

  //void filterWithPlutoGrid(String column, String keyword) {
  //  stateManager.setFilter(
  //    (element) =>
  //        element.cells[column]?.value.toString().contains(keyword) ?? false,
  //  );
  //}

  //void resetFilters() {
  //  filter = Filter();
  //  stateManager.setFilter(null);
  //}

  void startFetching({DateTime? startDate, DateTime? endDate}) async {
    debugPrint(DateTime.now().toString());

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

    if (!isCancelled) showSuccessDialog();
    setState(() => isFetching = false);
  }

  void showSuccessDialog() {
    debugPrint(DateTime.now().toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sucesso!"),
          content: Text("Jogos buscados com sucesso!"),
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

  void filterHistoryMatches(int time) {
    filterPastYears = time;
    filter.startDate = DateTime.now().subtract(Duration(days: time * 365));
    _loadRecords();
  }

  void filterUpcomingMatches(int duration) {
    filterFutureNextMinutes = duration;
    filter.futureNextMinutes = duration;
    _loadRecords();
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        toolbarHeight: 130,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: const Text("Listagem de Jogos")),
            if (!isFetching)
              Padding(
                padding: EdgeInsetsDirectional.all(10),
                child: ElevatedButton(
                  onPressed: startFetching,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text("Buscar Jogos"),
                ),
              ),
            if (isFetching)
              Padding(
                padding: EdgeInsetsDirectional.all(12),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentDate.split(" ")[0],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      LinearProgressIndicator(value: progress / 100),
                      SizedBox(height: 5),
                      Text("$progress%"),
                      SizedBox(height: 10),
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
                        child: Text(
                          "Abort",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              filter.filterName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              records.length.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Jogos Passados:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                for (var time in [1, 2, 3, 5, 8, 10, 15, 20])
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                      onPressed: () => filterHistoryMatches(time),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor:
                            time == filterPastYears ? Colors.blue : null,
                      ),
                      child: Text(time <= 1 ? '$time ano' : '$time anos'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Jogos Futuros:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                for (var minutes in [10, 30, 60, 60 * 3, 60 * 6, 60 * 12])
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                      onPressed: () => filterUpcomingMatches(minutes),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor:
                            minutes == filterFutureNextMinutes
                                ? Colors.blue
                                : null,
                      ),
                      child: Text(
                        minutes < 60
                            ? '$minutes minutos'
                            : minutes == 60
                            ? '${minutes ~/ 60} hora'
                            : '${minutes ~/ 60} horas',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  records.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : PlutoGrid(
                        columns: getColumns(),
                        columnGroups: getFirstRow(),
                        rows: getRows(),
                        onLoaded: (PlutoGridOnLoadedEvent event) {
                          stateManager = event.stateManager;
                          stateManager.setShowColumnFilter(true);
                        },
                        onChanged: (PlutoGridOnChangedEvent event) {
                          debugPrint(event.toString());
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
                      ),
            ),
          ],
        ),
      ),
    );
  }

  List<PlutoColumnGroup> getFirstRow() {
    if (records.isEmpty) {
      return [];
    }

    final Record record = records.first;

    return [
      PlutoColumnGroup(
        title: record.matchDate.toString().split(".")[0],
        fields: ["dia"],
      ),
      PlutoColumnGroup(title: record.league.code, fields: ["liga"]),
      PlutoColumnGroup(title: record.homeTeam.name, fields: ["home"]),
      PlutoColumnGroup(title: record.awayTeam.name, fields: ["away"]),
      PlutoColumnGroup(title: record.firstHalfScore, fields: ["intervalo"]),
      PlutoColumnGroup(title: record.secondHalfScore, fields: ["placar"]),
      PlutoColumnGroup(
        title: record.earlyOdds1 == null ? "" : record.earlyOdds1.toString(),
        fields: ["early_home"],
      ),
      PlutoColumnGroup(
        title: record.earlyOddsX == null ? "" : record.earlyOddsX.toString(),
        fields: ["early_draw"],
      ),
      PlutoColumnGroup(
        title: record.earlyOdds2 == null ? "" : record.earlyOdds2.toString(),
        fields: ["early_away"],
      ),
      PlutoColumnGroup(
        title: record.finalOdds1 == null ? "" : record.finalOdds1.toString(),
        fields: ["final_home"],
      ),
      PlutoColumnGroup(
        title: record.finalOddsX == null ? "" : record.finalOddsX.toString(),
        fields: ["final_draw"],
      ),
      PlutoColumnGroup(
        title: record.finalOdds2 == null ? "" : record.finalOdds2.toString(),
        fields: ["final_away"],
      ),
    ];
  }

  List<PlutoColumn> getColumns() {
    return [
      PlutoColumn(
        title: "DIA",
        field: "dia",
        type: PlutoColumnType.date(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 180,
      ),
      PlutoColumn(
        title: "LIGA",
        field: "liga",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
      PlutoColumn(
        title: "HOME",
        field: "home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 180,
      ),
      PlutoColumn(
        title: "AWAY",
        field: "away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 180,
      ),
      PlutoColumn(
        title: "PLACAR HT",
        field: "intervalo",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 140,
      ),
      PlutoColumn(
        title: "PLACAR FT",
        field: "placar",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 140,
      ),
      PlutoColumn(
        title: "E HOME",
        field: "early_home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
      PlutoColumn(
        title: "E DRAW",
        field: "early_draw",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
      PlutoColumn(
        title: "E AWAY",
        field: "early_away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
      PlutoColumn(
        title: "F HOME",
        field: "final_home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
      PlutoColumn(
        title: "F DRAW",
        field: "final_draw",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
      PlutoColumn(
        title: "F AWAY",
        field: "final_away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.center,
        textAlign: PlutoColumnTextAlign.center,
        width: 130,
      ),
    ];
  }

  List<PlutoRow> getRows() {
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
