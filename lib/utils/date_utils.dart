String formatDate(DateTime date) {
  return date.toIso8601String().substring(0, 10);
}

String rawDate(DateTime date) {
  return date.toIso8601String().substring(0, 10).replaceAll("-", "");
}

String rawDateTime(DateTime date) {
  return date.toIso8601String().substring(0, 16).replaceAll("-", "").replaceAll("T", "").replaceAll(":", "");
}

DateTime parseRawDate(String dateStr) {
  final String formattedString = "${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}";

  return DateTime.parse(formattedString);
}

DateTime parseRawDateTime(String dateStr) {
  final String formattedString =
      "${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}"
      " ${dateStr.substring(8, 10)}:${dateStr.substring(10, 12)}";

  return DateTime.parse(formattedString);
}
