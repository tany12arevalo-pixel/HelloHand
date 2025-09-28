// lib/services/api_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';

class ApiService extends ChangeNotifier {
  String _baseUrl = '';
  late http.Client _httpClient;
  
  ApiService() {
    _httpClient = _createHttpClient();
  }
  
  http.Client _createHttpClient() {
    if (kReleaseMode) {
      return http.Client();
    }
    
    // Cliente personalizado para desarrollo que ignore SSL
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('Ignorando certificado SSL para $host:$port');
        return true;
      };
    
    return IOClient(httpClient);
  }
  
  void updateBaseUrl(String ip) {
    _baseUrl = 'https://$ip:8021/api';
    notifyListeners();
  }

  Future<Map<String, dynamic>> testConnection() async {
    print('Conectando a: $_baseUrl/translator/health/');
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/translator/health/'),
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> testAvailableSigns() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/translator/available-signs/'),
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> testModelInfo() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/translator/model-info/'),
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> listRooms() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/rooms/list/'),
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // MÉTODO ORIGINAL para conversación grupal (mantener compatibilidad)
  Future<Map<String, dynamic>> createRoom(String name, int maxParticipants) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/rooms/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'name': name,
        'max_participants': maxParticipants,
        'room_type': 'group', // Por defecto tipo grupal
      }),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // NUEVO MÉTODO con parámetros nombrados para conversación rápida
  Future<Map<String, dynamic>> createRoomWithParams({
    required String participantName,
    required int maxParticipants,
    String? roomType,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/rooms/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'name': 'Sala de $participantName', // Generar nombre automático
        'max_participants': maxParticipants,
        'room_type': roomType ?? 'group',
        'creator_name': participantName,
      }),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // MÉTODO ORIGINAL para conversación grupal (mantener compatibilidad)
  Future<Map<String, dynamic>> joinRoom(String roomId, String participantName) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/rooms/$roomId/join/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'name': participantName,
        'has_camera': true,
        'has_microphone': true,
        'is_deaf': false,
        'is_mute': false,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // NUEVO MÉTODO con parámetros nombrados para conversación rápida
  

  // NUEVO: Obtener información específica de una sala
  Future<Map<String, dynamic>> getRoomInfo(String roomId) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/rooms/$roomId/info/'),
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'Sala no encontrada'
      };
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // EXISTENTE: Obtener estado de una sala
  Future<Map<String, dynamic>> getRoomStatus(String roomId) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/rooms/$roomId/status/'),
      headers: {'Accept': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // EXISTENTE: Salir de una sala
  Future<Map<String, dynamic>> leaveRoom(String roomId, String participantId) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/rooms/$roomId/leave/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'participant_id': participantId,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // NUEVO MÉTODO con parámetros nombrados para conversación rápida
Future<Map<String, dynamic>> joinRoomWithParams({
  required String roomCode,
  required String participantName,
}) async {
  final response = await _httpClient.post(
    Uri.parse('$_baseUrl/rooms/$roomCode/join/'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: json.encode({
      'participant_name': participantName,  // ← Cambiar a 'participant_name'
      'has_camera': true,
      'has_microphone': true,
      'is_deaf': false,
      'is_mute': false,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'success': true,
      'participant_id': data['participant_id'],  // ← Extraer participant_id
      'room_info': data['room_info'],
      'participants': data['participants'],
    };
  } else {
    return {
      'success': false,
      'message': json.decode(response.body)['error'] ?? 'Error desconocido'
    };
  }
} 

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}