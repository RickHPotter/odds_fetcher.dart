import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/material.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";

class LeagueFolderFilterButton extends StatefulWidget {
  final List<League> leagues;
  final List<Folder> folders;

  const LeagueFolderFilterButton({super.key, required this.leagues, required this.folders});

  @override
  State<LeagueFolderFilterButton> createState() => _LeagueFolderFilterButtonState();
}

class _LeagueFolderFilterButtonState extends State<LeagueFolderFilterButton> {
  final List<League> selectedLeagues = [];
  final List<Folder> selectedFolders = [];
  dynamic selectedNode = League;

  Widget _showFilterModal() {
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

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMultiSelect<League>(
                    shouldFocus: true,
                    items: widget.leagues,
                    selectedItems: selectedLeagues,
                    getItemName: (league) => league.name,
                    onItemSelected: (league) {
                      setStates(() {
                        if (!selectedLeagues.contains(league)) selectedLeagues.add(league);
                        selectedNode = League;
                      });
                    },
                    onItemRemoved: (league) {
                      setStates(() {
                        selectedLeagues.remove(league);
                      });
                    },
                  ),
                  _buildMultiSelect<Folder>(
                    shouldFocus: false,
                    items: widget.folders,
                    selectedItems: selectedFolders,
                    getItemName: (folder) => folder.name,
                    onItemSelected: (folder) {
                      setStates(() {
                        if (!selectedFolders.contains(folder)) selectedFolders.add(folder);
                        selectedNode = Folder;
                      });
                    },
                    onItemRemoved: (folder) {
                      setStates(() {
                        selectedFolders.remove(folder);
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
                                selectedLeagues.clear();
                                selectedFolders.clear();
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
                            onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: Colors.purple,
        backgroundColor: selectedLeagues.isNotEmpty || selectedFolders.isNotEmpty ? Colors.blueAccent : null,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _showFilterModal();
          },
        );
      },
      child: Row(
        children: [
          Icon(Icons.folder, color: selectedLeagues.isNotEmpty || selectedFolders.isNotEmpty ? Colors.white : null),
          const SizedBox(width: 2),
          Text(
            "Ligas & Pastas",
            style: TextStyle(color: selectedLeagues.isNotEmpty || selectedFolders.isNotEmpty ? Colors.white : null),
          ),
        ],
      ),
    );
  }
}
