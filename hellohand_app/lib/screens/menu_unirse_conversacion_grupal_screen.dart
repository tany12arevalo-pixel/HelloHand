// lib/screens/menu_unirse_conversacion_grupal_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class MenuUnirseConversacionGrupalScreen extends StatefulWidget {
  @override
  _MenuUnirseConversacionGrupalScreenState createState() => _MenuUnirseConversacionGrupalScreenState();
}

class _MenuUnirseConversacionGrupalScreenState extends State<MenuUnirseConversacionGrupalScreen> {
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
            padding: EdgeInsets.all(2),
            child: Column(
              children: [
                // Botón Volver al Inicio (arriba)
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/menu-conversacion-grupal'),
                    child: Image.asset(
                      'assets/images/elements/boton_volver_al_inicio.png',
                      height: 120,
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
                      // Campo ID de la Sala
                      _buildInputWithLabel("Coloca el ID de la sala:", _roomIdController, "ABC123"),
                      
                      SizedBox(height: 20),
                      
                      // Botón Escanear QR
                      GestureDetector(
                        onTap: () => _escanearQR(),
                        child: Image.asset(
                          'assets/images/elements/menu unrise conversacion grupal/boton escanar QR.png',
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Campo Nombre del Usuario
                      _buildInputWithLabel("Coloca tu nombre:", _nombreController, "Tu nombre..."),
                      
                      SizedBox(height: 50),
                      
                      // Botón Unirse a la Conversación
                      GestureDetector(
                        onTap: _isLoading ? null : () => _unirseConversacion(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/elements/menu unrise conversacion grupal/boton unirse a la conversacion.png',
                              width: double.infinity,
                              height: 125,
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
          ),
        ),
      ],
    );
  }

  void _escanearQR() {
    // TODO: Implementar scanner QR en el futuro
    print('Abrir scanner QR');
    _mostrarInfo('Scanner QR próximamente...');
  }

  void _unirseConversacion() async {
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
      
      print('Intentando unirse a sala: $roomId');
      print('Usuario: $nombreUsuario');
      
      // Verificar que la sala existe haciendo una llamada de prueba
      try {
        // Nota: La API joinRoom manejará si la sala existe o no
        // Si la sala no existe, el backend devolverá un error
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Uniéndose a la sala $roomId!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Esperar un momento para que se vea el snackbar
        await Future.delayed(Duration(seconds: 1));
        
        // Navegar a la pantalla de la sala
        context.go('/conversacion-grupal/$roomId?name=$nombreUsuario&isCreator=false');
        
      } catch (apiError) {
        throw Exception('La sala "$roomId" no existe o no está disponible');
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

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
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