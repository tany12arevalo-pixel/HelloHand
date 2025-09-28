// lib/screens/conversacion_rapida_screen.dart
// Pantalla principal de conversación rápida 1-a-1 con chat en tiempo real
// Implementa WebSocket para comunicación instantánea entre 2 participantes

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

/// Pantalla principal para la conversación rápida 1-a-1 de HelloHand
/// Optimizada para conversaciones íntimas entre solo 2 participantes
class ConversacionRapidaScreen extends StatefulWidget {
  final String roomId;           // ID de la sala rápida
  final String participantName;  // Nombre del participante actual
  final bool isCreator;         // Si es el creador de la sala

  const ConversacionRapidaScreen({
    Key? key,
    required this.roomId,
    required this.participantName,
    this.isCreator = false,
  }) : super(key: key);

  @override
  _ConversacionRapidaScreenState createState() => _ConversacionRapidaScreenState();
}

class _ConversacionRapidaScreenState extends State<ConversacionRapidaScreen> {
  // Estados principales de la pantalla
  bool _isLoading = true;      // Estado de carga inicial
  bool _isConnected = false;   // Estado de conexión WebSocket
  String _error = '';          // Mensaje de error si algo falla
  String _participantId = '';  // ID único del participante (UUID)
  
  // Datos de la sala y participantes (máximo 2)
  Room? _room;                          // Objeto de la sala actual
  List<Participant> _participants = []; // Lista de participantes (max 2)
  Participant? _otherParticipant;       // El otro participante en la conversación
  
  // Sistema de chat en tiempo real 1-a-1
  List<ChatMessage> _messages = [];                               // Lista de mensajes del chat
  final TextEditingController _messageController = TextEditingController(); // Controlador del input
  final ScrollController _chatScrollController = ScrollController();        // Controlador del scroll del chat
  
  // Estados específicos para conversación rápida
  bool _isWaitingForPartner = true;  // Esperando que se una el segundo participante
  String _connectionStatus = 'Conectando...'; // Estado visual de conexión

  // WebRTC para videollamadas P2P (1-a-1)
  WebRTCService? _webrtcService;

  @override
  void initState() {
    super.initState();
    print('=== INICIANDO ConversacionRapidaScreen ===');
    print('Room ID: ${widget.roomId}');
    print('Participant Name: ${widget.participantName}');
    print('Is Creator: ${widget.isCreator}');
    
    // Inicializar WebRTC service para P2P
    _webrtcService = WebRTCService();
    // Inicializar la sala al cargar la pantalla
    _initializeRoom();
  }

  @override
  void dispose() {
    print('=== DISPOSING ConversacionRapidaScreen ===');
    // Limpiar recursos al salir de la pantalla
    _messageController.dispose();
    _chatScrollController.dispose();
    _disconnectWebSocket();
    _webrtcService?.dispose();
    super.dispose();
  }

  /// Inicialización completa de la sala rápida
  /// Igual que grupal pero validando máximo 2 participantes
  Future<void> _initializeRoom() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
        _connectionStatus = 'Conectando...';
      });

      print('=== INICIALIZANDO SALA RÁPIDA ===');
      
      // Paso 1: Configurar IP del servidor desde SharedPreferences
      print('Paso 1: Configurando servidor...');
      await _setupServerConnection();
      
      // Paso 2: Unirse a la sala usando API REST
      print('Paso 2: Uniéndose a la sala rápida...');
      await _joinRoom();
      
      // Paso 3: Conectar WebSocket para comunicación en tiempo real
      print('Paso 3: Conectando WebSocket...');
      await _connectWebSocket();
      
      // Paso 4: Inicializar WebRTC para P2P
      print('Paso 4: Inicializando WebRTC P2P...');
      await _initializeWebRTC();
      
      setState(() {
        _isLoading = false;
        _connectionStatus = _participants.length == 2 ? 'Conectado con pareja' : 'Esperando pareja...';
      });
      
      print('=== SALA RÁPIDA INICIALIZADA EXITOSAMENTE ===');
      
    } catch (error) {
      print('ERROR inicializando sala rápida: $error');
      setState(() {
        _error = 'Error inicializando sala: $error';
        _isLoading = false;
        _connectionStatus = 'Error de conexión';
      });
    }
  }

  /// Configurar conexión al servidor Django (igual que grupal)
  Future<void> _setupServerConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final serverIp = prefs.getString('server_ip');
    
    print('Server IP desde SharedPreferences: $serverIp');
    
    if (serverIp == null || serverIp.isEmpty) {
      throw Exception('IP del servidor no configurada. Ve a Test para configurarla.');
    }
    
    // Configurar ApiService para llamadas REST
    final apiService = Provider.of<ApiService>(context, listen: false);
    apiService.updateBaseUrl(serverIp);
    print('ApiService configurado con IP: $serverIp');
    
    // Configurar WebSocketService para tiempo real
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    wsService.updateServerIp(serverIp);
    print('WebSocketService configurado con IP: $serverIp');
  }

  /// Unirse a la sala rápida usando la API REST
  /// Valida que es sala tipo 'quick' y no está llena
  /// SIEMPRE hace joinRoom (sin condición de participantId)
  Future<void> _joinRoom() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      print('Llamando joinRoom API para sala rápida...');
      
      // Primero verificar información de la sala
      final roomInfo = await apiService.getRoomInfo(widget.roomId);
      if (!roomInfo['success']) {
        throw Exception('Sala rápida no encontrada');
      }
      
      final roomData = roomInfo['room'];
      if (roomData['room_type'] != 'quick') {
        throw Exception('Esta no es una sala de conversación rápida');
      }
      
      if (roomData['participant_count'] >= 2) {
        throw Exception('La sala está llena (máximo 2 participantes)');
      }
      
      // Unirse a la sala usando el método original (posicional)
      final result = await apiService.joinRoom(widget.roomId, widget.participantName);
      
      print('Resultado joinRoom sala rápida: $result');
      
      // Guardar el ID del participante para el WebSocket
      _participantId = result['participant_id'];
      print('Participant ID asignado: $_participantId');
      
      // Obtener estado completo de la sala y participantes
      await _refreshRoomStatus();
      
    } catch (error) {
      print('ERROR en joinRoom sala rápida: $error');
      throw Exception('Error uniéndose a sala rápida: $error');
    }
  }

  /// Refrescar estado de la sala rápida
  /// Actualiza el estado de espera según participantes
  Future<void> _refreshRoomStatus() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final status = await apiService.getRoomStatus(widget.roomId);
      
      print('Estado de sala rápida actualizado: ${status['participants']?.length} participantes');
      
      final participantsList = (status['participants'] as List?)
          ?.map((p) => Participant.fromJson(p))
          .toList() ?? [];
      
      setState(() {
        _participants = participantsList;
        _isWaitingForPartner = _participants.length < 2;
        
        // Identificar al otro participante
        _otherParticipant = _participants
            .where((p) => p.id != _participantId)
            .isNotEmpty 
                ? _participants.firstWhere((p) => p.id != _participantId)
                : null;
        
        // Actualizar estado de conexión
        if (_participants.length == 2) {
          _connectionStatus = 'Conectado con ${_otherParticipant?.name ?? 'pareja'}';
        } else {
          _connectionStatus = 'Esperando pareja...';
        }
      });
      
      print('Participantes en sala rápida: ${_participants.map((p) => '${p.name}(${p.id})').toList()}');
      print('Otro participante: ${_otherParticipant?.name ?? 'ninguno'}');
      
    } catch (error) {
      print('Error refrescando estado de sala rápida: $error');
    }
  }

  /// Conectar WebSocket (igual que grupal)
  Future<void> _connectWebSocket() async {
    try {
      final wsService = Provider.of<WebSocketService>(context, listen: false);
      
      print('Configurando listeners WebSocket para sala rápida...');
      _setupWebSocketListeners();
      
      print('Conectando WebSocket con Room: ${widget.roomId}, Participant: $_participantId');
      await wsService.connect(widget.roomId, _participantId);
      
      setState(() {
        _isConnected = true;
      });
      
      print('WebSocket conectado exitosamente para sala rápida');
      
    } catch (error) {
      print('ERROR conectando WebSocket: $error');
      throw Exception('Error conectando WebSocket: $error');
    }
  }

  /// Configurar listeners para eventos WebSocket específicos de sala rápida
  void _setupWebSocketListeners() {
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    
    print('Configurando listeners WebSocket para conversación rápida...');
    
    // Listener para cambios de estado de conexión WebSocket
    wsService.addListener(() {
      if (mounted) {
        final newConnectionState = wsService.isConnected;
        print('Estado conexión WebSocket cambió: $newConnectionState');
        setState(() {
          _isConnected = newConnectionState;
        });
      }
    });

    // Listener para mensajes de chat 1-a-1
    wsService.addMessageCallback('chat_message', (message) {
      print('=== MENSAJE CHAT RÁPIDO RECIBIDO ===');
      print('Mensaje: $message');
      
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: message['sender_id'] ?? '',
        senderName: message['sender_name'] ?? 'Pareja',
        message: message['message'] ?? '',
        timestamp: DateTime.now(),
        isOwn: message['sender_id'] == _participantId,
      );
      
      if (mounted) {
        setState(() {
          _messages.add(chatMessage);
        });
        _scrollToBottom();
      }
    });

    // Listener para cuando se une el segundo participante
    wsService.addMessageCallback('participant_joined', (message) {
      print('=== PAREJA SE UNIÓ A SALA RÁPIDA ===');
      print('Mensaje: $message');
      _refreshRoomStatus();
      
      // Mostrar notificación de que se unió la pareja
      if (mounted && _participants.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Tu pareja se ha unido a la conversación!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // Listener para cuando sale la pareja
    wsService.addMessageCallback('participant_left', (message) {
      print('=== PAREJA SE FUE DE SALA RÁPIDA ===');
      print('Mensaje: $message');
      _refreshRoomStatus();
      
      // Mostrar notificación de que se fue la pareja
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tu pareja ha abandonado la conversación'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    print('Listeners WebSocket configurados para conversación rápida');
  }

  /// Inicializar WebRTC para P2P (optimizado para 2 participantes)
  Future<void> _initializeWebRTC() async {
    try {
      if (_webrtcService != null) {
        final wsService = Provider.of<WebSocketService>(context, listen: false);
        
        print('Inicializando WebRTC service P2P...');
        
        _webrtcService!.initialize(wsService);
        
        _webrtcService!.addListener(() {
          if (mounted) {
            print('WebRTC service P2P estado cambió, actualizando UI...');
            setState(() {});
          }
        });
        
        print('Inicializando media local para conversación rápida...');
        await _webrtcService!.initializeLocalMedia();
        
        print('WebRTC P2P inicializado correctamente');
        
      } else {
        print('ERROR: _webrtcService es null');
      }
    } catch (error) {
      print('Error inicializando WebRTC P2P: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inicializando cámara: $error'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Desconectar WebSocket (igual que grupal)
  void _disconnectWebSocket() {
    print('Desconectando WebSocket de sala rápida...');
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    wsService.disconnect();
  }

  /// Enviar mensaje de chat en conversación rápida
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || !_isConnected) {
      print('No se puede enviar mensaje: texto vacío o desconectado');
      return;
    }

    final message = _messageController.text.trim();
    final wsService = Provider.of<WebSocketService>(context, listen: false);
    
    print('=== ENVIANDO MENSAJE EN SALA RÁPIDA ===');
    print('Mensaje: $message');
    print('Para pareja: ${_otherParticipant?.name ?? 'esperando'}');
    
    wsService.sendChatMessage(message);
    
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
    
    _messageController.clear();
    _scrollToBottom();
  }

  /// Scroll automático (igual que grupal)
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

  /// Salir de la sala rápida
  void _leaveRoom() async {
    try {
      print('=== SALIENDO DE LA SALA RÁPIDA ===');
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.leaveRoom(widget.roomId, _participantId);
      print('API leaveRoom completada');
    } catch (error) {
      print('Error saliendo de sala rápida: $error');
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

  /// Pantalla de carga (igual que grupal)
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
            'Conectando a sala rápida...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Código: ${widget.roomId}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido principal optimizado para 2 participantes
  Widget _buildMainContent() {
    if (_error.isNotEmpty) {
      return _buildErrorScreen();
    }
    
    return Column(
      children: [
        // Header específico para conversación rápida
        _buildQuickRoomHeader(),
        
        // Contenido principal
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Grid de video P2P (máximo 2 participantes)
                _buildP2PVideoGrid(),
                
                SizedBox(height: 16),
                
                // Sección de chat 1-a-1
                Expanded(
                  child: _buildQuickChatSection(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Pantalla de error (igual que grupal)
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

  /// Header específico para conversación rápida
  Widget _buildQuickRoomHeader() {
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
          // Información específica de conversación rápida
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversación Rápida',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Código: ${widget.roomId}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    // Indicador visual de conexión
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
                      _connectionStatus,
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
          
          // Botones de control para conversación rápida
          Row(
            children: [
              // Mostrar info de la pareja si está conectada
              if (_otherParticipant != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        _otherParticipant!.name,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(width: 8),
              
              // Botón para salir de la sala
              GestureDetector(
                onTap: _leaveRoom,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Icon(
                    Icons.exit_to_app,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Grid de video P2P optimizado para 2 participantes
  Widget _buildP2PVideoGrid() {
    return Container(
      height: 250,
      child: Column(
        children: [
          // Controles de videollamada P2P
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón iniciar/terminar videollamada P2P
                ElevatedButton.icon(
                  onPressed: _webrtcService != null && _otherParticipant != null
                      ? (_webrtcService!.isVideoCallActive 
                          ? () async {
                              print('=== TERMINAR VIDEO P2P ===');
                              try {
                                await _webrtcService!.endGroupVideoCall();
                                setState(() {});
                              } catch (error) {
                                print('Error terminando video P2P: $error');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error terminando video: $error')),
                                );
                              }
                            }
                          : () async {
                              print('=== INICIAR VIDEO P2P ===');
                              try {
                                await _webrtcService!.startGroupVideoCall();
                                setState(() {});
                              } catch (error) {
                                print('Error iniciando video P2P: $error');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error iniciando video: $error')),
                                );
                              }
                            })
                      : null,
                  icon: Icon(
                    _webrtcService?.isVideoCallActive == true 
                        ? Icons.videocam_off 
                        : Icons.videocam,
                    size: 20,
                  ),
                  label: Text(
                    _webrtcService?.isVideoCallActive == true 
                        ? 'Terminar Video' 
                        : (_otherParticipant != null ? 'Iniciar Video P2P' : 'Esperando pareja'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _webrtcService?.isVideoCallActive == true 
                        ? Colors.red 
                        : (_otherParticipant != null ? Colors.green : Colors.grey),
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Controles adicionales si el video está activo
                if (_webrtcService?.isVideoCallActive == true) ...[
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      _webrtcService?.toggleMicrophone();
                      setState(() {});
                    },
                    icon: Icon(
                      _webrtcService?.isMuted == true ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _webrtcService?.isMuted == true ? Colors.red : Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _webrtcService?.switchCamera();
                      setState(() {});
                    },
                    icon: Icon(Icons.flip_camera_android, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Grid de videos P2P (máximo 2)
          Expanded(
            child: Row(
              children: [
                // Video local
                if (_webrtcService?.localRenderer != null)
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _webrtcService?.isVideoCallActive == true 
                              ? Colors.green 
                              : Colors.purple,
                          width: 2,
                        ),
                        color: Colors.black,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: RTCVideoView(_webrtcService!.localRenderer!),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.participantName} (Tú)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Video de la pareja o placeholder
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _otherParticipant != null ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      color: Colors.black,
                    ),
                    child: _otherParticipant != null
                        ? (_webrtcService?.remoteRenderers.containsKey(_otherParticipant!.id) == true
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: RTCVideoView(_webrtcService!.remoteRenderers[_otherParticipant!.id]!),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _otherParticipant!.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person, color: Colors.white54, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      _otherParticipant!.name,
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    Text(
                                      'Sin video',
                                      style: TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ))
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, color: Colors.white54, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  _isWaitingForPartner ? 'Esperando pareja...' : 'Pareja desconectada',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                Text(
                                  'Código: ${widget.roomId}',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de chat optimizada para conversación 1-a-1
  Widget _buildQuickChatSection() {
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
          // Header del chat específico para conversación rápida
          Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  _otherParticipant != null 
                      ? 'Chat con ${_otherParticipant!.name}'
                      : 'Chat Rápido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                // Indicador específico para conversación rápida
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _otherParticipant != null 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _otherParticipant != null ? '1 a 1' : 'Esperando',
                    style: TextStyle(
                      color: _otherParticipant != null ? Colors.green : Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de mensajes
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _messages.isEmpty ? _buildEmptyQuickChat() : _buildMessagesList(),
            ),
          ),
          
          // Input para mensajes en conversación rápida
          _buildQuickMessageInput(),
        ],
      ),
    );
  }

  /// Estado vacío del chat para conversación rápida
  Widget _buildEmptyQuickChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum,
            size: 50,
            color: Colors.white54,
          ),
          SizedBox(height: 12),
          Text(
            _otherParticipant != null 
                ? 'Inicia la conversación con ${_otherParticipant!.name}'
                : 'Esperando a tu pareja para chatear',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            _otherParticipant != null 
                ? 'Escribe el primer mensaje 💬'
                : 'Comparte el código: ${widget.roomId}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Lista de mensajes (igual que grupal)
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

  /// Burbuja de mensaje optimizada para conversación 1-a-1
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Más ancho para conversación 1-a-1
        ),
        decoration: BoxDecoration(
          color: message.isOwn 
              ? Colors.purple.withOpacity(0.7) 
              : Colors.blue.withOpacity(0.6), // Colores diferenciados para P2P
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En conversación rápida, no mostrar nombre (solo hay 2 personas)
            Text(
              message.message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            // Timestamp
            Align(
              alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Input de mensaje específico para conversación rápida
  Widget _buildQuickMessageInput() {
    final canSendMessage = _isConnected && _otherParticipant != null;
    
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          // Campo de texto
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: canSendMessage ? Colors.purple.withOpacity(0.5) : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: canSendMessage,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: canSendMessage 
                      ? 'Mensaje para ${_otherParticipant?.name ?? 'tu pareja'}...'
                      : 'Esperando pareja...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: canSendMessage
                      ? IconButton(
                          icon: Icon(Icons.mic, color: Colors.white70),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Micrófono próximamente...')),
                            );
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => canSendMessage ? _sendMessage() : null,
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Botón de envío
          Container(
            decoration: BoxDecoration(
              gradient: canSendMessage
                  ? LinearGradient(colors: [Colors.purple, Colors.deepPurple])
                  : LinearGradient(colors: [Colors.grey, Colors.grey.shade700]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (canSendMessage ? Colors.purple : Colors.grey).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: canSendMessage ? _sendMessage : null,
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

  /// Formatear tiempo (igual que grupal)
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Clase modelo para mensajes de chat (igual que grupal)
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isOwn,
  });
}