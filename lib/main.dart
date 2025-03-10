import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

import 'package:odds_fetcher/services/api_service.dart';
import 'package:odds_fetcher/services/database_service.dart';
import 'package:odds_fetcher/models/record.dart';
import 'package:odds_fetcher/models/filter.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Record List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RecordListScreen(),
    );
  }
}

class RecordListScreen extends StatefulWidget {
  @override
  _RecordListScreenState createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  late List<Record> records = [];
  late DateTime selectedStartDate;
  late DateTime selectedEndDate;

  Future<void> _insertRecords() async {
    ApiService apiService = ApiService();

    try {
      final data = await apiService.fetchData('2025-03-01');

      for (var record in data) {
        await DatabaseService.insertRecord(record);
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _loadRecords() async {
    final fetchedRecords = await DatabaseService.fetchRecords();

    setState(() {
      records = fetchedRecords;
    });
  }

  @override
  void initState() {
    super.initState();
    _insertRecords();
    _loadRecords();
    selectedStartDate = DateTime.now().subtract(Duration(days: 30)); // 30 days ago
    selectedEndDate = DateTime.now();
  }

  bool _filterByDate(Record record) {
    DateTime matchDate = DateTime.parse(record.matchDate); // Convert matchDate string to DateTime
    return matchDate.isAfter(selectedStartDate) && matchDate.isBefore(selectedEndDate);
  }

  void _showDatePicker(bool isStartDate) async {
    DateTime initialDate = isStartDate ? selectedStartDate : selectedEndDate;
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != initialDate) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = pickedDate;
        } else {
          selectedEndDate = pickedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Records'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Date: ${DateFormat('yyyy-MM-dd').format(selectedStartDate)}',
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _showDatePicker(true),
                ),
                Text(
                  'End Date: ${DateFormat('yyyy-MM-dd').format(selectedEndDate)}',
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _showDatePicker(false),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(record.matchDate));

                  return ListTile(
                    title: Text('${record.homeTeam} vs ${record.awayTeam}'),
                    subtitle: Text('Date: $formattedDate, League: ${record.leagueName}, Score: ${record.score}'),
                  );
                },
              ),
            ),
            //Expanded(
            //  child: FutureBuilder<List<Record>>(
            //    future: records,
            //    builder: (context, snapshot) {
            //      if (snapshot.connectionState == ConnectionState.waiting) {
            //        return Center(child: CircularProgressIndicator());
            //      }
            //
            //      if (snapshot.hasError) {
            //        return Center(child: Text('Error loading data'));
            //      }
            //
            //      if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //        return Center(child: Text('No records available'));
            //      }
            //
            //      List<Record> filteredRecords = snapshot.data!
            //          .where((record) => _filterByDate(record))
            //          .toList();
            //
            //      return ListView.builder(
            //        itemCount: filteredRecords.length,
            //        itemBuilder: (context, index) {
            //          final record = filteredRecords[index];
            //          return Card(
            //            margin: EdgeInsets.symmetric(vertical: 8),
            //            child: ListTile(
            //              title: Text('${record.homeTeam} vs ${record.awayTeam}'),
            //              subtitle: Text('${record.league} - ${record.matchDate}'),
            //              trailing: Text(record.score),
            //            ),
            //          );
            //        },
            //      );
            //    },
            //  ),
            //),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Your floating action button logic here
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
