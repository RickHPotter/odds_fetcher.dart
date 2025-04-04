import "package:flutter/material.dart";
import "package:odds_fetcher/models/filter.dart" show Filter;
import "package:odds_fetcher/models/record.dart";
import "package:pluto_grid/pluto_grid.dart";

class PastMachDataTable extends StatelessWidget {
  final Future<List<Record>>? records;
  final Filter filter;
  final double percentagesContainerWidthFactor = 0.10;

  const PastMachDataTable({super.key, required this.records, required this.filter});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    late PlutoGridStateManager stateManager;

    return Expanded(
      child: FutureBuilder<List<Record>>(
        future: records,
        builder: (BuildContext context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum jogo passado encontrado com os critérios informados."));
          }

          final List<Record> records = snapshot.data!;

          return PlutoGrid(
            columns: getColumns(screenWidth),
            rows: getRows(records, filter),
            rowColorCallback: (PlutoRowColorContext context) {
              final Record record = records[context.rowIdx];
              final int home = record.homeFullTimeScore ?? 0;
              final int away = record.awayFullTimeScore ?? 0;

              if (home == away) {
                return Colors.grey.shade200;
              } else if (home > away) {
                return Colors.blue.shade200;
              } else {
                return Colors.orange.shade300;
              }
            },
            onLoaded: (event) {
              stateManager = event.stateManager;
              stateManager.setShowColumnFilter(false);
            },
            configuration: PlutoGridConfiguration(
              localeText: const PlutoGridLocaleText.brazilianPortuguese(),
              scrollbar: const PlutoGridScrollbarConfig(
                isAlwaysShown: true,
                draggableScrollbar: true,
                scrollbarThickness: 8,
              ),
              style: PlutoGridStyleConfig(
                gridBorderRadius: BorderRadius.circular(8),
                columnHeight: 32,
                rowHeight: 24,
                columnTextStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  List<PlutoColumn> getColumns(double screenWidth) {
    final double baseWidth = screenWidth * 0.075;
    final double largerWidth = screenWidth * 0.116;

    return [
      PlutoColumn(
        title: "DIA",
        field: "dia",
        type: PlutoColumnType.date(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "LIGA",
        field: "liga",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "HOME",
        field: "home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: largerWidth,
      ),
      PlutoColumn(
        title: "AWAY",
        field: "away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: largerWidth,
      ),
      PlutoColumn(
        title: "1T",
        field: "intervalo",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FT",
        field: "placar",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "EARLY 1",
        field: "early_home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "EARLY X",
        field: "early_draw",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "EARLY 2",
        field: "early_away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FINAL 1",
        field: "final_home",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FINAL X",
        field: "final_draw",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
      PlutoColumn(
        title: "FINAL 2",
        field: "final_away",
        type: PlutoColumnType.text(),
        titleTextAlign: PlutoColumnTextAlign.start,
        textAlign: PlutoColumnTextAlign.center,
        width: baseWidth,
      ),
    ];
  }

  List<PlutoRow> getRows(List<Record> records, Filter filter) {
    return records.map((Record record) {
      String halfTimeScore =
          ((record.homeHalfTimeScore ?? 0) + (record.awayHalfTimeScore ?? 0)) >= filter.milestoneGoalsFirstHalf
              ? "+ ${record.halfTimeScore} +"
              : "-- ${record.halfTimeScore} --";

      String fullTimeScore =
          ((record.homeFullTimeScore ?? 0) + (record.awayFullTimeScore ?? 0)) >= filter.milestoneGoalsFullTime
              ? "+ ${record.fullTimeScore} +"
              : "-- ${record.fullTimeScore} --";

      return PlutoRow(
        cells: {
          "dia": PlutoCell(value: record.matchDate.toString()),
          "liga": PlutoCell(value: record.league.code),
          "home": PlutoCell(value: record.homeTeam.name),
          "away": PlutoCell(value: record.awayTeam.name),
          "intervalo": PlutoCell(value: halfTimeScore),
          "placar": PlutoCell(value: fullTimeScore),
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
