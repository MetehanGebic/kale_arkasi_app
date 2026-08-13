import 'package:dio/dio.dart';
import 'dart:async';
import '../token_storage.dart';
import 'socket_client.dart';

class UnauthorizedEvent {}
final StreamController<UnauthorizedEvent> unauthorizedStream = StreamController<UnauthorizedEvent>.broadcast();

class DioClient {
  static Dio getDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token süresi dolmuş veya geçersiz, global olarak çıkış yap.
          await TokenStorage().clearToken();
          SocketClient().disconnect();
          unauthorizedStream.add(UnauthorizedEvent());
        }
        return handler.next(e);
      },
    ));
    return dio;
  }
}
