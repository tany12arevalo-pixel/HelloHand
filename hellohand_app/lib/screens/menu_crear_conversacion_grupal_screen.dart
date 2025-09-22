import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class MenuCrearConversacionGrupalScreen extends StatefulWidget {
  @override
  _MenuCrearConversacionGrupalScreenState createState() => _MenuCrearConversacionGrupalScreenState();
}

class _MenuCrearConversacionGrupalScreenState extends State<MenuCrearConversacionGrupalScreen> {
  final TextEditingController _nombreUsuarioController = TextEditingController();
  final TextEditingController _nombreSalaController = TextEditingController();
  final TextEditingController _maxParticipantesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Valores por defecto
    _maxParticipantesController.text = '10';
  }

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
                    onTap: () => context.go('/menu-conversacion-grupal'),
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
                      // Campo Tu Nombre
                      _buildInputWithLabel("Tu nombre:", _nombreUsuarioController, "Escribe tu nombre..."),
                      
                      SizedBox(height: 30),
                      
                      // Campo Nombre de la Sala
                      _buildInputWithLabel("Nombre de la sala:", _nombreSalaController, "Mi sala HelloHand"),
                      
                      SizedBox(height: 30),
                      
                      // Campo Máximo Participantes
                      _buildInputWithLabel("Máximo participantes:", _maxParticipantesController, "10", isNumeric: true),
                      
                      SizedBox(height: 50),
                      
                      // Botón Crear Conversación
                      GestureDetector(
                        onTap: _isLoading ? null : () => _crearConversacion(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/elements/Menu crear conversacion grupal/boton crear conversacion.png',
                              width: double.infinity,
                              height: 70,
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

  void _crearConversacion() async {
    // Validaciones
    if (_nombreUsuarioController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa tu nombre');
      return;
    }
    
    if (_nombreSalaController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa el nombre de la sala');
      return;
    }
    
    final maxParticipantes = int.tryParse(_maxParticipantesController.text.trim());
    if (maxParticipantes == null || maxParticipantes < 2 || maxParticipantes > 50) {
      _mostrarError('El número de participantes debe estar entre 2 y 50');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Crear la sala usando la API
      final result = await apiService.createRoom(
        _nombreSalaController.text.trim(),
        maxParticipantes,
      );
      
      final roomId = result['room_id'];
      final nombreUsuario = _nombreUsuarioController.text.trim();
      
      // TODO: Navegar a la sala creada con el usuario como creador
      print('Sala creada exitosamente: $roomId');
      print('Usuario creador: $nombreUsuario');
      
      // Por ahora mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Sala creada exitosamente!\nCódigo: $roomId'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // TODO: Navegar a la pantalla de la sala
      // context.go('/room/$roomId?name=$nombreUsuario&isCreator=true');
      
    } catch (error) {
      _mostrarError('Error al crear la sala: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    _nombreSalaController.dispose();
    _maxParticipantesController.dispose();
    super.dispose();
  }
}