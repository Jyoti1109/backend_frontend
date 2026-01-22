import 'package:dio/dio.dart';
import 'package:good_news/core/constants/api_constants.dart';

class ApiClient {
  static final Dio _dio = Dio();

  static Future<Response> get(String endpoint) async {
    return await _dio.get('${ApiConstants.baseUrl}$endpoint');
  }

  static Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    return await _dio.post('${ApiConstants.baseUrl}$endpoint', data: data);
  }
}