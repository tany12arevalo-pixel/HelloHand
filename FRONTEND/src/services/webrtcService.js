// src/services/webrtcService.js - Servicio para videollamadas WebRTC

class WebRTCService {
  constructor() {
    this.localStream = null
    this.peerConnections = new Map() // participantId -> RTCPeerConnection
    this.remoteStreams = new Map()   // participantId -> MediaStream
    this.isCallActive = false
    this.isMuted = false
    this.isVideoOff = false
    
    // Callbacks
    this.callbacks = {
      onRemoteStream: null,      // (participantId, stream) => {}
      onRemoteStreamRemoved: null, // (participantId) => {}
      onConnectionStateChange: null, // (participantId, state) => {}
      onError: null,             // (error) => {}
      onCallStarted: null,       // () => {}
      onCallEnded: null          // () => {}
    }
    
    // Configuración ICE
    this.iceConfiguration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' }
      ]
    }
    
    // WebSocket para señalización
    this.wsService = null
    this.roomId = null
    this.participantId = null
  }

  /**
   * Inicializar WebRTC
   * @param {MediaStream} localStream - Stream local de audio/video
   * @param {Object} wsService - Servicio WebSocket para señalización
   * @param {string} roomId - ID de la sala
   * @param {string} participantId - ID del participante
   */
  async initialize(localStream, wsService, roomId, participantId) {
    try {
      this.localStream = localStream
      this.wsService = wsService
      this.roomId = roomId
      this.participantId = participantId
      
      // Configurar listeners de señalización
      this.setupSignalingListeners()
      
      console.log('WebRTCService inicializado correctamente')
      return true
      
    } catch (error) {
      console.error('Error inicializando WebRTC:', error)
      this.emitError(error)
      return false
    }
  }

  /**
   * Configurar listeners de señalización WebSocket
   */
  setupSignalingListeners() {
    if (!this.wsService) return

    // Solicitud de llamada entrante
    this.wsService.on('webrtc_call_request', (data) => {
      this.handleIncomingCall(data.from_participant_id)
    })

    // Respuesta a solicitud de llamada
    this.wsService.on('webrtc_call_response', (data) => {
      this.handleCallResponse(data.from_participant_id, data.accepted)
    })

    // Oferta WebRTC
    this.wsService.on('webrtc_offer', (data) => {
      this.handleOffer(data.from_participant_id, data.offer)
    })

    // Respuesta WebRTC
    this.wsService.on('webrtc_answer', (data) => {
      this.handleAnswer(data.from_participant_id, data.answer)
    })

    // Candidato ICE
    this.wsService.on('webrtc_ice_candidate', (data) => {
      this.handleIceCandidate(data.from_participant_id, data.candidate)
    })

    // Participante colgó
    this.wsService.on('webrtc_call_ended', (data) => {
      this.handleCallEnded(data.from_participant_id)
    })
  }

  /**
   * Iniciar llamada con otro participante
   * @param {string} targetParticipantId - ID del participante a llamar
   */
  async startCall(targetParticipantId) {
    try {
      if (!this.localStream) {
        throw new Error('No hay stream local disponible')
      }

      // Crear conexión peer
      const peerConnection = await this.createPeerConnection(targetParticipantId)
      
      // Añadir stream local
      this.localStream.getTracks().forEach(track => {
        peerConnection.addTrack(track, this.localStream)
      })

      // Crear oferta
      const offer = await peerConnection.createOffer({
        offerToReceiveAudio: true,
        offerToReceiveVideo: true
      })

      await peerConnection.setLocalDescription(offer)

      // Enviar solicitud de llamada
      this.sendSignalingMessage('webrtc_call_request', {
        to_participant_id: targetParticipantId
      })

      console.log(`Llamada iniciada hacia ${targetParticipantId}`)
      
    } catch (error) {
      console.error('Error iniciando llamada:', error)
      this.emitError(error)
    }
  }

  /**
   * Responder a llamada entrante
   * @param {string} fromParticipantId - ID del participante que llama
   * @param {boolean} accept - Aceptar o rechazar
   */
  async respondToCall(fromParticipantId, accept) {
    try {
      // Enviar respuesta
      this.sendSignalingMessage('webrtc_call_response', {
        to_participant_id: fromParticipantId,
        accepted: accept
      })

      if (accept) {
        // Si acepta, crear conexión peer
        await this.createPeerConnection(fromParticipantId)
        this.isCallActive = true
        
        if (this.callbacks.onCallStarted) {
          this.callbacks.onCallStarted()
        }
      }
      
    } catch (error) {
      console.error('Error respondiendo llamada:', error)
      this.emitError(error)
    }
  }

  /**
   * Crear conexión WebRTC peer-to-peer
   * @param {string} participantId - ID del participante
   */
  async createPeerConnection(participantId) {
    try {
      const peerConnection = new RTCPeerConnection(this.iceConfiguration)
      
      // Guardar conexión
      this.peerConnections.set(participantId, peerConnection)

      // Manejar stream remoto
      peerConnection.ontrack = (event) => {
        const [remoteStream] = event.streams
        this.remoteStreams.set(participantId, remoteStream)
        
        if (this.callbacks.onRemoteStream) {
          this.callbacks.onRemoteStream(participantId, remoteStream)
        }
        
        console.log(`Stream remoto recibido de ${participantId}`)
      }

      // Manejar candidatos ICE
      peerConnection.onicecandidate = (event) => {
        if (event.candidate) {
          this.sendSignalingMessage('webrtc_ice_candidate', {
            to_participant_id: participantId,
            candidate: event.candidate
          })
        }
      }

      // Manejar cambios de estado de conexión
      peerConnection.onconnectionstatechange = () => {
        const state = peerConnection.connectionState
        console.log(`Estado de conexión con ${participantId}: ${state}`)
        
        if (this.callbacks.onConnectionStateChange) {
          this.callbacks.onConnectionStateChange(participantId, state)
        }

        if (state === 'failed' || state === 'disconnected') {
          this.closePeerConnection(participantId)
        }
      }

      return peerConnection
      
    } catch (error) {
      console.error('Error creando peer connection:', error)
      throw error
    }
  }

  /**
   * Manejar llamada entrante
   * @param {string} fromParticipantId - ID del participante que llama
   */
  async handleIncomingCall(fromParticipantId) {
    // Aquí normalmente mostrarías un modal de llamada entrante
    // Por ahora auto-aceptamos
    console.log(`Llamada entrante de ${fromParticipantId}`)
    await this.respondToCall(fromParticipantId, true)
  }

  /**
   * Manejar respuesta a llamada
   * @param {string} fromParticipantId - ID del participante
   * @param {boolean} accepted - Si aceptó o no
   */
  async handleCallResponse(fromParticipantId, accepted) {
    if (accepted) {
      // Enviar oferta WebRTC
      const peerConnection = this.peerConnections.get(fromParticipantId)
      if (peerConnection && peerConnection.localDescription) {
        this.sendSignalingMessage('webrtc_offer', {
          to_participant_id: fromParticipantId,
          offer: peerConnection.localDescription
        })
        
        this.isCallActive = true
        if (this.callbacks.onCallStarted) {
          this.callbacks.onCallStarted()
        }
      }
    } else {
      console.log(`Llamada rechazada por ${fromParticipantId}`)
      this.closePeerConnection(fromParticipantId)
    }
  }

  /**
   * Manejar oferta WebRTC
   * @param {string} fromParticipantId - ID del participante
   * @param {RTCSessionDescription} offer - Oferta WebRTC
   */
  async handleOffer(fromParticipantId, offer) {
    try {
      let peerConnection = this.peerConnections.get(fromParticipantId)
      
      if (!peerConnection) {
        peerConnection = await this.createPeerConnection(fromParticipantId)
      }

      // Añadir stream local
      this.localStream.getTracks().forEach(track => {
        peerConnection.addTrack(track, this.localStream)
      })

      await peerConnection.setRemoteDescription(offer)

      // Crear respuesta
      const answer = await peerConnection.createAnswer()
      await peerConnection.setLocalDescription(answer)

      // Enviar respuesta
      this.sendSignalingMessage('webrtc_answer', {
        to_participant_id: fromParticipantId,
        answer: answer
      })
      
    } catch (error) {
      console.error('Error manejando oferta:', error)
      this.emitError(error)
    }
  }

  /**
   * Manejar respuesta WebRTC
   * @param {string} fromParticipantId - ID del participante
   * @param {RTCSessionDescription} answer - Respuesta WebRTC
   */
  async handleAnswer(fromParticipantId, answer) {
    try {
      const peerConnection = this.peerConnections.get(fromParticipantId)
      if (peerConnection) {
        await peerConnection.setRemoteDescription(answer)
        console.log(`Respuesta WebRTC procesada de ${fromParticipantId}`)
      }
    } catch (error) {
      console.error('Error manejando respuesta:', error)
      this.emitError(error)
    }
  }

  /**
   * Manejar candidato ICE
   * @param {string} fromParticipantId - ID del participante
   * @param {RTCIceCandidate} candidate - Candidato ICE
   */
  async handleIceCandidate(fromParticipantId, candidate) {
    try {
      const peerConnection = this.peerConnections.get(fromParticipantId)
      if (peerConnection) {
        await peerConnection.addIceCandidate(candidate)
      }
    } catch (error) {
      console.error('Error añadiendo candidato ICE:', error)
    }
  }

  /**
   * Manejar fin de llamada
   * @param {string} fromParticipantId - ID del participante
   */
  handleCallEnded(fromParticipantId) {
    this.closePeerConnection(fromParticipantId)
    console.log(`Llamada terminada con ${fromParticipantId}`)
  }

  /**
   * Terminar llamada
   * @param {string} participantId - ID específico o null para todas
   */
  endCall(participantId = null) {
    if (participantId) {
      // Terminar llamada específica
      this.sendSignalingMessage('webrtc_call_ended', {
        to_participant_id: participantId
      })
      this.closePeerConnection(participantId)
    } else {
      // Terminar todas las llamadas
      for (const [pid] of this.peerConnections) {
        this.sendSignalingMessage('webrtc_call_ended', {
          to_participant_id: pid
        })
      }
      this.closeAllConnections()
    }
  }

  /**
   * Cerrar conexión específica
   * @param {string} participantId - ID del participante
   */
  closePeerConnection(participantId) {
    const peerConnection = this.peerConnections.get(participantId)
    if (peerConnection) {
      peerConnection.close()
      this.peerConnections.delete(participantId)
    }

    if (this.remoteStreams.has(participantId)) {
      this.remoteStreams.delete(participantId)
      
      if (this.callbacks.onRemoteStreamRemoved) {
        this.callbacks.onRemoteStreamRemoved(participantId)
      }
    }

    // Si no quedan conexiones, la llamada terminó
    if (this.peerConnections.size === 0) {
      this.isCallActive = false
      if (this.callbacks.onCallEnded) {
        this.callbacks.onCallEnded()
      }
    }
  }

  /**
   * Cerrar todas las conexiones
   */
  closeAllConnections() {
    for (const [participantId] of this.peerConnections) {
      this.closePeerConnection(participantId)
    }
  }

  /**
   * Controlar audio
   * @param {boolean} muted - Silenciar o no
   */
  toggleMute(muted = !this.isMuted) {
    if (this.localStream) {
      const audioTracks = this.localStream.getAudioTracks()
      audioTracks.forEach(track => {
        track.enabled = !muted
      })
      this.isMuted = muted
    }
    return this.isMuted
  }

  /**
   * Controlar video
   * @param {boolean} videoOff - Apagar video o no
   */
  toggleVideo(videoOff = !this.isVideoOff) {
    if (this.localStream) {
      const videoTracks = this.localStream.getVideoTracks()
      videoTracks.forEach(track => {
        track.enabled = !videoOff
      })
      this.isVideoOff = videoOff
    }
    return this.isVideoOff
  }

  /**
   * Enviar mensaje de señalización
   * @param {string} type - Tipo de mensaje
   * @param {Object} data - Datos del mensaje
   */
  sendSignalingMessage(type, data) {
    console.log('=== ENVIANDO SEÑAL WebRTC ===')
    console.log('Tipo:', type)
    console.log('Datos:', data)
    console.log('wsService disponible:', !!this.wsService)
    
    if (this.wsService) {
      const message = {
        type: type,
        room_id: this.roomId,
        participant_id: this.participantId,
        ...data
      }
      console.log('Mensaje completo:', message)
      this.wsService.send(message)
    } else {
      console.error('wsService no disponible para enviar señal')
    }
  }

  /**
   * Configurar callbacks
   * @param {Object} callbacks - Objeto con callbacks
   */
  setCallbacks(callbacks) {
    this.callbacks = { ...this.callbacks, ...callbacks }
  }

  /**
   * Emitir error
   * @param {Error} error - Error ocurrido
   */
  emitError(error) {
    if (this.callbacks.onError) {
      this.callbacks.onError(error)
    }
  }

  /**
   * Obtener stream remoto
   * @param {string} participantId - ID del participante
   * @returns {MediaStream|null}
   */
  getRemoteStream(participantId) {
    return this.remoteStreams.get(participantId) || null
  }

  /**
   * Obtener lista de participantes conectados
   * @returns {Array<string>}
   */
  getConnectedParticipants() {
    return Array.from(this.peerConnections.keys())
  }

  /**
   * Obtener estado del servicio
   * @returns {Object}
   */
  getStatus() {
    return {
      isCallActive: this.isCallActive,
      isMuted: this.isMuted,
      isVideoOff: this.isVideoOff,
      connectedParticipants: this.getConnectedParticipants().length,
      hasLocalStream: !!this.localStream
    }
  }

  /**
   * Limpiar recursos
   */
  cleanup() {
    this.endCall()
    this.closeAllConnections()
    this.localStream = null
    this.wsService = null
    this.roomId = null
    this.participantId = null
    
    console.log('WebRTCService limpiado')
  }
}

// Instancia global
export const webrtcService = new WebRTCService()
export default webrtcService