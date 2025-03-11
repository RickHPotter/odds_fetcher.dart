import "package:flutter/material.dart";
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
  final viewKey = GlobalKey();

  List<Record> records = [];
  late int filterPastYears = 1;
  late Duration filterFutureNext = Duration(hours: 1);
  Filter filter = Filter();

  late PlutoGridStateManager stateManager;

  void _loadRecords() async {
    final fetchedRecords = await DatabaseService.fetchRecords(filter: filter);

    setState(() {
      records = fetchedRecords;
    });
  }

  @override
  void initState() {
    filter.updateFilter(
      futureNext: filterFutureNext,
      pastYears: filterPastYears,
    );
    _loadRecords();
    super.initState();
  }

  void filterWithPlutoGrid(String column, String keyword) {
    stateManager.setFilter(
      (element) =>
          element.cells[column]?.value.toString().contains(keyword) ?? false,
    );
  }

  void applyDbFilter() {
    _loadRecords();
  }

  void resetFilters() {
    filter = Filter();
    stateManager.setFilter(null);
  }

  void filterHistoryMatches(int time) {
    filterPastYears = time;
    filter.startDate = DateTime.now().subtract(Duration(days: time * 365));
    _loadRecords();
  }

  void filterUpcomingMatches(Duration duration) {
    filterFutureNext = duration;
    filter.futureNext = duration;
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Listagem de Jogos")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Últimos:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  "Próximos:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (var duration in [
                  Duration(minutes: 10),
                  Duration(minutes: 30),
                  Duration(hours: 1),
                  Duration(hours: 3),
                  Duration(hours: 6),
                  Duration(hours: 12),
                ])
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                      onPressed: () => filterUpcomingMatches(duration),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor:
                            duration == filterFutureNext ? Colors.blue : null,
                      ),
                      child: Text(
                        duration.inMinutes < 60
                            ? '${duration.inMinutes} min'
                            : '${duration.inHours} h',
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
