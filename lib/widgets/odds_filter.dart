import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:odds_fetcher/models/filter.dart";

class OddsFilterButton extends StatefulWidget {
  final Filter filter;
  final void Function() onApplyCallback;

  const OddsFilterButton({super.key, required this.filter, required this.onApplyCallback});

  @override
  State<OddsFilterButton> createState() => _OddsFilterButtonState();
}

class _OddsFilterButtonState extends State<OddsFilterButton> {
  @override
  Widget build(BuildContext context) {
    final Filter filter = widget.filter;
    final List<Color> colors = [];
    final bool anyApply =
        filter.anySpecificOddsPresent() || filter.futureDismissNoEarlyOdds || filter.futureDismissNoFinalOdds;

    if (filter.anySpecificOddsPresent()) colors.add(Colors.indigoAccent);
    if (filter.futureDismissNoEarlyOdds) colors.add(Colors.purple);
    if (filter.futureDismissNoFinalOdds) colors.add(Colors.pink);

    final List<double> stops = List.generate(colors.length, (index) => index / (colors.length - 1));

    if (colors.isEmpty) colors.add(Colors.grey.shade100);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, stops: colors.length == 1 ? [0.0] : stops),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2, offset: Offset(0, 2))],
      ),
      height: MediaQuery.of(context).size.height * 0.04,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return OddsFilterModal(filter: filter, onApplyCallback: widget.onApplyCallback);
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: anyApply ? Colors.white : Colors.indigo),
              const SizedBox(width: 4),
              Text(
                "ODDS",
                style: TextStyle(fontWeight: FontWeight.bold, color: anyApply ? Colors.white : Colors.indigo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OddsFilterModal extends StatefulWidget {
  final Filter filter;
  final void Function() onApplyCallback;

  const OddsFilterModal({super.key, required this.filter, required this.onApplyCallback});

  @override
  State<OddsFilterModal> createState() => _OddsFilterModalState();
}

class _OddsFilterModalState extends State<OddsFilterModal> {
  final List<MinMaxOdds> earlyHome = [MinMaxOdds.minEarlyHome, MinMaxOdds.maxEarlyHome];
  final List<MinMaxOdds> earlyDraw = [MinMaxOdds.minEarlyDraw, MinMaxOdds.maxEarlyDraw];
  final List<MinMaxOdds> earlyAway = [MinMaxOdds.minEarlyAway, MinMaxOdds.maxEarlyAway];
  final List<MinMaxOdds> finalHome = [MinMaxOdds.minFinalHome, MinMaxOdds.maxFinalHome];
  final List<MinMaxOdds> finalDraw = [MinMaxOdds.minFinalDraw, MinMaxOdds.maxFinalDraw];
  final List<MinMaxOdds> finalAway = [MinMaxOdds.minFinalAway, MinMaxOdds.maxFinalAway];

  late List<TextEditingController> earlyHomeControllers;
  late List<TextEditingController> earlyDrawControllers;
  late List<TextEditingController> earlyAwayControllers;
  late List<TextEditingController> finalHomeControllers;
  late List<TextEditingController> finalDrawControllers;
  late List<TextEditingController> finalAwayControllers;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    earlyHomeControllers = [
      TextEditingController(text: (widget.filter.minEarlyHome ?? "").toString()),
      TextEditingController(text: (widget.filter.maxEarlyHome ?? "").toString()),
    ];
    earlyDrawControllers = [
      TextEditingController(text: (widget.filter.minEarlyDraw ?? "").toString()),
      TextEditingController(text: (widget.filter.maxEarlyDraw ?? "").toString()),
    ];
    earlyAwayControllers = [
      TextEditingController(text: (widget.filter.minEarlyAway ?? "").toString()),
      TextEditingController(text: (widget.filter.maxEarlyAway ?? "").toString()),
    ];
    finalHomeControllers = [
      TextEditingController(text: (widget.filter.minFinalHome ?? "").toString()),
      TextEditingController(text: (widget.filter.maxFinalHome ?? "").toString()),
    ];
    finalDrawControllers = [
      TextEditingController(text: (widget.filter.minFinalDraw ?? "").toString()),
      TextEditingController(text: (widget.filter.maxFinalDraw ?? "").toString()),
    ];
    finalAwayControllers = [
      TextEditingController(text: (widget.filter.minFinalAway ?? "").toString()),
      TextEditingController(text: (widget.filter.maxFinalAway ?? "").toString()),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();

    final List<List<TextEditingController>> controllersList = [
      earlyHomeControllers,
      earlyDrawControllers,
      earlyAwayControllers,
      finalHomeControllers,
      finalDrawControllers,
      finalAwayControllers,
    ];
    final List<TextEditingController> controllers = controllersList.expand((e) => e).toList();

    for (final TextEditingController controller in controllers) {
      controller.dispose();
    }

    _focusNode.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onApplyCallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Filter filter = widget.filter;

    return StatefulBuilder(
      builder: (BuildContext context, setModalState) {
        void setStates(callback) {
          setModalState(() {
            callback();
          });
          setState(() {
            callback();
          });
        }

        void clearAllTextFields() {
          earlyHomeControllers[0].clear();
          earlyHomeControllers[1].clear();
          earlyDrawControllers[0].clear();
          earlyDrawControllers[1].clear();
          earlyAwayControllers[0].clear();
          earlyAwayControllers[1].clear();
          finalHomeControllers[0].clear();
          finalHomeControllers[1].clear();
          finalDrawControllers[0].clear();
          finalDrawControllers[1].clear();
          finalAwayControllers[0].clear();
          finalAwayControllers[1].clear();
        }

        void updateSpecificOddsAndApplyCallback() {
          setStates(() {
            filter.minEarlyHome = double.tryParse(earlyHomeControllers[0].text);
            filter.maxEarlyHome = double.tryParse(earlyHomeControllers[1].text);
            filter.minEarlyDraw = double.tryParse(earlyDrawControllers[0].text);
            filter.maxEarlyDraw = double.tryParse(earlyDrawControllers[1].text);
            filter.minEarlyAway = double.tryParse(earlyAwayControllers[0].text);
            filter.maxEarlyAway = double.tryParse(earlyAwayControllers[1].text);
            filter.minFinalHome = double.tryParse(finalHomeControllers[0].text);
            filter.maxFinalHome = double.tryParse(finalHomeControllers[1].text);
            filter.minFinalDraw = double.tryParse(finalDrawControllers[0].text);
            filter.maxFinalDraw = double.tryParse(finalDrawControllers[1].text);
            filter.minFinalAway = double.tryParse(finalAwayControllers[0].text);
            filter.maxFinalAway = double.tryParse(finalAwayControllers[1].text);
          });

          widget.onApplyCallback();
        }

        return Dialog(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.70,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FILTER APPLYING
                  if (filter.showPivotOptions)
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: Row(
                            children: [
                              Switch(
                                value: widget.filter.filterFutureRecordsBySpecificOdds,
                                onChanged: (value) {
                                  setStates(() {
                                    widget.filter.filterFutureRecordsBySpecificOdds = value;
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
                                value: widget.filter.filterPastRecordsBySpecificOdds,
                                onChanged: (value) {
                                  setStates(() {
                                    widget.filter.filterPastRecordsBySpecificOdds = value;
                                  });
                                },
                              ),
                              const Text("FILTRAR JOGOS ANTERIORES"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  // DISMISS MATCHES
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Switch(
                              value: filter.futureDismissNoEarlyOdds,
                              activeColor: Colors.purple,
                              onChanged: (bool value) {
                                setState(() {
                                  filter.futureDismissNoEarlyOdds = value;
                                });
                              },
                            ),
                            const Text("DESCONSIDERAR JOGOS SEM EARLY ODDS"),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          children: [
                            Switch(
                              value: filter.futureDismissNoFinalOdds,
                              activeColor: Colors.pink,
                              onChanged: (bool value) {
                                setState(() {
                                  filter.futureDismissNoFinalOdds = value;
                                });
                              },
                            ),
                            const Text("DESCONSIDERAR JOGOS SEM FINAL ODDS"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  buildOddsColumn(
                    "Early Home",
                    earlyHome,
                    earlyHomeControllers,
                    updateSpecificOddsAndApplyCallback,
                    focusNode: _focusNode,
                  ),
                  buildOddsColumn("Early Draw", earlyDraw, earlyDrawControllers, updateSpecificOddsAndApplyCallback),
                  buildOddsColumn("Early Away", earlyAway, earlyAwayControllers, updateSpecificOddsAndApplyCallback),
                  buildOddsColumn("Final Home", finalHome, finalHomeControllers, updateSpecificOddsAndApplyCallback),
                  buildOddsColumn("Final Draw", finalDraw, finalDrawControllers, updateSpecificOddsAndApplyCallback),
                  buildOddsColumn("Final Away", finalAway, finalAwayControllers, updateSpecificOddsAndApplyCallback),
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
                                filter.removeAllSpecificOdds();
                                clearAllTextFields();
                                updateSpecificOddsAndApplyCallback();
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
                              updateSpecificOddsAndApplyCallback();
                              Navigator.pop(context);
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

  Widget buildOddsColumn(
    String title,
    List<MinMaxOdds> oddsList,
    List<TextEditingController> controllers,
    onApplyCallback, {
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            for (int i = 0; i < oddsList.length; i += 2)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      focusNode: focusNode,
                      controller: controllers[i],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Min $title",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^\d*\.?\d*"))],
                      onChanged: (_) => onApplyCallback(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: controllers[i + 1],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Max $title",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^\d*\.?\d*"))],
                      onChanged: (_) => onApplyCallback(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
