import 'dart:io';

import 'package:cron/cron.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:weatherman/models/best_hour.dart';
import 'package:weatherman/tools/http_wrapper.dart';

import 'tools/logger.dart';

class WeatherWatcher {
  static final Map<String, WeatherWatcher> _cache = <String, WeatherWatcher>{};
  final _logger = LoggerWrapper().logger;
  final _cron = Cron();
  final List<BestHour> _bestHours = [];
  late Location _location;
  late double _lat;
  late double _long;
  late int _numberOfTimeSlots;

  factory WeatherWatcher() {
    return _cache.putIfAbsent(
        'WeatherWatcher', () => WeatherWatcher._internal());
  }
  WeatherWatcher._internal();

  List<BestHour> get bestHours => _bestHours;

  Future<void> init() async {
    tz.initializeTimeZones();
    _location = getLocation('Europe/Madrid');
    final env = Platform.environment;
    _lat = double.parse(env["WEATHER_LOCATION_LAT"]!);
    _long = double.parse(env["WEATHER_LOCATION_LONG"]!);
    _numberOfTimeSlots = int.parse(env["NUMBER_OF_TIME_SLOTS"]!);

    //populate prices
    await _populatePriceData();

    //schedule crons
    /* 
    This cronjob will get the price data every day at 20:30 (Madrid time) for the Spanish API
    */
    _cron.schedule(Schedule.parse('31 20 * * *'), () async {
      //default timezone for docker-compose.yml is Europe/Madrid as well
      _logger.i('cron: get price for next day');
      await _getPricesFromAPI(
        TZDateTime.now(_location).add(Duration(days: 1)),
      );
    });

    /* 
    This cronjob cleans up the data table, every day at 21:00 (Madrid time)
    */
    _cron.schedule(Schedule.parse('0 21 * * *'), () async {
      final oneDayAgo = TZDateTime.now(_location).subtract(Duration(days: 1));
      _logger.i('cron: removing data before day ${oneDayAgo.day}');
      _logger.d('cron: _bestHours before: ${_bestHours.length}');

      _bestHours.removeWhere(
        (element) => element.time.isBefore(oneDayAgo),
      );

      _logger.d('cron: _bestHours after: ${_bestHours.length}');
    });
  }

  Future<void> _getPricesFromAPI(DateTime dateTime) async {
    final isoDate = dateTime.toIso8601String().split('T')[0];
    final timeInSeconds = dateTime.millisecondsSinceEpoch ~/ 1000;

    final priceData = await HttpWrapper().getProtected(
      path:
          'https://pvpc-hourly-spanish-energy-prices-api.p.rapidapi.com/price-daily/$timeInSeconds/peninsular',
    ); //TODO allow location to be configurable
    final weatherData = await HttpWrapper().get(
      path:
          'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_long&hourly=temperature_2m&forecast_days=1&start_date=$isoDate&end_date=$isoDate&timezone=Europe%2FBerlin',
    );

    // Create a list of hourly data tuples with time, price, and temperature
    var hourlyData =
        List.generate(weatherData['hourly']['time'].length, (index) {
      var time = weatherData['hourly']['time'][index];
      var price = priceData[index]['price'];
      var temperature = weatherData['hourly']['temperature_2m'][index];
      var priceRating = priceData[index]['price_rating'];
      return {
        'time': time,
        'price': price,
        'temperature': temperature,
        'priceRating': priceRating
      };
    });

    // Sort the hourly data by price (ascending), then by time (ascending)
    hourlyData.sort((a, b) {
      int priceComparison = a['price'].compareTo(b['price']);
      if (priceComparison != 0) {
        return priceComparison;
      }
      return a['time'].compareTo(b['time']);
    });

    // Find the four hours with the lowest price and highest temperature
    var cheapestHours = hourlyData.sublist(0, _numberOfTimeSlots);
    cheapestHours.sort((a, b) => a['time'].compareTo(b['time']));

    // Create a list of BestHour objects from the cheapestHours list
    for (var element in cheapestHours) {
      _bestHours.add(
        BestHour(
          time: DateTime.parse(element['time']),
          price: element['price'],
          temperature: element['temperature'],
        ),
      );
      _logger.i(
        'Added best hour: ${DateTime.parse(element['time'])} - ${element['price']} - ${element['temperature']}',
      );
    }
  }

  Future<void> _populatePriceData() async {
    final now = TZDateTime.now(_location);
    await _getPricesFromAPI(now); //TODAY

    if (now.hour >= 20 && now.hour <= 23) {
      //check if init happened between 20 and 23 -> cron might not have run -> get tomorrows data
      if (now.hour == 20 && now.minute < 30) {
        //don't fetch before 20:30
        return;
      }

      await _getPricesFromAPI(
        now.add(Duration(days: 1)),
      );
    }
  }
}
