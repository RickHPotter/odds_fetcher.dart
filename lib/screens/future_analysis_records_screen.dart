import "package:flutter/material.dart";
import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:intl/intl.dart" show DateFormat;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:google_fonts/google_fonts.dart";
import "package:odds_fetcher/models/filter.dart" show Filter;

import "package:odds_fetcher/models/record.dart";
import "package:odds_fetcher/services/database_service.dart" show DatabaseService;
import "package:odds_fetcher/utils/parse_utils.dart" show humaniseNumber, humaniseTime;

import "package:odds_fetcher/screens/base_analysis_records_screen.dart";

import "package:odds_fetcher/widgets/overlay_message.dart" show MessageType, showOverlayMessage;
import "package:odds_fetcher/widgets/teams_filter.dart" show TeamsFilterButton;
import "package:odds_fetcher/widgets/leagues_folders_filter.dart" show LeaguesFoldersFilterButton;
import "package:odds_fetcher/widgets/odds_filter.dart" show OddsFilterButton;
import "package:odds_fetcher/widgets/criteria_filter.dart" show CriteriaFilterButton, CriteriaFilterModal;
import "package:odds_fetcher/widgets/match_card.dart" show MatchCard;
import "package:odds_fetcher/widgets/past_matches_datatable.dart" show PastMachDataTable;
import "package:odds_fetcher/widgets/filter_select.dart" show FilterSelectButton;

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
    return DatabaseService.fetchFutureRecords(filter);
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.087;
    final double smallButtonSize = MediaQuery.of(context).size.width * 0.058;

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
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: Icon(Icons.update)),
                  for (final int minutes in futureMatchesMinutesList)
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
                    width: buttonSize * 1.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => filterMatchesBySameLeague(),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          shadowColor: Colors.purple,
                          backgroundColor: filter.futureOnlySameLeague ? Colors.indigoAccent : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dehaze, color: filter.futureOnlySameLeague ? Colors.white : null),
                            const SizedBox(width: 1),
                            Text(
                              "MESMA LIGA",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: filter.futureOnlySameLeague ? Colors.white : null,
                              ),
                            ),
                          ],
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
          // Footer and Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Tooltip(
                    message: filter.filterName,
                    child:
                        isCreatingFilter || isUpdatingFilter
                            ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.05,
                              child: TextField(
                                controller: _filterNameController,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Adjust padding
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  hintText: "Informe um Nome...",
                                ),
                                onChanged: (value) => filter.filterName = value,
                              ),
                            )
                            : FilterSelectButton(
                              filter: filter,
                              onApplyCallback: () {
                                retrieveFilter(filter.id as int);
                              },
                            ),
                  ),
                ),
                Row(
                  children: [
                    Tooltip(
                      message: "Novo Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          backgroundColor: isCreatingFilter ? Colors.grey[300] : Colors.grey[100],
                        ),
                        onPressed: () {
                          setState(() {
                            isCreatingFilter = true;
                            filter.id = null;
                            filter.filterName = "Novo Filtro Data: ${DateFormat.MMMMd("pt-BR").format(DateTime.now())}";
                            _filterNameController.text = filter.filterName;
                          });
                        },
                        child: Icon(FontAwesomeIcons.squarePlus, color: Colors.black),
                      ),
                    ),
                    Tooltip(
                      message: "Editar Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          backgroundColor: isUpdatingFilter ? Colors.grey[300] : Colors.grey[100],
                        ),
                        onPressed: () {
                          if (isCreatingFilter || isUpdatingFilter) return;

                          setState(() {
                            isUpdatingFilter = true;
                            _filterNameController.text = filter.filterName;
                          });
                        },
                        child: const Icon(FontAwesomeIcons.solidPenToSquare, color: Colors.black87),
                      ),
                    ),
                    Tooltip(
                      message: "Salvar Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        onPressed: () async {
                          final bool success = await saveFilter();

                          if (!context.mounted) return;
                          if (success) {
                            showOverlayMessage(context, "Filtro salvo com sucesso!", type: MessageType.success);
                          } else {
                            showOverlayMessage(
                              context,
                              "Filtro precisa de um nome diferente!",
                              type: MessageType.error,
                            );
                          }
                        },
                        child: Icon(FontAwesomeIcons.solidFloppyDisk, color: Colors.black87),
                      ),
                    ),
                    Tooltip(
                      message:
                          isCreatingFilter || isUpdatingFilter
                              ? "Cancelar Criação/Edição de Filtro"
                              : "Resetar Filtro",
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        onPressed: () {
                          setState(() {
                            if (isCreatingFilter || isUpdatingFilter) {
                              isCreatingFilter = false;
                              isUpdatingFilter = false;
                              filter.filterName = placeholderFilter.filterName;

                              showOverlayMessage(
                                context,
                                "Criação/Edição de filtro cancelada com sucesso!",
                                type: MessageType.info,
                              );
                            } else {
                              filter = placeholderFilter.copyWith();
                              updateOddsFilter();
                              loadFutureMatches();
                              showOverlayMessage(context, "Filtro resetado com sucesso!", type: MessageType.info);
                            }
                          });
                        },
                        child:
                            isCreatingFilter || isUpdatingFilter
                                ? Icon(FontAwesomeIcons.ban, color: Colors.red)
                                : Icon(FontAwesomeIcons.rotateLeft, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                isLoading
                    ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator())
                    : SizedBox(width: 20, height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${humaniseNumber(pivotRecords.length)} JOGOS FUTUROS.",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    FutureBuilder<List<Record>>(
                      future: records,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            "Carregando jogos passados...",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            "Erro ao carregar jogos passados.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text(
                            "0 JOGOS PASSADOS.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        }
                        return Text(
                          "${humaniseNumber(snapshot.data!.length)} JOGOS PASSADOS.",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
                // Fetch Controls
                ElevatedButton(
                  onPressed: () => setState(() => showFilters = !showFilters),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: Text(
                    showFilters ? "OCULTAR FILTROS" : "MOSTRAR FILTROS",
                    style: GoogleFonts.martianMono(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      isFetchingPast || isFetchingPivot
                          ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.31,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(value: progress / 100),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Tooltip(
                                        message: "Cancelar",
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              isCancelled = true;
                                              isFetchingPast = false;
                                              isFetchingPivot = false;
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          ),
                                          child: const Icon(FontAwesomeIcons.ban, size: 16, color: Colors.red),
                                        ),
                                      ),
                                      Text(
                                        currentDate,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                        ),
                                        child: Text("$progress%"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          : Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: ElevatedButton(
                                  onPressed: startFetching,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  ),
                                  child: Text(
                                    "ATUALIZAR PASSADO",
                                    style: GoogleFonts.martianMono(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: ElevatedButton(
                                  onPressed: startFetchingFuture,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  ),
                                  child: Text(
                                    "ATUALIZAR FUTURO",
                                    style: GoogleFonts.martianMono(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
