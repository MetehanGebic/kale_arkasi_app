import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api_constants.dart';

class SocketClient {
  void disconnect() {
    try {
      socket.disconnect();
      socket.dispose();
    } catch (_) {}
  }
  static final SocketClient _instance = SocketClient._internal();
  late io.Socket socket;
  factory SocketClient() {
    return _instance;
  }
  SocketClient._internal();

  void init({String? token}) {
    if (token == null) {
      // Bağlanma, çünkü token yok. Gerekirse başlangıçta boş bırakılabilir.
    }
    
    // Varolan socketi kapat
    try {
      socket.dispose();
    } catch (_) {}

    socket = io.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      if (token != null) 'auth': {'token': token},
    });
    
    socket.onConnect((_) {
      debugPrint('[Socket] Sunucuya bağlanıldı');
    });
    socket.onDisconnect((_) {
      debugPrint('[Socket] Sunucuyla bağlantı kesildi');
    });
  }

  void joinMatch(String matchId) {
    if (socket.connected) {
      socket.emit('join_match', matchId);
    }
  }

  void votePoll(String pollId, int optionIndex) {
    if (socket.connected) {
      socket.emit('vote_poll', {
        'pollId': pollId,
        'optionIndex': optionIndex,
      });
    }
  }

  void leaveMatch(String matchId) {
    socket.emit('leave_match', matchId);
  }

  void sendMessage(String matchId, String text, {bool isCapo = false}) {
    socket.emit('send_message', {
      'matchId': matchId,
      'text': text,
      'isCapo': isCapo,
    });
  }

  void buyAddon(String matchId, String type, {String? target}) {
    final payload = <String, dynamic>{
      'matchId': matchId,
      'type': type,
    };
    if (target != null) {
      payload['target'] = target;
    }
    socket.emit('buy_addon', payload);
  }

  void onChatMessage(Function(Map<String, dynamic>) callback) {
    socket.on('chat_message', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void onAddonEvent(Function(Map<String, dynamic>) callback) {
    socket.on('addon_event', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void submitPollVote(String matchId, String pollId, String optionId) {
    socket.emit('submit_poll_vote', {
      'matchId': matchId,
      'pollId': pollId,
      'optionId': optionId,
    });
  }

  void onPollUpdated(Function(Map<String, dynamic>) callback) {
    socket.on('poll_updated', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void onSocketError(Function(String) callback) {
    socket.on('socket_error', (data) {
      if (data is Map) {
        callback(data['message']?.toString() ?? 'Bilinmeyen Hata');
      }
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

