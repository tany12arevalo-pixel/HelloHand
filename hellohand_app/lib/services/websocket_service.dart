import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverIp = '';

  bool get isConnected => _isConnected;

  void updateServerIp(String ip) {
    _serverIp = ip;
  }

  Future<void> connect(String roomId, String participantId) async {
    try {
      final wsUrl = '${ApiConfig.buildWebSocketUrl(_serverIp)}/room/$roomId/$participantId/';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );
      
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Error conectando WebSocket: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  void sendChatMessage(String message) {
    sendMessage({
      'type': 'chat_message',
      'message': message,
    });
  }

  void _onMessage(dynamic data) {
    try {
      final message = json.decode(data);
      // Notificar a listeners sobre el mensaje recibido
      notifyListeners();
    } catch (e) {
      print('Error procesando mensaje WebSocket: $e');
    }
  }

  void _onError(error) {
    print('Error WebSocket: $error');
    _isConnected = false;
    notifyListeners();
  }

  void _onDisconnected() {
    _isConnected = false;
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}