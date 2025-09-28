// lib/screens/menu_crear_conversacion_rapida_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class MenuCrearConversacionRapidaScreen extends StatefulWidget {
  @override
  _MenuCrearConversacionRapidaScreenState createState() => _MenuCrearConversacionRapidaScreenState();
}

class _MenuCrearConversacionRapidaScreenState extends State<MenuCrearConversacionRapidaScreen> {
  final TextEditingController _nombreUsuarioController = TextEditingController();
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
                        'Crear Conversación Rápida',
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
                        'Máximo 2 participantes\nPerfecto para conversaciones íntimas',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Campo Tu Nombre
                      _buildInputWithLabel("Tu nombre:", _nombreUsuarioController, "Escribe tu nombre..."),
                      
                      SizedBox(height: 50),
                      
                      // Botón Crear Conversación Rápida
                      GestureDetector(
                        onTap: _isLoading ? null : () => _crearConversacionRapida(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/elements/menu conversacion rapdia/boton crear conversaison rapida.png',
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

  Widget _buildInputWithLabel(String label, TextEditingController controller, String hint, {bool isNumeric = false}) {
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
              image: AssetImage('assets/images/elements/Menu crear conversacion grupal/input block.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  void _crearConversacionRapida() async {
    // Validaciones
    if (_nombreUsuarioController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa tu nombre');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar IP guardada
      final prefs = await SharedPreferences.getInstance();
      final savedIP = prefs.getString('server_ip');
      
      if (savedIP == null || savedIP.isEmpty) {
        _mostrarError('Primero configura la IP del servidor en la pantalla de Test');
        return;
      }

      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Configurar la URL base con la IP guardada
      apiService.updateBaseUrl(savedIP);
      
      // Crear la sala rápida usando la API (máximo 2 participantes)
      final result = await apiService.createRoomWithParams(
        participantName: _nombreUsuarioController.text.trim(),
        maxParticipants: 2, // Límite fijo para conversación rápida
        roomType: 'quick', // Tipo de sala rápida
      );
      
      final roomId = result['room_id'];
      final nombreUsuario = _nombreUsuarioController.text.trim();
      
      print('Sala rápida creada exitosamente: $roomId');
      print('Usuario creador: $nombreUsuario');
      print('Máximo participantes: 2');
      
      // Mostrar éxito brevemente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Sala rápida creada exitosamente!\nCódigo: $roomId'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Esperar un momento para que se vea el snackbar
      await Future.delayed(Duration(seconds: 1));
      
      // SOLUCIÓN: Navegar SIN participantId (igual que conversación grupal)
      context.go('/conversacion-rapida/$roomId?name=$nombreUsuario&isCreator=true');
      
    } catch (error) {
      _mostrarError('Error al crear la sala rápida: $error');
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
    _nombreUsuarioController.dispose();
    super.dispose();
  }
}