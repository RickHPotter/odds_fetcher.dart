import "package:flutter/material.dart";
import "package:odds_fetcher/models/filter.dart";
import "package:odds_fetcher/services/database_service.dart" show DatabaseService;

class FilterSelectButton extends StatefulWidget {
  final Filter filter;
  final void Function() onApplyCallback;

  const FilterSelectButton({super.key, required this.filter, required this.onApplyCallback});

  @override
  State<FilterSelectButton> createState() => _FilterSelectButtonState();
}

class _FilterSelectButtonState extends State<FilterSelectButton> {
  late List<Filter> filters = [];

  void retrieveFilters() async {
    filters = await DatabaseService.fetchFilters();
  }

  @override
  void initState() {
    retrieveFilters();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return FilterSelectModal(filter: widget.filter, filters: filters, onApplyCallback: widget.onApplyCallback);
          },
        );
      },
      child: Text(
        widget.filter.filterName.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, overflow: TextOverflow.ellipsis),
        maxLines: 1,
      ),
    );
  }
}

class FilterSelectModal extends StatefulWidget {
  final Filter filter;
  final List<Filter> filters;
  final void Function() onApplyCallback;

  const FilterSelectModal({super.key, required this.filter, required this.filters, required this.onApplyCallback});

  @override
  State<FilterSelectModal> createState() => _FilterSelectModalState();
}

class _FilterSelectModalState extends State<FilterSelectModal> {
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
        String getItemName(filter) => filter.filterName;

        return Dialog(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Autocomplete<Filter>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return [];

                return widget.filters
                    .where((item) => getItemName(item).toLowerCase().contains(textEditingValue.text.toLowerCase()))
                    .toList();
              },
              displayStringForOption: (option) => getItemName(option),
              onSelected: (selectedFilter) {
                widget.filter.id = selectedFilter.id;
                widget.onApplyCallback();
                Navigator.pop(context);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                textEditingController.clear();
                focusNode.requestFocus();

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: "Pesquisar filtro...",
                  ),
                  onSubmitted: (value) {
                    onFieldSubmitted();
                    focusNode.requestFocus();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
