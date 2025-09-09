// src/services/mediaStreamService.js - Servicio unificado para audio/video

import mediaPipeService from './mediapipe'
import { translatorAPI } from './api'

class MediaStreamService {
  constructor() {
    this.mediaStream = null
    this.videoElement = null
    this.canvasElement = null
    this.audioContext = null
    this.audioAnalyser = null
    
    // Estados
    this.isActive = false
    this.isVideoEnabled = true
    this.isAudioEnabled = true
    
    // Características habilitadas
    this.features = {
      signTranslation: false,
      speechToText: false,
      webrtc: false
    }
    
    // Callbacks
    this.callbacks = {
      onSignTranslation: null,
      onSpeechResult: null,
      onStreamReady: null,
      onError: null
    }
    
    // STT con Web Speech API
    this.speechRecognition = null
    this.isListening = false
    
    // Buffer para traducción de señas
    this.landmarkBuffer = []
    this.bufferSize = 25
    this.lastPredictionTime = 0
    this.predictionInterval = 1000
  }

  /**
   * Inicializar stream unificado
   * @param {HTMLVideoElement} videoElement 
   * @param {HTMLCanvasElement} canvasElement 
   * @param {Object} constraints - Configuración de medios
   * @returns {Promise}
   */
  async initialize(videoElement, canvasElement, constraints = {}) {
    try {
      this.videoElement = videoElement
      this.canvasElement = canvasElement

      // Configuración por defecto
      const defaultConstraints = {
        video: {
          width: { ideal: 640 },
          height: { ideal: 480 },
          frameRate: { ideal: 30 }
        },
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        }
      }

      const finalConstraints = { ...defaultConstraints, ...constraints }

      // Obtener stream unificado
      this.mediaStream = await navigator.mediaDevices.getUserMedia(finalConstraints)
      
      // Configurar video
      this.videoElement.srcObject = this.mediaStream
      await this.videoElement.play()
      
      // Configurar canvas
      this.canvasElement.width = this.videoElement.videoWidth || 640
      this.canvasElement.height = this.videoElement.videoHeight || 480
      
      // Configurar audio para análisis
      await this.setupAudioAnalysis()
      
      // Configurar Speech Recognition
      this.setupSpeechRecognition()
      
      this.isActive = true
      console.log('MediaStreamService inicializado correctamente')
      
      if (this.callbacks.onStreamReady) {
        this.callbacks.onStreamReady(this.mediaStream)
      }
      
      return true

    } catch (error) {
      console.error('Error inicializando MediaStreamService:', error)
      if (this.callbacks.onError) {
        this.callbacks.onError(error)
      }
      return false
    }
  }

  /**
   * Configurar análisis de audio
   */
  async setupAudioAnalysis() {
    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const source = this.audioContext.createMediaStreamSource(this.mediaStream)
      this.audioAnalyser = this.audioContext.createAnalyser()
      
      this.audioAnalyser.fftSize = 256
      source.connect(this.audioAnalyser)
      
      console.log('Análisis de audio configurado')
    } catch (error) {
      console.warn('No se pudo configurar análisis de audio:', error)
    }
  }

  /**
   * Configurar Speech Recognition
   */
  setupSpeechRecognition() {
    if ('webkitSpeechRecognition' in window) {
      this.speechRecognition = new webkitSpeechRecognition()
    } else if ('SpeechRecognition' in window) {
      this.speechRecognition = new SpeechRecognition()
    } else {
      console.warn('Web Speech API no disponible')
      return
    }

    this.speechRecognition.continuous = false
    this.speechRecognition.interimResults = true
    this.speechRecognition.lang = 'es-ES'

    this.speechRecognition.onresult = (event) => {
      let finalTranscript = ''
      let interimTranscript = ''

      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript
        
        if (event.results[i].isFinal) {
          finalTranscript += transcript
        } else {
          interimTranscript += transcript
        }
      }

      if (this.callbacks.onSpeechResult) {
        this.callbacks.onSpeechResult({
          final: finalTranscript.trim(),
          interim: interimTranscript.trim(),
          confidence: event.results[0] ? event.results[0][0].confidence : 0
        })
      }
    }

    this.speechRecognition.onstart = () => {
      this.isListening = true
    }

    this.speechRecognition.onend = () => {
      this.isListening = false
    }

    this.speechRecognition.onerror = (event) => {
      console.error('Error Speech Recognition:', event.error)
      this.isListening = false
    }
  }

  /**
   * Habilitar/deshabilitar traducción de señas
   * @param {boolean} enabled 
   */
  async setSignTranslation(enabled) {
    this.features.signTranslation = enabled

    if (enabled) {
      // Configurar MediaPipe con nuestro stream
      mediaPipeService.setCallbacks({
        onLandmarks: this.handleLandmarks.bind(this),
        onResults: this.handleMediaPipeResults.bind(this)
      })

      const initialized = await mediaPipeService.initialize(
        this.videoElement,
        this.canvasElement
      )

      if (initialized) {
        await mediaPipeService.startCapture()
        console.log('Traducción de señas habilitada')
      }
    } else {
      mediaPipeService.stopCapture()
      this.landmarkBuffer = []
      console.log('Traducción de señas deshabilitada')
    }
  }

  /**
   * Habilitar/deshabilitar speech-to-text
   * @param {boolean} enabled 
   */
  setSpeechToText(enabled) {
    this.features.speechToText = enabled
    
    if (!enabled && this.isListening) {
      this.stopSpeechRecognition()
    }
  }

  /**
   * Iniciar reconocimiento de voz
   */
  startSpeechRecognition() {
    if (!this.features.speechToText || !this.speechRecognition || this.isListening) {
      return false
    }

    try {
      this.speechRecognition.start()
      return true
    } catch (error) {
      console.error('Error iniciando speech recognition:', error)
      return false
    }
  }

  /**
   * Detener reconocimiento de voz
   */
  stopSpeechRecognition() {
    if (this.speechRecognition && this.isListening) {
      this.speechRecognition.stop()
    }
  }

  /**
   * Manejar landmarks de MediaPipe
   * @param {Array} landmarkSequence 
   */
  async handleLandmarks(landmarkSequence) {
    try {
      // Enviar al backend para traducción
      const result = await translatorAPI.predictSigns(landmarkSequence, 0.3)
      
      if (result.success && result.prediction && this.callbacks.onSignTranslation) {
        this.callbacks.onSignTranslation({
          prediction: result.prediction,
          confidence: result.confidence,
          timestamp: new Date().toISOString()
        })
      }
    } catch (error) {
      console.error('Error en traducción de señas:', error)
    }
  }

  /**
   * Manejar resultados de MediaPipe
   * @param {Object} results 
   */
  handleMediaPipeResults(results) {
    // MediaPipe ya maneja el dibujo en canvas
    // Aquí podríamos agregar lógica adicional si es necesario
  }

  /**
   * Obtener stream para WebRTC
   * @returns {MediaStream}
   */
  getStreamForWebRTC() {
    return this.mediaStream
  }

  /**
   * Obtener pistas de audio/video
   */
  getTracks() {
    if (!this.mediaStream) return { video: [], audio: [] }

    return {
      video: this.mediaStream.getVideoTracks(),
      audio: this.mediaStream.getAudioTracks()
    }
  }

  /**
   * Controlar audio/video
   */
  toggleAudio(enabled = !this.isAudioEnabled) {
    const audioTracks = this.mediaStream?.getAudioTracks() || []
    audioTracks.forEach(track => {
      track.enabled = enabled
    })
    this.isAudioEnabled = enabled
    return enabled
  }

  toggleVideo(enabled = !this.isVideoEnabled) {
    const videoTracks = this.mediaStream?.getVideoTracks() || []
    videoTracks.forEach(track => {
      track.enabled = enabled
    })
    this.isVideoEnabled = enabled
    return enabled
  }

  /**
   * Obtener nivel de audio (para indicadores visuales)
   * @returns {number} Nivel entre 0-100
   */
  getAudioLevel() {
    if (!this.audioAnalyser) return 0

    const dataArray = new Uint8Array(this.audioAnalyser.frequencyBinCount)
    this.audioAnalyser.getByteFrequencyData(dataArray)
    
    const average = dataArray.reduce((a, b) => a + b) / dataArray.length
    return Math.round((average / 255) * 100)
  }

  /**
   * Configurar callbacks
   * @param {Object} callbacks 
   */
  setCallbacks(callbacks) {
    this.callbacks = { ...this.callbacks, ...callbacks }
  }

  /**
   * Obtener estado del servicio
   */
  getStatus() {
    return {
      isActive: this.isActive,
      isVideoEnabled: this.isVideoEnabled,
      isAudioEnabled: this.isAudioEnabled,
      isListening: this.isListening,
      features: { ...this.features },
      hasStream: !!this.mediaStream,
      audioLevel: this.getAudioLevel()
    }
  }

  /**
   * Limpiar recursos
   */
  cleanup() {
    // Detener características
    this.setSignTranslation(false)
    this.setSpeechToText(false)

    // Limpiar MediaPipe
    mediaPipeService.cleanup()

    // Detener reconocimiento de voz
    if (this.speechRecognition) {
      this.speechRecognition.abort()
    }

    // Cerrar audio context
    if (this.audioContext) {
      this.audioContext.close()
    }

    // Detener stream
    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach(track => track.stop())
      this.mediaStream = null
    }

    // Limpiar video
    if (this.videoElement) {
      this.videoElement.srcObject = null
    }

    this.isActive = false
    this.landmarkBuffer = []
    
    console.log('MediaStreamService limpiado')
  }
}

// Instancia global
export const mediaStreamService = new MediaStreamService()
export default mediaStreamService