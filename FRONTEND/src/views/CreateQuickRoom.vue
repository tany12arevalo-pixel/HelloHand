<!-- src/views/CreateQuickRoom.vue -->
<template>
  <div class="create-quick-room">
    <div class="quick-container">
      <!-- Botón de regresar -->
      <button @click="goBack" class="back-btn">
        <span class="back-icon">←</span>
        Volver
      </button>

      <!-- Header -->
      <div class="quick-header">
        <div class="header-icon">⚡</div>
        <h1 class="quick-title">Conversación Rápida</h1>
        <p class="quick-subtitle">Conexión instantánea entre 2 personas</p>
      </div>

      <!-- Switch para alternar entre crear y unirse -->
      <div class="switch-container">
        <button 
          :class="['switch-btn', { active: activeMode === 'create' }]"
          @click="activeMode = 'create'"
        >
          <span class="switch-icon">⚡</span>
          Crear Sala
        </button>
        <button 
          :class="['switch-btn', { active: activeMode === 'join' }]"
          @click="activeMode = 'join'"
        >
          <span class="switch-icon">🔗</span>
          Unirse a Sala
        </button>
      </div>

      <!-- Contenido dinámico según el modo -->
      <div class="content-wrapper">
        <!-- Columna izquierda: Formulario -->
        <div class="content-card">
          <!-- MODO CREAR SALA RÁPIDA -->
          <div v-if="activeMode === 'create'" class="mode-content">
            <div class="mode-header">
              <h2>Crear Sala Rápida</h2>
              <p>Sala automática para 2 personas - comparte el código con alguien</p>
            </div>

            <form @submit.prevent="createQuickRoom" class="form-content">
              <!-- Tu nombre -->
              <div class="form-group">
                <label class="form-label">
                  <span class="label-icon">👤</span>
                  Tu nombre
                </label>
                <input 
                  v-model="creatorName"
                  type="text" 
                  class="form-input"
                  placeholder="Ej: María López"
                  maxlength="50"
                  required
                >
              </div>

              <!-- Info automática -->
              <div class="auto-config-info">
                <div class="info-item">
                  <span class="info-icon">👥</span>
                  <span>Máximo: 2 participantes</span>
                </div>
                <div class="info-item">
                  <span class="info-icon">⚡</span>
                  <span>Configuración automática</span>
                </div>
              </div>

              <!-- Botón submit -->
              <button 
                type="submit" 
                :disabled="loading || !creatorName.trim()"
                class="submit-btn create-btn"
              >
                <span v-if="loading" class="loading-spinner"></span>
                <span v-else class="btn-icon">⚡</span>
                {{ loading ? 'Creando...' : 'Crear Sala Rápida' }}
              </button>
            </form>
          </div>

          <!-- MODO UNIRSE A SALA RÁPIDA -->
          <div v-else class="mode-content">
            <div class="mode-header">
              <h2>Unirse a Sala Rápida</h2>
              <p>Ingresa el código de 6 caracteres de la sala</p>
            </div>

            <form @submit.prevent="joinQuickRoom" class="form-content">
              <!-- Tu nombre -->
              <div class="form-group">
                <label class="form-label">
                  <span class="label-icon">👤</span>
                  Tu nombre
                </label>
                <input 
                  v-model="joinData.name"
                  type="text" 
                  class="form-input"
                  placeholder="Ej: Juan Pérez"
                  maxlength="50"
                  required
                >
              </div>

              <!-- Código de sala -->
              <div class="form-group">
                <label class="form-label">
                  <span class="label-icon">🔑</span>
                  Código de la sala
                </label>
                <input 
                  v-model="joinData.roomId"
                  type="text" 
                  class="form-input code-input"
                  placeholder="ABC123"
                  maxlength="6"
                  required
                >
                <small class="input-hint">6 caracteres alfanuméricos</small>
              </div>

              <!-- Botón submit -->
              <button 
                type="submit" 
                :disabled="loading || !joinData.roomId || !joinData.name"
                class="submit-btn join-btn"
              >
                <span v-if="loading" class="loading-spinner"></span>
                <span v-else class="btn-icon">🚀</span>
                {{ loading ? 'Uniéndose...' : 'Unirse a Sala' }}
              </button>
            </form>
          </div>
        </div>

        <!-- Columna derecha: Info y características -->
        <div class="info-panel">
          <!-- Preview visual -->
          <div class="preview-card">
            <div class="preview-header">
              <span class="preview-icon">{{ activeMode === 'create' ? '⚡' : '🚀' }}</span>
              <h3>{{ activeMode === 'create' ? 'Sala 1 a 1' : 'Conexión Directa' }}</h3>
            </div>
            <div class="preview-content">
              <div v-if="activeMode === 'create'" class="preview-illustration">
                <div class="quick-room-preview">
                  <div class="participant-slot filled">👤</div>
                  <div class="connection-line"></div>
                  <div class="participant-slot empty">👤</div>
                </div>
                <p class="preview-text">Sala privada para 2 personas únicamente</p>
              </div>
              <div v-else class="preview-illustration">
                <div class="join-preview">
                  <div class="join-icon">🔐</div>
                  <div class="join-arrow">→</div>
                  <div class="join-room quick">
                    <div class="room-icon">⚡</div>
                  </div>
                </div>
                <p class="preview-text">Acceso instantáneo con el código</p>
              </div>
            </div>
          </div>

          <!-- Features del modo actual -->
          <div class="features-list">
            <h4 class="features-title">Características:</h4>
            <div v-if="activeMode === 'create'" class="feature-items">
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Solo 2 participantes</span>
              </div>
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Código único generado</span>
              </div>
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Configuración automática</span>
              </div>
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Máxima privacidad</span>
              </div>
            </div>
            <div v-else class="feature-items">
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Acceso instantáneo</span>
              </div>
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>No requiere registro</span>
              </div>
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Conversación privada</span>
              </div>
              <div class="feature-item-small">
                <span class="feature-check quick">✓</span>
                <span>Únete en segundos</span>
              </div>
            </div>
          </div>

          <!-- Info adicional -->
          <div class="info-badge-box">
            <div class="info-badge-inline quick">
              <span class="badge-icon-small">🤟</span>
              <span>Traducción de señas</span>
            </div>
            <div class="info-badge-inline quick">
              <span class="badge-icon-small">🎤</span>
              <span>Voz a texto</span>
            </div>
            <div class="info-badge-inline quick">
              <span class="badge-icon-small">🔊</span>
              <span>Texto a voz</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal de error -->
      <div v-if="error" class="error-toast">
        <div class="error-content">
          <span class="error-icon">⚠️</span>
          <span class="error-text">{{ error }}</span>
        </div>
        <button @click="error = ''" class="error-close">✕</button>
      </div>
    </div>
  </div>
</template>

<script>
import { roomsAPI } from '@/services/api'

export default {
  name: 'CreateQuickRoom',
  
  data() {
    return {
      // Modo activo: 'create' o 'join'
      activeMode: 'create',
      
      // Estado de carga
      loading: false,
      error: '',
      
      // Nombre del creador
      creatorName: '',
      
      // Datos para unirse a sala
      joinData: {
        roomId: '',
        name: ''
      }
    }
  },
  
  methods: {
    /**
     * Volver al home
     */
    goBack() {
      this.$router.push('/')
    },
    
    /**
     * Crear una nueva sala rápida (automática para 2 personas)
     */
    async createQuickRoom() {
      this.loading = true
      this.error = ''
      
      try {
        const result = await roomsAPI.createRoom({
          name: `Conversación rápida - ${this.creatorName}`,
          max_participants: 2, // Solo 2 personas
          room_type: 'quick'
        })
        
        console.log('Sala rápida creada:', result)
        
        // Redirigir a la sala rápida
        this.$router.push({
          name: 'QuickRoom',
          params: { roomId: result.room_id },
          query: { name: this.creatorName }
        })
      } catch (error) {
        this.error = error.message || 'Error al crear la sala rápida'
        console.error('Error:', error)
      } finally {
        this.loading = false
      }
    },
    
    /**
     * Unirse a una sala rápida existente
     */
    async joinQuickRoom() {
      this.loading = true
      this.error = ''
      
      try {
        // Redirigir directamente a la sala rápida
        this.$router.push({
          name: 'QuickRoom',
          params: { roomId: this.joinData.roomId.toUpperCase() },
          query: { name: this.joinData.name }
        })
      } catch (error) {
        this.error = error.message || 'Error al unirse a la sala'
        console.error('Error:', error)
      } finally {
        this.loading = false
      }
    }
  },
  
  watch: {
    // Convertir roomId a mayúsculas automáticamente
    'joinData.roomId'(newValue) {
      this.joinData.roomId = newValue.toUpperCase()
    }
  }
}
</script>

<style scoped>
/* ============================================
   LAYOUT PRINCIPAL - Tema Naranja/Amarillo
   ============================================ */
.create-quick-room {
  min-height: 100vh;
  background: linear-gradient(135deg, #1a0828 0%, #2d1b69 50%, #1a0828 100%);
  padding: 2rem;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  color: white;
}

.quick-container {
  max-width: 1200px;
  margin: 0 auto;
}

/* ============================================
   BOTÓN DE REGRESAR
   ============================================ */
.back-btn {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(245, 158, 11, 0.3);
  border-radius: 0.75rem;
  padding: 0.75rem 1.5rem;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 2rem;
  font-size: 0.95rem;
}

.back-btn:hover {
  background: rgba(245, 158, 11, 0.2);
  border-color: rgba(245, 158, 11, 0.5);
  transform: translateX(-5px);
}

.back-icon {
  font-size: 1.2rem;
}

/* ============================================
   HEADER
   ============================================ */
.quick-header {
  text-align: center;
  margin-bottom: 3rem;
}

.header-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
  filter: drop-shadow(0 0 20px rgba(245, 158, 11, 0.5));
}

.quick-title {
  font-size: 2.5rem;
  font-weight: 800;
  margin: 0 0 0.5rem 0;
  background: linear-gradient(135deg, #f59e0b, #d97706);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.quick-subtitle {
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
}

/* ============================================
   SWITCH CONTAINER - Tema naranja
   ============================================ */
.switch-container {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  background: rgba(255, 255, 255, 0.05);
  padding: 0.5rem;
  border-radius: 1rem;
  border: 1px solid rgba(245, 158, 11, 0.2);
}

.switch-btn {
  flex: 1;
  background: transparent;
  border: none;
  border-radius: 0.75rem;
  padding: 1rem;
  color: rgba(255, 255, 255, 0.6);
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
}

.switch-btn:hover {
  background: rgba(245, 158, 11, 0.1);
  color: rgba(255, 255, 255, 0.9);
}

.switch-btn.active {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: white;
  box-shadow: 0 8px 20px rgba(245, 158, 11, 0.4);
}

.switch-icon {
  font-size: 1.2rem;
}

/* ============================================
   LAYOUT DE 2 COLUMNAS
   ============================================ */
.content-wrapper {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  align-items: start;
}

/* ============================================
   CONTENT CARD
   ============================================ */
.content-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(245, 158, 11, 0.2);
  border-radius: 1.5rem;
  padding: 2.5rem;
}

.mode-content {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ============================================
   MODE HEADER
   ============================================ */
.mode-header {
  text-align: center;
  margin-bottom: 2rem;
}

.mode-header h2 {
  font-size: 1.75rem;
  font-weight: 700;
  margin: 0 0 0.5rem 0;
  color: white;
}

.mode-header p {
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
}

/* ============================================
   FORMULARIO
   ============================================ */
.form-content {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.95rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
}

.label-icon {
  font-size: 1.1rem;
}

.form-input {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(245, 158, 11, 0.3);
  border-radius: 0.75rem;
  padding: 1rem;
  color: white;
  font-size: 1rem;
  transition: all 0.3s ease;
}

.form-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.form-input:focus {
  outline: none;
  border-color: #f59e0b;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2);
  background: rgba(255, 255, 255, 0.12);
}

.code-input {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-weight: 600;
  text-align: center;
  font-size: 1.5rem;
}

.input-hint {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.5);
  margin-top: 0.25rem;
}

/* ============================================
   INFO AUTOMÁTICA
   ============================================ */
.auto-config-info {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  background: rgba(245, 158, 11, 0.1);
  border: 1px solid rgba(245, 158, 11, 0.3);
  border-radius: 0.75rem;
  padding: 1rem;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.9);
}

.info-icon {
  font-size: 1.2rem;
}

/* ============================================
   BOTONES DE SUBMIT
   ============================================ */
.submit-btn {
  padding: 1.25rem;
  border: none;
  border-radius: 0.75rem;
  font-weight: 700;
  font-size: 1.1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  margin-top: 1rem;
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.create-btn {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: white;
}

.create-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 15px 35px rgba(245, 158, 11, 0.4);
}

.join-btn {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
}

.join-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 15px 35px rgba(16, 185, 129, 0.4);
}

.btn-icon {
  font-size: 1.3rem;
}

.loading-spinner {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top: 2px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ============================================
   PANEL DE INFORMACIÓN DERECHO
   ============================================ */
.info-panel {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.preview-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(245, 158, 11, 0.2);
  border-radius: 1.5rem;
  padding: 2rem;
  animation: fadeIn 0.3s ease;
}

.preview-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.preview-icon {
  font-size: 2rem;
}

.preview-header h3 {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
  color: white;
}

.preview-illustration {
  text-align: center;
}

/* Ilustración de sala rápida 1 a 1 */
.quick-room-preview {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 2rem;
  margin-bottom: 1rem;
}

.participant-slot {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2.5rem;
  border: 3px solid rgba(245, 158, 11, 0.5);
}

.participant-slot.filled {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  box-shadow: 0 10px 30px rgba(245, 158, 11, 0.4);
  animation: pulse-quick 2s infinite;
}

.participant-slot.empty {
  background: rgba(255, 255, 255, 0.05);
  border-style: dashed;
}

@keyframes pulse-quick {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

.connection-line {
  width: 60px;
  height: 3px;
  background: linear-gradient(90deg, #f59e0b, #d97706);
  position: relative;
}

.connection-line::after {
  content: '⚡';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 1.5rem;
  animation: bolt-pulse 1.5s infinite;
}

@keyframes bolt-pulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 1; }
}

/* Join preview con tema quick */
.join-preview {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1.5rem;
  padding: 2rem;
  margin-bottom: 1rem;
}

.join-icon {
  font-size: 3rem;
  animation: float 2s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.join-arrow {
  font-size: 2.5rem;
  color: #f59e0b;
  animation: slide-right 1.5s ease-in-out infinite;
}

@keyframes slide-right {
  0%, 100% { transform: translateX(0); opacity: 0.5; }
  50% { transform: translateX(10px); opacity: 1; }
}

.join-room.quick {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  box-shadow: 0 10px 30px rgba(245, 158, 11, 0.4);
  width: 80px;
  height: 80px;
  border-radius: 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.room-icon {
  font-size: 2.5rem;
}

.preview-text {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  line-height: 1.5;
}

/* ============================================
   LISTA DE CARACTERÍSTICAS
   ============================================ */
.features-list {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(245, 158, 11, 0.2);
  border-radius: 1.5rem;
  padding: 1.5rem;
}

.features-title {
  font-size: 1.1rem;
  font-weight: 700;
  margin: 0 0 1rem 0;
  color: white;
}

.feature-items {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.feature-item-small {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.8);
}

.feature-check {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.85rem;
  flex-shrink: 0;
}

.feature-check.quick {
  background: linear-gradient(135deg, #f59e0b, #d97706);
}

/* ============================================
   INFO BADGES
   ============================================ */
.info-badge-box {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.info-badge-inline {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  background: rgba(139, 92, 246, 0.15);
  border: 1px solid rgba(139, 92, 246, 0.3);
  padding: 0.75rem 1rem;
  border-radius: 0.75rem;
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.9);
}

.info-badge-inline.quick {
  background: rgba(245, 158, 11, 0.15);
  border-color: rgba(245, 158, 11, 0.3);
}

.badge-icon-small {
  font-size: 1.25rem;
}

/* ============================================
   ERROR TOAST
   ============================================ */
.error-toast {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  background: rgba(239, 68, 68, 0.15);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(239, 68, 68, 0.4);
  border-radius: 1rem;
  padding: 1rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  animation: slideInUp 0.3s ease;
  z-index: 1000;
  max-width: 400px;
}

@keyframes slideInUp {
  from { transform: translateY(100%); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

.error-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
}

.error-icon {
  font-size: 1.5rem;
}

.error-text {
  font-size: 0.95rem;
  color: white;
}

.error-close {
  background: none;
  border: none;
  color: white;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0.25rem;
  transition: opacity 0.2s;
}

.error-close:hover {
  opacity: 0.7;
}

/* ============================================
   RESPONSIVE
   ============================================ */
@media (max-width: 1024px) {
  .content-wrapper {
    grid-template-columns: 1fr;
  }
  
  .info-panel {
    order: 1;
  }
}

@media (max-width: 768px) {
  .create-quick-room {
    padding: 1rem;
  }
  
  .quick-container {
    padding: 0;
  }
  
  .quick-title {
    font-size: 2rem;
  }
  
  .content-card {
    padding: 1.5rem;
  }
  
  .switch-container {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .error-toast {
    bottom: 1rem;
    right: 1rem;
    left: 1rem;
    max-width: none;
  }
}
</style>