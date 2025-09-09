// src/services/mediapipe.js - Servicio para captura de landmarks con MediaPipe

import { Holistic } from '@mediapipe/holistic'
import { Camera } from '@mediapipe/camera_utils'

class MediaPipeService {
  constructor() {
    this.holistic = null
    this.camera = null
    this.videoElement = null
    this.canvasElement = null
    this.isInitialized = false
    this.isCapturing = false
    
    // Buffer para secuencias de landmarks
    this.landmarkBuffer = []
    this.bufferSize = 25  // 2.5 segundos a 10fps
    this.lastPredictionTime = 0
    this.predictionInterval = 1000  // Predecir cada 1 segundo
    
    // Callbacks
    this.onLandmarks = null
    this.onResults = null
    this.onError = null
  }

  /**
   * Inicializar MediaPipe Holistic
   * @param {HTMLVideoElement} videoElement - Elemento video
   * @param {HTMLCanvasElement} canvasElement - Canvas para dibujar
   * @returns {Promise}
   */
  async initialize(videoElement, canvasElement) {
    try {
      this.videoElement = videoElement
      this.canvasElement = canvasElement

      // Configurar Holistic
      this.holistic = new Holistic({
        locateFile: (file) => {
          return `https://cdn.jsdelivr.net/npm/@mediapipe/holistic/${file}`
        }
      })

      // Configurar opciones
      this.holistic.setOptions({
        modelComplexity: 1,
        smoothLandmarks: true,
        enableSegmentation: false,
        smoothSegmentation: false,
        refineFaceLandmarks: false,
        minDetectionConfidence: 0.5,
        minTrackingConfidence: 0.5
      })

      // Configurar callback de resultados
      this.holistic.onResults(this.onHolisticResults.bind(this))

      // Configurar cámara
      this.camera = new Camera(this.videoElement, {
        onFrame: async () => {
          if (this.isCapturing) {
            await this.holistic.send({ image: this.videoElement })
          }
        },
        width: 640,
        height: 480
      })

      this.isInitialized = true
      console.log('MediaPipe inicializado correctamente')
      
      return true

    } catch (error) {
      console.error('Error inicializando MediaPipe:', error)
      if (this.onError) this.onError(error)
      return false
    }
  }

  /**
   * Iniciar captura de video y landmarks
   * @returns {Promise}
   */
  async startCapture() {
    if (!this.isInitialized) {
      throw new Error('MediaPipe no está inicializado')
    }

    try {
      await this.camera.start()
      this.isCapturing = true
      console.log('Captura iniciada')
      
      return true

    } catch (error) {
      console.error('Error iniciando captura:', error)
      if (this.onError) this.onError(error)
      return false
    }
  }

  /**
   * Detener captura
   */
  stopCapture() {
    if (this.camera) {
      this.camera.stop()
    }
    this.isCapturing = false
    this.landmarkBuffer = []
    console.log('Captura detenida')
  }

  /**
   * Callback cuando MediaPipe procesa un frame
   * @param {Object} results - Resultados de MediaPipe
   */
  onHolisticResults(results) {
    if (!this.isCapturing) return

    // Dibujar landmarks en canvas
    this.drawLandmarks(results)

    // Extraer landmarks y añadir al buffer
    const landmarks = this.extractLandmarks(results)
    if (landmarks) {
      this.addToBuffer(landmarks)
      
      // Verificar si es momento de hacer predicción
      this.checkForPrediction()
    }

    // Callback para resultados generales
    if (this.onResults) {
      this.onResults(results)
    }
  }

  /**
   * Dibujar landmarks en el canvas
   * @param {Object} results - Resultados de MediaPipe
   */
  drawLandmarks(results) {
    if (!this.canvasElement) return

    const ctx = this.canvasElement.getContext('2d')
    const width = this.canvasElement.width
    const height = this.canvasElement.height

    // Limpiar canvas
    ctx.clearRect(0, 0, width, height)

    // Configurar canvas size si es necesario
    if (this.canvasElement.width !== this.videoElement.videoWidth) {
      this.canvasElement.width = this.videoElement.videoWidth
      this.canvasElement.height = this.videoElement.videoHeight
    }

    // Dibujar pose landmarks
    if (results.poseLandmarks) {
      this.drawConnections(ctx, results.poseLandmarks, [
        [11, 12], [11, 13], [13, 15], [12, 14], [14, 16]  // Pose key points
      ], '#00FF00', 2)
      
      this.drawLandmarkPoints(ctx, results.poseLandmarks.slice(11, 17), '#00FF00', 4)
    }

    // Dibujar hand landmarks
    if (results.leftHandLandmarks) {
      this.drawHandConnections(ctx, results.leftHandLandmarks, '#FF0000')
      this.drawLandmarkPoints(ctx, results.leftHandLandmarks, '#FF0000', 2)
    }

    if (results.rightHandLandmarks) {
      this.drawHandConnections(ctx, results.rightHandLandmarks, '#0000FF')
      this.drawLandmarkPoints(ctx, results.rightHandLandmarks, '#0000FF', 2)
    }

    // Dibujar face landmarks (solo algunos puntos clave)
    if (results.faceLandmarks) {
      const keyFacePoints = results.faceLandmarks.slice(0, 20)
      this.drawLandmarkPoints(ctx, keyFacePoints, '#FFFF00', 1)
    }
  }

  /**
   * Dibujar conexiones entre landmarks
   */
  drawConnections(ctx, landmarks, connections, color, width) {
    ctx.strokeStyle = color
    ctx.lineWidth = width

    connections.forEach(([start, end]) => {
      if (landmarks[start] && landmarks[end]) {
        ctx.beginPath()
        ctx.moveTo(
          landmarks[start].x * this.canvasElement.width,
          landmarks[start].y * this.canvasElement.height
        )
        ctx.lineTo(
          landmarks[end].x * this.canvasElement.width,
          landmarks[end].y * this.canvasElement.height
        )
        ctx.stroke()
      }
    })
  }

  /**
   * Dibujar conexiones de mano
   */
  drawHandConnections(ctx, landmarks, color) {
    const connections = [
      [0,1], [1,2], [2,3], [3,4],           // Thumb
      [0,5], [5,6], [6,7], [7,8],           // Index
      [0,9], [9,10], [10,11], [11,12],      // Middle
      [0,13], [13,14], [14,15], [15,16],    // Ring
      [0,17], [17,18], [18,19], [19,20]     // Pinky
    ]
    
    this.drawConnections(ctx, landmarks, connections, color, 1)
  }

  /**
   * Dibujar puntos de landmarks
   */
  drawLandmarkPoints(ctx, landmarks, color, radius) {
    ctx.fillStyle = color
    
    landmarks.forEach(landmark => {
      ctx.beginPath()
      ctx.arc(
        landmark.x * this.canvasElement.width,
        landmark.y * this.canvasElement.height,
        radius,
        0,
        2 * Math.PI
      )
      ctx.fill()
    })
  }

  /**
   * Extraer landmarks en formato compatible con backend
   * @param {Object} results - Resultados de MediaPipe
   * @returns {Object} Landmarks formateados
   */
  extractLandmarks(results) {
    const timestamp = Date.now()

    // Estructura compatible con backend
    const landmarks = {
      timestamp: timestamp / 1000, // Convertir a segundos
      face: [],
      pose: {},
      left_hand: [],
      right_hand: []
    }

    // Extraer cara (primeros 20 puntos)
    if (results.faceLandmarks && results.faceLandmarks.length >= 20) {
      for (let i = 0; i < 20; i++) {
        const point = results.faceLandmarks[i]
        landmarks.face.push({
          x: point.x,
          y: point.y,
          z: point.z || 0
        })
      }
    }

    // Extraer pose (puntos clave del cuerpo)
    if (results.poseLandmarks) {
      const poseMapping = {
        "hombro_izq": 11,
        "hombro_der": 12,
        "codo_izq": 13,
        "codo_der": 14,
        "muneca_izq": 15,
        "muneca_der": 16
      }

      Object.entries(poseMapping).forEach(([key, index]) => {
        if (results.poseLandmarks[index]) {
          const point = results.poseLandmarks[index]
          landmarks.pose[key] = {
            x: point.x,
            y: point.y,
            z: point.z || 0
          }
        }
      })
    }

    // Extraer manos
    if (results.leftHandLandmarks) {
      results.leftHandLandmarks.forEach(point => {
        landmarks.left_hand.push({
          x: point.x,
          y: point.y,
          z: point.z || 0
        })
      })
    }

    if (results.rightHandLandmarks) {
      results.rightHandLandmarks.forEach(point => {
        landmarks.right_hand.push({
          x: point.x,
          y: point.y,
          z: point.z || 0
        })
      })
    }

    // Solo retornar si hay datos útiles
    const hasData = landmarks.face.length > 0 || 
                   Object.keys(landmarks.pose).length > 0 ||
                   landmarks.left_hand.length > 0 || 
                   landmarks.right_hand.length > 0

    return hasData ? landmarks : null
  }

  /**
   * Añadir landmarks al buffer
   * @param {Object} landmarks - Landmarks extraídos
   */
  addToBuffer(landmarks) {
    this.landmarkBuffer.push(landmarks)

    // Mantener tamaño del buffer
    if (this.landmarkBuffer.length > this.bufferSize) {
      this.landmarkBuffer.shift()
    }
  }

  /**
   * Verificar si es momento de hacer predicción
   */
  checkForPrediction() {
    const now = Date.now()
    
    if (now - this.lastPredictionTime >= this.predictionInterval && 
        this.landmarkBuffer.length >= 10) { // Mínimo 10 frames
      
      this.lastPredictionTime = now
      
      // Callback con secuencia para predicción
      if (this.onLandmarks) {
        // Enviar copia del buffer actual
        const sequence = [...this.landmarkBuffer]
        this.onLandmarks(sequence)
      }
    }
  }

  /**
   * Obtener información del estado actual
   * @returns {Object} Estado del servicio
   */
  getStatus() {
    return {
      isInitialized: this.isInitialized,
      isCapturing: this.isCapturing,
      bufferSize: this.landmarkBuffer.length,
      maxBufferSize: this.bufferSize,
      hasVideo: !!this.videoElement,
      hasCanvas: !!this.canvasElement
    }
  }

  /**
   * Configurar callbacks
   * @param {Object} callbacks - Funciones callback
   */
  setCallbacks({ onLandmarks, onResults, onError }) {
    if (onLandmarks) this.onLandmarks = onLandmarks
    if (onResults) this.onResults = onResults
    if (onError) this.onError = onError
  }

  /**
   * Limpiar recursos
   */
  cleanup() {
    this.stopCapture()
    
    if (this.holistic) {
      this.holistic.close()
    }
    
    this.holistic = null
    this.camera = null
    this.videoElement = null
    this.canvasElement = null
    this.isInitialized = false
    
    console.log('MediaPipe limpiado')
  }
}

// Instancia global del servicio
export const mediaPipeService = new MediaPipeService()
export default mediaPipeService