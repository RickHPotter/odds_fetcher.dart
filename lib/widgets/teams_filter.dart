import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/material.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/models/team.dart";

class TeamsFilterButton extends StatefulWidget {
  final Filter filter;
  final List<Team> teams;
  final void Function() onApplyCallback;

  const TeamsFilterButton({super.key, required this.filter, required this.teams, required this.onApplyCallback});

  @override
  State<TeamsFilterButton> createState() => _TeamsFilterButtonState();
}

class _TeamsFilterButtonState extends State<TeamsFilterButton> {
  late List<Team> selectedTeams = [];

  @override
  Widget build(BuildContext context) {
    final Filter filter = widget.filter;
    selectedTeams = filter.teams;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: Colors.purple,
        backgroundColor: selectedTeams.isNotEmpty ? Colors.indigoAccent : null,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return TeamsFilterModal(
              filter: widget.filter,
              teams: widget.teams,
              selectedTeams: selectedTeams,
              onApplyCallback: widget.onApplyCallback,
            );
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.group, color: selectedTeams.isNotEmpty ? Colors.white : null),
          Text(
            "TIMES",
            style: TextStyle(fontWeight: FontWeight.bold, color: selectedTeams.isNotEmpty ? Colors.white : null),
          ),
        ],
      ),
    );
  }
}

class TeamsFilterModal extends StatefulWidget {
  final Filter filter;
  final List<Team> teams;
  final List<Team> selectedTeams;
  final void Function() onApplyCallback;

  const TeamsFilterModal({
    super.key,
    required this.filter,
    required this.teams,
    required this.selectedTeams,
    required this.onApplyCallback,
  });

  @override
  State<TeamsFilterModal> createState() => _TeamsFilterModalState();
}

class _TeamsFilterModalState extends State<TeamsFilterModal> {
  dynamic selectedNode = Team;

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

        final double heightFactor = widget.filter.showPivotOptions ? 0.4 : 0.3;

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
                                value: widget.filter.filterFutureRecordsByTeams,
                                onChanged: (bool value) {
                                  setState(() {
                                    widget.filter.filterFutureRecordsByTeams = value;
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
                                value: widget.filter.filterPastRecordsByTeams,
                                onChanged: (value) {
                                  setStates(() {
                                    widget.filter.filterPastRecordsByTeams = value;
                                  });
                                },
                              ),
                              const Text("FILTRAR JOGOS ANTERIORES"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  _buildMultiSelect<Team>(
                    shouldFocus: true,
                    items: widget.teams,
                    selectedItems: widget.selectedTeams,
                    getItemName: (team) => team.name,
                    onItemSelected: (team) {
                      setStates(() {
                        if (!widget.selectedTeams.contains(team)) widget.selectedTeams.add(team);
                        selectedNode = Team;
                      });
                    },
                    onItemRemoved: (team) {
                      setStates(() {
                        widget.selectedTeams.remove(team);
                      });
                    },
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
                                widget.selectedTeams.clear();
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
                case const (Team):
                  return "Pesquisar Time...";
                //case const (Folder):
                //  return "Pesquisar Pasta...";
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
                            label: Text(getItemName(item)),
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
