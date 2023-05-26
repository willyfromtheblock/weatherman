import 'dart:io';

import 'package:cron/cron.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'models/hour_with_temperature.dart';
import 'models/price_period.dart';
import 'tools/http_wrapper.dart';
import 'tools/logger.dart';

class WeatherWatcher {
  static final Map<String, WeatherWatcher> _cache = <String, WeatherWatcher>{};
  final _logger = LoggerWrapper().logger;
  final _cron = Cron();
  final List<HourWithTemperature> _hoursWithTemperatures = [];
  late Location _location;
  late double _lat;
  late double _long;

  factory WeatherWatcher() {
    return _cache.putIfAbsent(
        'WeatherWatcher', () => WeatherWatcher._internal());
  }

  WeatherWatcher._internal();

  List<HourWithTemperature> get hoursWithTemperatures => _hoursWithTemperatures;

  Future<void> init() async {
    tz.initializeTimeZones();
    _location = getLocation('Europe/Madrid');
    final env = Platform.environment;
    _lat = double.parse(env["WEATHER_LOCATION_LAT"]!);
    _long = double.parse(env["WEATHER_LOCATION_LONG"]!);

    await _populatePriceData();
    _scheduleCronJobs();
  }

  void _cleanupOldData() {
    final oneDayAgo = TZDateTime.now(_location).subtract(Duration(days: 1));
    _logger.i('cron: removing data before day ${oneDayAgo.day}');
    _logger.d('cron: _bestHours before: ${_hoursWithTemperatures.length}');

    _hoursWithTemperatures
        .removeWhere((element) => element.time.isBefore(oneDayAgo));

    _logger.d('cron: _bestHours after: ${_hoursWithTemperatures.length}');
  }

  Future<void> _getWeatherAndHolidaysFromApi(DateTime dateTime) async {
    bool isHolidayOrWeekend = dateTime.weekday == 6 || dateTime.weekday == 7;
    final isoDate = dateTime.toIso8601String().split('T')[0];

    if (!isHolidayOrWeekend) {
      final holidayData = await HttpWrapper().get(
        path: 'https://date.nager.at/api/v3/publicholidays/2023/ES',
      );

      if (holidayData is List) {
        isHolidayOrWeekend = holidayData.any((holiday) =>
            holiday['date'] == isoDate && holiday['global'] == true);
      }

      if (!isHolidayOrWeekend) {
        _logger.i('API: not a holiday');
      } else {
        _logger.i('API: found a holiday');
      }
    }

    final weatherData = await HttpWrapper().get(
      path:
          'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_long&hourly=temperature_2m&forecast_days=1&start_date=$isoDate&end_date=$isoDate&timezone=Europe%2FBerlin',
    );

    var hourlyData =
        List.generate(weatherData['hourly']['time'].length, (index) {
      var time = weatherData['hourly']['time'][index];
      var temperature = weatherData['hourly']['temperature_2m'][index];
      return {'time': time, 'temperature': temperature};
    });

    if (isHolidayOrWeekend) {
      _logger.i('is holiday or weekend');
      for (var element in hourlyData) {
        final newBestHour = HourWithTemperature(
          time: DateTime.parse(element['time']),
          temperature: element['temperature'],
          period: PricePeriod.superOffPeak,
        );
        _hoursWithTemperatures.add(newBestHour);
        _logger.i(
          'Added hour: ${newBestHour.time.toString()} - ${newBestHour.period} - ${newBestHour.temperature}',
        );
      }
    } else {
      _logger.i('is not holiday or weekend');
      List<String> timeList = List<String>.from(weatherData['hourly']['time']);
      List<double> temperatureList =
          List<double>.from(weatherData['hourly']['temperature_2m']);

      List<MapEntry<String, double>> hourTemperaturePairs = List.generate(
        timeList.length,
        (index) => MapEntry(timeList[index], temperatureList[index]),
      );

      List<MapEntry<String, double>> filteredPairs = hourTemperaturePairs
          .where((pair) =>
              (pair.key.contains(RegExp(r'T0[0-7]|T22|T23'))) ||
              (pair.key.contains(RegExp(r'T08|T09|T14|T15|T16|T17'))))
          .toList();

      List<HourWithTemperature> results = filteredPairs.map((pair) {
        DateTime time = DateTime.parse(pair.key);
        PricePeriod period = getPricePeriod(time.hour);
        double temperature = pair.value;
        return HourWithTemperature(
          period: period,
          temperature: temperature,
          time: time,
        );
      }).toList();

      for (HourWithTemperature hourWithTemp in results) {
        _hoursWithTemperatures.add(hourWithTemp);
        _logger.i(
          'Added hour: ${hourWithTemp.time.toString()} - ${hourWithTemp.period} - ${hourWithTemp.temperature}',
        );
      }
    }
  }

  Future<void> _getWeatherAndHolidaysFromApiTomorrow() async {
    final tomorrow = TZDateTime.now(_location).add(Duration(days: 1));
    _logger.i('cron: get price for next day');
    await _getWeatherAndHolidaysFromApi(tomorrow);
  }

  Future<void> _populatePriceData() async {
    final now = TZDateTime.now(_location);
    await _getWeatherAndHolidaysFromApi(now); // TODAY

    if (now.hour >= 23 && now.hour <= 0) {
      if (now.hour == 23 && now.minute < 30) {
        return;
      }

      await _getWeatherAndHolidaysFromApi(now.add(Duration(days: 1)));
    }
  }

  void _scheduleCronJobs() {
    _cron.schedule(
      Schedule.parse('30 23 * * *'),
      _getWeatherAndHolidaysFromApiTomorrow,
    );
    _cron.schedule(Schedule.parse('45 23 * * *'), _cleanupOldData);
  }
}
