import 'package:weatherman/models/price_period.dart';

class HourWithTemperature {
  DateTime time;
  PricePeriod period;
  double temperature;

  Map toMap() {
    return {
      'time': time.toString(),
      'period': getPricePeriodName(period),
      'temperature': temperature,
    };
  }

  HourWithTemperature({
    required this.time,
    required this.period,
    required this.temperature,
  });
}
