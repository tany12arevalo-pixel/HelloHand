// src/services/websocket.js - Servicio WebSocket para comunicación en tiempo real

class WebSocketService {
  constructor() {
    this.socket = null
    this.isConnected = false
    this.roomId = null
    this.participantId = null
    this.eventListeners = {}
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
  }

  /**
   * Conectar a una sala específica
   * @param {string} roomId - ID de la sala
   * @param {string} participantId - ID del participante
   * @returns {Promise}
   */
  connect(roomId, participantId) {
    return new Promise((resolve, reject) => {
      try {
        this.roomId = roomId
        this.participantId = participantId

        // URL del WebSocket
        const wsUrl = `wss://localhost:8021/ws/room/${roomId}/?participant_id=${participantId}`
        
        this.socket = new WebSocket(wsUrl)

        this.socket.onopen = () => {
          console.log(`Conectado a sala ${roomId}`)
          this.isConnected = true
          this.reconnectAttempts = 0
          resolve()
        }

        this.socket.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data)
            this._handleMessage(data)
          } catch (error) {
            console.error('Error parseando mensaje WebSocket:', error)
          }
        }

        this.socket.onclose = (event) => {
          console.log('WebSocket cerrado:', event.code, event.reason)
          this.isConnected = false
          this._handleDisconnection()
        }

        this.socket.onerror = (error) => {
          console.error('Error WebSocket:', error)
          reject(error)
        }

        // Timeout de conexión
        setTimeout(() => {
          if (!this.isConnected) {
            reject(new Error('Timeout conectando al WebSocket'))
          }
        }, 10000)

      } catch (error) {
        reject(error)
      }
    })
  }

  /**
   * Desconectar del WebSocket
   */
  disconnect() {
    if (this.socket) {
      this.socket.close()
      this.socket = null
    }
    this.isConnected = false
    this.roomId = null
    this.participantId = null
  }

  /**
   * Enviar mensaje por WebSocket
   * @param {Object} message - Mensaje a enviar
   */
  send(message) {
    if (this.isConnected && this.socket) {
      this.socket.send(JSON.stringify(message))
    } else {
      console.warn('WebSocket no conectado, no se puede enviar mensaje')
    }
  }

  /**
   * Registrar listener para eventos
   * @param {string} event - Nombre del evento
   * @param {Function} callback - Función callback
   */
  on(event, callback) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = []
    }
    this.eventListeners[event].push(callback)
  }

  /**
   * Remover listener
   * @param {string} event - Nombre del evento
   * @param {Function} callback - Función callback
   */
  off(event, callback) {
    if (this.eventListeners[event]) {
      this.eventListeners[event] = this.eventListeners[event].filter(cb => cb !== callback)
    }
  }

  /**
   * Emitir evento a los listeners
   * @param {string} event - Nombre del evento
   * @param {*} data - Datos del evento
   */
  _emit(event, data) {
    if (this.eventListeners[event]) {
      this.eventListeners[event].forEach(callback => {
        try {
          callback(data)
        } catch (error) {
          console.error(`Error en listener ${event}:`, error)
        }
      })
    }
  }

  /**
   * Manejar mensajes recibidos del WebSocket
   * @param {Object} data - Datos del mensaje
   */
  _handleMessage(data) {
    const { type } = data

    switch (type) {
      case 'participant_joined':
        this._emit('participant_joined', data)
        break

      case 'participant_left':
        this._emit('participant_left', data)
        break

      case 'chat_message':
        this._emit('chat_message', data)
        break

      case 'translation_result':
        this._emit('translation_result', data)
        break

      case 'webrtc_signal':
        this._emit('webrtc_signal', data)
        break

      case 'participant_status_update':
        this._emit('participant_status_update', data)
        break

      case 'error':
        this._emit('error', data)
        console.error('Error del servidor:', data.message)
        break

      default:
        console.log('Mensaje WebSocket no manejado:', data)
    }
  }

  /**
   * Manejar desconexión
   */
  _handleDisconnection() {
    this._emit('disconnected')

    // Intentar reconectar automáticamente
    if (this.reconnectAttempts < this.maxReconnectAttempts && this.roomId && this.participantId) {
      this.reconnectAttempts++
      console.log(`Intentando reconectar... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`)
      
      setTimeout(() => {
        this.connect(this.roomId, this.participantId).catch(error => {
          console.error('Error reconectando:', error)
        })
      }, 2000 * this.reconnectAttempts)
    }
  }

  // Métodos específicos para HelloHand

  /**
   * Enviar mensaje de chat
   * @param {string} message - Mensaje de texto
   */
  sendChatMessage(message) {
    this.send({
      type: 'chat_message',
      message: message,
      participant_id: this.participantId
    })
  }

  /**
   * Enviar landmarks para traducción
   * @param {Array} landmarks - Array de landmarks
   */
  sendTranslationRequest(landmarks) {
    this.send({
      type: 'translation_request',
      landmarks: landmarks,
      participant_id: this.participantId
    })
  }

  /**
   * Actualizar estado del participante
   * @param {Object} status - Estado del participante
   */
  updateParticipantStatus(status) {
    this.send({
      type: 'participant_status',
      participant_id: this.participantId,
      ...status
    })
  }
}

// Instancia global del servicio
export const wsService = new WebSocketService()
export default wsService