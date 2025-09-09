/* eslint-disable no-undef */
// src/services/speechRecognition.js - Servicio para Speech-to-Text

class SpeechRecognitionService {
  constructor() {
    this.recognition = null
    this.isListening = false
    this.isSupported = false
    this.currentLanguage = 'es-ES'
    
    // Callbacks
    this.onResult = null
    this.onError = null
    this.onStart = null
    this.onEnd = null
    
    this.init()
  }

  /**
   * Inicializar Web Speech API
   */
  init() {
    // Verificar soporte del navegador
    if ('webkitSpeechRecognition' in window) {
      this.recognition = new webkitSpeechRecognition()
      this.isSupported = true
    } else if ('SpeechRecognition' in window) {
      this.recognition = new SpeechRecognition()
      this.isSupported = true
    } else {
      console.warn('Web Speech API no está soportada en este navegador')
      this.isSupported = false
      return
    }

    // Configurar reconocimiento
    this.recognition.continuous = false          // Una frase por vez
    this.recognition.interimResults = true       // Resultados intermedios
    this.recognition.lang = this.currentLanguage // Idioma español
    this.recognition.maxAlternatives = 1         // Solo la mejor opción

    // Event listeners
    this.recognition.onstart = () => {
      this.isListening = true
      console.log('Reconocimiento de voz iniciado')
      if (this.onStart) this.onStart()
    }

    this.recognition.onresult = (event) => {
      let finalTranscript = ''
      let interimTranscript = ''

      // Procesar resultados
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript
        
        if (event.results[i].isFinal) {
          finalTranscript += transcript
        } else {
          interimTranscript += transcript
        }
      }

      // Callback con resultados
      if (this.onResult) {
        this.onResult({
          final: finalTranscript.trim(),
          interim: interimTranscript.trim(),
          confidence: event.results[0] ? event.results[0][0].confidence : 0
        })
      }
    }

    this.recognition.onerror = (event) => {
      console.error('Error en reconocimiento de voz:', event.error)
      this.isListening = false
      
      if (this.onError) {
        this.onError(this.getErrorMessage(event.error))
      }
    }

    this.recognition.onend = () => {
      this.isListening = false
      console.log('Reconocimiento de voz terminado')
      if (this.onEnd) this.onEnd()
    }
  }

  /**
   * Iniciar reconocimiento de voz
   * @returns {Promise}
   */
  startListening() {
    if (!this.isSupported) {
      return Promise.reject(new Error('Web Speech API no está soportada'))
    }

    if (this.isListening) {
      return Promise.reject(new Error('Ya está escuchando'))
    }

    try {
      this.recognition.start()
      return Promise.resolve()
    } catch (error) {
      return Promise.reject(error)
    }
  }

  /**
   * Detener reconocimiento de voz
   */
  stopListening() {
    if (this.recognition && this.isListening) {
      this.recognition.stop()
    }
  }

  /**
   * Abortar reconocimiento inmediatamente
   */
  abort() {
    if (this.recognition) {
      this.recognition.abort()
      this.isListening = false
    }
  }

  /**
   * Cambiar idioma de reconocimiento
   * @param {string} language - Código de idioma (ej: 'es-ES', 'en-US')
   */
  setLanguage(language) {
    this.currentLanguage = language
    if (this.recognition) {
      this.recognition.lang = language
    }
  }

  /**
   * Configurar callbacks
   * @param {Object} callbacks - Funciones callback
   */
  setCallbacks({ onResult, onError, onStart, onEnd }) {
    if (onResult) this.onResult = onResult
    if (onError) this.onError = onError
    if (onStart) this.onStart = onStart
    if (onEnd) this.onEnd = onEnd
  }

  /**
   * Obtener mensaje de error legible
   * @param {string} errorCode - Código de error
   * @returns {string} Mensaje de error
   */
  getErrorMessage(errorCode) {
    const errorMessages = {
      'no-speech': 'No se detectó voz. Intenta hablar más fuerte.',
      'audio-capture': 'No se pudo capturar audio. Verifica tu micrófono.',
      'not-allowed': 'Permiso denegado para acceder al micrófono.',
      'network': 'Error de red. Verifica tu conexión.',
      'language-not-supported': 'Idioma no soportado.',
      'service-not-allowed': 'Servicio de reconocimiento no permitido.',
      'bad-grammar': 'Error en la gramática de reconocimiento.',
      'aborted': 'Reconocimiento abortado por el usuario.'
    }

    return errorMessages[errorCode] || `Error desconocido: ${errorCode}`
  }

  /**
   * Verificar si los permisos de micrófono están disponibles
   * @returns {Promise}
   */
  async checkMicrophonePermission() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      stream.getTracks().forEach(track => track.stop()) // Cerrar inmediatamente
      return true
    } catch (error) {
      console.error('Error verificando permisos de micrófono:', error)
      return false
    }
  }

  /**
   * Obtener idiomas soportados (lista común)
   * @returns {Array} Lista de idiomas
   */
  getSupportedLanguages() {
    return [
      { code: 'es-ES', name: 'Español (España)' },
      { code: 'es-MX', name: 'Español (México)' },
      { code: 'es-AR', name: 'Español (Argentina)' },
      { code: 'es-CO', name: 'Español (Colombia)' },
      { code: 'en-US', name: 'English (US)' },
      { code: 'en-GB', name: 'English (UK)' }
    ]
  }

  /**
   * Obtener estado del servicio
   * @returns {Object} Estado actual
   */
  getStatus() {
    return {
      isSupported: this.isSupported,
      isListening: this.isListening,
      currentLanguage: this.currentLanguage,
      hasRecognition: !!this.recognition
    }
  }
}

// Servicio alternativo usando servidor (para casos donde Web Speech API no funciona)
class ServerSpeechRecognitionService {
  constructor() {
    this.mediaRecorder = null
    this.audioChunks = []
    this.isRecording = false
    
    // Callbacks
    this.onResult = null
    this.onError = null
    this.onStart = null
    this.onEnd = null
  }

  /**
   * Iniciar grabación de audio para enviar al servidor
   * @returns {Promise}
   */
  async startListening() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      
      this.mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus'
      })
      
      this.audioChunks = []
      
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data)
        }
      }
      
      this.mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
        await this.sendAudioToServer(audioBlob)
        
        // Detener stream
        stream.getTracks().forEach(track => track.stop())
        
        this.isRecording = false
        if (this.onEnd) this.onEnd()
      }
      
      this.mediaRecorder.start()
      this.isRecording = true
      
      if (this.onStart) this.onStart()
      
      return Promise.resolve()
      
    } catch (error) {
      console.error('Error iniciando grabación:', error)
      if (this.onError) this.onError('No se pudo acceder al micrófono')
      return Promise.reject(error)
    }
  }

  /**
   * Detener grabación
   */
  stopListening() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
    }
  }

  /**
   * Enviar audio al servidor para transcripción
   * @param {Blob} audioBlob - Audio grabado
   */
  async sendAudioToServer(audioBlob) {
    try {
      // Importar API dinámicamente para evitar circular imports
      const { translatorAPI } = await import('./api')
      
      // Convertir blob a archivo
      const audioFile = new File([audioBlob], 'recording.webm', { type: 'audio/webm' })
      
      // Enviar al backend
      const result = await translatorAPI.speechToText(audioFile)
      
      if (result.success && this.onResult) {
        this.onResult({
          final: result.text,
          interim: '',
          confidence: 1.0 // El servidor no devuelve confianza específica
        })
      } else if (this.onError) {
        this.onError(result.message || 'Error en transcripción')
      }
      
    } catch (error) {
      console.error('Error enviando audio al servidor:', error)
      if (this.onError) this.onError('Error procesando audio')
    }
  }

  /**
   * Configurar callbacks
   * @param {Object} callbacks - Funciones callback
   */
  setCallbacks({ onResult, onError, onStart, onEnd }) {
    if (onResult) this.onResult = onResult
    if (onError) this.onError = onError
    if (onStart) this.onStart = onStart
    if (onEnd) this.onEnd = onEnd
  }

  /**
   * Obtener estado del servicio
   * @returns {Object} Estado actual
   */
  getStatus() {
    return {
      isSupported: true, // MediaRecorder está bien soportado
      isListening: this.isRecording,
      currentLanguage: 'es-ES',
      hasRecognition: true
    }
  }
}

// Factory para crear el servicio apropiado
export function createSpeechRecognitionService() {
  // Intentar usar Web Speech API primero
  const webSpeechService = new SpeechRecognitionService()
  
  if (webSpeechService.isSupported) {
    console.log('Usando Web Speech API para STT')
    return webSpeechService
  } else {
    console.log('Usando servidor para STT (Web Speech API no disponible)')
    return new ServerSpeechRecognitionService()
  }
}

// Instancia global
export const speechRecognitionService = createSpeechRecognitionService()
export default speechRecognitionService