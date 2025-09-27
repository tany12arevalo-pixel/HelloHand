// lib/screens/conversacion_grupal_screen.dart
// Pantalla principal de conversación grupal con chat en tiempo real
// Implementa WebSocket para comunicación instantánea entre participantes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/webrtc_service.dart';
import '../models/participant.dart';
import '../models/room.dart';

/// Pantalla principal para la conversación grupal de HelloHand
/// Maneja la conexión WebSocket, chat en tiempo real y estado de participantes
class ConversacionGrupalScreen extends StatefulWidget {
  final String roomId;           // ID de la sala a la que se conecta
  final String participantName;  // Nombre del participante actual
  final bool isCreator;         // Si es el creador de la sala

  const ConversacionGrupalScreen({
    Key? key,
    required this.roomId,
    required this.participantName,
    this.isCreator = false,
  }) : super(key: key);

  @override
  _ConversacionGrupalScreenState createState() => _ConversacionGrupalScreenState();
}

class _ConversacionGrupalScreenState extends State<ConversacionGrupalScreen> {
  // Estados principales de la pantalla
  bool _isLoading = true;      // Estado de carga inicial
  bool _isConnected = false;   // Estado de conexión WebSocket
  String _error = '';          // Mensaje de error si algo falla
  String _participantId = '';  // ID único del participante (UUID)
  
  // Datos de la sala y participantes
  Room? _room;                          // Objeto de la sala actual
  List<Participant> _participants = []; // Lista de participantes activos
  
  // Sistema de chat en tiempo real
  List<ChatMessage> _messages = [];                               // Lista de mensajes del chat
  final TextEditingController _messageController = TextEditingController(); // Controlador del input
  final ScrollController _chatScrollController = ScrollController();        // Controlador del scroll del chat
  
  // Estados de la interfaz de usuario
  bool _showParticipants = false; // Mostrar panel de participantes
  bool _showOptions = false;      // Mostrar panel de opciones

  // WebRTC para videollamadas
  WebRTCService? _webrtcService;

  @override
  void initState() {
    super.initState();
    // Inicializar WebRTC service
    _webrtcService = WebRTCService();
    // Inicializar la sala al cargar la pantalla
    _initializeRoom();
  }

  @override
  void dispose() {
    // Limpiar recursos al salir de la pantalla
    _messageController.dispose();
    _chatScrollController.dispose();
    _disconnectWebSocket();
    _webrtcService?.dispose();
    super.dispose();
  }

  /// Inicialización completa de la sala
  /// 1. Configura conexión al servidor
  /// 2. Se une a la sala via API REST
  /// 3. Conecta WebSocket para tiempo real
  Future<void> _initializeRoom() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Paso 1: Configurar IP del servidor desde SharedPreferences
      await _setupServerConnection();
      
      // Paso 2: Unirse a la sala usando API REST
      await _joinRoom();
      
      // Paso 3: Conectar WebSocket para comunicación en tiempo real
      await _connectWebSocket();
      
      // Paso 4: Inicializar WebRTC
      await _initializeWebRTC();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (error) {
      setState(() {
        _error = 'Error inicializando sala: $error';
        _isLoading = false;
      });
    }
  }

  /// Configurar conexión al servidor Django
  /// Obtiene la IP guardada y configura tanto ApiService como WebSocketService
  Future<void> _setupServerConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final serverIp = prefs.getString('server_ip');
    
    if (serverIp == null || serverIp.isEmpty) {
      throw Exception('IP del servidor no configurada. Ve a Test para configurarla.');
    }
    
    // Configurar ApiService para llamadas REST
    final apiService = Provider.of<ApiService>(context, listen: false);
    apiService.updateBaseUrl(serverIp);
    
    // Configurar WebSocketService para tiempo real
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    wsService.updateServerIp(serverIp);
  }

  /// Unirse a la sala usando la API REST
  /// Obtiene el participant_id que se usará para el WebSocket
  Future<void> _joinRoom() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Llamar a la API para unirse a la sala
      final result = await apiService.joinRoom(
        widget.roomId,
        widget.participantName,
      );
      
      // Guardar el ID del participante para el WebSocket
      _participantId = result['participant_id'];
      
      // Obtener estado completo de la sala y participantes
      await _refreshRoomStatus();
      
    } catch (error) {
      throw Exception('Error uniéndose a sala: $error');
    }
  }

  /// Refrescar estado de la sala y lista de participantes
  /// Se llama cuando hay cambios (alguien se une/sale)
  Future<void> _refreshRoomStatus() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final status = await apiService.getRoomStatus(widget.roomId);
      
      setState(() {
        // Convertir JSON de participantes a objetos Participant
        _participants = (status['participants'] as List?)
            ?.map((p) => Participant.fromJson(p))
            .toList() ?? [];
      });
      
    } catch (error) {
      print('Error refrescando estado de sala: $error');
    }
  }

  /// Conectar WebSocket para comunicación en tiempo real
  /// Configura listeners antes de conectar
  Future<void> _connectWebSocket() async {
    try {
      final wsService = Provider.of<WebSocketService>(context, listen: false);
      
      // Configurar listeners ANTES de conectar
      _setupWebSocketListeners();
      
      // Conectar usando room_id y participant_id
      await wsService.connect(widget.roomId, _participantId);
      
      setState(() {
        _isConnected = true;
      });
      
    } catch (error) {
      throw Exception('Error conectando WebSocket: $error');
    }
  }

  /// Configurar listeners para eventos WebSocket
  /// Maneja mensajes de chat, participantes que se unen/salen, etc.
  void _setupWebSocketListeners() {
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    
    // Listener para cambios de estado de conexión WebSocket
    wsService.addListener(() {
      if (mounted) {
        setState(() {
          _isConnected = wsService.isConnected;
        });
      }
    });

    // Listener para mensajes de chat entrantes
    // Cuando alguien más envía un mensaje, lo recibimos aquí
    wsService.addMessageCallback('chat_message', (message) {
      print('Procesando mensaje de chat: $message');
      
      // Crear objeto ChatMessage a partir del JSON recibido
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: message['sender_id'] ?? '',
        senderName: message['sender_name'] ?? 'Participante',
        message: message['message'] ?? '',
        timestamp: DateTime.now(),
        isOwn: message['sender_id'] == _participantId, // Verificar si es nuestro mensaje
      );
      
      // Agregar mensaje a la lista y hacer scroll hacia abajo
      if (mounted) {
        setState(() {
          _messages.add(chatMessage);
        });
        _scrollToBottom();
      }
    });

    // Listener para cuando se une un participante
    wsService.addMessageCallback('participant_joined', (message) {
      print('Participante se unió: $message');
      _refreshRoomStatus(); // Actualizar lista de participantes
    });

    // Listener para cuando sale un participante  
    wsService.addMessageCallback('participant_left', (message) {
      print('Participante se fue: $message');
      _refreshRoomStatus(); // Actualizar lista de participantes
    });
  }

  /// Inicializar WebRTC con la configuración del WebSocket
  Future<void> _initializeWebRTC() async {
    try {
      if (_webrtcService != null) {
        final wsService = Provider.of<WebSocketService>(context, listen: false);
        
        // Conectar WebRTC service con WebSocket
        _webrtcService!.initialize(wsService);
        
        // Agregar listener para cambios de estado
        _webrtcService!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
        
        // Inicializar media local (cámara y micrófono)
        await _webrtcService!.initializeLocalMedia();
        
        print('WebRTC inicializado correctamente');
      }
    } catch (error) {
      print('Error inicializando WebRTC: $error');
      // No fallar la inicialización completa por WebRTC
    }
  }

  /// Desconectar WebSocket al salir de la pantalla
  void _disconnectWebSocket() {
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    wsService.disconnect();
  }

  /// Enviar mensaje de chat
  /// Envía via WebSocket y agrega localmente para mostrar inmediatamente
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || !_isConnected) {
      return;
    }

    final message = _messageController.text.trim();
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    
    // Enviar mensaje via WebSocket al servidor
    wsService.sendChatMessage(message);
    
    // Agregar a la lista local inmediatamente para feedback instantáneo
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _participantId,
      senderName: widget.participantName,
      message: message,
      timestamp: DateTime.now(),
      isOwn: true,
    );
    
    setState(() {
      _messages.add(chatMessage);
    });
    
    // Limpiar input y hacer scroll hacia abajo
    _messageController.clear();
    _scrollToBottom();
  }

  /// Hacer scroll automático hacia el último mensaje
  /// Usa addPostFrameCallback para asegurar que el scroll ocurre después del render
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Salir de la sala
  /// Notifica al servidor via API REST y navega de regreso al home
  void _leaveRoom() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.leaveRoom(widget.roomId, _participantId);
    } catch (error) {
      print('Error saliendo de sala: $error');
    } finally {
      context.go('/home');
    }
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
          child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
        ),
      ),
    );
  }

  /// Pantalla de carga mientras se inicializa la sala
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Conectando a la sala...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido principal de la pantalla
  /// Muestra header, video grid y chat
  Widget _buildMainContent() {
    if (_error.isNotEmpty) {
      return _buildErrorScreen();
    }
    
    return Column(
      children: [
        // Header con información de la sala y botones
        _buildRoomHeader(),
        
        // Contenido principal
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Grid de cámaras con WebRTC
                _buildVideoGrid(),
                
                SizedBox(height: 16),
                
                // Sección de chat en tiempo real
                Expanded(
                  child: _buildChatSection(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Pantalla de error con opciones para reintentar o volver
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'Error de Conexión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _initializeRoom(),
                  child: Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text('Volver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Header de la sala con información y botones de control
  Widget _buildRoomHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Información de la sala (título, estado, participantes)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sala: ${widget.roomId}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    // Indicador visual de conexión WebSocket
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isConnected ? 'Conectado' : 'Desconectado',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '${_participants.length} participante(s)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botones de control (participantes, opciones, salir)
          Row(
            children: [
              // Botón para mostrar lista de participantes
              GestureDetector(
                onTap: () => setState(() => _showParticipants = !_showParticipants),
                child: Image.asset(
                  'assets/images/elements/conversacion grupal/boton participantes.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(width: 8),
              
              // Botón para mostrar opciones de la sala
              GestureDetector(
                onTap: () => setState(() => _showOptions = !_showOptions),
                child: Image.asset(
                  'assets/images/elements/conversacion grupal/boton opciones de sala.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(width: 8),
              
              // Botón para salir de la sala
              GestureDetector(
                onTap: _leaveRoom,
                child: Image.asset(
                  'assets/images/elements/conversacion grupal/boton salir de la sala.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Grid de video con WebRTC
  /// Muestra video local y remoto cuando hay videollamadas activas
  Widget _buildVideoGrid() {
    // Si hay videollamada activa, mostrar videos
    if (_webrtcService?.isConnected == true) {
      return Container(
        height: 200,
        child: Row(
          children: [
            // Video local (nuestro)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _webrtcService?.localStream != null
                      ? RTCVideoView(_webrtcService!.localStream!)
                      : Center(
                          child: Text(
                            'Cámara local',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ),
              ),
            ),
            // Video remoto (del otro participante)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _webrtcService?.remoteStream != null
                      ? RTCVideoView(_webrtcService!.remoteStream!)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, color: Colors.white54, size: 40),
                              Text(
                                'Esperando video...',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Estado sin videollamada - mostrar botones para iniciar
    return Container(
      height: 200,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/elements/conversacion grupal/layer card camara.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 50,
              color: Colors.white54,
            ),
            SizedBox(height: 8),
            Text(
              'Video llamada disponible',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            // Botón para iniciar llamada
            ElevatedButton.icon(
              onPressed: _participants.isNotEmpty ? () => _showCallDialog() : null,
              icon: Icon(Icons.video_call, size: 20),
              label: Text('Iniciar Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar dialog para seleccionar participante para videollamada
  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Iniciar Videollamada',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona un participante:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            ..._participants
                .where((p) => p.sessionId != _participantId)
                .map((participant) => ListTile(
                      leading: Icon(Icons.person, color: Colors.white),
                      title: Text(
                        participant.name,
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _startVideoCall(participant.sessionId);
                      },
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Iniciar videollamada con participante específico
  void _startVideoCall(String targetParticipantId) async {
    try {
      await _webrtcService?.startCall(targetParticipantId);
      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error iniciando videollamada: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Sección completa de chat en tiempo real
  /// Incluye header, lista de mensajes e input
  Widget _buildChatSection() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/elements/conversacion grupal/layer abrir chat.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Header del chat con título e indicador de estado
          Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Chat en Tiempo Real',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                // Indicador de desconexión si es necesario
                if (!_isConnected)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Desconectado',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de mensajes con scroll automático
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _messages.isEmpty ? _buildEmptyChat() : _buildMessagesList(),
            ),
          ),
          
          // Input para escribir mensajes
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Estado vacío del chat cuando no hay mensajes
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 50,
            color: Colors.white54,
          ),
          SizedBox(height: 12),
          Text(
            'No hay mensajes aún',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Sé el primero en escribir',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista scrolleable de mensajes de chat
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _chatScrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Burbuja individual de mensaje
  /// Diferentes estilos para mensajes propios vs. de otros
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          // Color diferente para mensajes propios vs. de otros
          color: message.isOwn 
              ? Colors.purple.withOpacity(0.7) 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar nombre del remitente solo para mensajes de otros
            if (!message.isOwn) ...[
              Text(
                message.senderName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
            ],
            // Contenido del mensaje
            Text(
              message.message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            // Timestamp del mensaje
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Input de mensaje con diseño Material personalizado
  /// Incluye botón de micrófono y envío
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          // Campo de texto expandible
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _isConnected ? Colors.purple.withOpacity(0.5) : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: _isConnected,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _isConnected ? 'Escribe un mensaje...' : 'Conectando...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  // Botón de micrófono dentro del input
                  suffixIcon: _isConnected
                      ? IconButton(
                          icon: Icon(Icons.mic, color: Colors.white70),
                          onPressed: () {
                            // TODO: Implementar speech-to-text
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Micrófono próximamente...')),
                            );
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Botón de envío con diseño Material personalizado
          Container(
            decoration: BoxDecoration(
              gradient: _isConnected
                  ? LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                    )
                  : LinearGradient(
                      colors: [Colors.grey, Colors.grey.shade700],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? Colors.purple : Colors.grey).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isConnected ? _sendMessage : null,
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
              padding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Formatear tiempo para mostrar en mensajes (HH:MM)
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Clase modelo para mensajes de chat
/// Representa un mensaje individual en la conversación
class ChatMessage {
  final String id;         // ID único del mensaje
  final String senderId;   // ID del participante que envió el mensaje
  final String senderName; // Nombre del participante que envió el mensaje
  final String message;    // Contenido del mensaje
  final DateTime timestamp; // Cuándo se envió el mensaje
  final bool isOwn;        // Si es nuestro mensaje o de otro participante

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isOwn,
  });
}