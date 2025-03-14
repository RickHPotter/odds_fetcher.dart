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

String humaniseTime(int minutes) {
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

String humaniseNumber(int number) {
  if (number >= 1000000) {
    return "${(number / 1000000).toStringAsFixed(2)}M";
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(2)}K";
  } else {
    return number.toString();
  }
}
