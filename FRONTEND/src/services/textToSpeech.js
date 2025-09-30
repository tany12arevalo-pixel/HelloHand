// src/services/textToSpeech.js
class TextToSpeechService {
  constructor() {
    this.synth = window.speechSynthesis
    this.currentUtterance = null
    this.isSpeaking = false
    
    // Configuración por defecto
    this.config = {
      lang: 'es-ES',
      rate: 1.0,
      pitch: 1.0,
      volume: 1.0
    }
  }

  /**
   * Verifica si el navegador soporta Web Speech API
   */
  isSupported() {
    return 'speechSynthesis' in window
  }

  /**
   * Obtiene las voces disponibles en español
   */
  getSpanishVoices() {
    return new Promise((resolve) => {
      let voices = this.synth.getVoices()
      
      if (voices.length > 0) {
        resolve(voices.filter(voice => voice.lang.startsWith('es')))
      } else {
        // Algunos navegadores necesitan esperar al evento
        this.synth.addEventListener('voiceschanged', () => {
          voices = this.synth.getVoices()
          resolve(voices.filter(voice => voice.lang.startsWith('es')))
        })
      }
    })
  }

  /**
   * Lee un texto en voz alta
   * @param {string} text - Texto a leer
   * @param {object} options - Opciones personalizadas
   * @returns {Promise} - Resuelve cuando termina de hablar
   */
  speak(text, options = {}) {
    return new Promise((resolve, reject) => {
      if (!this.isSupported()) {
        reject(new Error('Tu navegador no soporta texto a voz'))
        return
      }

      // Detener cualquier reproducción actual
      this.stop()

      // Crear nueva utterance
      this.currentUtterance = new SpeechSynthesisUtterance(text)
      
      // Aplicar configuración
      this.currentUtterance.lang = options.lang || this.config.lang
      this.currentUtterance.rate = options.rate || this.config.rate
      this.currentUtterance.pitch = options.pitch || this.config.pitch
      this.currentUtterance.volume = options.volume || this.config.volume

      // Callbacks
      this.currentUtterance.onstart = () => {
        this.isSpeaking = true
      }

      this.currentUtterance.onend = () => {
        this.isSpeaking = false
        this.currentUtterance = null
        resolve()
      }

      this.currentUtterance.onerror = (error) => {
        this.isSpeaking = false
        this.currentUtterance = null
        reject(error)
      }

      // Iniciar reproducción
      this.synth.speak(this.currentUtterance)
    })
  }

  /**
   * Detiene la reproducción actual
   */
  stop() {
    if (this.synth.speaking) {
      this.synth.cancel()
      this.isSpeaking = false
      this.currentUtterance = null
    }
  }

  /**
   * Pausa la reproducción
   */
  pause() {
    if (this.synth.speaking && !this.synth.paused) {
      this.synth.pause()
    }
  }

  /**
   * Reanuda la reproducción pausada
   */
  resume() {
    if (this.synth.paused) {
      this.synth.resume()
    }
  }

  /**
   * Actualiza la configuración del servicio
   */
  setConfig(newConfig) {
    this.config = { ...this.config, ...newConfig }
  }

  /**
   * Limpia recursos
   */
  cleanup() {
    this.stop()
  }
}

// Exportar instancia singleton
export default new TextToSpeechService()