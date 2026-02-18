import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CookieInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final cookie = await _storage.read(key: "session_cookie");
    if (cookie != null) {
      options.headers['Cookie'] = cookie;
      print("➡️ Sending Cookie: $cookie");
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.headers.map.containsKey('set-cookie')) {
      String newCookie = response.headers.map['set-cookie']!.join('; ');
      _storage.write(key: "session_cookie", value: newCookie);
      print("✅ Stored Cookie: $newCookie");
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storage.delete(key: "session_cookie");
      print("⚠️ Session Expired, cleared cookie.");
    }
    handler.next(err);
  }
}

class ApiClient {
  final Dio dio;

  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: "https://api.seattlepulse.net/api/v1",
          connectTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        )) {
    dio.interceptors.add(CookieInterceptor());
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<Response> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    try {
      print("🔄 API REQUEST: GET $endpoint");
      print("🔄 API PARAMS: $queryParams");

      final response = await dio.get(endpoint, queryParameters: queryParams);

      print("✅ API RESPONSE STATUS: ${response.statusCode}");
      print("✅ API RESPONSE SIZE: ${response.data.toString().length} chars");

      return response;
    } catch (e) {
      print("❌ API ERROR: $e");
      // Rethrow to let the repository handle the error
      rethrow;
    }
  }

  Future<Response> post(String endpoint,
      {Map<String, dynamic>? queryParams, dynamic data}) async {
    return await dio.post(endpoint, data: data, queryParameters: queryParams);
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    return await dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint,
      {Map<String, dynamic>? queryParams, dynamic data}) async {
    return await dio.delete(endpoint, data: data, queryParameters: queryParams);
  }
}
