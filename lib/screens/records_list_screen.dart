import "package:fluent_ui/fluent_ui.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/models/record.dart";
import "package:flutter/material.dart"
    show AppBar, CircularProgressIndicator, Scaffold;
import "package:pluto_grid/pluto_grid.dart";

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key, required this.title});
  final String title;

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final viewKey = GlobalKey();

  List<Record> records = [];
  late DateTime selectedStartDate;
  late DateTime selectedEndDate;

  PlutoGridStateManager? stateManager;

  void _loadRecords() async {
    final fetchedRecords = await DatabaseService.fetchRecords();
    debugPrint("Fetched ${fetchedRecords.length} records");

    setState(() {
      records = fetchedRecords;
    });
  }

  @override
  void initState() {
    _loadRecords();
    selectedStartDate = DateTime.now().subtract(Duration(days: 30));
    selectedEndDate = DateTime.now();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Records')),
      body: Container(
        padding: const EdgeInsets.all(30),
        child:
            records.isEmpty
                ? Center(child: CircularProgressIndicator())
                : PlutoGrid(
                  columns: _getColumns(),
                  columnGroups: _getFirstRow(),
                  rows: _getRows(),
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    stateManager = event.stateManager;
                    stateManager?.setShowColumnFilter(true);
                  },
                  onChanged: (PlutoGridOnChangedEvent event) {
                    debugPrint(event.toString());
                  },
                  configuration: const PlutoGridConfiguration(
                    scrollbar: PlutoGridScrollbarConfig(
                      isAlwaysShown: true,
                      draggableScrollbar: true,
                    ),
                  ),
                ),
      ),
    );
  }

  List<PlutoColumnGroup> _getFirstRow() {
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

  List<PlutoColumn> _getColumns() {
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

  List<PlutoRow> _getRows() {
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
