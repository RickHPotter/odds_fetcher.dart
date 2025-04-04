import "package:flutter/material.dart";
import "package:odds_fetcher/models/filter.dart" show Filter;

import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/services/database_service.dart" show DatabaseService;

import "package:odds_fetcher/screens/base_analysis_records_screen.dart";

import "package:odds_fetcher/widgets/match_card.dart" show MatchCard;
import "package:odds_fetcher/widgets/past_matches_datatable.dart" show PastMachDataTable;

class FutureAnalysisRecordsScreen extends BaseAnalysisScreen {
  const FutureAnalysisRecordsScreen({super.key});

  @override
  State<FutureAnalysisRecordsScreen> createState() => _FutureAnalysisRecordsScreenState();
}

class _FutureAnalysisRecordsScreenState extends BaseAnalysisScreenState<FutureAnalysisRecordsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _filterNameController = TextEditingController();

  final List<int> futureMatchesMinutesList = [10, 30, 60, 60 * 3, 60 * 6, 60 * 12, 60 * 24, 60 * 24 * 2, 60 * 24 * 3];
  final List<int> pastYearsList = [1, 2, 3, 4, 5, 8, 10, 15, 20];

  @override
  Stream<Record> fetchRecords(Filter filter) {
    return DatabaseService.fetchFutureRecords(filter, (count) => setState(() => pivotRecordsCount = count));
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.087;
    final double smallButtonSize = MediaQuery.of(context).size.width * 0.058;
    if (!futureMatchesMinutesList.contains(filter.pivotNextMinutes)) {
      filter.pivotNextMinutes = futureMatchesMinutesList.first;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // FILTERS
          if (showFilters) pastFilters(buttonSize, pastYearsList, _yearController),
          if (showFilters) pivotFilters(Icons.update, futureMatchesMinutesList, buttonSize),
          if (showFilters) bothFilters(buttonSize, smallButtonSize),

          Padding(
            padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
            child: pivotMatchesCarousel(pivotRecords, _scrollController),
          ),

          if (selectedMatchId != null && pivotRecords.isNotEmpty && pivotRecordIndex != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: MatchCard(records: records, pivotRecord: pivotRecords[pivotRecordIndex as int], filter: filter),
            ),

          PastMachDataTable(records: records, filter: filter),

          const Divider(),
          footerControls(context, _filterNameController),
        ],
      ),
    );
  }
}
