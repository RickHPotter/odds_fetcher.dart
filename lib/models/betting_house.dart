class BettingHouse {
  final int id;
  final String name;

  BettingHouse({required this.id, required this.name});

  factory BettingHouse.fromMap(Map<String, dynamic> map) {
    return BettingHouse(
      id: map['id'],
      name: map['bettingHouseName'],
    );
  }
}
