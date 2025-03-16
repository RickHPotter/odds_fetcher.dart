import "dart:io";
import "package:flutter/material.dart";
import "package:odds_fetcher/screens/records_list_screen.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

void logError(Object error, StackTrace? stack) {
  final logFile = File("${Directory.current.path}/error_log.txt");
  final errorMessage = "${DateTime.now()} - ERROR: $error\n$stack\n\n";
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Odds Fetcher",
      theme: ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
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
                      Text("Odds Fetcher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    ],
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ...[
                          {"icon": Icons.home, "label": "Listagem de Registros"},
                          {"icon": Icons.construction, "label": "Sobre"},
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
                                const SizedBox(width: 4),
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
                const RecordListScreen(),
                Padding(padding: const EdgeInsets.all(16.0), child: Text(MediaQuery.of(context).size.toString())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
