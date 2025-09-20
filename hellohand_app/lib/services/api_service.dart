// lib/services/api_services.dar
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
      }),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}