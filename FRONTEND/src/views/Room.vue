<template>
  <div class="min-vh-100 bg-light">
    <!-- Header de la Sala -->
    <header class="bg-primary text-white shadow-sm">
      <div class="container py-3">
        <div class="row align-items-center">
          <div class="col">
            <h2 class="h4 mb-1">Sala: {{ roomId }}</h2>
            <small class="text-light">
              {{ participants.length }} participante(s) conectado(s)
            </small>
          </div>
          <div class="col-auto">
            <button @click="leaveRoom" class="btn btn-outline-light btn-sm">
              Salir de la Sala
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Contenido Principal -->
    <div class="container-fluid py-4">
      <div class="row g-4">
        
        <!-- Panel de Video (Placeholder) -->
        <div class="col-lg-8">
          <div class="card shadow-sm">
            <div class="card-body">
              <div class="bg-dark text-white text-center py-5 rounded">
                <h5>Área de Video</h5>
                <p class="mb-0">Próximamente: WebRTC + Videollamadas</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Panel de Chat -->
        <div class="col-lg-4">
          <div class="card shadow-sm">
            <div class="card-header bg-white">
              <h6 class="mb-0">Chat en Tiempo Real</h6>
            </div>
            <div class="card-body p-0">
              
              <!-- Área de Mensajes -->
              <div class="chat-messages" ref="chatMessages">
                <div 
                  v-for="message in messages" 
                  :key="message.id"
                  class="message-item"
                  :class="{ 'own-message': message.sender_id === participantId }"
                >
                  <div class="message-content">
                    <div class="message-header">
                      <strong>{{ message.sender_name }}</strong>
                      <small class="text-muted ms-2">{{ formatTime(message.timestamp) }}</small>
                    </div>
                    <div class="message-text">{{ message.message }}</div>
                  </div>
                </div>
                
                <!-- Mensaje cuando no hay mensajes -->
                <div v-if="messages.length === 0" class="text-center text-muted p-4">
                  <p>No hay mensajes aún.</p>
                  <p>¡Sé el primero en escribir!</p>
                </div>
              </div>

              <!-- Área de Entrada de Mensaje con STT -->
              <div class="chat-input p-3 border-top">
                <!-- Input de texto normal -->
                <form @submit.prevent="sendMessage" class="d-flex gap-2 mb-2">
                  <input 
                    v-model="newMessage" 
                    type="text" 
                    class="form-control"
                    placeholder="Escribe un mensaje..."
                    :disabled="!isConnected"
                    maxlength="500"
                  >
                  <button 
                    type="submit" 
                    :disabled="!newMessage.trim() || !isConnected"
                    class="btn btn-primary"
                  >
                    Enviar
                  </button>
                </form>
                
                <!-- Nuevo: Controles de Speech-to-Text -->
                <div class="d-flex gap-2 align-items-center">
                  <button 
                    @mousedown="startSpeechRecognition"
                    @mouseup="stopSpeechRecognition"
                    @mouseleave="stopSpeechRecognition"
                    @touchstart="startSpeechRecognition"
                    @touchend="stopSpeechRecognition"
                    :disabled="!isConnected"
                    :class="['btn', 'btn-sm', isListening ? 'btn-danger' : 'btn-outline-primary']"
                    class="flex-shrink-0"
                  >
                    <span v-if="isListening">🔴 Grabando...</span>
                    <span v-else>🎤 Mantén presionado</span>
                  </button>
                  
                  <!-- Mostrar texto mientras habla -->
                  <small v-if="interimText" class="text-muted flex-grow-1 fst-italic">
                    "{{ interimText }}"
                  </small>
                  
                  <!-- Indicador de funcionalidad -->
                  <small v-if="!isListening && !interimText" class="text-muted flex-grow-1">
                    Habla para convertir voz a texto
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Panel de Traducción de Señas -->
      <div class="row mt-4">
        <div class="col-12">
          <div class="card shadow-sm">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
              <h6 class="mb-0">Traducción de Señas en Tiempo Real</h6>
              <div>
                <span v-if="isTranslating" class="badge bg-success me-2">Activo</span>
                <button 
                  @click="toggleSignTranslation" 
                  :class="['btn', 'btn-sm', isTranslating ? 'btn-danger' : 'btn-success']"
                >
                  {{ isTranslating ? 'Detener' : 'Iniciar' }} Traducción
                </button>
              </div>
            </div>
            <div class="card-body">
              <div class="row">
                <!-- Video de cámara -->
                <div class="col-md-6">
                  <div class="position-relative">
                    <video 
                      ref="videoElement" 
                      autoplay 
                      muted 
                      playsinline
                      class="w-100 rounded bg-dark"
                      style="max-height: 320px; object-fit: cover;"
                    ></video>
                    <canvas 
                      ref="canvasElement"
                      class="position-absolute top-0 start-0 w-100 rounded"
                      style="pointer-events: none; max-height: 320px;"
                    ></canvas>
                    
                    <!-- Overlay de estado -->
                    <div class="position-absolute top-0 end-0 m-2">
                      <span 
                        :class="['badge', isTranslating ? 'bg-success' : 'bg-secondary']"
                      >
                        {{ isTranslating ? 'Traduciendo...' : 'Detenido' }}
                      </span>
                    </div>
                  </div>
                  
                  <!-- Controles adicionales -->
                  <div class="mt-2 d-flex gap-2">
                    <button 
                      @click="clearTranslations" 
                      class="btn btn-outline-secondary btn-sm"
                      :disabled="recentTranslations.length === 0"
                    >
                      Limpiar Historial
                    </button>
                    <small class="text-muted align-self-center">
                      Señas disponibles: tonto, mal, bien
                    </small>
                  </div>
                </div>
                
                <!-- Resultados de traducción -->
                <div class="col-md-6">
                  <div class="bg-light p-3 rounded h-100">
                    <h6 class="mb-3">Últimas Traducciones:</h6>
                    <div class="translation-results" style="max-height: 280px; overflow-y: auto;">
                      <div 
                        v-for="translation in recentTranslations" 
                        :key="translation.id"
                        class="alert alert-info mb-2 py-2"
                      >
                        <div class="d-flex justify-content-between align-items-start">
                          <div>
                            <strong class="fs-5">{{ translation.prediction }}</strong>
                            <small class="d-block text-muted">
                              Confianza: {{ (translation.confidence * 100).toFixed(1) }}%
                            </small>
                          </div>
                          <small class="text-muted">
                            {{ formatTime(translation.timestamp) }}
                          </small>
                        </div>
                      </div>
                      
                      <div v-if="recentTranslations.length === 0" class="text-center text-muted">
                        <div class="py-4">
                          <p class="mb-2">No hay traducciones aún.</p>
                          <p class="mb-0">Haz una seña para empezar.</p>
                          <small class="text-muted">
                            Asegúrate de que tu cámara esté habilitada
                          </small>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Panel de Participantes -->
      <div class="row mt-4">
        <div class="col-12">
          <div class="card shadow-sm">
            <div class="card-header bg-white">
              <h6 class="mb-0">Participantes ({{ participants.length }})</h6>
            </div>
            <div class="card-body">
              <div class="row">
                <div 
                  v-for="participant in participants" 
                  :key="participant.id"
                  class="col-md-4 mb-3"
                >
                  <div class="participant-card p-3 border rounded">
                    <div class="d-flex align-items-center">
                      <div class="participant-avatar me-3">
                        <div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                          {{ participant.name.charAt(0).toUpperCase() }}
                        </div>
                      </div>
                      <div class="flex-grow-1">
                        <div class="fw-semibold">{{ participant.name }}</div>
                        <div class="small text-muted">
                          <span v-if="participant.has_camera" class="badge bg-success me-1">📹</span>
                          <span v-if="participant.has_microphone" class="badge bg-success me-1">🎤</span>
                          <span v-if="participant.is_deaf" class="badge bg-info me-1">👂</span>
                          <span v-if="participant.is_mute" class="badge bg-warning me-1">🤐</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de Error -->
    <div v-if="error" class="toast-container position-fixed bottom-0 end-0 p-3">
      <div class="toast show" role="alert">
        <div class="toast-header">
          <strong class="me-auto">Error</strong>
          <button @click="error = ''" class="btn-close"></button>
        </div>
        <div class="toast-body">
          {{ error }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { roomsAPI, translatorAPI } from '@/services/api'
import wsService from '@/services/websocket'
import mediaPipeService from '@/services/mediapipe'

export default {
  name: 'RoomView',
  data() {
    return {
      roomId: '',
      participantId: '',
      participantName: '',
      participants: [],
      messages: [],
      newMessage: '',
      isConnected: false,
      error: '',
      loading: true,
      
      // MediaPipe y traducción de señas
      isTranslating: false,
      recentTranslations: [],
      
      // Speech-to-Text
      isListening: false,
      interimText: ''
    }
  },
  async mounted() {
    this.roomId = this.$route.params.roomId
    this.participantName = this.$route.query.name || 'Participante'
    
    await this.joinRoom()
  },
  beforeUnmount() {
    this.cleanup()
  },
  methods: {
    async joinRoom() {
      try {
        // Unirse a la sala via API
        const result = await roomsAPI.joinRoom(this.roomId, {
          name: this.participantName,
          hasCamera: true,
          hasMicrophone: true,
          isDeaf: false,
          isMute: false
        })

        this.participantId = result.participant_id
        this.participants = result.participants || []

        // Conectar WebSocket
        await this.connectWebSocket()

      } catch (error) {
        this.error = error.message
        console.error('Error uniéndose a sala:', error)
      } finally {
        this.loading = false
      }
    },

    async connectWebSocket() {
      try {
        // Configurar listeners antes de conectar
        this.setupWebSocketListeners()
        
        // Conectar al WebSocket
        await wsService.connect(this.roomId, this.participantId)
        this.isConnected = true
        
        console.log('WebSocket conectado exitosamente')
        
      } catch (error) {
        this.error = 'Error conectando al chat en tiempo real'
        console.error('Error WebSocket:', error)
      }
    },

    setupWebSocketListeners() {
      // Mensaje de chat recibido
      wsService.on('chat_message', (data) => {
        this.addMessage({
          id: Date.now() + Math.random(),
          sender_id: data.sender_id,
          sender_name: data.sender_name,
          message: data.message,
          timestamp: data.timestamp
        })
      })

      // Participante se unió
      wsService.on('participant_joined', (data) => {
        console.log('Participante se unió:', data)
        this.refreshParticipants()
      })

      // Participante se fue
      wsService.on('participant_left', (data) => {
        console.log('Participante se fue:', data)
        this.refreshParticipants()
      })

      // Desconexión
      wsService.on('disconnected', () => {
        this.isConnected = false
        this.error = 'Conexión perdida. Intentando reconectar...'
      })

      // Error
      wsService.on('error', (data) => {
        this.error = data.message || 'Error en la comunicación'
      })
    },

    sendMessage() {
      if (!this.newMessage.trim() || !this.isConnected) {
        return
      }

      // Enviar mensaje via WebSocket
      wsService.sendChatMessage(this.newMessage.trim())
      
      // Limpiar input
      this.newMessage = ''
    },

    addMessage(message) {
      this.messages.push(message)
      
      // Scroll automático al último mensaje
      this.$nextTick(() => {
        const chatContainer = this.$refs.chatMessages
        if (chatContainer) {
          chatContainer.scrollTop = chatContainer.scrollHeight
        }
      })
    },

    async refreshParticipants() {
      try {
        const status = await roomsAPI.getRoomStatus(this.roomId)
        this.participants = status.participants || []
      } catch (error) {
        console.error('Error refrescando participantes:', error)
      }
    },

    // Métodos de Speech-to-Text
    async startSpeechRecognition() {
      if (this.isListening) return
      
      try {
        const { default: speechService } = await import('@/services/speechRecognition')
        
        speechService.setCallbacks({
          onResult: this.handleSpeechResult,
          onError: this.handleSpeechError,
          onStart: () => {
            this.isListening = true
            this.interimText = ''
          },
          onEnd: () => {
            this.isListening = false
            this.interimText = ''
          }
        })
        
        await speechService.startListening()
        
      } catch (error) {
        this.error = 'Error activando micrófono: ' + error.message
        console.error('Error STT:', error)
      }
    },

    stopSpeechRecognition() {
      if (!this.isListening) return
      
      import('@/services/speechRecognition').then(({ default: speechService }) => {
        speechService.stopListening()
      })
    },

    handleSpeechResult(result) {
      // Mostrar texto intermedio mientras habla
      if (result.interim) {
        this.interimText = result.interim
      }
      
      // Cuando termina de hablar, enviar al chat
      if (result.final && result.final.trim()) {
        // Agregar indicador de que fue por voz
        this.newMessage = `🎙️ ${result.final}`
        this.sendMessage()
        this.interimText = ''
      }
    },

    handleSpeechError(errorMessage) {
      this.error = 'Error de reconocimiento de voz: ' + errorMessage
      this.isListening = false
      this.interimText = ''
    },

    // Métodos de traducción de señas (sin cambios)
    async toggleSignTranslation() {
      if (this.isTranslating) {
        await this.stopSignTranslation()
      } else {
        await this.startSignTranslation()
      }
    },

    async startSignTranslation() {
      try {
        // Configurar callbacks de MediaPipe
        mediaPipeService.setCallbacks({
          onLandmarks: this.handleLandmarks,
          onError: this.handleMediaPipeError
        })

        // Inicializar MediaPipe
        const initialized = await mediaPipeService.initialize(
          this.$refs.videoElement,
          this.$refs.canvasElement
        )

        if (initialized) {
          await mediaPipeService.startCapture()
          this.isTranslating = true
          console.log('Traducción de señas iniciada')
        } else {
          throw new Error('No se pudo inicializar MediaPipe')
        }
      } catch (error) {
        this.error = 'Error iniciando traducción: ' + error.message
        console.error('Error:', error)
      }
    },

    async stopSignTranslation() {
      mediaPipeService.stopCapture()
      this.isTranslating = false
      console.log('Traducción de señas detenida')
    },

    async handleLandmarks(landmarkSequence) {
      try {
        // Enviar landmarks al backend para traducción
        const result = await translatorAPI.predictSigns(landmarkSequence, 0.3)
        
        if (result.success && result.prediction) {
          // Añadir a traducciones recientes
          const translation = {
            id: Date.now(),
            prediction: result.prediction,
            confidence: result.confidence,
            timestamp: new Date().toISOString()
          }
          
          this.recentTranslations.unshift(translation)
          
          // Mantener solo las últimas 10
          if (this.recentTranslations.length > 10) {
            this.recentTranslations = this.recentTranslations.slice(0, 10)
          }
          
          // Enviar al chat automáticamente
          this.sendTranslationToChat(translation)
          
          console.log('Traducción:', result.prediction, 'Confianza:', result.confidence)
        }
      } catch (error) {
        console.error('Error en traducción:', error)
      }
    },

    sendTranslationToChat(translation) {
      const message = `🤟 ${translation.prediction} (${(translation.confidence * 100).toFixed(1)}%)`
      
      // Enviar al chat via WebSocket
      wsService.sendChatMessage(message)
    },

    handleMediaPipeError(error) {
      this.error = 'Error en MediaPipe: ' + error.message
      this.isTranslating = false
    },

    clearTranslations() {
      this.recentTranslations = []
    },

    formatTime(timestamp) {
      try {
        const date = new Date(timestamp)
        return date.toLocaleTimeString('es-ES', { 
          hour: '2-digit', 
          minute: '2-digit' 
        })
      } catch (error) {
        return ''
      }
    },

    async leaveRoom() {
      try {
        // Salir via API
        await roomsAPI.leaveRoom(this.roomId, this.participantId)
        
        // Limpiar recursos
        this.cleanup()
        
        // Volver al home
        this.$router.push('/')
        
      } catch (error) {
        console.error('Error saliendo de sala:', error)
        // Volver al home de todas formas
        this.$router.push('/')
      }
    },

    cleanup() {
      // Detener reconocimiento de voz
      if (this.isListening) {
        this.stopSpeechRecognition()
      }

      // Detener traducción
      if (this.isTranslating) {
        this.stopSignTranslation()
      }

      // Limpiar MediaPipe
      mediaPipeService.cleanup()

      // Desconectar WebSocket
      if (wsService) {
        wsService.disconnect()
      }
      
      this.isConnected = false
    }
  }
}
</script>

<style scoped>
.chat-messages {
  height: 400px;
  overflow-y: auto;
  padding: 1rem;
  background-color: #f8f9fa;
}

.message-item {
  margin-bottom: 1rem;
}

.message-content {
  background: white;
  padding: 0.75rem;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.own-message .message-content {
  background: #007bff;
  color: white;
  margin-left: 2rem;
}

.own-message .message-header strong {
  color: rgba(255,255,255,0.9);
}

.message-header {
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
}

.message-text {
  margin: 0;
  word-wrap: break-word;
}

.participant-card {
  transition: box-shadow 0.2s;
}

.participant-card:hover {
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.chat-input {
  background: white;
}

.participant-avatar {
  flex-shrink: 0;
}

.translation-results {
  max-height: 280px;
}

.translation-results::-webkit-scrollbar {
  width: 4px;
}

.translation-results::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.translation-results::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

.translation-results::-webkit-scrollbar-thumb:hover {
  background: #555;
}

canvas {
  max-height: 320px;
}

video {
  background-color: #000;
}

/* Estilos para el botón STT */
.btn:active {
  transform: scale(0.95);
}

.fst-italic {
  font-style: italic;
}
</style>