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

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: Colors.purple,
        backgroundColor: filter.anySpecificOddsPresent() ? Colors.blueAccent : null,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return OddsFilterModal(filter: widget.filter, onApplyCallback: widget.onApplyCallback);
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.trending_up, color: filter.anySpecificOddsPresent() ? Colors.white : null),
          Text("Odds", style: TextStyle(color: filter.anySpecificOddsPresent() ? Colors.white : null)),
        ],
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
        final List<MinMaxOdds> earlyHome = [MinMaxOdds.minEarlyHome, MinMaxOdds.maxEarlyHome];
        final List<MinMaxOdds> earlyDraw = [MinMaxOdds.minEarlyDraw, MinMaxOdds.maxEarlyDraw];
        final List<MinMaxOdds> earlyAway = [MinMaxOdds.minEarlyAway, MinMaxOdds.maxEarlyAway];
        final List<MinMaxOdds> finalHome = [MinMaxOdds.minFinalHome, MinMaxOdds.maxFinalHome];
        final List<MinMaxOdds> finalDraw = [MinMaxOdds.minFinalDraw, MinMaxOdds.maxFinalDraw];
        final List<MinMaxOdds> finalAway = [MinMaxOdds.minFinalAway, MinMaxOdds.maxFinalAway];

        void setStates(callback) {
          setModalState(() {
            callback();
          });
          setState(() {
            callback();
          });
        }

        return Dialog(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height * 0.70,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildOddsColumn("Early Home", earlyHome),
                  buildOddsColumn("Early Draw", earlyDraw),
                  buildOddsColumn("Early Away", earlyAway),
                  buildOddsColumn("Final Home", finalHome),
                  buildOddsColumn("Final Draw", finalDraw),
                  buildOddsColumn("Final Away", finalAway),
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
                                widget.filter.removeAllSpecificOdds();
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

  Widget buildOddsColumn(String title, List<MinMaxOdds> oddsList) {
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
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
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
                      onChanged: (value) {},
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
