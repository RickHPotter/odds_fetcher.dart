import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart" show Clipboard, ClipboardData;

import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart" show FontAwesomeIcons;
import "package:google_fonts/google_fonts.dart" show GoogleFonts;

import "package:odds_fetcher/models/record.dart" show Record;
import "package:odds_fetcher/screens/history_analysis_records_screen.dart" show HistoryAnalysisRecordsScreen;
import "package:odds_fetcher/screens/future_analysis_records_screen.dart" show FutureAnalysisRecordsScreen;
import "package:odds_fetcher/screens/history_records_screen.dart" show HistoryRecordsScreen;
import "package:odds_fetcher/services/api_service.dart" show ApiService;
import "package:odds_fetcher/services/database_service.dart" show DatabaseService;

void logError(Object error, StackTrace? stack) {
  final File logFile = File("${Directory.current.path}/error_log.txt");
  final String errorMessage = "${DateTime.now()} - ERROR: $error\n$stack\n\n";
  logFile.writeAsStringSync(errorMessage, mode: FileMode.append);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    logError(details.exception, details.stack);
  };

  Timer.periodic(Duration(minutes: 5), (timer) async {
    List<Record> liveRecords = await ApiService().fetchLiveData();
    List<Record> futureRecords = await ApiService().fetchFutureData();
    List<Record> records = liveRecords + futureRecords;

    await DatabaseService.deleteOldFutureRecords();
    await DatabaseService.insertRecordsBatch(records);
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(brightness) {
    ThemeData baseTheme = ThemeData(brightness: brightness);

    return baseTheme.copyWith(
      textTheme: GoogleFonts.asapCondensedTextTheme(baseTheme.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Odds Fetcher",
      theme: _buildTheme(Brightness.light),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  final String githubLink = "https://github.com/RickHPotter/odds_fetcher.dart";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      body: Column(
        children: [
          Material(
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset("assets/images/logo.jpg", width: 40, height: 40, fit: BoxFit.cover),
                        ),
                      ),
                      Text(
                        "ODDS FETCHER",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          fontFamily: GoogleFonts.monomaniacOne().fontFamily,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const SizedBox(width: 24),
                        ...[
                          {"icon": FontAwesomeIcons.moon, "label": "JOGOS PASSADOS"},
                          {"icon": FontAwesomeIcons.sun, "label": "JOGOS FUTUROS"},
                          {"icon": FontAwesomeIcons.clockRotateLeft, "label": "HISTÓRICO"},
                          {"icon": FontAwesomeIcons.handPointUp, "label": "SOBRE"},
                        ].asMap().entries.map((entry) {
                          int index = entry.key;
                          final item = entry.value;

                          return GestureDetector(
                            onTap: () => setState(() => selectedIndex = index),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item["icon"] as IconData,
                                  color: selectedIndex == index ? Colors.blue : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item["label"] as String,
                                  style: TextStyle(color: selectedIndex == index ? Colors.blue : Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                const HistoryAnalysisRecordsScreen(),
                const FutureAnalysisRecordsScreen(),
                const HistoryRecordsScreen(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text("Height/Altura: ${MediaQuery.of(context).size.height.toString()}"),
                          Text("Width/Largura: ${MediaQuery.of(context).size.width.toString()}"),
                          InkWell(
                            onTap: () async {
                              Clipboard.setData(ClipboardData(text: githubLink));
                            },
                            child: Row(
                              children: [
                                const Icon(FontAwesomeIcons.github),
                                const SizedBox(width: 8),
                                const Text("Clique para copiar o link do meu Github ou acesse "),
                                Text(githubLink, style: const TextStyle(decoration: TextDecoration.underline)),
                              ],
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
        ],
      ),
    );
  }
}
