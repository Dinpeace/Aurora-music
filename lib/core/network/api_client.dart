import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'endpoints.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(
        seconds: 15,
      ),
      receiveTimeout: const Duration(
        seconds: 15,
      ),
      responseType: ResponseType.json,
    ),
  )..interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        responseBody: true,
      ),
    );
}