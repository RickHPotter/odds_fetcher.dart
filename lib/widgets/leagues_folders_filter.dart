import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/material.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/league.dart";
import "package:odds_fetcher/models/folder.dart";

class LeaguesFoldersFilterButton extends StatefulWidget {
  final Filter filter;
  final List<League> leagues;
  final List<Folder> folders;
  final void Function() onApplyCallback;

  const LeaguesFoldersFilterButton({
    super.key,
    required this.filter,
    required this.leagues,
    required this.folders,
    required this.onApplyCallback,
  });

  @override
  State<LeaguesFoldersFilterButton> createState() => _LeaguesFoldersFilterButtonState();
}

class _LeaguesFoldersFilterButtonState extends State<LeaguesFoldersFilterButton> {
  late List<League> selectedLeagues = [];
  late List<Folder> selectedFolders = [];

  @override
  Widget build(BuildContext context) {
    final Filter filter = widget.filter;
    selectedLeagues = filter.leagues;
    selectedFolders = filter.folders;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: Colors.purple,
        backgroundColor: selectedLeagues.isNotEmpty || selectedFolders.isNotEmpty ? Colors.indigoAccent : null,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return LeaguesFoldersFilterModal(
              filter: widget.filter,
              leagues: widget.leagues,
              folders: widget.folders,
              selectedLeagues: selectedLeagues,
              selectedFolders: selectedFolders,
              onApplyCallback: widget.onApplyCallback,
            );
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.folder, color: selectedLeagues.isNotEmpty || selectedFolders.isNotEmpty ? Colors.white : null),
          Text(
            "LIGAS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selectedLeagues.isNotEmpty || selectedFolders.isNotEmpty ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}

class LeaguesFoldersFilterModal extends StatefulWidget {
  final Filter filter;
  final List<League> leagues;
  final List<Folder> folders;
  final List<League> selectedLeagues;
  final List<Folder> selectedFolders;
  final void Function() onApplyCallback;

  const LeaguesFoldersFilterModal({
    super.key,
    required this.filter,
    required this.leagues,
    required this.folders,
    required this.selectedLeagues,
    required this.selectedFolders,
    required this.onApplyCallback,
  });

  @override
  State<LeaguesFoldersFilterModal> createState() => _LeaguesFoldersFilterModalState();
}

class _LeaguesFoldersFilterModalState extends State<LeaguesFoldersFilterModal> {
  dynamic selectedNode = League;
  late List<League> selectedLeaguesFromFolders = [];

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onApplyCallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        void setStates(callback) {
          setModalState(() {
            callback();
          });
          setState(() {
            callback();
          });
        }

        final ScrollController folderLeaguesScrollController = ScrollController();

        void populateSelectedLeaguesFolders() {
          selectedLeaguesFromFolders.clear();

          for (Folder folder in widget.selectedFolders) {
            final List<League> leagues = folder.leagues;

            selectedLeaguesFromFolders.addAll(leagues);
          }
        }

        populateSelectedLeaguesFolders();

        final double heightFactor = widget.filter.showPivotOptions ? 0.6 : 0.5;

        return Dialog(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * heightFactor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.filter.showPivotOptions)
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: Row(
                            children: [
                              Switch(
                                value: widget.filter.filterFutureRecordsByLeagues,
                                onChanged: (value) {
                                  setStates(() {
                                    widget.filter.filterFutureRecordsByLeagues = value;
                                  });
                                },
                              ),
                              const Text("FILTRAR JOGOS FUTUROS"),
                            ],
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: Row(
                            children: [
                              Switch(
                                value: widget.filter.filterPastRecordsByLeagues,
                                onChanged: (value) {
                                  setStates(() {
                                    widget.filter.filterPastRecordsByLeagues = value;
                                  });
                                },
                              ),
                              const Text("FILTRAR JOGOS ANTERIORES"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  _buildMultiSelect<League>(
                    shouldFocus: true,
                    items: widget.leagues,
                    selectedItems: widget.selectedLeagues,
                    getItemName: (league) => league.code,
                    getSubItemName: (league) => league.name,
                    onItemSelected: (league) {
                      setStates(() {
                        if (widget.filter.futureOnlySameLeague) {
                          widget.filter.futureOnlySameLeague = false;
                        }

                        if (!widget.selectedLeagues.contains(league)) widget.selectedLeagues.add(league);
                        selectedNode = League;
                      });
                    },
                    onItemRemoved: (league) {
                      setStates(() {
                        widget.selectedLeagues.remove(league);
                      });
                    },
                  ),
                  _buildMultiSelect<Folder>(
                    shouldFocus: false,
                    items: widget.folders,
                    selectedItems: widget.selectedFolders,
                    getItemName: (folder) => folder.name,
                    getSubItemName: (folder) => "${folder.leagues.length} ligas",
                    onItemSelected: (folder) {
                      setStates(() {
                        if (!widget.selectedFolders.contains(folder)) widget.selectedFolders.add(folder);
                        selectedNode = Folder;
                        populateSelectedLeaguesFolders();
                      });
                    },
                    onItemRemoved: (folder) {
                      setStates(() {
                        widget.selectedFolders.remove(folder);
                      });
                    },
                  ),
                  Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        folderLeaguesScrollController.jumpTo(
                          folderLeaguesScrollController.offset + event.scrollDelta.dy,
                        );
                      }
                    },
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: folderLeaguesScrollController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: folderLeaguesScrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Wrap(
                          spacing: 8.0,
                          children:
                              selectedLeaguesFromFolders.map((league) {
                                return Chip(
                                  label: Tooltip(message: league.name, child: Text(league.code)),
                                  deleteIconColor: Colors.red,
                                  onDeleted: () {
                                    setStates(() {
                                      for (final Folder folder in widget.selectedFolders) {
                                        folder.leagues.removeWhere((folderLeague) => league.code == folderLeague.code);
                                      }
                                      populateSelectedLeaguesFolders();
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text("Limpar", style: TextStyle(color: Colors.black)),
                            onPressed: () {
                              setStates(() {
                                widget.selectedLeagues.clear();
                                widget.selectedFolders.clear();
                                selectedLeaguesFromFolders.clear();
                                selectedNode = null;
                              });
                            },
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.green),
                            label: const Text("Aplicar", style: TextStyle(color: Colors.black)),
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onApplyCallback();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultiSelect<T extends Object>({
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) getItemName,
    required String Function(T) getSubItemName,
    required void Function(T) onItemSelected,
    required void Function(T) onItemRemoved,
    required bool shouldFocus,
  }) {
    final ScrollController scrollController = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<T>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return [];

            return items
                .where((item) => selectedItems.contains(item) == false)
                .where((item) => getItemName(item).toLowerCase().contains(textEditingValue.text.toLowerCase()))
                .toList();
          },
          displayStringForOption: (T option) => getItemName(option),
          onSelected: (T selection) {
            onItemSelected(selection);
            selectedNode = selection;
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.clear();
            if (T == selectedNode) focusNode.requestFocus();

            String hintText() {
              switch (T) {
                case const (League):
                  return "Pesquisar Liga...";
                case const (Folder):
                  return "Pesquisar Pasta...";
                default:
                  return "Pesquisar...";
              }
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: hintText(),
              ),
              onSubmitted: (value) {
                onFieldSubmitted();
                focusNode.requestFocus();
              },
            );
          },
        ),

        selectedItems.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Wrap(spacing: 8.0, children: [Chip(label: Text("Nenhum selecionado"))]),
            )
            : Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  scrollController.jumpTo(scrollController.offset + event.scrollDelta.dy);
                }
              },
              child: Scrollbar(
                thumbVisibility: true,
                controller: scrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Wrap(
                    spacing: 8.0,
                    children:
                        selectedItems.map((item) {
                          return Chip(
                            //label: Text(getItemName(item)),
                            label: Tooltip(message: getSubItemName(item), child: Text(getItemName(item))),
                            deleteIconColor: Colors.red,
                            onDeleted: () => onItemRemoved(item),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
