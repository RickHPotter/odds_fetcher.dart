import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:odds_fetcher/models/record.dart";

class MatchCard extends StatelessWidget {
  final Future<List<Record>>? records;
  final Record pivotRecord;
  final double screenWidth;

  final percentagesContainerWidthFactor = 0.15;

  const MatchCard({super.key, required this.records, required this.pivotRecord, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<List<Record>>(
            future: records,
            builder: (context, snapshot) {
              Widget scorePercentageChild;
              Widget goalsPercentageChild;

              if (snapshot.connectionState == ConnectionState.waiting) {
                scorePercentageChild = const Center(child: CircularProgressIndicator());
                goalsPercentageChild = const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                scorePercentageChild = Text("Erro ao carregar os dados: ${snapshot.error}");
                goalsPercentageChild = Text("Erro ao carregar os dados: ${snapshot.error}");
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                scorePercentageChild = const Center(child: Text("Nenhum dado disponível"));
                goalsPercentageChild = const Center(child: Text("Nenhum dado disponível"));
              } else {
                final records = snapshot.data!;
                final scorePercentages = Record.calculateScoreMatchPercentages(records);
                final goalsPercentages = Record.calculateGoalsMatchPercentages(records);

                scorePercentageChild = Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScorePercentageRow("HOME", scorePercentages["homeWins"] as double, Colors.green),
                    _buildScorePercentageRow("DRAW", scorePercentages["draws"] as double, Colors.orange),
                    _buildScorePercentageRow("AWAY", scorePercentages["awayWins"] as double, Colors.red),
                  ],
                );

                goalsPercentageChild = Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGoalsPercentageBar(
                      "1T",
                      goalsPercentages["underHalf"] as double,
                      goalsPercentages["overHalf"] as double,
                    ),
                    _buildGoalsPercentageBar(
                      "2T",
                      goalsPercentages["underFull"] as double,
                      goalsPercentages["overFull"] as double,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Container(
                    height: 150,
                    width: percentagesContainerWidthFactor * screenWidth,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Card(
                      color: Colors.blue.shade50,
                      elevation: 0,
                      child: Padding(padding: const EdgeInsets.all(12.0), child: scorePercentageChild),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Container(
                    height: 150,
                    width: percentagesContainerWidthFactor * screenWidth,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Card(
                      color: Colors.blue.shade50,
                      elevation: 0,
                      child: Padding(padding: const EdgeInsets.all(12.0), child: goalsPercentageChild),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: screenWidth * 0.01),
          Expanded(
            child: DataTable(
              columns: getColumns(),
              rows: getRows(),
              headingRowColor: WidgetStateColor.resolveWith((states) => Colors.blue.shade100),
              dataRowColor: WidgetStateColor.resolveWith((states) => Colors.blue.shade50),
              border: TableBorder.all(color: Colors.blue.shade200, width: 1, borderRadius: BorderRadius.circular(12)),
              columnSpacing: 20,
              horizontalMargin: 12,
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              dataTextStyle: const TextStyle(color: Colors.black87),
              headingRowHeight: 65,
              dataRowMinHeight: 85,
              dataRowMaxHeight: 85,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePercentageRow(String label, double value, Color color) {
    final percentage = "${value.toStringAsFixed(1)}%";
    final padding = "0" * (6 - percentage.length);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(padding, style: TextStyle(color: Colors.transparent)),
          Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGoalsPercentageBar(String label, double under, double over) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Under: ${under.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.red)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Over: ${over.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.green)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade200, // Background color
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Under Bar (Red)
              Expanded(
                flex: under.round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
              ),
              // Over Bar (Green)
              Expanded(
                flex: over.round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DataColumn> getColumns() {
    final baseWidth = FixedColumnWidth(screenWidth * 0.05);
    final largerWidth = FixedColumnWidth(screenWidth * 0.08);

    return [
      DataColumn(label: Text("Dia"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
      DataColumn(label: Text("Liga"), headingRowAlignment: MainAxisAlignment.center, columnWidth: largerWidth),
      DataColumn(label: Text("Home"), headingRowAlignment: MainAxisAlignment.center, columnWidth: largerWidth),
      DataColumn(label: Text("Away"), headingRowAlignment: MainAxisAlignment.center, columnWidth: largerWidth),
      DataColumn(label: Text("Early 1"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
      DataColumn(label: Text("Early X"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
      DataColumn(label: Text("Early 2"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
      DataColumn(label: Text("Final 1"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
      DataColumn(label: Text("Final X"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
      DataColumn(label: Text("Final 2"), headingRowAlignment: MainAxisAlignment.center, columnWidth: baseWidth),
    ];
  }

  List<DataRow> getRows() {
    final Icon notFound = Icon(Icons.cancel_rounded);

    return [
      DataRow(
        cells: [
          DataCell(Center(child: Text(DateFormat("d 'de' MMMM, HH:mm", "pt-BR").format(pivotRecord.matchDate)))),
          DataCell(Center(child: Text(pivotRecord.league.name))),
          DataCell(Center(child: Text(pivotRecord.homeTeam.name))),
          DataCell(Center(child: Text(pivotRecord.awayTeam.name))),
          DataCell(Center(child: Text(pivotRecord.earlyOdds1.toString()))),
          DataCell(Center(child: Text(pivotRecord.earlyOddsX.toString()))),
          DataCell(Center(child: Text(pivotRecord.earlyOdds2.toString()))),
          DataCell(Center(child: pivotRecord.finalOdds1 == null ? notFound : Text(pivotRecord.finalOdds1.toString()))),
          DataCell(Center(child: pivotRecord.finalOddsX == null ? notFound : Text(pivotRecord.finalOddsX.toString()))),
          DataCell(Center(child: pivotRecord.finalOdds2 == null ? notFound : Text(pivotRecord.finalOdds2.toString()))),
        ],
      ),
    ];
  }
}
