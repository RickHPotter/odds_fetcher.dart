import "package:flutter/material.dart";
import "package:odds_fetcher/screens/records_list_screen.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Odds Fetcher",
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: "Odds Fetcher"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text("Listagem de Registros"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.portrait),
                label: Text("About"),
              ),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: const [RecordListScreen(), Text("Hello")],
            ),
          ),
        ],
      ),
    );
  }
}
