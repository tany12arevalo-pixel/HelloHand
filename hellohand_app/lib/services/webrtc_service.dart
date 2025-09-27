// lib/services/webrtc_service.dart
// Servicio WebRTC para videollamadas P2P usando el signaling de Django
// Se conecta con el consumers.py para intercambio de ofertas/respuestas/ICE

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

class WebRTCService extends ChangeNotifier {
  // Configuración STUN para NAT traversal
  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // Estados de conexión
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isCaller = false;
  String? _connectedParticipantId;
  
  // WebSocket service para signaling
  WebSocketService? _wsService;
  
  // Renderers para mostrar video
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  
  // Estados públicos
  bool get isConnected => _peerConnection?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get connectedParticipant => _connectedParticipantId;

  /// Inicializar WebRTC con el WebSocket service
  void initialize(WebSocketService wsService) {
    _wsService = wsService;
    _setupWebSocketListeners();
  }

  /// Configurar listeners para eventos WebRTC del WebSocket
  void _setupWebSocketListeners() {
    if (_wsService == null) return;

    // Solicitud de llamada entrante
    _wsService!.addMessageCallback('webrtc_call_request', _handleCallRequest);
    
    // Respuesta a solicitud de llamada
    _wsService!.addMessageCallback('webrtc_call_response', _handleCallResponse);
    
    // Oferta WebRTC
    _wsService!.addMessageCallback('webrtc_offer', _handleOffer);
    
    // Respuesta WebRTC
    _wsService!.addMessageCallback('webrtc_answer', _handleAnswer);
    
    // Candidatos ICE
    _wsService!.addMessageCallback('webrtc_ice_candidate', _handleIceCandidate);
    
    // Llamada terminada
    _wsService!.addMessageCallback('webrtc_call_ended', _handleCallEnded);
  }

  /// Inicializar cámara y micrófono local
  Future<void> initializeLocalMedia() async {
    try {
      // Inicializar renderer local
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      // Inicializar renderer remoto
      _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer!.initialize();

      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': 'user', // Cámara frontal
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      // Asignar stream al renderer local
      _localRenderer!.srcObject = _localStream;
      
      notifyListeners();
      
      print('Media local inicializada: ${_localStream?.getTracks().length} tracks');
    } catch (error) {
      print('Error inicializando media local: $error');
      throw Exception('Error accediendo a cámara/micrófono: $error');
    }
  }

  /// Iniciar llamada a otro participante
  Future<void> startCall(String targetParticipantId) async {
    try {
      _isCaller = true;
      _connectedParticipantId = targetParticipantId;
      
      // Crear peer connection
      await _createPeerConnection();
      
      // Agregar stream local
      if (_localStream != null) {
        await _peerConnection!.addStream(_localStream!);
      }
      
      // Enviar solicitud de llamada
      _wsService?.sendMessage({
        'type': 'webrtc_call_request',
        'to_participant_id': targetParticipantId,
        'participant_id': _wsService?.getConnectionInfo()['participantId'],
      });
      
      print('Solicitud de llamada enviada a: $targetParticipantId');
    } catch (error) {
      print('Error iniciando llamada: $error');
      throw Exception('Error iniciando llamada: $error');
    }
  }

  /// Responder a solicitud de llamada entrante
  Future<void> answerCall(String fromParticipantId, bool accept) async {
    try {
      _connectedParticipantId = fromParticipantId;
      
      // Enviar respuesta
      _wsService?.sendMessage({
        'type': 'webrtc_call_response',
        'to_participant_id': fromParticipantId,
        'participant_id': _wsService?.getConnectionInfo()['participantId'],
        'accepted': accept,
      });
      
      if (accept) {
        _isCaller = false;
        await _createPeerConnection();
        
        // Agregar stream local
        if (_localStream != null) {
          await _peerConnection!.addStream(_localStream!);
        }
      }
      
      print('Respuesta a llamada enviada: ${accept ? "Aceptada" : "Rechazada"}');
    } catch (error) {
      print('Error respondiendo llamada: $error');
      throw Exception('Error respondiendo llamada: $error');
    }
  }

  /// Terminar llamada actual
  Future<void> endCall() async {
    try {
      // Notificar al otro participante
      if (_connectedParticipantId != null) {
        _wsService?.sendMessage({
          'type': 'webrtc_call_ended',
          'to_participant_id': _connectedParticipantId,
          'participant_id': _wsService?.getConnectionInfo()['participantId'],
        });
      }
      
      await _cleanupConnection();
      print('Llamada terminada');
    } catch (error) {
      print('Error terminando llamada: $error');
    }
  }

  /// Alternar cámara (encender/apagar)
  Future<void> toggleCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().isNotEmpty 
          ? _localStream!.getVideoTracks()[0] 
          : null;
      
      if (videoTrack != null) {
        videoTrack.enabled = !videoTrack.enabled;
        notifyListeners();
      }
    }
  }

  /// Alternar micrófono (mute/unmute)
  Future<void> toggleMicrophone() async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().isNotEmpty 
          ? _localStream!.getAudioTracks()[0] 
          : null;
      
      if (audioTrack != null) {
        audioTrack.enabled = !audioTrack.enabled;
        notifyListeners();
      }
    }
  }

  /// Cambiar cámara (frontal/trasera)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().isNotEmpty 
          ? _localStream!.getVideoTracks()[0] 
          : null;
      
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
        notifyListeners();
      }
    }
  }

  // MÉTODOS INTERNOS

  /// Crear peer connection
  Future<void> _createPeerConnection() async {
    try {
      _peerConnection = await createPeerConnection(_configuration);
      
      // Configurar callbacks
      _peerConnection!.onIceCandidate = _onIceCandidate;
      _peerConnection!.onAddStream = _onAddStream;
      _peerConnection!.onRemoveStream = _onRemoveStream;
      _peerConnection!.onConnectionState = _onConnectionStateChange;
      
      print('Peer connection creada');
    } catch (error) {
      throw Exception('Error creando peer connection: $error');
    }
  }

  /// Callback cuando se genera un candidato ICE
  void _onIceCandidate(RTCIceCandidate candidate) {
    if (_connectedParticipantId != null) {
      _wsService?.sendMessage({
        'type': 'webrtc_ice_candidate',
        'to_participant_id': _connectedParticipantId,
        'participant_id': _wsService?.getConnectionInfo()['participantId'],
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    }
  }

  /// Callback cuando se agrega stream remoto
  void _onAddStream(MediaStream stream) {
    _remoteStream = stream;
    
    // Asignar stream al renderer remoto
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = stream;
    }
    
    notifyListeners();
    print('Stream remoto agregado: ${stream.getTracks().length} tracks');
  }

  /// Callback cuando se remueve stream remoto
  void _onRemoveStream(MediaStream stream) {
    _remoteStream = null;
    
    // Limpiar renderer remoto
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null;
    }
    
    notifyListeners();
    print('Stream remoto removido');
  }

  /// Callback cambio de estado de conexión
  void _onConnectionStateChange(RTCPeerConnectionState state) {
    notifyListeners();
    print('Estado de conexión WebRTC: $state');
    
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _cleanupConnection();
    }
  }

  // HANDLERS DE EVENTOS WEBSOCKET

  /// Manejar solicitud de llamada entrante
  void _handleCallRequest(Map<String, dynamic> message) {
    final fromParticipantId = message['from_participant_id'];
    print('Solicitud de llamada de: $fromParticipantId');
    
    // Notificar a la UI que hay una llamada entrante
    notifyListeners();
    
    // La UI debe mostrar dialog y llamar answerCall()
  }

  /// Manejar respuesta a solicitud de llamada
  void _handleCallResponse(Map<String, dynamic> message) async {
    final accepted = message['accepted'] ?? false;
    final fromParticipantId = message['from_participant_id'];
    
    print('Respuesta de llamada: ${accepted ? "Aceptada" : "Rechazada"}');
    
    if (accepted && _isCaller) {
      // Crear oferta WebRTC
      try {
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        
        _wsService?.sendMessage({
          'type': 'webrtc_offer',
          'to_participant_id': fromParticipantId,
          'participant_id': _wsService?.getConnectionInfo()['participantId'],
          'offer': {
            'type': offer.type,
            'sdp': offer.sdp,
          },
        });
        
        print('Oferta WebRTC enviada');
      } catch (error) {
        print('Error creando oferta: $error');
      }
    } else if (!accepted) {
      await _cleanupConnection();
    }
    
    notifyListeners();
  }

  /// Manejar oferta WebRTC
  void _handleOffer(Map<String, dynamic> message) async {
    try {
      final offer = message['offer'];
      final fromParticipantId = message['from_participant_id'];
      
      final rtcOffer = RTCSessionDescription(offer['sdp'], offer['type']);
      await _peerConnection!.setRemoteDescription(rtcOffer);
      
      // Crear respuesta
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      
      _wsService?.sendMessage({
        'type': 'webrtc_answer',
        'to_participant_id': fromParticipantId,
        'participant_id': _wsService?.getConnectionInfo()['participantId'],
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      
      print('Respuesta WebRTC enviada');
    } catch (error) {
      print('Error manejando oferta: $error');
    }
  }

  /// Manejar respuesta WebRTC
  void _handleAnswer(Map<String, dynamic> message) async {
    try {
      final answer = message['answer'];
      final rtcAnswer = RTCSessionDescription(answer['sdp'], answer['type']);
      await _peerConnection!.setRemoteDescription(rtcAnswer);
      
      print('Respuesta WebRTC recibida y aplicada');
    } catch (error) {
      print('Error manejando respuesta: $error');
    }
  }

  /// Manejar candidato ICE
  void _handleIceCandidate(Map<String, dynamic> message) async {
    try {
      final candidate = message['candidate'];
      final rtcCandidate = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      
      await _peerConnection!.addCandidate(rtcCandidate);
      print('Candidato ICE agregado');
    } catch (error) {
      print('Error agregando candidato ICE: $error');
    }
  }

  /// Manejar fin de llamada
  void _handleCallEnded(Map<String, dynamic> message) {
    final fromParticipantId = message['from_participant_id'];
    print('Llamada terminada por: $fromParticipantId');
    
    _cleanupConnection();
    notifyListeners();
  }

  /// Limpiar conexión y recursos
  Future<void> _cleanupConnection() async {
    _remoteStream = null;
    _connectedParticipantId = null;
    _isCaller = false;
    
    // Limpiar renderer remoto
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null;
    }
    
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    
    notifyListeners();
  }

  /// Obtener información del estado actual
  Map<String, dynamic> getCallInfo() {
    return {
      'isConnected': isConnected,
      'connectedParticipant': _connectedParticipantId,
      'isCaller': _isCaller,
      'hasLocalStream': _localStream != null,
      'hasRemoteStream': _remoteStream != null,
      'connectionState': _peerConnection?.connectionState?.toString(),
    };
  }

  @override
  void dispose() {
    _cleanupConnection();
    
    // Limpiar renderers
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    
    // Limpiar media local
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    
    super.dispose();
  }
}