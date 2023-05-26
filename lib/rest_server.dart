/// Find the implementation of the strom_api endpoints.
///
/// {@category REST}
library rest_server;

import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:timezone/timezone.dart';
import 'package:weatherman/weather_watcher.dart';

import 'tools/logger.dart';

class RESTServer {
  final _logger = LoggerWrapper().logger;
  final _env = Platform.environment;

  RESTServer();

  final _httpServer = Alfred(
    logLevel: LogType.values.firstWhere(
      (element) => Platform.environment['HTTP_LOG_LEVEL']! == element.name,
    ),
  );

  final Location _locationMadrid = getLocation('Europe/Madrid');
  final AlfredException notInSetException = AlfredException(
    400,
    {
      "message":
          "This timestamp is not included in the current table. weatherman does not serve this time frame."
    },
  );

  Future<void> serve() async {
    //API header middleware
    //Enable only if API protected mode is true in env variables
    _httpServer.all(
      '/best-time-daily/:timestamp:int/:slots:int',
      (req, res) {
        if (req.headers.value('API_KEY') != _env['API_SECRET']!) {
          throw AlfredException(
            401,
            {'error': 'You are not authorized to perform this operation'},
          );
        }
      },
    );

    _httpServer.get(
      '/alive',
      (req, res) async {
        res.json({'message': 'I am alive!'});
      },
    );

    /// price-daily endpoint
    ///
    /// Returns JSON with price data for the day that matches the timestamp in the given zone.
    /// Returned "time" object is  l o c a l time in the given zone.
    ///
    /// Parameter 1:
    /// int - timestamp: in s e c o n d s unix time U T C
    /// if timestamp is 0, current day for the zone will be used
    //
    /// Parameter 2:
    /// int - slots: number of results to return
    //

    _httpServer.get(
      '/best-time-daily/:timestamp:int/:slots:int',
      (req, res) async {
        final timestamp = _parseDateTime(req.params['timestamp']);
        final timeNow = _getTimeForZone(timestamp);
        final slots = req.params['slots'];

        final prices = WeatherWatcher().hoursWithTemperatures;
        final result = prices
            .where(
              (element) => element.time.day == timeNow.day,
            )
            .toList();
        if (result.isEmpty) {
          throw notInSetException;
        } else {
          // sorts hourlyData by highest temperature
          result.sort((a, b) => b.temperature.compareTo(a.temperature));
          final shortenedList = result.sublist(0, slots);
          //sort shorenedList by time
          shortenedList.sort((a, b) => a.time.compareTo(b.time));
          await res.json(shortenedList.map((e) => e.toMap()).toList());
        }
      },
    );

    final server = await _httpServer.listen(
      int.parse(_env['HTTP_PORT']!),
    );
    _logger.i('http_server: Listening on ${server.port}');
  }

  TZDateTime _getTimeForZone(DateTime timestamp) {
    return TZDateTime.from(timestamp, _locationMadrid);
  }

  DateTime _parseDateTime(int timestampInSecondsSinceEpoch) {
    if (timestampInSecondsSinceEpoch == 0) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(
      timestampInSecondsSinceEpoch * 1000,
    );
  }
}
