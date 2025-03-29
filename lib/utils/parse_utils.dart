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

String humaniseTime(int minutes, {bool short = false}) {
  const int hour = 60;
  const int day = hour * 24;

  final String minuteStr;
  final String hourStr;
  final String hoursStr;
  final String dayStr;
  final String daysStr;

  if (short) {
    minuteStr = "Min.";
    hourStr = "Hora";
    hoursStr = "Horas";
    dayStr = "Dia";
    daysStr = "Dias";
  } else {
    minuteStr = "minutos";
    hourStr = "hora";
    hoursStr = "horas";
    dayStr = "dia";
    daysStr = "dias";
  }

  switch (minutes) {
    case < hour:
      return "$minutes $minuteStr";
    case hour:
      return "${minutes ~/ 60} $hourStr";
    case < day:
      return "${minutes ~/ 60} $hoursStr";
    case day:
      return "${minutes ~/ (60 * 24)} $dayStr";
    default:
      return "${minutes ~/ (60 * 24)} $daysStr";
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
