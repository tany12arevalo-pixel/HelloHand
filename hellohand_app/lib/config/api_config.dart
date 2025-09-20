class ApiConfig {
  static const String defaultPort = '8021';
  static const String apiPath = '/api';
  static const bool useHttps = true;
  
  static String buildBaseUrl(String ip) {
    final protocol = useHttps ? 'https' : 'http';
    return '$protocol://$ip:$defaultPort$apiPath';
  }
  
  static String buildWebSocketUrl(String ip) {
    final protocol = useHttps ? 'wss' : 'ws';
    return '$protocol://$ip:$defaultPort/ws';
  }
}