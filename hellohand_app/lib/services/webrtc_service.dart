// lib/services/webrtc_service.dart
// Servicio WebRTC para videollamadas grupales usando el signaling de Django
// Implementa broadcasting grupal en lugar de P2P

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

class WebRTCService extends ChangeNotifier {
  // Configuración WebRTC moderna
  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan', // Usar Unified Plan SDP
  };

  // Estados de conexión grupal
  Map<String, RTCPeerConnection> _peerConnections = {}; // participantId -> connection
  Map<String, RTCVideoRenderer> _remoteRenderers = {}; // participantId -> renderer
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  bool _isVideoCallActive = false;
  
  // WebSocket service para signaling
  WebSocketService? _wsService;
  String? _currentRoomId;
  String? _currentParticipantId;
  
  // Control de audio/video
  bool _isMuted = false;
  bool _isVideoOff = false;
  
  // Estados públicos
  bool get isVideoCallActive => _isVideoCallActive;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  Map<String, RTCVideoRenderer> get remoteRenderers => Map.from(_remoteRenderers);
  MediaStream? get localStream => _localStream;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;

  /// Inicializar WebRTC con el WebSocket service
  void initialize(WebSocketService wsService) {
    _wsService = wsService;
    // Obtener info de conexión del WebSocket
    final connectionInfo = wsService.getConnectionInfo();
    _currentRoomId = connectionInfo['roomId'];
    _currentParticipantId = connectionInfo['participantId'];
    
    print('WebRTC inicializado:');
    print('- Room ID: $_currentRoomId');
    print('- Participant ID: $_currentParticipantId');
    
    _setupWebSocketListeners();
  }

  /// Configurar listeners para eventos WebRTC del WebSocket
  void _setupWebSocketListeners() {
    if (_wsService == null) return;

    print('Configurando listeners WebRTC...');

    // Listener para nuevos participantes que inician video
    _wsService!.addMessageCallback('video_call_started', (message) {
      print('video_call_started recibido: $message');
      _handleParticipantStartedVideo(message);
    });
    
    // Listener para participantes que terminan video
    _wsService!.addMessageCallback('video_call_ended', (message) {
      print('video_call_ended recibido: $message');
      _handleParticipantEndedVideo(message);
    });
    
    // Listeners de signaling WebRTC
    _wsService!.addMessageCallback('webrtc_offer', (message) {
      print('webrtc_offer recibido: ${message.keys}');
      _handleOffer(message);
    });
    
    _wsService!.addMessageCallback('webrtc_answer', (message) {
      print('webrtc_answer recibido: ${message.keys}');
      _handleAnswer(message);
    });
    
    _wsService!.addMessageCallback('webrtc_ice_candidate', (message) {
      print('webrtc_ice_candidate recibido');
      _handleIceCandidate(message);
    });

    print('Listeners WebRTC configurados');
  }

  /// Inicializar media local (cámara y micrófono)
  Future<void> initializeLocalMedia() async {
    try {
      print('Inicializando media local...');
      
      // Crear renderer local
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      // Configuración específica para diferentes plataformas
      final Map<String, dynamic> constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640, 'min': 320, 'max': 1280},
          'height': {'ideal': 480, 'min': 240, 'max': 720},
          'frameRate': {'ideal': 30, 'min': 15, 'max': 30},
        }
      };

      // Obtener stream de cámara y micrófono
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      
      // Asignar stream al renderer
      _localRenderer!.srcObject = _localStream;
      
      // Verificar tracks
      final audioTracks = _localStream!.getAudioTracks();
      final videoTracks = _localStream!.getVideoTracks();
      
      print('Media local inicializada:');
      print('- Audio tracks: ${audioTracks.length}');
      print('- Video tracks: ${videoTracks.length}');
      print('- Stream ID: ${_localStream!.id}');
      
      notifyListeners();
      
    } catch (error) {
      print('Error inicializando media local: $error');
      throw Exception('Error accediendo a cámara/micrófono: $error');
    }
  }

  /// Iniciar videollamada grupal (broadcasting)
  Future<void> startGroupVideoCall() async {
    try {
      if (_localStream == null) {
        throw Exception('No hay stream local disponible');
      }
      
      print('=== INICIANDO VIDEOLLAMADA GRUPAL ===');
      print('Room ID: $_currentRoomId');
      print('Participant ID: $_currentParticipantId');
      print('WebSocket conectado: ${_wsService?.isConnected}');
      print('Stream local tracks: ${_localStream!.getTracks().length}');
      
      _isVideoCallActive = true;
      notifyListeners();
      
      // Notificar a otros participantes que iniciamos video
      final message = {
        'type': 'video_call_started',
        'room_id': _currentRoomId,
        'participant_id': _currentParticipantId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('Enviando mensaje: $message');
      _wsService?.sendMessage(message);
      
      print('Videollamada grupal iniciada exitosamente');
      
    } catch (error) {
      print('Error iniciando videollamada grupal: $error');
      _isVideoCallActive = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Terminar videollamada grupal
  Future<void> endGroupVideoCall() async {
    try {
      print('=== TERMINANDO VIDEOLLAMADA GRUPAL ===');
      
      _isVideoCallActive = false;
      
      // Cerrar todas las conexiones peer
      final participantIds = _peerConnections.keys.toList();
      for (String participantId in participantIds) {
        await _closePeerConnection(participantId);
      }
      
      // Notificar a otros participantes
      final message = {
        'type': 'video_call_ended',
        'room_id': _currentRoomId,
        'participant_id': _currentParticipantId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('Enviando mensaje: $message');
      _wsService?.sendMessage(message);
      
      notifyListeners();
      print('Videollamada grupal terminada');
      
    } catch (error) {
      print('Error terminando videollamada: $error');
    }
  }

  /// Manejar cuando otro participante inicia video
  void _handleParticipantStartedVideo(Map<String, dynamic> message) async {
    try {
      final fromParticipantId = message['participant_id'];
      
      if (fromParticipantId == _currentParticipantId) {
        print('Ignorando nuestro propio mensaje video_call_started');
        return;
      }
      
      print('=== PARTICIPANTE INICIÓ VIDEO ===');
      print('From: $fromParticipantId');
      print('Nosotros tenemos video activo: $_isVideoCallActive');
      print('Tenemos stream local: ${_localStream != null}');
      
      // Si nosotros también tenemos video activo, crear conexión
      if (_isVideoCallActive && _localStream != null) {
        print('Creando conexión peer como caller...');
        await _createPeerConnection(fromParticipantId, true); // Somos el caller
      } else {
        print('No creamos conexión porque no tenemos video activo');
      }
      
    } catch (error) {
      print('Error manejando video_call_started: $error');
    }
  }

  /// Manejar cuando otro participante termina video
  void _handleParticipantEndedVideo(Map<String, dynamic> message) async {
    try {
      final fromParticipantId = message['participant_id'];
      
      if (fromParticipantId == _currentParticipantId) {
        print('Ignorando nuestro propio mensaje video_call_ended');
        return;
      }
      
      print('=== PARTICIPANTE TERMINÓ VIDEO ===');
      print('From: $fromParticipantId');
      
      await _closePeerConnection(fromParticipantId);
      
    } catch (error) {
      print('Error manejando video_call_ended: $error');
    }
  }

  /// Crear conexión peer con otro participante
  Future<void> _createPeerConnection(String participantId, bool isCaller) async {
    try {
      print('=== CREANDO PEER CONNECTION ===');
      print('Participante: $participantId');
      print('Es caller: $isCaller');
      
      // Verificar si ya existe conexión
      if (_peerConnections.containsKey(participantId)) {
        print('Ya existe conexión con $participantId, cerrando anterior');
        await _closePeerConnection(participantId);
      }
      
      final peerConnection = await createPeerConnection(_configuration);
      _peerConnections[participantId] = peerConnection;
      
      // Crear renderer para video remoto
      final remoteRenderer = RTCVideoRenderer();
      await remoteRenderer.initialize();
      _remoteRenderers[participantId] = remoteRenderer;
      
      print('Peer connection y renderer creados');
      
      // Configurar callbacks ANTES de agregar tracks
      peerConnection.onIceCandidate = (candidate) {
        print('ICE candidate generado para $participantId');
        _sendIceCandidate(participantId, candidate);
      };
      
      peerConnection.onTrack = (event) {
        print('=== TRACK RECIBIDO ===');
        print('De: $participantId');
        print('Streams: ${event.streams.length}');
        print('Track kind: ${event.track.kind}');
        print('Track enabled: ${event.track.enabled}');
        
        if (event.streams.isNotEmpty) {
          final stream = event.streams[0];
          print('Stream ID: ${stream.id}');
          print('Stream tracks: ${stream.getTracks().length}');
          
          remoteRenderer.srcObject = stream;
          notifyListeners();
          print('Stream remoto asignado al renderer');
        } else {
          print('ADVERTENCIA: Track recibido sin streams');
        }
      };
      
      peerConnection.onConnectionState = (state) {
        print('Estado conexión con $participantId: $state');
        
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          print('✅ Conexión establecida con $participantId');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                   state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          print('❌ Conexión falló con $participantId');
          _closePeerConnection(participantId);
        }
      };
      
      peerConnection.onIceConnectionState = (state) {
        print('ICE estado con $participantId: $state');
      };
      
      // CRÍTICO: Agregar tracks locales usando la API moderna
      if (_localStream != null) {
        print('Agregando tracks locales...');
        final tracks = _localStream!.getTracks();
        print('Tracks a agregar: ${tracks.length}');
        
        for (final track in tracks) {
          print('Agregando track: ${track.kind} (enabled: ${track.enabled})');
          final sender = await peerConnection.addTrack(track, _localStream!);
          print('Track agregado, sender: ${sender != null}');
        }
        
        print('Todos los tracks agregados');
      } else {
        print('ERROR: No hay stream local para agregar');
        return;
      }
      
      // Si somos el caller, crear oferta
      if (isCaller) {
        print('Creando oferta...');
        
        final offer = await peerConnection.createOffer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': true,
        });
        
        await peerConnection.setLocalDescription(offer);
        print('Local description establecida');
        print('Oferta SDP length: ${offer.sdp?.length}');
        
        _sendOffer(participantId, offer);
        print('Oferta enviada');
      }
      
      print('Peer connection creada exitosamente con $participantId');
      
    } catch (error) {
      print('ERROR creando peer connection con $participantId: $error');
      await _closePeerConnection(participantId);
      rethrow;
    }
  }

  /// Manejar oferta WebRTC
  void _handleOffer(Map<String, dynamic> message) async {
    try {
      final fromParticipantId = message['from_participant_id'];
      final offer = message['offer'];
      
      if (fromParticipantId == _currentParticipantId) {
        print('Ignorando nuestra propia oferta');
        return;
      }
      
      print('=== PROCESANDO OFERTA ===');
      print('De: $fromParticipantId');
      print('Oferta type: ${offer['type']}');
      print('SDP length: ${offer['sdp']?.length}');
      
      // Si no tenemos video activo, ignorar
      if (!_isVideoCallActive || _localStream == null) {
        print('Ignorando oferta porque no tenemos video activo');
        return;
      }
      
      // Si no tenemos conexión con este participante, crearla
      if (!_peerConnections.containsKey(fromParticipantId)) {
        print('Creando nueva peer connection para responder');
        await _createPeerConnection(fromParticipantId, false); // No somos caller
      }
      
      final peerConnection = _peerConnections[fromParticipantId];
      if (peerConnection != null) {
        final rtcOffer = RTCSessionDescription(offer['sdp'], offer['type']);
        await peerConnection.setRemoteDescription(rtcOffer);
        print('Remote description establecida');
        
        // Crear respuesta
        final answer = await peerConnection.createAnswer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': true,
        });
        
        await peerConnection.setLocalDescription(answer);
        print('Local description establecida para respuesta');
        
        _sendAnswer(fromParticipantId, answer);
        print('Respuesta enviada');
      } else {
        print('ERROR: No se pudo obtener peer connection');
      }
      
    } catch (error) {
      print('ERROR manejando oferta: $error');
    }
  }

  /// Manejar respuesta WebRTC
  void _handleAnswer(Map<String, dynamic> message) async {
    try {
      final fromParticipantId = message['from_participant_id'];
      final answer = message['answer'];
      
      if (fromParticipantId == _currentParticipantId) {
        print('Ignorando nuestra propia respuesta');
        return;
      }
      
      print('=== PROCESANDO RESPUESTA ===');
      print('De: $fromParticipantId');
      print('Answer type: ${answer['type']}');
      
      final peerConnection = _peerConnections[fromParticipantId];
      if (peerConnection != null) {
        final rtcAnswer = RTCSessionDescription(answer['sdp'], answer['type']);
        await peerConnection.setRemoteDescription(rtcAnswer);
        print('Remote description establecida desde respuesta');
      } else {
        print('ERROR: No se encontró peer connection para respuesta');
      }
      
    } catch (error) {
      print('ERROR manejando respuesta: $error');
    }
  }

  /// Manejar candidato ICE
  void _handleIceCandidate(Map<String, dynamic> message) async {
    try {
      final fromParticipantId = message['from_participant_id'];
      final candidate = message['candidate'];
      
      if (fromParticipantId == _currentParticipantId) {
        return; // Ignorar nuestros propios candidatos
      }
      
      print('ICE candidate recibido de $fromParticipantId');
      
      final peerConnection = _peerConnections[fromParticipantId];
      if (peerConnection != null) {
        final rtcCandidate = RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        );
        await peerConnection.addCandidate(rtcCandidate);
        print('ICE candidate agregado');
      } else {
        print('ADVERTENCIA: ICE candidate recibido sin peer connection');
      }
      
    } catch (error) {
      print('Error agregando candidato ICE: $error');
    }
  }

  /// Enviar oferta WebRTC
  void _sendOffer(String targetParticipantId, RTCSessionDescription offer) {
    final message = {
      'type': 'webrtc_offer',
      'to_participant_id': targetParticipantId,
      'participant_id': _currentParticipantId,
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    };
    
    print('Enviando oferta a $targetParticipantId');
    _wsService?.sendMessage(message);
  }

  /// Enviar respuesta WebRTC
  void _sendAnswer(String targetParticipantId, RTCSessionDescription answer) {
    final message = {
      'type': 'webrtc_answer',
      'to_participant_id': targetParticipantId,
      'participant_id': _currentParticipantId,
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    };
    
    print('Enviando respuesta a $targetParticipantId');
    _wsService?.sendMessage(message);
  }

  /// Enviar candidato ICE
  void _sendIceCandidate(String targetParticipantId, RTCIceCandidate candidate) {
    final message = {
      'type': 'webrtc_ice_candidate',
      'to_participant_id': targetParticipantId,
      'participant_id': _currentParticipantId,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    };
    
    _wsService?.sendMessage(message);
  }

  /// Cerrar conexión con participante específico
  Future<void> _closePeerConnection(String participantId) async {
    try {
      print('Cerrando conexión con $participantId');
      
      // Cerrar peer connection
      final peerConnection = _peerConnections[participantId];
      if (peerConnection != null) {
        await peerConnection.close();
        _peerConnections.remove(participantId);
        print('Peer connection cerrada');
      }
      
      // Limpiar renderer remoto
      final remoteRenderer = _remoteRenderers[participantId];
      if (remoteRenderer != null) {
        remoteRenderer.srcObject = null;
        await remoteRenderer.dispose();
        _remoteRenderers.remove(participantId);
        print('Renderer remoto limpiado');
      }
      
      notifyListeners();
      print('Conexión cerrada completamente con $participantId');
      
    } catch (error) {
      print('Error cerrando conexión con $participantId: $error');
    }
  }

  /// Controlar micrófono
  void toggleMicrophone() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        _isMuted = !_isMuted;
        audioTracks[0].enabled = !_isMuted;
        notifyListeners();
        print('Micrófono ${_isMuted ? "silenciado" : "activado"}');
      }
    }
  }

  /// Controlar cámara
  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        _isVideoOff = !_isVideoOff;
        videoTracks[0].enabled = !_isVideoOff;
        notifyListeners();
        print('Cámara ${_isVideoOff ? "desactivada" : "activada"}');
      }
    }
  }

  /// Cambiar entre cámara frontal y trasera
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        try {
          await Helper.switchCamera(videoTracks[0]);
          notifyListeners();
          print('Cámara cambiada');
        } catch (error) {
          print('Error cambiando cámara: $error');
        }
      }
    }
  }

  /// Obtener información del estado actual
  Map<String, dynamic> getCallInfo() {
    return {
      'isVideoCallActive': _isVideoCallActive,
      'connectedParticipants': _peerConnections.keys.toList(),
      'hasLocalStream': _localStream != null,
      'remoteRenderersCount': _remoteRenderers.length,
      'isMuted': _isMuted,
      'isVideoOff': _isVideoOff,
      'localStreamTracks': _localStream?.getTracks().length ?? 0,
    };
  }

  @override
  void dispose() {
    print('Disposing WebRTCService...');
    
    // Terminar videollamada si está activa
    if (_isVideoCallActive) {
      endGroupVideoCall();
    }
    
    // Limpiar renderer local
    _localRenderer?.srcObject = null;
    _localRenderer?.dispose();
    
    // Limpiar media local
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    
    super.dispose();
    print('WebRTCService disposed');
  }
}