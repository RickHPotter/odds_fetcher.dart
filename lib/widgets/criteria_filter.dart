import "package:flutter/material.dart";
import "package:flutter/services.dart" show FilteringTextInputFormatter;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:odds_fetcher/models/filter.dart";

class CriteriaFilterButton extends StatefulWidget {
  final Filter filter;
  final void Function() onApplyCallback;

  const CriteriaFilterButton({super.key, required this.filter, required this.onApplyCallback});

  @override
  State<CriteriaFilterButton> createState() => _CriteriaFilterButtonState();
}

class _CriteriaFilterButtonState extends State<CriteriaFilterButton> {
  @override
  Widget build(BuildContext context) {
    final Filter filter = widget.filter;

    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CriteriaFilterModal(filter: filter, onApplyCallback: widget.onApplyCallback);
          },
        );
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: Colors.purple,
        backgroundColor: filter.anyFutureMinPercent() ? Colors.indigoAccent : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.arrowUpRightFromSquare,
            color: filter.anyFutureMinPercent() ? Colors.white : null,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            "ACEITE",
            style: TextStyle(fontWeight: FontWeight.bold, color: filter.anyFutureMinPercent() ? Colors.white : null),
          ),
        ],
      ),
    );
  }
}

class CriteriaFilterModal extends StatefulWidget {
  final Filter filter;
  final void Function() onApplyCallback;

  const CriteriaFilterModal({super.key, required this.filter, required this.onApplyCallback});

  @override
  State<CriteriaFilterModal> createState() => _CriteriaFilterModalState();
}

class _CriteriaFilterModalState extends State<CriteriaFilterModal> {
  final FocusNode _focusNode = FocusNode();

  late TextEditingController futureMinHomeController = TextEditingController(
    text: (widget.filter.futureMinHomeWinPercentage).toString(),
  );
  late TextEditingController futureMinDrawController = TextEditingController(
    text: (widget.filter.futureMinDrawPercentage).toString(),
  );
  late TextEditingController futureMinAwayController = TextEditingController(
    text: (widget.filter.futureMinAwayWinPercentage).toString(),
  );
  late TextEditingController futureOverFirstController = TextEditingController(
    text: (widget.filter.milestoneGoalsFirstHalf).toString(),
  );
  late TextEditingController futureOverFullController = TextEditingController(
    text: (widget.filter.milestoneGoalsFullTime).toString(),
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();

    final List<TextEditingController> controllersList = [
      futureMinHomeController,
      futureMinDrawController,
      futureMinAwayController,
    ];

    for (final TextEditingController controller in controllersList) {
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
    late String hintText;

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
          futureMinHomeController.clear();
          futureMinDrawController.clear();
          futureMinAwayController.clear();
        }

        void updatePercentagesAndApply() {
          setStates(() {
            filter.futureMinHomeWinPercentage = int.tryParse(futureMinHomeController.text) ?? 0;
            filter.futureMinDrawPercentage = int.tryParse(futureMinDrawController.text) ?? 0;
            filter.futureMinAwayWinPercentage = int.tryParse(futureMinAwayController.text) ?? 0;
          });

          widget.onApplyCallback();
        }

        hintText = """CRITERIOS:
          - HOME precisa de uma porcentagem de ${filter.futureMinHomeWinPercentage}%
          - DRAW precisa de uma porcentagem de ${filter.futureMinDrawPercentage}%
          - AWAY precisa de uma porcentagem de ${filter.futureMinAwayWinPercentage}%
          - OVER 1T > ${filter.milestoneGoalsFirstHalf} GOLS
          - OVER 2T > ${filter.milestoneGoalsSecondHalf} GOLS
          - OVER FT > ${filter.milestoneGoalsFullTime} GOLS\n""";

        return Dialog(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      hintText.trim(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.purple.shade900),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: TextFormField(
                            focusNode: _focusNode,
                            controller: futureMinHomeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Porcentagem Mínima HOME",
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
                            onChanged: (String value) {
                              setState(() => filter.futureMinHomeWinPercentage = int.tryParse(value) ?? 0);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: TextFormField(
                            controller: futureMinDrawController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Porcentagem Mínima DRAW",
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
                            onChanged: (String value) {
                              setState(() => filter.futureMinDrawPercentage = int.tryParse(value) ?? 0);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: TextFormField(
                            controller: futureMinAwayController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Porcentagem Mínima AWAY",
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
                            onChanged: (String value) {
                              setState(() => filter.futureMinAwayWinPercentage = int.tryParse(value) ?? 0);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: TextFormField(
                            controller: futureOverFirstController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Porcentagem Mínima OVER HT",
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
                            onChanged: (String value) {
                              setState(() => filter.milestoneGoalsFirstHalf = int.tryParse(value) ?? 0);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: TextFormField(
                            controller: futureOverFullController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Porcentagem Mínima OVER FT",
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
                            onChanged: (String value) {
                              setState(() => filter.milestoneGoalsFullTime = int.tryParse(value) ?? 0);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: TextFormField(
                            controller: futureMinAwayController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Porcentagem Mínima AWAY",
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
                            onChanged: (String value) {
                              setState(() => filter.futureMinAwayWinPercentage = int.tryParse(value) ?? 0);
                            },
                          ),
                        ),
                      ),
                    ],
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
                                clearAllTextFields();
                                updatePercentagesAndApply();
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
                              updatePercentagesAndApply();
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
}
