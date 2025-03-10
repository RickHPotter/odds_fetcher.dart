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
