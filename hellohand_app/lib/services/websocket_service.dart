// lib/services/websocket_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverIp = '';
  String _currentRoomId = '';
  String _currentParticipantId = '';
  
  // Lista de mensajes recibidos
  List<Map<String, dynamic>> _receivedMessages = [];
  
  // Callbacks para diferentes tipos de mensajes
  final Map<String, List<Function(Map<String, dynamic>)>> _messageCallbacks = {};

  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get receivedMessages => List.from(_receivedMessages);

  void updateServerIp(String ip) {
    _serverIp = ip;
  }

  Future<void> connect(String roomId, String participantId) async {
    try {
      _currentRoomId = roomId;
      _currentParticipantId = participantId;
      
      final wsUrl = '${ApiConfig.buildWebSocketUrl(_serverIp)}/room/$roomId/?participant_id=$participantId';
      print('Conectando WebSocket a: $wsUrl');
      
      // Crear HttpClient con certificados SSL ignorados
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('Ignorando certificado SSL WebSocket para $host:$port');
          return true;
        };
      
      // Usar IOWebSocketChannel directamente con HttpClient personalizado  
      final webSocket = await WebSocket.connect(
        wsUrl,
        customClient: httpClient,
      );
      
      _channel = IOWebSocketChannel(webSocket);
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );
      
      _isConnected = true;
      notifyListeners();
      print('WebSocket conectado exitosamente');
    } catch (e) {
      print('Error conectando WebSocket: $e');
      throw Exception('Error conectando WebSocket: $e');
    }
  }

  // Método removido ya no es necesario

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      final jsonMessage = json.encode(message);
      print('Enviando mensaje WebSocket: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } else {
      print('WebSocket no conectado, no se puede enviar mensaje: $message');
    }
  }

  void sendChatMessage(String message) {
    sendMessage({
      'type': 'chat_message',
      'message': message,
      'participant_id': _currentParticipantId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Sistema de callbacks para diferentes tipos de mensajes
  void addMessageCallback(String messageType, Function(Map<String, dynamic>) callback) {
    if (!_messageCallbacks.containsKey(messageType)) {
      _messageCallbacks[messageType] = [];
    }
    _messageCallbacks[messageType]!.add(callback);
  }

  void removeMessageCallback(String messageType, Function(Map<String, dynamic>) callback) {
    if (_messageCallbacks.containsKey(messageType)) {
      _messageCallbacks[messageType]!.remove(callback);
    }
  }

  void _onMessage(dynamic data) {
    try {
      final message = json.decode(data);
      print('Mensaje WebSocket recibido: $message');
      
      // Guardar mensaje en lista
      _receivedMessages.add(message);
      
      // Limitar el número de mensajes guardados
      if (_receivedMessages.length > 100) {
        _receivedMessages.removeAt(0);
      }
      
      // Ejecutar callbacks específicos para el tipo de mensaje
      final messageType = message['type'];
      if (messageType != null && _messageCallbacks.containsKey(messageType)) {
        for (final callback in _messageCallbacks[messageType]!) {
          try {
            callback(message);
          } catch (e) {
            print('Error ejecutando callback para $messageType: $e');
          }
        }
      }
      
      // Notificar cambios generales
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
    print('WebSocket desconectado');
    _isConnected = false;
    notifyListeners();
  }

  void disconnect() {
    print('Desconectando WebSocket...');
    _channel?.sink.close();
    _isConnected = false;
    _currentRoomId = '';
    _currentParticipantId = '';
    _receivedMessages.clear();
    _messageCallbacks.clear();
    notifyListeners();
  }

  // Métodos de utilidad
  List<Map<String, dynamic>> getMessagesByType(String type) {
    return _receivedMessages.where((message) => message['type'] == type).toList();
  }

  List<Map<String, dynamic>> getChatMessages() {
    return getMessagesByType('chat_message');
  }

  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'roomId': _currentRoomId,
      'participantId': _currentParticipantId,
      'serverIp': _serverIp,
      'totalMessages': _receivedMessages.length,
    };
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}