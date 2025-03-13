import "package:flutter/material.dart";
import "package:odds_fetcher/models/folder.dart";
import "package:odds_fetcher/models/league.dart";

class LeagueFolderFilterButton extends StatefulWidget {
  final List<League> leagues;
  final List<Folder> folders;
  final double screenWidth;

  const LeagueFolderFilterButton({super.key, required this.leagues, required this.folders, required this.screenWidth});

  @override
  State<LeagueFolderFilterButton> createState() => _LeagueFolderFilterButtonState();
}

class _LeagueFolderFilterButtonState extends State<LeagueFolderFilterButton> {
  final List<League> selectedLeagues = [];
  final List<Folder> selectedFolders = [];

  Widget _showFilterModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMultiSelect<League>(
                          shouldFocus: true,
                          items: widget.leagues,
                          selectedItems: selectedLeagues,
                          getItemName: (league) => league.name,
                          onItemSelected: (league) {
                            // FIXME: I guess I need both setState and setModalState
                            setModalState(() {
                              if (!selectedLeagues.contains(league)) selectedLeagues.add(league);
                            });
                            setState(() {
                              if (!selectedLeagues.contains(league)) selectedLeagues.add(league);
                            });
                          },
                          onItemRemoved: (league) {
                            setModalState(() {
                              selectedLeagues.remove(league);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelect<Folder>(
                          shouldFocus: false,
                          items: widget.folders,
                          selectedItems: selectedFolders,
                          getItemName: (folder) => folder.name,
                          onItemSelected: (folder) {
                            setModalState(() {
                              if (!selectedFolders.contains(folder)) selectedFolders.add(folder);
                            });
                          },
                          onItemRemoved: (folder) {
                            setModalState(() {
                              selectedFolders.remove(folder);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedLeagues.clear();
                                  selectedFolders.clear();
                                });
                              },
                              child: Row(children: [const Icon(Icons.close), const Text("Limpar")]),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Row(children: [const Icon(Icons.check), const Text("Aplicar")]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8.0,
            children:
                selectedItems.map((item) {
                  return Chip(label: Text(getItemName(item)), onDeleted: () => onItemRemoved(item));
                }).toList(),
          ),
        ),
        const SizedBox(height: 8),
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
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.clear();
            if (shouldFocus) focusNode.requestFocus();

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: "Pesquisar...",
              ),
              onSubmitted: (value) {
                onFieldSubmitted();
              },
            );
          },
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
