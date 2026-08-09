import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api_constants.dart';

class SocketClient {
  static final SocketClient _instance = SocketClient._internal();
  late IO.Socket socket;
  factory SocketClient() {
    return _instance;
  }
  SocketClient._internal();
  void init() {
    // Aynı adrese (port dahil) bağlanır
    socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.onConnect((_) {
      print('[Socket] Sunucuya bağlanıldı');
    });
    socket.onDisconnect((_) {
      print('[Socket] Sunucuyla bağlantı kesildi');
    });
  }

  void onLeaderboardUpdated(Function callback) {
    socket.on('leaderboard_updated', (_) {
      callback();
    });
  }

  void dispose() {
    socket.dispose();
  }
}
