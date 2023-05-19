class BestHour {
  DateTime time;
  double price;
  double temperature;

  Map toMap() {
    return {
      'time': time.toString(),
      'price': price,
      'temperature': temperature,
    };
  }

  BestHour({
    required this.time,
    required this.price,
    required this.temperature,
  });
}
