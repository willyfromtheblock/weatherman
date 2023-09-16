import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import '../tools/logger.dart';

class HttpWrapper {
  static final Map<String, HttpWrapper> _cache = <String, HttpWrapper>{};
  final _logger = LoggerWrapper().logger;
  Map<String, String> env = Platform.environment;
  late Dio _dio;

  factory HttpWrapper() {
    return _cache.putIfAbsent('httpWrapper', () => HttpWrapper._internal());
  }
  HttpWrapper._internal();

  void log(dynamic data) {
    _logger.e('HttpWrapper Dio ${data.toString()}');
  }

  void init() {
    _dio = Dio();

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: log,
        retries: 10,
      ),
    );

    _logger.d('Dio initialized ... ');
  }

  void _handleError(Object rawError) {
    final e = rawError as DioError;
    log(e.toString());
    if (e.response != null) {
      log(e.response!.data);
      log(e.response!.headers);
      // log(e.requestOptions.path);
    } else {
      log(e.requestOptions);
      log(e.message);
    }
  }

  Future<dynamic> post(String path, Map payload) async {
    try {
      final res = await _dio.post(
        path,
        data: payload,
      );
      return res.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> get({
    required String path,
    bool requestJson = true,
    bool trimmed = false,
  }) async {
    try {
      final res = await _dio.get(
        path,
        options: requestJson
            ? Options(
                headers: {'Content-Type': 'application/json'},
              )
            : Options(),
      );

      final data = res.data.toString();
      if (trimmed == true) {
        return data.trim();
      }

      return res.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}
