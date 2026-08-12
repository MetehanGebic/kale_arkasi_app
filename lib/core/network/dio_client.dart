import 'package:dio/dio.dart';
import 'dart:async';
import '../token_storage.dart';

class UnauthorizedEvent {}
final StreamController<UnauthorizedEvent> unauthorizedStream = StreamController<UnauthorizedEvent>.broadcast();

class DioClient {
  static Dio getDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token süresi dolmuş veya geçersiz, global olarak çıkış yap.
          await TokenStorage().clearToken();
          unauthorizedStream.add(UnauthorizedEvent());
        }
        return handler.next(e);
      },
    ));
    return dio;
  }
}
