// src/services/api.js - Servicio para comunicarse con el backend Django

import axios from 'axios'

const API_BASE_URL = 'https://192.168.1.88:8021/api'

// Configurar axios
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  }
})

// Interceptor para manejar errores globalmente
api.interceptors.response.use(
  response => response,
  error => {
    console.error('API Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

export const roomsAPI = {
  /**
   * Crear una nueva sala
   * @param {Object} roomData - Datos de la sala
   * @returns {Promise}
   */
  async createRoom(roomData = {}) {
    try {
      const response = await api.post('/rooms/create/', {
        name: roomData.name || 'Sala HelloHand',
        max_participants: roomData.maxParticipants || 10,
        translation_enabled: roomData.translationEnabled !== false,
        stt_enabled: roomData.sttEnabled !== false,
        tts_enabled: roomData.ttsEnabled !== false
      })
      return response.data
    } catch (error) {
      throw new Error(`Error creando sala: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Unirse a una sala existente
   * @param {string} roomId - ID de la sala
   * @param {Object} participantData - Datos del participante
   * @returns {Promise}
   */
  async joinRoom(roomId, participantData) {
    try {
      const response = await api.post(`/rooms/${roomId}/join/`, {
        participant_name: participantData.name || 'Participante',
        has_camera: participantData.hasCamera !== false,
        has_microphone: participantData.hasMicrophone !== false,
        is_deaf: participantData.isDeaf || false,
        is_mute: participantData.isMute || false
      })
      return response.data
    } catch (error) {
      throw new Error(`Error uniéndose a sala: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Obtener estado de una sala
   * @param {string} roomId - ID de la sala
   * @returns {Promise}
   */
  async getRoomStatus(roomId) {
    try {
      const response = await api.get(`/rooms/${roomId}/status/`)
      return response.data
    } catch (error) {
      throw new Error(`Error obteniendo estado: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Salir de una sala
   * @param {string} roomId - ID de la sala
   * @param {string} participantId - ID del participante
   * @returns {Promise}
   */
  async leaveRoom(roomId, participantId) {
    try {
      const response = await api.post(`/rooms/${roomId}/leave/`, {
        participant_id: participantId
      })
      return response.data
    } catch (error) {
      throw new Error(`Error saliendo de sala: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Listar salas disponibles
   * @param {Object} filters - Filtros opcionales
   * @returns {Promise}
   */
  async listRooms(filters = {}) {
    try {
      const params = new URLSearchParams()
      if (filters.status) params.append('status', filters.status)
      if (filters.limit) params.append('limit', filters.limit)

      const response = await api.get(`/rooms/list/?${params}`)
      return response.data
    } catch (error) {
      throw new Error(`Error listando salas: ${error.response?.data?.error || error.message}`)
    }
  }
}

export const translatorAPI = {
  /**
   * Traducir landmarks de señas a texto
   * @param {Array} landmarks - Array de frames con landmarks
   * @param {number} minConfidence - Confianza mínima
   * @returns {Promise}
   */
  async predictSigns(landmarks, minConfidence = 0.4) {
    try {
      const response = await api.post('/translator/predict-signs/', {
        landmarks,
        min_confidence: minConfidence
      })
      return response.data
    } catch (error) {
      throw new Error(`Error en traducción: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Convertir texto a voz
   * @param {string} text - Texto a sintetizar
   * @param {string} priority - Prioridad ('normal' o 'high')
   * @returns {Promise}
   */
  async textToSpeech(text, priority = 'normal') {
    try {
      const response = await api.post('/translator/text-to-speech/', {
        text,
        priority
      })
      return response.data
    } catch (error) {
      throw new Error(`Error en TTS: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Convertir voz a texto
   * @param {File} audioFile - Archivo de audio
   * @returns {Promise}
   */
  async speechToText(audioFile) {
    try {
      const formData = new FormData()
      formData.append('audio', audioFile)

      const response = await api.post('/translator/speech-to-text/', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })
      return response.data
    } catch (error) {
      throw new Error(`Error en STT: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Obtener información del modelo
   * @returns {Promise}
   */
  async getModelInfo() {
    try {
      const response = await api.get('/translator/model-info/')
      return response.data
    } catch (error) {
      throw new Error(`Error obteniendo info del modelo: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Obtener señas disponibles
   * @returns {Promise}
   */
  async getAvailableSigns() {
    try {
      const response = await api.get('/translator/available-signs/')
      return response.data
    } catch (error) {
      throw new Error(`Error obteniendo señas: ${error.response?.data?.error || error.message}`)
    }
  },

  /**
   * Health check del servicio de traducción
   * @returns {Promise}
   */
  async healthCheck() {
    try {
      const response = await api.get('/translator/health/')
      return response.data
    } catch (error) {
      throw new Error(`Error en health check: ${error.response?.data?.error || error.message}`)
    }
  }
}

export default api