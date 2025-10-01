<!-- src/views/MenuGrupal.vue -->
<template>
    <div class="menu-grupal">
        <div class="menu-container">
            <!-- Botón de regresar -->
            <button @click="goBack" class="back-btn">
                <span class="back-icon">←</span>
                Volver
            </button>

            <!-- Header -->
            <div class="menu-header">
                <div class="header-icon">👥</div>
                <h1 class="menu-title">Conversación Grupal</h1>
                <p class="menu-subtitle">Elige una opción para comenzar</p>
            </div>

            <!-- Switch para alternar entre crear y unirse -->
            <div class="switch-container">
                <button :class="['switch-btn', { active: activeMode === 'create' }]" @click="activeMode = 'create'">
                    <span class="switch-icon">📝</span>
                    Crear Sala
                </button>
                <button :class="['switch-btn', { active: activeMode === 'join' }]" @click="activeMode = 'join'">
                    <span class="switch-icon">🔗</span>
                    Unirse a Sala
                </button>
            </div>

            <!-- Contenido dinámico según el modo -->
            <div class="content-wrapper">
                <!-- Columna izquierda: Formulario -->
                <div class="content-card">
                    <!-- MODO CREAR SALA -->
                    <div v-if="activeMode === 'create'" class="mode-content">
                        <div class="mode-header">
                            <h2>Crear Nueva Sala</h2>
                            <p>Configura tu sala grupal y comparte el código con otros</p>
                        </div>

                        <form @submit.prevent="createRoom" class="form-content">
                            <!-- Nombre de la sala -->
                            <div class="form-group">
                                <label class="form-label">
                                    <span class="label-icon">📌</span>
                                    Nombre de la sala (opcional)
                                </label>
                                <input v-model="newRoom.name" type="text" class="form-input"
                                    placeholder="Ej: Reunión de equipo" maxlength="50">
                            </div>

                            <!-- Máximo de participantes -->
                            <div class="form-group">
                                <label class="form-label">
                                    <span class="label-icon">👥</span>
                                    Máximo de participantes
                                </label>
                                <select v-model="newRoom.maxParticipants" class="form-select">
                                    <option value="5">5 participantes</option>
                                    <option value="10">10 participantes</option>
                                    <option value="15">15 participantes</option>
                                    <option value="20">20 participantes</option>
                                </select>
                            </div>

                            <!-- Botón submit -->
                            <button type="submit" :disabled="loading" class="submit-btn create-btn">
                                <span v-if="loading" class="loading-spinner"></span>
                                <span v-else class="btn-icon">✨</span>
                                {{ loading ? 'Creando...' : 'Crear Sala' }}
                            </button>
                        </form>
                    </div>

                    <!-- MODO UNIRSE A SALA -->
                    <div v-else class="mode-content">
                        <div class="mode-header">
                            <h2>Unirse a una Sala</h2>
                            <p>Ingresa el código de 6 caracteres de la sala</p>
                        </div>

                        <form @submit.prevent="joinRoom" class="form-content">
                            <!-- Tu nombre -->
                            <div class="form-group">
                                <label class="form-label">
                                    <span class="label-icon">👤</span>
                                    Tu nombre
                                </label>
                                <input v-model="joinData.name" type="text" class="form-input"
                                    placeholder="Ej: Juan Pérez" maxlength="50" required>
                            </div>

                            <!-- Código de sala -->
                            <div class="form-group">
                                <label class="form-label">
                                    <span class="label-icon">🔑</span>
                                    Código de la sala
                                </label>
                                <input v-model="joinData.roomId" type="text" class="form-input code-input"
                                    placeholder="ABC123" maxlength="6" required>
                                <small class="input-hint">6 caracteres alfanuméricos</small>
                            </div>

                            <!-- Botón submit -->
                            <button type="submit" :disabled="loading || !joinData.roomId || !joinData.name"
                                class="submit-btn join-btn">
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
                            <span class="preview-icon">{{ activeMode === 'create' ? '✨' : '🚀' }}</span>
                            <h3>{{ activeMode === 'create' ? 'Modo Creador' : 'Modo Invitado' }}</h3>
                        </div>
                        <div class="preview-content">
                            <div v-if="activeMode === 'create'" class="preview-illustration">
                                <div class="room-preview">
                                    <div class="room-code">ABC123</div>
                                    <div class="room-participants">
                                        <div class="participant-dot active"></div>
                                        <div class="participant-dot"></div>
                                        <div class="participant-dot"></div>
                                    </div>
                                </div>
                                <p class="preview-text">Se generará un código único que podrás compartir</p>
                            </div>
                            <div v-else class="preview-illustration">
                                <div class="join-preview">
                                    <div class="join-icon">🔐</div>
                                    <div class="join-arrow">→</div>
                                    <div class="join-room">
                                        <div class="room-icon">👥</div>
                                    </div>
                                </div>
                                <p class="preview-text">Ingresa el código para unirte instantáneamente</p>
                            </div>
                        </div>
                    </div>

                    <!-- Features del modo actual -->
                    <div class="features-list">
                        <h4 class="features-title">Características:</h4>
                        <div v-if="activeMode === 'create'" class="feature-items">
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>Eres el host de la sala</span>
                            </div>
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>Código único generado</span>
                            </div>
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>Control de participantes</span>
                            </div>
                        </div>
                        <div v-else class="feature-items">
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>Acceso instantáneo</span>
                            </div>
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>No requiere registro</span>
                            </div>
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>Solo necesitas el código</span>
                            </div>
                            <div class="feature-item-small">
                                <span class="feature-check">✓</span>
                                <span>Únete en segundos</span>
                            </div>
                        </div>
                    </div>

                    <!-- Info adicional -->
                    <div class="info-badge-box">
                        <div class="info-badge-inline">
                            <span class="badge-icon-small">🤟</span>
                            <span>Traducción de señas</span>
                        </div>
                        <div class="info-badge-inline">
                            <span class="badge-icon-small">🎤</span>
                            <span>Voz a texto</span>
                        </div>
                        <div class="info-badge-inline">
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
    name: 'MenuGrupal',

    data() {
        return {
            // Modo activo: 'create' o 'join'
            activeMode: 'create',

            // Estado de carga
            loading: false,
            error: '',

            // Datos para crear sala
            newRoom: {
                name: '',
                maxParticipants: 10
            },

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
         * Crear una nueva sala grupal
         */
        async createRoom() {
            this.loading = true
            this.error = ''

            try {
                const result = await roomsAPI.createRoom({
                    name: this.newRoom.name,
                    max_participants: parseInt(this.newRoom.maxParticipants),
                    room_type: 'group'
                })

                console.log('Sala creada:', result)

                // Redirigir a la sala con nombre de creador
                this.$router.push({
                    name: 'GroupRoom',
                    params: { roomId: result.room_id },
                    query: { name: 'Creador' }
                })
            } catch (error) {
                this.error = error.message || 'Error al crear la sala'
                console.error('Error:', error)
            } finally {
                this.loading = false
            }
        },

        /**
         * Unirse a una sala existente
         */
        async joinRoom() {
            this.loading = true
            this.error = ''

            try {
                // Redirigir directamente a la sala
                // El Room.vue se encargará de llamar a joinRoom API
                this.$router.push({
                    name: 'GroupRoom',
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
   LAYOUT PRINCIPAL
   ============================================ */
.menu-grupal {
    min-height: 100vh;
    background: linear-gradient(135deg, #1a0828 0%, #2d1b69 50%, #1a0828 100%);
    padding: 2rem;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    color: white;
}

.menu-container {
    max-width: 1024px;
    margin: 0 auto;
}

/* ============================================
   BOTÓN DE REGRESAR
   ============================================ */
.back-btn {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(139, 92, 246, 0.3);
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
    background: rgba(139, 92, 246, 0.2);
    border-color: rgba(139, 92, 246, 0.5);
    transform: translateX(-5px);
}

.back-icon {
    font-size: 1.2rem;
}

/* ============================================
   HEADER
   ============================================ */
.menu-header {
    text-align: center;
    margin-bottom: 3rem;
}

.header-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
}

.menu-title {
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0 0 0.5rem 0;
    background: linear-gradient(135deg, #8b5cf6, #e879f9);
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.menu-subtitle {
    font-size: 1.1rem;
    color: rgba(255, 255, 255, 0.7);
    margin: 0;
}

/* ============================================
   SWITCH CONTAINER
   ============================================ */
.switch-container {
    display: flex;
    gap: 1rem;
    margin-bottom: 2rem;
    background: rgba(255, 255, 255, 0.05);
    padding: 0.5rem;
    border-radius: 1rem;
    border: 1px solid rgba(139, 92, 246, 0.2);
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
    background: rgba(139, 92, 246, 0.1);
    color: rgba(255, 255, 255, 0.9);
}

.switch-btn.active {
    background: linear-gradient(135deg, #8b5cf6, #a855f7);
    color: white;
    box-shadow: 0 8px 20px rgba(139, 92, 246, 0.4);
}

.switch-icon {
    font-size: 1.2rem;
}

/* ============================================
   CONTENT CARD
   ============================================ */
.content-card {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(20px);
    border: 1px solid rgba(139, 92, 246, 0.2);
    border-radius: 1.5rem;
    padding: 2.5rem;
}

.mode-content {
    animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
    from {
        opacity: 0;
        transform: translateY(10px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
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

.form-input,
.form-select {
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(139, 92, 246, 0.3);
    border-radius: 0.75rem;
    padding: 1rem;
    color: white;
    font-size: 1rem;
    transition: all 0.3s ease;
}

.form-input::placeholder {
    color: rgba(255, 255, 255, 0.4);
}

.form-input:focus,
.form-select:focus {
    outline: none;
    border-color: #8b5cf6;
    box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.2);
    background: rgba(255, 255, 255, 0.12);
}

.form-select {
    cursor: pointer;
}

.form-select option {
    background: #2d1b69;
    color: white;
}

/* Input de código especial */
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
    background: linear-gradient(135deg, #8b5cf6, #a855f7);
    color: white;
}

.create-btn:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 15px 35px rgba(139, 92, 246, 0.4);
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
    to {
        transform: rotate(360deg);
    }
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
   LAYOUT DE 2 COLUMNAS
   ============================================ */
.content-wrapper {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  align-items: start;
}

/* ============================================
   PANEL DE INFORMACIÓN DERECHO
   ============================================ */
.info-panel {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Preview Card */
.preview-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(139, 92, 246, 0.2);
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

/* Ilustración de crear sala */
.room-preview {
  background: rgba(139, 92, 246, 0.15);
  border: 2px dashed rgba(139, 92, 246, 0.5);
  border-radius: 1rem;
  padding: 2rem;
  margin-bottom: 1rem;
}

.room-code {
  font-size: 2.5rem;
  font-weight: 800;
  letter-spacing: 0.3em;
  color: #8b5cf6;
  margin-bottom: 1.5rem;
  text-shadow: 0 0 20px rgba(139, 92, 246, 0.5);
}

.room-participants {
  display: flex;
  justify-content: center;
  gap: 0.75rem;
}

.participant-dot {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: 2px solid rgba(139, 92, 246, 0.3);
  transition: all 0.3s ease;
}

.participant-dot.active {
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  border-color: #8b5cf6;
  box-shadow: 0 0 15px rgba(139, 92, 246, 0.6);
  animation: pulse-dot 2s infinite;
}

@keyframes pulse-dot {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

/* Ilustración de unirse a sala */
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

.join-arrow {
  font-size: 2.5rem;
  color: #10b981;
  animation: slide-right 1.5s ease-in-out infinite;
}

@keyframes slide-right {
  0%, 100% { transform: translateX(0); opacity: 0.5; }
  50% { transform: translateX(10px); opacity: 1; }
}

.join-room {
  width: 80px;
  height: 80px;
  border-radius: 1rem;
  background: linear-gradient(135deg, #10b981, #059669);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 10px 30px rgba(16, 185, 129, 0.4);
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
  border: 1px solid rgba(139, 92, 246, 0.2);
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
  background: linear-gradient(135deg, #10b981, #059669);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.85rem;
  flex-shrink: 0;
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

.badge-icon-small {
  font-size: 1.25rem;
}

/* ============================================
   RESPONSIVE
   ============================================ */
@media (max-width: 1024px) {
  .content-wrapper {
    grid-template-columns: 1fr;
  }
  
  .info-panel {
    order: -1; /* Mostrar info primero en móvil */
  }
}

@media (max-width: 768px) {
  .menu-grupal {
    padding: 1rem;
  }
  
  .menu-container {
    padding: 0;
  }
  
  .menu-title {
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