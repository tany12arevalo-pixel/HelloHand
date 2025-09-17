<!-- src/views/Room.vue -->
<template>
  <div class="hello-hand-room">
    <!-- Header de la Sala -->
    <header class="room-header">
      <div class="container">
        <div class="header-content">
          <div class="room-info">
            <h1 class="room-title">👋 Sala: {{ roomId }}</h1>
            <div class="room-stats">
              <div class="stat-item">
                <div class="stat-icon">👥</div>
                <span>{{ participants.length }} participante(s)</span>
              </div>
              <div class="stat-item">
                <div class="connection-indicator" :class="{ active: isConnected }"></div>
                <span>{{ isConnected ? 'Conectado' : 'Desconectado' }}</span>
              </div>
            </div>
          </div>
          <button @click="leaveRoom" class="leave-btn">
            <span>🚪</span>
            Salir
          </button>
        </div>
      </div>
    </header>

    <!-- Contenido Principal -->
    <main class="room-content">
      <div class="container">
        <div class="room-grid">
          
          <!-- Panel de Videollamada -->
          <section class="video-section">
            <div class="section-card video-card">
              <div class="card-header">
                <div class="header-left">
                  <div class="section-icon">📹</div>
                  <h2>Videollamada</h2>
                </div>
                <div class="header-right">
                  <div class="call-status" :class="{ active: isCallActive }">
                    <div class="status-dot"></div>
                    <span>{{ isCallActive ? 'En llamada' : 'Sin llamada' }}</span>
                  </div>
                  
                  <!-- Controles de videollamada -->
                  <button 
                    v-if="!isCallActive && otherParticipants.length > 0"
                    @click="startVideoCall"
                    class="call-btn start-call"
                    :disabled="!hasLocalStream"
                  >
                    📞 Iniciar
                  </button>
                  
                  <button 
                    v-if="isCallActive"
                    @click="endVideoCall"
                    class="call-btn end-call"
                  >
                    📞 Colgar
                  </button>
                </div>
              </div>
              
              <div class="video-container-wrapper">
                <!-- Grid de videos -->
                <div class="video-grid">
                  <!-- Video local (propio) -->
                  <div class="video-item local-video">
                    <video 
                      ref="localVideoElement"
                      autoplay 
                      muted 
                      playsinline
                      class="video-element"
                    ></video>
                    <div class="video-overlay">
                      <span class="video-label">{{ participantName }} (Tú)</span>
                    </div>
                    
                    <!-- Controles de audio/video local -->
                    <div class="video-controls">
                      <button 
                        @click="toggleMute"
                        :class="['control-btn', { muted: isMuted }]"
                        :title="isMuted ? 'Activar micrófono' : 'Silenciar micrófono'"
                      >
                        {{ isMuted ? '🔇' : '🎤' }}
                      </button>
                      <button 
                        @click="toggleVideo"
                        :class="['control-btn', { disabled: isVideoOff }]"
                        :title="isVideoOff ? 'Activar cámara' : 'Desactivar cámara'"
                      >
                        {{ isVideoOff ? '📷' : '📹' }}
                      </button>
                    </div>
                  </div>
                  
                  <!-- Videos remotos -->
                  <div 
                    v-for="(remoteParticipant, participantId) in remoteParticipants" 
                    :key="participantId"
                    class="video-item remote-video"
                  >
                    <video 
                      :ref="`remoteVideo_${participantId}`"
                      autoplay 
                      playsinline
                      class="video-element"
                    ></video>
                    <div class="video-overlay">
                      <span class="video-label">{{ remoteParticipant.name }}</span>
                    </div>
                  </div>
                  
                  <!-- Placeholder cuando no hay videos remotos -->
                  <div v-if="Object.keys(remoteParticipants).length === 0" class="video-placeholder">
                    <div class="placeholder-content">
                      <div class="placeholder-icon">👋</div>
                      <h3>Esperando participantes...</h3>
                      <p v-if="!hasLocalStream">
                        Permitir acceso a cámara y micrófono
                      </p>
                      <p v-else-if="otherParticipants.length === 0">
                        No hay otros participantes en la sala
                      </p>
                      <p v-else>
                        Haz clic en "Iniciar" para conectar
                      </p>
                    </div>
                  </div>
                </div>
                
                <!-- Estado de conexión WebRTC -->
                <div v-if="connectionStates.length > 0" class="connection-states">
                  <span 
                    v-for="state in connectionStates" 
                    :key="state.participantId"
                    :class="['connection-badge', getConnectionClass(state.state)]"
                  >
                    {{ state.participantName }}: {{ state.state }}
                  </span>
                </div>
              </div>
            </div>
          </section>

          <!-- Panel de Chat -->
          <section class="chat-section">
            <div class="section-card chat-card">
              <div class="card-header">
                <div class="section-icon">💬</div>
                <h2>Chat en Tiempo Real</h2>
              </div>
              
              <div class="chat-container">
                <!-- Área de Mensajes -->
                <div class="messages-area" ref="chatMessages">
                  <div 
                    v-for="message in messages" 
                    :key="message.id"
                    :class="['message-bubble', { 'own-message': message.sender_id === participantId }]"
                  >
                    <div class="message-header">
                      <strong class="sender-name">{{ message.sender_name }}</strong>
                      <span class="message-time">{{ formatTime(message.timestamp) }}</span>
                    </div>
                    <div class="message-text">{{ message.message }}</div>
                  </div>
                  
                  <!-- Mensaje cuando no hay mensajes -->
                  <div v-if="messages.length === 0" class="empty-chat">
                    <div class="empty-icon">💭</div>
                    <p>No hay mensajes aún</p>
                    <small>¡Sé el primero en escribir!</small>
                  </div>
                </div>

                <!-- Área de Entrada de Mensaje -->
                <div class="chat-input-area">
                  <!-- Input de texto normal -->
                  <form @submit.prevent="sendMessage" class="message-form">
                    <input 
                      v-model="newMessage" 
                      type="text" 
                      class="message-input"
                      placeholder="Escribe un mensaje..."
                      :disabled="!isConnected"
                      maxlength="500"
                    >
                    <button 
                      type="submit" 
                      :disabled="!newMessage.trim() || !isConnected"
                      class="send-btn"
                    >
                      📤
                    </button>
                  </form>
                  
                  <!-- Controles de Speech-to-Text -->
                  <div class="stt-controls">
                    <button 
                      @mousedown="startSpeechRecognition"
                      @mouseup="stopSpeechRecognition"
                      @mouseleave="stopSpeechRecognition"
                      @touchstart="startSpeechRecognition"
                      @touchend="stopSpeechRecognition"
                      :disabled="!isConnected"
                      :class="['stt-btn', { recording: isListening }]"
                    >
                      <span class="stt-icon">{{ isListening ? '🔴' : '🎤' }}</span>
                      <span class="stt-text">
                        {{ isListening ? 'Grabando...' : 'Mantén presionado' }}
                      </span>
                    </button>
                    
                    <!-- Mostrar texto mientras habla -->
                    <div v-if="interimText" class="interim-text">
                      "{{ interimText }}"
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        <!-- Panel de Traducción de Señas -->
        <section class="translation-section">
          <div class="section-card translation-card">
            <div class="card-header">
              <div class="header-left">
                <div class="section-icon">🤟</div>
                <h2>Traducción de Señas en Tiempo Real</h2>
              </div>
              <div class="header-right">
                <div class="translation-status" :class="{ active: isTranslating }">
                  <div class="status-dot"></div>
                  <span>{{ isTranslating ? 'Activo' : 'Detenido' }}</span>
                </div>
                <button 
                  @click="toggleSignTranslation" 
                  :class="['toggle-btn', { active: isTranslating }]"
                  :disabled="!hasLocalStream"
                >
                  {{ isTranslating ? 'Detener' : 'Iniciar' }}
                </button>
              </div>
            </div>
            
            <div class="translation-content">
              <div class="translation-grid">
                <!-- Video de cámara para señas -->
                <div class="camera-section">
                  <div class="camera-container">
                    <video 
                      ref="videoElement" 
                      autoplay 
                      muted 
                      playsinline
                      class="translation-video"
                    ></video>
                    <canvas 
                      ref="canvasElement"
                      class="translation-canvas"
                    ></canvas>
                    
                    <!-- Overlay de estado -->
                    <div class="video-status-overlay">
                      <span :class="['status-badge', { active: isTranslating }]">
                        {{ isTranslating ? 'Traduciendo...' : 'Detenido' }}
                      </span>
                    </div>
                  </div>
                  
                  <!-- Controles adicionales -->
                  <div class="camera-controls">
                    <button 
                      @click="clearTranslations" 
                      class="clear-btn"
                      :disabled="recentTranslations.length === 0"
                    >
                      🗑️ Limpiar
                    </button>
                    <div class="available-signs">
                      <span class="signs-label">Disponibles:</span>
                      <span class="sign-tag">tonto</span>
                      <span class="sign-tag">mal</span>
                      <span class="sign-tag">bien</span>
                    </div>
                  </div>
                </div>
                
                <!-- Resultados de traducción -->
                <div class="results-section">
                  <h3 class="results-title">Últimas Traducciones:</h3>
                  <div class="results-container">
                    <div 
                      v-for="translation in recentTranslations" 
                      :key="translation.id"
                      class="translation-result"
                    >
                      <div class="result-content">
                        <div class="result-text">{{ translation.prediction }}</div>
                        <div class="result-confidence">
                          {{ (translation.confidence * 100).toFixed(1) }}%
                        </div>
                      </div>
                      <div class="result-time">
                        {{ formatTime(translation.timestamp) }}
                      </div>
                    </div>
                    
                    <div v-if="recentTranslations.length === 0" class="empty-results">
                      <div class="empty-icon">🤟</div>
                      <p>No hay traducciones aún</p>
                      <small>Haz una seña para empezar</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- Panel de Participantes -->
        <section class="participants-section">
          <div class="section-card participants-card">
            <div class="card-header">
              <div class="section-icon">👥</div>
              <h2>Participantes ({{ participants.length }})</h2>
            </div>
            
            <div class="participants-grid">
              <div 
                v-for="participant in participants" 
                :key="participant.id"
                class="participant-item"
              >
                <div class="participant-avatar">
                  <span class="avatar-text">{{ participant.name.charAt(0).toUpperCase() }}</span>
                </div>
                <div class="participant-info">
                  <div class="participant-name">{{ participant.name }}</div>
                  <div class="participant-badges">
                    <span v-if="participant.has_camera" class="badge camera">📹</span>
                    <span v-if="participant.has_microphone" class="badge microphone">🎤</span>
                    <span v-if="participant.is_deaf" class="badge deaf">👂</span>
                    <span v-if="participant.is_mute" class="badge mute">🤐</span>
                  </div>
                </div>
                
                <!-- Botón para llamar individualmente -->
                <div v-if="participant.id !== participantId" class="participant-actions">
                  <button 
                    v-if="!isCallActive"
                    @click="callParticipant(participant.id)"
                    class="call-participant-btn"
                    :disabled="!hasLocalStream"
                  >
                    📞
                  </button>
                  <span v-else-if="remoteParticipants[participant.id]" class="in-call-badge">
                    En llamada
                  </span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>

    <!-- Modal de Error -->
    <div v-if="error" class="error-modal">
      <div class="error-content">
        <div class="error-icon">⚠️</div>
        <span class="error-text">{{ error }}</span>
        <button @click="error = ''" class="error-close">✕</button>
      </div>
    </div>
  </div>
</template>

<script>
import { roomsAPI, translatorAPI } from '@/services/api'
import wsService from '@/services/websocket'
import mediaPipeService from '@/services/mediapipe'
import webrtcService from '@/services/webrtcService'

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
      interimText: '',
      
      // WebRTC Videollamadas
      isCallActive: false,
      hasLocalStream: false,
      isMuted: false,
      isVideoOff: false,
      remoteParticipants: {}, // participantId -> { name, stream }
      connectionStates: [], // [{ participantId, participantName, state }]
      localStream: null
    }
  },
  
  computed: {
    otherParticipants() {
      return this.participants.filter(p => p.id !== this.participantId)
    }
  },
  
  async mounted() {
    this.roomId = this.$route.params.roomId
    this.participantName = this.$route.query.name || 'Participante'
    
    await this.joinRoom()
    await this.initializeMedia()
  },
  
  beforeUnmount() {
    this.cleanup()
  },
  
  methods: {
    async joinRoom() {
      try {
        const result = await roomsAPI.joinRoom(this.roomId, {
          name: this.participantName,
          hasCamera: true,
          hasMicrophone: true,
          isDeaf: false,
          isMute: false
        })

        this.participantId = result.participant_id
        this.participants = result.participants || []

        await this.connectWebSocket()

      } catch (error) {
        this.error = error.message
        console.error('Error uniéndose a sala:', error)
      } finally {
        this.loading = false
      }
    },

    async initializeMedia() {
      console.log('=== INICIALIZANDO MEDIA ===')
      try {
        console.log('Solicitando getUserMedia...')
        this.localStream = await navigator.mediaDevices.getUserMedia({
          video: { width: { ideal: 640 }, height: { ideal: 480 } },
          audio: { echoCancellation: true, noiseSuppression: true }
        })
        console.log('Stream obtenido:', this.localStream)
        
        if (this.$refs.localVideoElement) {
          this.$refs.localVideoElement.srcObject = this.localStream
          console.log('Video local configurado')
        } else {
          console.warn('localVideoElement no encontrado')
        }
        
        this.hasLocalStream = true
        
        console.log('Inicializando WebRTC...')
        const initialized = await webrtcService.initialize(
          this.localStream,
          wsService,
          this.roomId,
          this.participantId
        )
        console.log('WebRTC inicializado:', initialized)
        
        webrtcService.setCallbacks({
          onRemoteStream: this.handleRemoteStream,
          onRemoteStreamRemoved: this.handleRemoteStreamRemoved,
          onConnectionStateChange: this.handleConnectionStateChange,
          onCallStarted: this.handleCallStarted,
          onCallEnded: this.handleCallEnded,
          onError: this.handleWebRTCError
        })
        
        console.log('Media inicializado correctamente')
        
      } catch (error) {
        console.error('ERROR en initializeMedia:', error)
        this.error = 'Error accediendo a cámara/micrófono: ' + error.message
      }
    },

    async connectWebSocket() {
      try {
        this.setupWebSocketListeners()
        await wsService.connect(this.roomId, this.participantId)
        this.isConnected = true
        console.log('WebSocket conectado exitosamente')
      } catch (error) {
        this.error = 'Error conectando al chat en tiempo real'
        console.error('Error WebSocket:', error)
      }
    },

    setupWebSocketListeners() {
      wsService.on('chat_message', (data) => {
        this.addMessage({
          id: Date.now() + Math.random(),
          sender_id: data.sender_id,
          sender_name: data.sender_name,
          message: data.message,
          timestamp: data.timestamp
        })
      })

      wsService.on('participant_joined', (data) => {
        console.log('Participante se unió:', data)
        this.refreshParticipants()
      })

      wsService.on('participant_left', (data) => {
        console.log('Participante se fue:', data)
        this.refreshParticipants()
        if (this.remoteParticipants[data.participant_id]) {
          this.handleRemoteStreamRemoved(data.participant_id)
        }
      })

      wsService.on('disconnected', () => {
        this.isConnected = false
        this.error = 'Conexión perdida. Intentando reconectar...'
      })

      wsService.on('error', (data) => {
        this.error = data.message || 'Error en la comunicación'
      })
    },

    async startVideoCall() {
      console.log('=== INICIANDO VIDEOLLAMADA ===')
      try {
        if (this.otherParticipants.length === 0) {
          this.error = 'No hay otros participantes para llamar'
          return
        }
        
        if (!this.hasLocalStream) {
          this.error = 'No hay stream local disponible'
          return
        }
        
        const targetParticipant = this.otherParticipants[0]
        await webrtcService.startCall(targetParticipant.id)
        console.log(`Llamada iniciada con ${targetParticipant.name}`)
        
      } catch (error) {
        console.error('ERROR en startVideoCall:', error)
        this.error = 'Error iniciando videollamada: ' + error.message
      }
    },
    
    async callParticipant(participantId) {
      try {
        await webrtcService.startCall(participantId)
        console.log(`Llamando a participante ${participantId}`)
      } catch (error) {
        this.error = 'Error llamando participante: ' + error.message
      }
    },

    endVideoCall() {
      webrtcService.endCall()
    },

    toggleMute() {
      this.isMuted = webrtcService.toggleMute()
    },

    toggleVideo() {
      this.isVideoOff = webrtcService.toggleVideo()
    },

    handleRemoteStream(participantId, stream) {
      const participant = this.participants.find(p => p.id === participantId)
      const participantName = participant ? participant.name : 'Participante'
      
      this.remoteParticipants = {
        ...this.remoteParticipants,
        [participantId]: {
          name: participantName,
          stream: stream
        }
      }
      
      this.$nextTick(() => {
        const videoElement = this.$refs[`remoteVideo_${participantId}`]
        if (videoElement && videoElement[0]) {
          videoElement[0].srcObject = stream
        }
      })
      
      console.log(`Stream remoto recibido de ${participantName}`)
    },

    handleRemoteStreamRemoved(participantId) {
      // eslint-disable-next-line no-unused-vars
      const { [participantId]: removed, ...remaining } = this.remoteParticipants
      this.remoteParticipants = remaining
      
      this.$nextTick(() => {
        const videoElement = this.$refs[`remoteVideo_${participantId}`]
        if (videoElement && videoElement[0]) {
          videoElement[0].srcObject = null
        }
      })
    },

    handleConnectionStateChange(participantId, state) {
      const participant = this.participants.find(p => p.id === participantId)
      const participantName = participant ? participant.name : 'Participante'
      
      const existingIndex = this.connectionStates.findIndex(cs => cs.participantId === participantId)
      if (existingIndex >= 0) {
        this.connectionStates = this.connectionStates.map((cs, index) => 
          index === existingIndex 
            ? { participantId, participantName, state }
            : cs
        )
      } else {
        this.connectionStates = [
          ...this.connectionStates,
          { participantId, participantName, state }
        ]
      }
      
      if (state === 'disconnected' || state === 'failed') {
        setTimeout(() => {
          this.connectionStates = this.connectionStates.filter(cs => cs.participantId !== participantId)
        }, 5000)
      }
    },

    handleCallStarted() {
      this.isCallActive = true
      console.log('Llamada iniciada')
    },

    handleCallEnded() {
      this.isCallActive = false
      this.connectionStates = []
      console.log('Llamada terminada')
    },

    handleWebRTCError(error) {
      this.error = 'Error en videollamada: ' + error.message
      console.error('WebRTC Error:', error)
    },

    getConnectionClass(state) {
      return {
        'connected': state === 'connected',
        'connecting': state === 'connecting',
        'failed': state === 'failed'
      }
    },

    sendMessage() {
      if (!this.newMessage.trim() || !this.isConnected) {
        return
      }

      wsService.sendChatMessage(this.newMessage.trim())
      this.newMessage = ''
    },

    addMessage(message) {
      this.messages.push(message)
      
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
      if (result.interim) {
        this.interimText = result.interim
      }
      
      if (result.final && result.final.trim()) {
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

    async toggleSignTranslation() {
      if (this.isTranslating) {
        await this.stopSignTranslation()
      } else {
        await this.startSignTranslation()
      }
    },

    async startSignTranslation() {
      try {
        mediaPipeService.setCallbacks({
          onLandmarks: this.handleLandmarks,
          onError: this.handleMediaPipeError
        })

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
        const result = await translatorAPI.predictSigns(landmarkSequence, 0.3)
        
        if (result.success && result.prediction) {
          const translation = {
            id: Date.now(),
            prediction: result.prediction,
            confidence: result.confidence,
            timestamp: new Date().toISOString()
          }
          
          this.recentTranslations.unshift(translation)
          
          if (this.recentTranslations.length > 10) {
            this.recentTranslations = this.recentTranslations.slice(0, 10)
          }
          
          this.sendTranslationToChat(translation)
          
          console.log('Traducción:', result.prediction, 'Confianza:', result.confidence)
        }
      } catch (error) {
        console.error('Error en traducción:', error)
      }
    },

    sendTranslationToChat(translation) {
      const message = `🤟 ${translation.prediction} (${(translation.confidence * 100).toFixed(1)}%)`
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
        await roomsAPI.leaveRoom(this.roomId, this.participantId)
        this.cleanup()
        this.$router.push('/')
      } catch (error) {
        console.error('Error saliendo de sala:', error)
        this.$router.push('/')
      }
    },

    cleanup() {
      if (this.isListening) {
        this.stopSpeechRecognition()
      }

      if (this.isTranslating) {
        this.stopSignTranslation()
      }

      if (webrtcService) {
        webrtcService.cleanup()
      }

      if (this.localStream) {
        this.localStream.getTracks().forEach(track => track.stop())
      }

      mediaPipeService.cleanup()

      if (wsService) {
        wsService.disconnect()
      }
      
      this.isConnected = false
    }
  }
}
</script>

<style scoped>
.hello-hand-room {
  min-height: 100vh;
  background: linear-gradient(135deg, #1a0828 0%, #2d1b69 50%, #1a0828 100%);
  color: white;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
}

.container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 1.5rem;
}

/* Header */
.room-header {
  padding: 2rem 0;
  border-bottom: 1px solid rgba(139, 92, 246, 0.2);
  background: rgba(255, 255, 255, 0.02);
  backdrop-filter: blur(20px);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}

.room-title {
  font-size: 2rem;
  font-weight: 700;
  margin: 0 0 0.5rem 0;
  background: linear-gradient(135deg, #8b5cf6, #e879f9);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.room-stats {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.8);
}

.stat-icon {
  font-size: 1.2rem;
}

.connection-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ef4444;
  transition: all 0.3s ease;
}

.connection-indicator.active {
  background: #10b981;
  box-shadow: 0 0 10px #10b981;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.leave-btn {
  background: linear-gradient(135deg, #ef4444, #dc2626);
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 0.75rem;
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.leave-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(239, 68, 68, 0.4);
}

/* Contenido principal */
.room-content {
  padding: 2rem 0;
}

.room-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
  margin-bottom: 2rem;
}

/* Tarjetas de sección */
.section-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 1.5rem;
  padding: 2rem;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.section-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.05), rgba(232, 121, 249, 0.05));
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}

.section-card:hover::before {
  opacity: 1;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  position: relative;
  z-index: 2;
}

.header-left,
.header-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.section-icon {
  font-size: 1.5rem;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #8b5cf6, #e879f9);
  border-radius: 0.75rem;
  box-shadow: 0 8px 25px rgba(139, 92, 246, 0.3);
}

.card-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
}

/* Estados */
.call-status,
.translation-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 2rem;
  font-size: 0.85rem;
  font-weight: 500;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.call-status.active,
.translation-status.active {
  background: rgba(16, 185, 129, 0.2);
  border-color: rgba(16, 185, 129, 0.4);
  color: #10b981;
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #6b7280;
}

.call-status.active .status-dot,
.translation-status.active .status-dot {
  background: #10b981;
  animation: pulse 2s infinite;
}

/* Botones */
.call-btn,
.toggle-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9rem;
}

.start-call {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
}

.start-call:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(16, 185, 129, 0.4);
}

.end-call {
  background: linear-gradient(135deg, #ef4444, #dc2626);
  color: white;
}

.end-call:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(239, 68, 68, 0.4);
}

.toggle-btn {
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  color: white;
}

.toggle-btn.active {
  background: linear-gradient(135deg, #ef4444, #dc2626);
}

.toggle-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(139, 92, 246, 0.4);
}

/* Video Grid */
.video-container-wrapper {
  position: relative;
  z-index: 2;
}

.video-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
  min-height: 350px;
}

.video-item {
  position: relative;
  background: #000;
  border-radius: 1rem;
  overflow: hidden;
  aspect-ratio: 16/9;
}

.video-element {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.local-video {
  border: 2px solid #8b5cf6;
  box-shadow: 0 0 20px rgba(139, 92, 246, 0.3);
}

.remote-video {
  border: 2px solid #10b981;
  box-shadow: 0 0 20px rgba(16, 185, 129, 0.3);
}

.video-overlay {
  position: absolute;
  bottom: 1rem;
  left: 1rem;
  z-index: 10;
}

.video-label {
  background: rgba(0, 0, 0, 0.7);
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-size: 0.85rem;
  font-weight: 500;
  backdrop-filter: blur(10px);
}

.video-controls {
  position: absolute;
  bottom: 1rem;
  right: 1rem;
  z-index: 10;
  display: flex;
  gap: 0.5rem;
}

.control-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.control-btn:hover {
  background: rgba(139, 92, 246, 0.8);
  transform: scale(1.1);
}

.control-btn.muted,
.control-btn.disabled {
  background: rgba(239, 68, 68, 0.8);
}

.video-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.02);
  border: 2px dashed rgba(139, 92, 246, 0.3);
  border-radius: 1rem;
  aspect-ratio: 16/9;
}

.placeholder-content {
  text-align: center;
  padding: 2rem;
}

.placeholder-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.placeholder-content h3 {
  margin: 0 0 1rem 0;
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.9);
}

.placeholder-content p {
  margin: 0;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.9rem;
}

.connection-states {
  margin-top: 1rem;
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.connection-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 500;
  background: rgba(107, 114, 128, 0.2);
  color: #9ca3af;
}

.connection-badge.connected {
  background: rgba(16, 185, 129, 0.2);
  color: #10b981;
}

.connection-badge.connecting {
  background: rgba(245, 158, 11, 0.2);
  color: #f59e0b;
}

.connection-badge.failed {
  background: rgba(239, 68, 68, 0.2);
  color: #ef4444;
}

/* Chat */
.chat-container {
  position: relative;
  z-index: 2;
}

.messages-area {
  height: 350px;
  overflow-y: auto;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 1rem;
  margin-bottom: 1rem;
  border: 1px solid rgba(139, 92, 246, 0.1);
}

.messages-area::-webkit-scrollbar {
  width: 6px;
}

.messages-area::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 3px;
}

.messages-area::-webkit-scrollbar-thumb {
  background: rgba(139, 92, 246, 0.5);
  border-radius: 3px;
}

.message-bubble {
  margin-bottom: 1rem;
  max-width: 85%;
}

.message-bubble.own-message {
  margin-left: auto;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.25rem;
}

.sender-name {
  font-size: 0.85rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
}

.message-time {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.5);
}

.message-text {
  background: rgba(255, 255, 255, 0.1);
  padding: 0.75rem 1rem;
  border-radius: 1rem;
  font-size: 0.9rem;
  word-wrap: break-word;
}

.own-message .message-text {
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  color: white;
}

.empty-chat {
  text-align: center;
  padding: 3rem 1rem;
  color: rgba(255, 255, 255, 0.5);
}

.empty-icon {
  font-size: 2.5rem;
  margin-bottom: 1rem;
}

.chat-input-area {
  position: relative;
  z-index: 2;
}

.message-form {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.message-input {
  flex: 1;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(139, 92, 246, 0.3);
  border-radius: 1rem;
  padding: 0.75rem 1rem;
  color: white;
  font-size: 0.95rem;
  transition: all 0.3s ease;
}

.message-input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.message-input:focus {
  outline: none;
  border-color: #8b5cf6;
  box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.2);
  background: rgba(255, 255, 255, 0.12);
}

.send-btn {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  color: white;
  font-size: 1.1rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.send-btn:hover:not(:disabled) {
  transform: scale(1.1);
  box-shadow: 0 8px 25px rgba(139, 92, 246, 0.4);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.stt-controls {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.stt-btn {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(139, 92, 246, 0.3);
  border-radius: 0.75rem;
  padding: 0.75rem 1rem;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stt-btn:hover:not(:disabled) {
  background: rgba(139, 92, 246, 0.2);
  border-color: rgba(139, 92, 246, 0.5);
}

.stt-btn.recording {
  background: rgba(239, 68, 68, 0.2);
  border-color: rgba(239, 68, 68, 0.5);
  animation: recording-pulse 1s infinite;
}

@keyframes recording-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.02); }
}

.stt-text {
  font-size: 0.85rem;
  font-weight: 500;
}

.interim-text {
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 0.5rem;
  font-style: italic;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.85rem;
}

/* Traducción de señas */
.translation-content {
  position: relative;
  z-index: 2;
}

.translation-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
}

.camera-container {
  position: relative;
  aspect-ratio: 4/3;
  border-radius: 1rem;
  overflow: hidden;
  background: #000;
}

.translation-video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.translation-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

.video-status-overlay {
  position: absolute;
  top: 1rem;
  right: 1rem;
  z-index: 10;
}

.status-badge {
  background: rgba(0, 0, 0, 0.7);
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-size: 0.85rem;
  font-weight: 500;
  color: #9ca3af;
  backdrop-filter: blur(10px);
}

.status-badge.active {
  background: rgba(16, 185, 129, 0.8);
  color: white;
}

.camera-controls {
  margin-top: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}

.clear-btn {
  background: rgba(239, 68, 68, 0.2);
  border: 1px solid rgba(239, 68, 68, 0.4);
  border-radius: 0.5rem;
  padding: 0.5rem 1rem;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.85rem;
}

.clear-btn:hover:not(:disabled) {
  background: rgba(239, 68, 68, 0.3);
}

.clear-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.available-signs {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.signs-label {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.7);
}

.sign-tag {
  background: rgba(139, 92, 246, 0.2);
  border: 1px solid rgba(139, 92, 246, 0.4);
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 500;
}

.results-section {
  display: flex;
  flex-direction: column;
}

.results-title {
  margin: 0 0 1rem 0;
  font-size: 1.1rem;
  font-weight: 600;
}

.results-container {
  flex: 1;
  max-height: 350px;
  overflow-y: auto;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 1rem;
  border: 1px solid rgba(139, 92, 246, 0.1);
}

.results-container::-webkit-scrollbar {
  width: 6px;
}

.results-container::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 3px;
}

.results-container::-webkit-scrollbar-thumb {
  background: rgba(139, 92, 246, 0.5);
  border-radius: 3px;
}

.translation-result {
  background: rgba(139, 92, 246, 0.1);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 0.75rem;
  padding: 1rem;
  margin-bottom: 0.75rem;
  transition: all 0.3s ease;
}

.translation-result:hover {
  background: rgba(139, 92, 246, 0.15);
  transform: translateY(-2px);
}

.result-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.result-text {
  font-size: 1.1rem;
  font-weight: 600;
  color: white;
}

.result-confidence {
  background: rgba(16, 185, 129, 0.2);
  color: #10b981;
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 600;
}

.result-time {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.5);
}

.empty-results {
  text-align: center;
  padding: 3rem 1rem;
  color: rgba(255, 255, 255, 0.5);
}

/* Participantes */
.participants-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
}

.participant-item {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 1rem;
  padding: 1rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: all 0.3s ease;
}

.participant-item:hover {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(139, 92, 246, 0.4);
}

.participant-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #8b5cf6, #e879f9);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.avatar-text {
  font-weight: 600;
  font-size: 1.1rem;
  color: white;
}

.participant-info {
  flex: 1;
}

.participant-name {
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.participant-badges {
  display: flex;
  gap: 0.25rem;
  flex-wrap: wrap;
}

.badge {
  font-size: 0.7rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.5rem;
  background: rgba(255, 255, 255, 0.1);
}

.call-participant-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.call-participant-btn:hover:not(:disabled) {
  transform: scale(1.1);
  box-shadow: 0 8px 25px rgba(16, 185, 129, 0.4);
}

.call-participant-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.in-call-badge {
  background: rgba(16, 185, 129, 0.2);
  color: #10b981;
  padding: 0.5rem 1rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 600;
}

/* Secciones completas */
.translation-section,
.participants-section {
  grid-column: 1 / -1;
}

/* Error modal */
.error-modal {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  z-index: 1000;
  animation: slideInUp 0.3s ease;
}

@keyframes slideInUp {
  from {
    transform: translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.error-content {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 1rem;
  padding: 1rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  backdrop-filter: blur(20px);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
  max-width: 400px;
}

.error-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.error-text {
  color: white;
  font-size: 0.9rem;
}

.error-close {
  background: none;
  border: none;
  color: white;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 0.25rem;
  transition: background 0.2s ease;
  flex-shrink: 0;
}

.error-close:hover {
  background: rgba(255, 255, 255, 0.1);
}

/* Responsive */
@media (max-width: 1200px) {
  .room-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
  
  .translation-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
}

@media (max-width: 768px) {
  .container {
    padding: 0 1rem;
  }
  
  .room-header {
    padding: 1.5rem 0;
  }
  
  .header-content {
    flex-direction: column;
    text-align: center;
  }
  
  .room-title {
    font-size: 1.5rem;
  }
  
  .section-card {
    padding: 1.5rem;
  }
  
  .card-header {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
  
  .video-grid {
    grid-template-columns: 1fr;
  }
  
  .participants-grid {
    grid-template-columns: 1fr;
  }
  
  .error-modal {
    bottom: 1rem;
    right: 1rem;
    left: 1rem;
  }
  
  .error-content {
    max-width: none;
  }
}
</style>