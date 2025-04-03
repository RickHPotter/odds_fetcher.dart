import "dart:math";

import "package:flutter/material.dart";
import "package:intl/intl.dart" show DateFormat;
import "package:odds_fetcher/models/record.dart";

class MatchCard extends StatelessWidget {
  final Future<List<Record>>? records;
  final Record pivotRecord;
  final double percentagesContainerWidthFactor = 0.15;

  const MatchCard({super.key, required this.records, required this.pivotRecord});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return IntrinsicHeight(
      child: FutureBuilder<List<Record>>(
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
            final List<Record> records = snapshot.data!;
            final Map<String, double> scorePercentages = Record.calculateScoreMatchPercentages(pivotRecord, records);
            final Map<String, double> goalsPercentages = Record.calculateGoalsMatchPercentages(pivotRecord, records);

            scorePercentageChild = Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    "${records.length} JOGOS PASSADOS ENCONTRADOS",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildScorePercentageRow("HOME", scorePercentages["homeWins"] as double, Colors.blue),
                _buildScorePercentageRow("DRAW", scorePercentages["draws"] as double, Colors.grey),
                _buildScorePercentageRow("AWAY", scorePercentages["awayWins"] as double, Colors.orange),
              ],
            );

            goalsPercentageChild = Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGoalsPercentageBar(
                  "1T",
                  goalsPercentages["underFirst"] as double,
                  goalsPercentages["overFirst"] as double,
                ),
                _buildGoalsPercentageBar(
                  "2T",
                  goalsPercentages["underSecond"] as double,
                  goalsPercentages["overSecond"] as double,
                ),
                _buildGoalsPercentageBar(
                  "FT",
                  goalsPercentages["underFull"] as double,
                  goalsPercentages["overFull"] as double,
                ),
              ],
            );
          }

          Widget container({child}) => Container(
            height: 125,
            width: percentagesContainerWidthFactor * screenWidth,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(2, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.blue.shade50,
                child: child,
              ),
            ),
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (pivotRecord.pastRecordsCount > 0) Expanded(child: container(child: MatchDetails(match: pivotRecord))),
              if (pivotRecord.pastRecordsCount > 0) SizedBox(width: screenWidth * 0.01),
              if (pivotRecord.pastRecordsCount > 0) Expanded(child: container(child: MatchOdds(match: pivotRecord))),
              SizedBox(width: screenWidth * 0.01),
              Expanded(child: container(child: scorePercentageChild)),
              SizedBox(width: screenWidth * 0.01),
              Expanded(child: container(child: goalsPercentageChild)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScorePercentageRow(String label, double value, Color color) {
    final String percentage = "${value.toStringAsFixed(1)}%";
    final String padding = "0" * (6 - percentage.length);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              color: color.withValues(alpha: 0.8),
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
            Text(
              "UNDER: ${under.toStringAsFixed(2).padLeft(5, "0")}%",
              style: TextStyle(color: Colors.orange.shade800),
            ),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("OVER: ${over.toStringAsFixed(2).padLeft(5, "0")}%", style: TextStyle(color: Colors.blue.shade800)),
          ],
        ),
        Container(
          height: 10,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
          child: Row(
            children: [
              Expanded(
                flex: under.round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade300,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                  ),
                ),
              ),
              Expanded(
                flex: over.round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
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
}

class MatchDetails extends StatelessWidget {
  const MatchDetails({super.key, required this.match});

  final Record match;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Tooltip(
          message: match.league.name,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(2, 2)),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Text(
              match.league.code,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decorationStyle: TextDecorationStyle.dashed,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(child: Text(match.homeTeam.name, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
        const Text("vs", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        Expanded(child: Text(match.awayTeam.name, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
        Text(
          DateFormat("EEEE, d MMM yyyy - HH:mm", "pt_BR").format(match.matchDate),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class MatchOdds extends StatelessWidget {
  const MatchOdds({super.key, required this.match});

  final Record match;

  @override
  Widget build(BuildContext context) {
    double earlyHome = match.earlyOdds1 ?? 0.0;
    double earlyDraw = match.earlyOddsX ?? 0.0;
    double earlyAway = match.earlyOdds2 ?? 0.0;
    double finalHome = match.finalOdds1 ?? 0.0;
    double finalDraw = match.finalOddsX ?? 0.0;
    double finalAway = match.finalOdds2 ?? 0.0;

    Widget oddsChip(double value, Color color) {
      return Chip(
        backgroundColor: color,
        label: Text(value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    Widget oddsRow(String label, String shortLabel, double homeOdds, double drawOdds, double awayOdds) {
      double lowestOdds = [homeOdds, drawOdds, awayOdds].reduce(min);
      double highestOdds = [homeOdds, drawOdds, awayOdds].reduce(max);

      Color color(double odds) => switch (odds) {
        _ when homeOdds == drawOdds && homeOdds == awayOdds => Colors.yellow.shade300,
        _ when odds == lowestOdds => Colors.blue.shade200,
        _ when odds == highestOdds => Colors.orange.shade300,
        _ => Colors.grey.shade200,
      };

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(message: label, child: Text(shortLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
          oddsChip(homeOdds, color(homeOdds)),
          oddsChip(drawOdds, color(drawOdds)),
          oddsChip(awayOdds, color(awayOdds)),
        ],
      );
    }

    return Column(
      children: [
        oddsRow("Early", "E", earlyHome, earlyDraw, earlyAway),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(child: Icon(Icons.home, size: 16)),
              Center(child: Icon(Icons.close, size: 16)),
              Center(child: Icon(Icons.public, size: 16)),
            ],
          ),
        ),
        oddsRow("Final", "F", finalHome, finalDraw, finalAway),
      ],
    );
  }
}
