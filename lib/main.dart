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
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  // Error Catcher
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

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            elevation: 2,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: Text("Listagem de Registros")),
              NavigationRailDestination(icon: Icon(Icons.portrait), label: Text("About")),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [const RecordListScreen(), Text(MediaQuery.of(context).size.toString())],
            ),
          ),
        ],
      ),
    );
  }
}
