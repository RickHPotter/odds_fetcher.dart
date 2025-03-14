import "package:flutter/material.dart";
import "package:odds_fetcher/models/record.dart";
import "package:pluto_grid/pluto_grid.dart";

class PastMachDataTable extends StatelessWidget {
  final Future<List<Record>>? records;
  final double percentagesContainerWidthFactor = 0.10;

  const PastMachDataTable({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    late PlutoGridStateManager stateManager;

    return Expanded(
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
            return const Center(child: Text("Nenhum jogo passado encontrado com os critérios informados."));
          }

          final records = snapshot.data!;
          return PlutoGrid(
            columns: getColumns(screenWidth),
            rows: getRows(records),
            rowColorCallback: (PlutoRowColorContext context) {
              final record = records[context.rowIdx];
              final int home = record.homeSecondHalfScore ?? 0;
              final int away = record.awaySecondHalfScore ?? 0;

              if (home == away) {
                return Colors.grey.shade200;
              } else if (home > away) {
                return Colors.green.shade100;
              } else {
                return Colors.red.shade100;
              }
            },
            onLoaded: (event) {
              stateManager = event.stateManager;
              stateManager.setShowColumnFilter(true);
            },
            configuration: PlutoGridConfiguration(
              scrollbar: const PlutoGridScrollbarConfig(isAlwaysShown: true, draggableScrollbar: true),
              style: PlutoGridStyleConfig(gridBorderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }

  List<PlutoColumn> getColumns(double screenWidth) {
    final double baseWidth = screenWidth * 0.06;
    final double largerWidth = screenWidth * 0.126;

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
        title: "PLACAR FINAL",
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
