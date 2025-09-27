// lib/screens/menu_unirse_conversacion_rapida_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class MenuUnirseConversacionRapidaScreen extends StatefulWidget {
  @override
  _MenuUnirseConversacionRapidaScreenState createState() => _MenuUnirseConversacionRapidaScreenState();
}

class _MenuUnirseConversacionRapidaScreenState extends State<MenuUnirseConversacionRapidaScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/elements/Background_1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Botón Volver al Inicio (arriba)
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/menu-conversacion-rapida'),
                    child: Image.asset(
                      'assets/images/elements/boton_volver_al_inicio.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // Espacio ajustable entre botón volver y contenido
                SizedBox(height: 50),
                
                // Contenido centrado
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título descriptivo
                      Text(
                        'Unirse a Conversación Rápida',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Descripción
                      Text(
                        'Ingresa el código de la sala\npara conversar 1 a 1',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Campo ID de la Sala
                      _buildInputWithLabel("Coloca el ID de la sala:", _roomIdController, "ABC123"),
                      
                      SizedBox(height: 30),
                      
                      // Campo Nombre del Usuario
                      _buildInputWithLabel("Coloca tu nombre:", _nombreController, "Tu nombre..."),
                      
                      SizedBox(height: 50),
                      
                      // Botón Unirse a la Conversación Rápida
                      GestureDetector(
                        onTap: _isLoading ? null : () => _unirseConversacionRapida(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/elements/menu conversacion rapdia/boton unirse a conversasion rapida.png',
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.contain,
                            ),
                            if (_isLoading)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputWithLabel(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto label
        Padding(
          padding: EdgeInsets.only(left: 10, bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Input con imagen de fondo
        Container(
          height: 60,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/elements/menu unrise conversacion grupal/layer input.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 16),
            textCapitalization: controller == _roomIdController 
                ? TextCapitalization.characters 
                : TextCapitalization.words,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white54),
            ),
            onChanged: (value) {
              if (controller == _roomIdController) {
                // Auto convertir a mayúsculas para códigos de sala
                final upperValue = value.toUpperCase();
                if (upperValue != value) {
                  controller.value = TextEditingValue(
                    text: upperValue,
                    selection: TextSelection.collapsed(offset: upperValue.length),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  void _unirseConversacionRapida() async {
    // Validaciones
    if (_roomIdController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa el ID de la sala');
      return;
    }
    
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa tu nombre');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar la IP guardada desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedIP = prefs.getString('server_ip');
      
      if (savedIP == null || savedIP.isEmpty) {
        _mostrarError('Primero configura la IP del servidor en la pantalla de Test');
        return;
      }
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Configurar la URL base
      apiService.updateBaseUrl(savedIP);
      
      final roomId = _roomIdController.text.trim().toUpperCase();
      final nombreUsuario = _nombreController.text.trim();
      
      print('Intentando unirse a sala rápida: $roomId');
      print('Usuario: $nombreUsuario');
      
      try {
        // Verificar que la sala existe y es del tipo correcto
        final roomInfo = await apiService.getRoomInfo(roomId);
        
        if (!roomInfo['success']) {
          throw Exception('La sala "$roomId" no existe');
        }

        final roomData = roomInfo['room'];
        
        // Verificar que es una sala rápida
        if (roomData['room_type'] != 'quick') {
          throw Exception('Esta no es una sala de conversación rápida');
        }

        // Verificar que no esté llena (máximo 2 participantes)
        if (roomData['participant_count'] >= 2) {
          throw Exception('La sala está llena (máximo 2 participantes)');
        }
        
        // Unirse a la sala
        final joinResult = await apiService.joinRoom(
          roomCode: roomId,
          participantName: nombreUsuario,
        );
        
        if (!joinResult['success']) {
          throw Exception(joinResult['message'] ?? 'Error al unirse a la sala');
        }
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Te has unido a la sala rápida $roomId!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Esperar un momento para que se vea el snackbar
        await Future.delayed(Duration(seconds: 1));
        
        // Navegar a la pantalla de la sala rápida
        context.go('/conversacion-rapida/$roomId?name=$nombreUsuario&isCreator=false');
        
      } catch (apiError) {
        throw Exception(apiError.toString());
      }
      
    } catch (error) {
      _mostrarError('Error al unirse a la sala: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _nombreController.dispose();
    super.dispose();
  }
}