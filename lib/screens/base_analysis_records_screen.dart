import "dart:async";
import "dart:io" show Platform;

import "package:flutter/material.dart";

import "package:intl/date_symbol_data_local.dart" show initializeDateFormatting;

import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/team.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league_folder.dart";
import "package:odds_fetcher/jobs/records_fetcher.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/widgets/overlay_message.dart" show MessageType, showOverlayMessage;

abstract class BaseAnalysisScreen extends StatefulWidget {
  const BaseAnalysisScreen({super.key});
}

abstract class BaseAnalysisScreenState<T extends BaseAnalysisScreen> extends State<T> {
  Stream<Record> fetchRecords(Filter filter);

  late Future<List<Record>>? records;
  late List<Record> pivotRecords = [];
  late List<Team> teams = [];
  late List<League> leagues = [];
  late List<Folder> folders = [];
  late List<LeagueFolder> leaguesFolders = [];

  late RecordFetcher fetcher;
  String currentDate = DateTime.now().toString();
  int progress = 0;
  bool isFetchingPast = false;
  bool isFetchingPivot = false;
  bool isLoading = false;
  bool isCancelled = false;
  bool isCreatingFilter = false;
  bool isUpdatingFilter = false;

  int? selectedMatchId;
  int? pivotRecordIndex;

  bool showFilters = true;
  bool hideFiltersOnFutureRecordSelect = Platform.isLinux ? false : true;

  // <-- FILTERS
  late Filter filter = Filter(filterName: "FILTRO PADRÃO");
  late Filter placeholderFilter = filter.copyWith();

  late Map<Odds, bool> selectedOddsMap = {
    Odds.earlyOdds1: filter.futureSameEarlyHome,
    Odds.earlyOddsX: filter.futureSameEarlyDraw,
    Odds.earlyOdds2: filter.futureSameEarlyAway,
    Odds.finalOdds1: filter.futureSameFinalHome,
    Odds.finalOddsX: filter.futureSameFinalDraw,
    Odds.finalOdds2: filter.futureSameFinalAway,
  };
  // FILTERS -->

  StreamSubscription<Record>? _recordSubscription;

  Future<void> fetchFromMaxMatchDate() async {
    final DateTime minDateToFetch = await DatabaseService.fetchFromMaxMatchDate();

    if (minDateToFetch != DateTime.now()) {
      startFetching(minDate: minDateToFetch);
    }

    startFetchingFuture();
  }

  void loadFutureMatches() {
    _recordSubscription?.cancel();

    setState(() {
      isLoading = true;
      pivotRecords.clear();
      selectedMatchId = null;
      pivotRecordIndex = null;
      records = Future.value([]);
    });

    _recordSubscription = fetchRecords(filter).listen(
      (record) {
        setState(() {
          pivotRecords.add(record);
          if (pivotRecordIndex == null) {
            loadPastMatches(record.id, 0);
          }
        });
      },
      onDone: () {
        setState(() {
          isLoading = false;
          pivotRecordIndex ??= 0;
        });
      },
    );
  }

  void loadPastMatches(int? id, int? index) async {
    setState(() {
      selectedMatchId = id;
      pivotRecordIndex = index;

      if (id != null && index != null && pivotRecords.isNotEmpty) {
        final Record futurePivotRecord = pivotRecords[index];
        records = DatabaseService.fetchRecords(filter: filter, futureRecord: futurePivotRecord);
      }
    });
  }

  void loadTeamsAndLeaguesAndFolders() async {
    final List<Team> fetchedTeams = await DatabaseService.fetchTeams();
    final List<League> fetchedLeagues = await DatabaseService.fetchLeagues();
    final List<Folder> fetchedFolders = await DatabaseService.fetchFoldersWithLeagues();

    setState(() {
      teams = fetchedTeams;
      leagues = fetchedLeagues;
      folders = fetchedFolders;
    });
  }

  void retrieveFilter(int id) async {
    filter = await DatabaseService.fetchFilter(id);

    setState(() {
      filter = filter;
      placeholderFilter = filter.copyWith();
    });

    updateOddsFilter();
    loadFutureMatches();
  }

  void updateOddsFilter() {
    filter.updateOdds();

    selectedOddsMap = {
      Odds.earlyOdds1: filter.futureSameEarlyHome,
      Odds.earlyOddsX: filter.futureSameEarlyDraw,
      Odds.earlyOdds2: filter.futureSameEarlyAway,
      Odds.finalOdds1: filter.futureSameFinalHome,
      Odds.finalOddsX: filter.futureSameFinalDraw,
      Odds.finalOdds2: filter.futureSameFinalAway,
    };
  }

  void updateFutureSameOddsTypes() {
    updateOddsFilter();

    setState(() => filter = filter);
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting("pt-BR");

    fetcher = RecordFetcher();
    fetcher.progressStream.listen((value) {
      setState(() => progress = value);
    });
    fetcher.currentDateStream.listen((value) {
      setState(() => currentDate = value);
    });

    records = Future.value([]);

    fetchFromMaxMatchDate();
    loadTeamsAndLeaguesAndFolders();

    retrieveFilter(0);
  }

  @override
  void dispose() {
    fetcher.dispose();
    _recordSubscription?.cancel();
    super.dispose();
  }

  void startFetching({DateTime? minDate, DateTime? maxDate}) async {
    minDate ??= DateTime.parse("2008-01-01");
    maxDate ??= DateTime.now().subtract(Duration(days: 1));

    setState(() {
      isFetchingPast = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertRecords(minDate: minDate, maxDate: maxDate, isCancelledCallback: () => isCancelled);

    if (mounted) {
      if (isCancelled) {
        showOverlayMessage(context, "Operação cancelada!", type: MessageType.info);
      } else {
        showOverlayMessage(context, "Jogos passados buscados com sucesso!");
      }
    }

    setState(() => isFetchingPast = false);
  }

  void startFetchingFuture() async {
    setState(() {
      isFetchingPivot = true;
      isCancelled = false;
    });

    await fetcher.fetchAndInsertFutureRecords(isCancelledCallback: () => isCancelled);

    if (mounted && !isCancelled) showOverlayMessage(context, "Jogos futuros buscados com sucesso!");

    setState(() => isFetchingPivot = false);
  }

  // FILTERS
  void filterHistoryMatches(TextEditingController yearController, {int? time, int? specificYear}) {
    if (time == null && specificYear == null) {
      showOverlayMessage(context, "Filtro de Tempo Passado preenchido incompletamente!", type: MessageType.warning);
      return;
    }

    if (time != null) {
      filter.pastYears = time;
      yearController.clear();
    } else if (specificYear != null) {
      filter.pastYears = null;
      filter.specificYears = specificYear;
    }

    setState(() => filter = filter);

    loadFutureMatches();
  }

  void filterUpcomingMatches(int duration) {
    setState(() => filter.futureNextMinutes = duration);

    loadFutureMatches();
  }

  void filterMatchesBySimiliarity(Odds oddType) {
    setState(() {
      switch (oddType) {
        case Odds.earlyOdds1:
          filter.futureSameEarlyHome = !filter.futureSameEarlyHome;
          break;
        case Odds.earlyOddsX:
          filter.futureSameEarlyDraw = !filter.futureSameEarlyDraw;
          break;
        case Odds.earlyOdds2:
          filter.futureSameEarlyAway = !filter.futureSameEarlyAway;
          break;
        case Odds.finalOdds1:
          filter.futureSameFinalHome = !filter.futureSameFinalHome;
          break;
        case Odds.finalOddsX:
          filter.futureSameFinalDraw = !filter.futureSameFinalDraw;
          break;
        case Odds.finalOdds2:
          filter.futureSameFinalAway = !filter.futureSameFinalAway;
          break;
      }

      updateOddsFilter();

      setState(() => filter = filter);

      if (filter.anyFutureMinPercent()) {
        loadFutureMatches();
      } else {
        loadPastMatches(selectedMatchId, pivotRecordIndex);
      }
    });
  }

  void filterMatchesBySameLeague() {
    filter.futureOnlySameLeague = !filter.futureOnlySameLeague;
    if (filter.futureOnlySameLeague) {
      filter.leagues.clear();
      filter.folders.clear();
    }

    setState(() {
      filter = filter;
    });

    loadPastMatches(selectedMatchId, pivotRecordIndex);
  }

  Future<bool> saveFilter() async {
    late bool success;

    if (filter.id == null) {
      success = await DatabaseService.insertFilter(filter);
    } else {
      success = await DatabaseService.updateFilter(filter);
    }

    if (!success) return false;

    setState(() {
      placeholderFilter = filter.copyWith();
      isCreatingFilter = false;
      isUpdatingFilter = false;
    });

    return true;
  }
}
