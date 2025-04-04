import "package:flutter/material.dart";
import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:intl/intl.dart" show DateFormat;
import "package:odds_fetcher/models/filter.dart" show Filter;

import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/services/database_service.dart" show DatabaseService;
import "package:odds_fetcher/utils/parse_utils.dart" show humaniseTime;

import "package:odds_fetcher/screens/base_analysis_records_screen.dart";

import "package:odds_fetcher/widgets/teams_filter.dart" show TeamsFilterButton;
import "package:odds_fetcher/widgets/leagues_folders_filter.dart" show LeaguesFoldersFilterButton;
import "package:odds_fetcher/widgets/odds_filter.dart" show OddsFilterButton;
import "package:odds_fetcher/widgets/criteria_filter.dart" show CriteriaFilterButton, CriteriaFilterModal;
import "package:odds_fetcher/widgets/match_card.dart" show MatchCard;
import "package:odds_fetcher/widgets/past_matches_datatable.dart" show PastMachDataTable;

class HistoryAnalysisRecordsScreen extends BaseAnalysisScreen {
  const HistoryAnalysisRecordsScreen({super.key});

  @override
  State<HistoryAnalysisRecordsScreen> createState() => _HistoryAnalysisRecordsScreenState();
}

class _HistoryAnalysisRecordsScreenState extends BaseAnalysisScreenState<HistoryAnalysisRecordsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _filterNameController = TextEditingController();

  final List<int> pastMatchesMinutesList = [
    60 * 5,
    60 * 6,
    60 * 12,
    60 * 24,
    60 * 24 * 2,
    60 * 24 * 3,
    60 * 24 * 4,
    60 * 24 * 5,
    60 * 24 * 7,
  ];
  final List<int> pastYearsList = [1, 2, 3, 4, 5, 8, 10, 15, 20];

  @override
  Stream<Record> fetchRecords(Filter filter) {
    return DatabaseService.fetchPivotRecords(filter, (count) => setState(() => pivotRecordsCount = count));
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.087;
    final double smallButtonSize = MediaQuery.of(context).size.width * 0.058;
    if (!pastMatchesMinutesList.contains(filter.futureNextMinutes)) {
      filter.futureNextMinutes = pastMatchesMinutesList.first;
    }

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
                  for (final int time in pastYearsList)
                    SizedBox(
                      width: buttonSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                        child: ElevatedButton(
                          onPressed: () => filterHistoryMatches(_yearController, time: time),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: time == filter.pastYears ? Colors.indigoAccent : null,
                          ),
                          child: Text(
                            time <= 1 ? "$time Ano" : "$time Anos",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: time == filter.pastYears ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: buttonSize,
                    height: MediaQuery.of(context).size.height * 0.042,
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null ? "ANO INVÁLIDO" : null,
                      decoration: InputDecoration(
                        labelText: "ANO",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^\d*\.?\d*"))],
                      onChanged:
                          (value) => filterHistoryMatches(
                            _yearController,
                            specificYear: value.isEmpty ? null : int.parse(value),
                          ),
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
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.history)),
                  for (final int minutes in pastMatchesMinutesList)
                    SizedBox(
                      width: buttonSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                        child: ElevatedButton(
                          onPressed: () => filterUpcomingMatches(minutes),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: minutes == filter.futureNextMinutes ? Colors.indigoAccent : null,
                          ),
                          child: Text(
                            humaniseTime(minutes, short: true),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: minutes == filter.futureNextMinutes ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.042,
                    child: Switch(
                      value: hideFiltersOnFutureRecordSelect,
                      activeColor: Colors.indigoAccent,
                      onChanged: (bool value) {
                        setState(() {
                          hideFiltersOnFutureRecordSelect = value;
                        });
                      },
                    ),
                  ),
                  const Text("OCULTAR FILTROS AO PESQUISAR"),
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
                    final bool isSelected = selectedOddsMap[oddsType] ?? false;

                    return SizedBox(
                      width: smallButtonSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () => filterMatchesBySimiliarity(oddsType),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: isSelected ? Colors.indigoAccent : null,
                          ),
                          child: Text(
                            oddsType.shortName,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: buttonSize,
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
                    width: buttonSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: TeamsFilterButton(
                        filter: filter,
                        teams: teams,
                        onApplyCallback: () {
                          loadFutureMatches();
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: buttonSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ElevatedButton(
                        onPressed: () => filterMatchesBySameLeague(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: filter.futureOnlySameLeague ? Colors.indigoAccent : null,
                        ),
                        child: Text(
                          "MESMA LIGA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: filter.futureOnlySameLeague ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: buttonSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: LeaguesFoldersFilterButton(
                        filter: filter,
                        leagues: leagues,
                        folders: folders,
                        onApplyCallback: () {
                          if (filter.futureOnlySameLeague && (filter.leagues.isNotEmpty || filter.folders.isNotEmpty)) {
                            setState(() => filter.futureOnlySameLeague = false);
                          }
                          loadFutureMatches();
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: buttonSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: CriteriaFilterButton(filter: filter, onApplyCallback: () => loadFutureMatches()),
                    ),
                  ),
                  SizedBox(
                    width: buttonSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (filter.futureMinHomeWinPercentage == 52 &&
                              filter.futureMinDrawPercentage == 52 &&
                              filter.futureMinAwayWinPercentage == 52) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CriteriaFilterModal(filter: filter, onApplyCallback: () => loadFutureMatches());
                              },
                            );
                          } else {
                            filter.futureMinHomeWinPercentage = 52;
                            filter.futureMinDrawPercentage = 52;
                            filter.futureMinAwayWinPercentage = 52;

                            setState(() => filter = filter);

                            loadFutureMatches();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: filter.allFutureMinPercentSpecificValue(52) ? Colors.indigoAccent : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: filter.allFutureMinPercentSpecificValue(52) ? Colors.white : null,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              "52 %",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: filter.allFutureMinPercentSpecificValue(52) ? Colors.white : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          // Future Matches Carousel
          SizedBox(
            height: 66.6,
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
                  itemBuilder: (BuildContext context, int index) {
                    final Record match = pivotRecords[index];

                    final List<Color> colors = [];

                    if (match.anyPercentageHigherThan(80)) {
                      colors.add(Colors.red[300] as Color);
                    } else if (match.anyPercentageHigherThan(65)) {
                      colors.add(Colors.orange[300] as Color);
                    } else if (match.anyPercentageHigherThan(52)) {
                      colors.add(Colors.amber[300] as Color);
                    }

                    if (selectedMatchId == match.id) {
                      colors.add(Colors.grey[300] as Color);
                      if (colors.length == 2) {
                        colors.add(colors.first);
                      }
                    }

                    if (colors.isEmpty) {
                      colors.add(Colors.grey[100] as Color);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors, stops: colors.length == 1 ? [0.0] : [0.2, 0.4, 0.8]),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 0.7),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              if (hideFiltersOnFutureRecordSelect) showFilters = false;
                              loadPastMatches(match.id as int, index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    match.homeTeam.name,
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat.MMMMd("pt-BR").format(match.matchDate),
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        DateFormat.Hm("pt-BR").format(match.matchDate),
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    match.awayTeam.name,
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
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
          footerControls(context, _filterNameController),
        ],
      ),
    );
  }
}
