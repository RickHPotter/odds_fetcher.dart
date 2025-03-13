double parseDouble(String value) {
  final parsed = double.tryParse(value);
  if (parsed != null) {
    return parsed;
  }
  return 0.0;
}

int parseInteger(String value) {
  final parsed = int.tryParse(value);
  if (parsed != null) {
    return parsed;
  }
  return 0;
}

String humanisedTime(int minutes) {
  const int hour = 60;
  const int day = hour * 24;

  switch (minutes) {
    case < hour:
      return "$minutes minutos";
    case hour:
      return "1 hora";
    case < day:
      return "${minutes ~/ 60} horas";
    case day:
      return "1 dia";
    default:
      return "${minutes ~/ (60 * 24)} dias";
  }
}
