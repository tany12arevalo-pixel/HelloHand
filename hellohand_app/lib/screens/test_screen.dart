// lib/screens/test_screen.dar
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TextEditingController _ipController = TextEditingController();
  String _consoleOutput = '';

  @override
  void initState() {
    super.initState();
    _loadSavedIP();
  }

  void _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('server_ip') ?? '192.168.1.100';
    });
  }

  void _saveIP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _ipController.text);
    _updateConsole('✓ IP guardada: ${_ipController.text}');
  }

  void _updateConsole(String message) {
    setState(() {
      _consoleOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Servidor Django'),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input para IP
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'IP del Servidor',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // Botón Guardar IP
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveIP(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Guardar IP'),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Botones de prueba
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _testConnection(),
                        child: Text('Test Health'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _testModelInfo(),
                        child: Text('Model Info'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _testAvailableSigns(),
                        child: Text('Señas Disponibles'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _testListRooms(),
                        child: Text('Listar Salas'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _testCreateRoom(),
                    child: Text('Test Crear Sala'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Botón limpiar consola
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _consoleOutput = '';
                });
              },
              child: Text('Limpiar Consola'),
            ),
            
            SizedBox(height: 16),
            
            // Consola de salida
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _consoleOutput.isEmpty ? 'Consola vacía...' : _consoleOutput,
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testConnection() async {
    _updateConsole('Probando conexión...');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      apiService.updateBaseUrl(_ipController.text);
      
      final result = await apiService.testConnection();
      _updateConsole('✓ Conexión exitosa: $result');
    } catch (e) {
      _updateConsole('✗ Error de conexión: $e');
    }
  }

  void _testCreateRoom() async {
    _updateConsole('Probando crear sala...');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      apiService.updateBaseUrl(_ipController.text);
      
      final result = await apiService.createRoom('Sala de Prueba', 10);
      _updateConsole('✓ Sala creada: ${result['room_id']}');
    } catch (e) {
      _updateConsole('✗ Error crear sala: $e');
    }
  }

  void _testModelInfo() async {
    _updateConsole('Obteniendo info del modelo...');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      apiService.updateBaseUrl(_ipController.text);
      
      final result = await apiService.testModelInfo();
      _updateConsole('✓ Modelo: ${result['model_name']} - ${result['status']}');
    } catch (e) {
      _updateConsole('✗ Error modelo: $e');
    }
  }

  void _testAvailableSigns() async {
    _updateConsole('Obteniendo señas disponibles...');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      apiService.updateBaseUrl(_ipController.text);
      
      final result = await apiService.testAvailableSigns();
      final signs = result['signs'] as List;
      _updateConsole('✓ Señas disponibles: ${signs.join(', ')}');
    } catch (e) {
      _updateConsole('✗ Error señas: $e');
    }
  }

  void _testListRooms() async {
    _updateConsole('Listando salas...');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      apiService.updateBaseUrl(_ipController.text);
      
      final result = await apiService.listRooms();
      final rooms = result['rooms'] as List;
      _updateConsole('✓ Salas activas: ${rooms.length}');
      if (rooms.isNotEmpty) {
        for (var room in rooms) {
          _updateConsole('  - ${room['name']} (${room['room_id']})');
        }
      }
    } catch (e) {
      _updateConsole('✗ Error listar salas: $e');
    }
  }
}