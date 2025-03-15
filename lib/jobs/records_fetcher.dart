import "dart:async";
import "package:flutter/foundation.dart" show debugPrint;
import "package:odds_fetcher/services/api_service.dart";
import "package:odds_fetcher/services/database_service.dart";
import "package:odds_fetcher/models/record.dart";

class RecordFetcher {
  final StreamController<int> _progressController = StreamController<int>();
  final StreamController<String> _currentDateController = StreamController<String>();

  Stream<int> get progressStream => _progressController.stream;
  Stream<String> get currentDateStream => _currentDateController.stream;

  static const int maxParallelRequests = 10;
  static const int batchInsertThreshold = 30;
  static const int maxRetryAttempts = 3;

  List<DateTime> failedFetches = [];

  Future<List<Record>> fetchWithRetry(String dateStr, int attempt) async {
    try {
      return await ApiService().fetchData(dateStr);
    } catch (e) {
      if (attempt < maxRetryAttempts) {
        debugPrint("Retrying $dateStr - Attempt ${attempt + 1}");
        return fetchWithRetry(dateStr, attempt + 1);
      } else {
        debugPrint("Failed to fetch $dateStr after $maxRetryAttempts attempts.");
        failedFetches.add(DateTime.parse(dateStr));
        return [];
      }
    }
  }

  Future<void> fetchAndInsertRecords({
    required DateTime minDate,
    required DateTime maxDate,
    required bool Function() isCancelledCallback,
  }) async {
    List<Future<List<Record>>> fetchTasks = [];
    List<Record> recordBuffer = [];
    int completedSteps = 0;

    int totalDays = maxDate.difference(minDate).inDays + 1;
    int totalFetchTasks = totalDays;

    for (
      DateTime date = minDate;
      date.isBefore(maxDate) || date.isAtSameMomentAs(maxDate);
      date = date.add(Duration(days: 1))
    ) {
      String dateStr = date.toString().split(" ")[0];
      _currentDateController.add(dateStr);

      fetchTasks.add(fetchWithRetry(dateStr, 1));

      // When fetch tasks reach maxParallelRequests, process them
      if (fetchTasks.length >= maxParallelRequests) {
        List<List<Record>> results = await Future.wait(fetchTasks);
        fetchTasks.clear();

        for (var records in results) {
          recordBuffer.addAll(records);
          if (recordBuffer.length >= batchInsertThreshold) {
            await DatabaseService.insertRecordsBatch(recordBuffer);
            recordBuffer.clear();
          }
        }
      }

      completedSteps++;
      _progressController.add(((completedSteps / totalFetchTasks) * 100).toInt());

      if (isCancelledCallback()) {
        break;
      }
    }

    if (isCancelledCallback()) {
      return;
    }

    if (fetchTasks.isNotEmpty) {
      List<List<Record>> results = await Future.wait(fetchTasks);
      fetchTasks.clear();

      for (var records in results) {
        recordBuffer.addAll(records);
        if (recordBuffer.length >= batchInsertThreshold) {
          await DatabaseService.insertRecordsBatch(recordBuffer);
          recordBuffer.clear();
        }
      }
    }

    if (recordBuffer.isNotEmpty) {
      await DatabaseService.insertRecordsBatch(recordBuffer);
      recordBuffer.clear();
    }
  }

  Future<void> fetchAndInsertFutureRecords({required bool Function() isCancelledCallback}) async {
    List<Record> records = [];

    records = await ApiService().fetchFutureData();
    _currentDateController.add("Data Futura");
    _progressController.add(50);

    if (isCancelledCallback()) {
      return;
    }

    await DatabaseService.deleteOldFutureRecords();
    await DatabaseService.insertRecordsBatch(records);

    _progressController.add(50);
  }

  void dispose() {
    _progressController.close();
    _currentDateController.close();
  }
}
