import "package:flutter/gestures.dart" show PointerScrollEvent;
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:odds_fetcher/models/filter.dart" show Filter;

class DateTimePickerWidget extends StatefulWidget {
  final Filter filter;
  final void Function({DateTime? minDate, DateTime? maxDate}) onApplyCallback;
  const DateTimePickerWidget({super.key, required this.filter, required this.onApplyCallback});

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime? startDate;
  DateTime? endDate;

  Future<void> _pickDateTimeRange({
    required Filter filter,
    required void Function({DateTime? minDate, DateTime? maxDate}) onApplyCallback,
  }) async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2008),
      lastDate: DateTime(2100),
      initialDateRange: startDate != null && endDate != null ? DateTimeRange(start: startDate!, end: endDate!) : null,
      locale: const Locale("pt", "BR"),
    );

    if (mounted && pickedRange != null) {
      TimeOfDay? startTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (mounted && startTime != null) {
        TimeOfDay? endTime = await showTimePicker(context: context, initialTime: startTime);

        if (endTime != null) {
          setState(() {
            startDate = DateTime(
              pickedRange.start.year,
              pickedRange.start.month,
              pickedRange.start.day,
              startTime.hour,
              startTime.minute,
            );

            endDate = DateTime(
              pickedRange.end.year,
              pickedRange.end.month,
              pickedRange.end.day,
              endTime.hour,
              endTime.minute,
            );

            filter.specificMinDate = startDate;
            filter.specificMaxDate = endDate;
            onApplyCallback(minDate: filter.specificMinDate, maxDate: filter.specificMaxDate);
          });
        }
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    return dateTime != null ? DateFormat("yyyy-MM-dd HH:mm").format(dateTime) : "Data e Hora";
  }

  @override
  Widget build(BuildContext context) {
    Filter filter = widget.filter;
    startDate = filter.specificMinDate;
    endDate = filter.specificMaxDate;

    List<int> years = List.generate(DateTime.now().year - 2007, (index) => 2008 + index);
    Set<int> selectedYears = {};

    for (var currentYear in years) {
      if (filter.specificMinDate == null && filter.specificMaxDate == null) break;

      DateTime minYear = DateTime(currentYear, 1, 1, 0, 0);
      DateTime maxYear = DateTime(currentYear, 12, 31, 23, 59);

      if (filter.specificMinDate!.isBefore(maxYear) && filter.specificMaxDate!.isAfter(minYear)) {
        selectedYears.add(currentYear);
      }
    }

    final void Function({DateTime? minDate, DateTime? maxDate}) onApplyCallback = widget.onApplyCallback;

    final ScrollController yearsScrollController = ScrollController();

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Data Inicial:"),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: _formatDateTime(startDate)),
              onTap: () => _pickDateTimeRange(filter: filter, onApplyCallback: onApplyCallback),
              decoration: InputDecoration(border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
            ),
          ),
          Text("Data Final:"),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: _formatDateTime(endDate)),
              onTap: () => _pickDateTimeRange(filter: filter, onApplyCallback: onApplyCallback),
              decoration: InputDecoration(border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
            ),
          ),
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                yearsScrollController.jumpTo(yearsScrollController.offset + event.scrollDelta.dy);
              }
            },
            child: Scrollbar(
              thumbVisibility: true,
              controller: yearsScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: yearsScrollController,
                child: Row(
                  children: [
                    for (int year in years.reversed)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            shadowColor: Colors.purple,
                            backgroundColor: selectedYears.contains(year) ? Colors.indigoAccent : null,
                          ),
                          onPressed: () {
                            DateTime minYear = DateTime(year, 1, 1, 0, 0);
                            DateTime maxYear = DateTime(year, 12, 31, 23, 59);

                            filter.specificMinDate ??= minYear;
                            filter.specificMaxDate ??= maxYear;

                            bool overlapMin = filter.specificMinDate!.isBefore(maxYear);
                            bool overlapMax = filter.specificMaxDate!.isAfter(minYear);

                            if (!overlapMin) filter.specificMinDate = minYear;
                            if (!overlapMax) filter.specificMaxDate = maxYear;

                            if (overlapMin && overlapMax) {
                              selectedYears.add(year);
                            }

                            setState(() => filter = filter);
                            onApplyCallback(minDate: filter.specificMinDate, maxDate: filter.specificMaxDate);
                          },
                          child: Text(
                            year.toString(),
                            style: TextStyle(color: selectedYears.contains(year) ? Colors.white : Colors.indigoAccent),
                          ),
                        ),
                      ),
                  ],
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
                      setState(() {
                        filter.specificMinDate = null;
                        filter.specificMaxDate = null;
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
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
