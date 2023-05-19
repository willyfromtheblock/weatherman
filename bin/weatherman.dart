import 'dart:io';

import 'package:weatherman/rest_server.dart';
import 'package:weatherman/tools/http_wrapper.dart';
import 'package:weatherman/tools/logger.dart';
import 'package:weatherman/weather_watcher.dart';

void main() async {
  Map<String, String> env = Platform.environment;
  List<String> requiredEnvs = [
    "API_SECRET",
    "RAPID_API_KEY",
    "RAPID_API_HOST",
    "HTTP_LOG_LEVEL",
    "LOG_LEVEL",
    "HTTP_PORT",
    "WEATHER_LOCATION_LONG",
    "WEATHER_LOCATION_LAT",
    "NUMBER_OF_TIME_SLOTS",
  ];

  for (var requiredEnv in requiredEnvs) {
    if (!env.containsKey(requiredEnv)) {
      throw Exception("$requiredEnv needs to be in environment");
    } else if (env[requiredEnv]!.isEmpty) {
      throw Exception("$requiredEnv needs to have a value");
    }
  }

  final numberOfTimeSlots = int.parse(env["NUMBER_OF_TIME_SLOTS"]!);
  if (numberOfTimeSlots > 24 || numberOfTimeSlots < 1) {
    throw Exception(
      "NUMBER_OF_TIME_SLOTS needs to be in range of 1-24",
    );
  }

  LoggerWrapper().init();
  HttpWrapper().init();
  await WeatherWatcher().init();
  await RESTServer().serve();
//TODO Tests
//TODO Readme
//TODO github actions
}
