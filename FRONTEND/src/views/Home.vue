<!-- src/views/Home.vue -->
<template>
  <div class="hello-hand-app">
    <!-- Header Principal -->
    <header class="app-header">
      <div class="container">
        <div class="header-content">
          <div class="logo-section">
            <h1 class="app-title">
              👋 HelloHand 🤟
            </h1>
            <p class="app-subtitle">Traductor de Lenguaje de Señas en Tiempo Real</p>
            <div class="feature-tags">
              <span class="tag">Tecnología</span>
              <span class="tag">Lingüística</span>
              <span class="tag">Programación</span>
            </div>
          </div>
        </div>
        
        <!-- Estado de conexión -->
        <div class="connection-status">
          <div class="status-item">
            <div class="status-indicator active"></div>
            <span>Backend: Conectado</span>
          </div>
          <div class="status-item">
            <div class="status-indicator active"></div>
            <span>Modelo: Cargado ✓</span>
          </div>
          <button class="verify-btn">Verificar Conexión</button>
        </div>
      </div>
    </header>

    <!-- Contenido Principal -->
    <main class="main-content">
      <div class="container">
        <div class="cards-grid">
          
          <!-- Crear Sala -->
          <div class="feature-card">
            <div class="card-header">
              <div class="card-icon">📝</div>
              <h2>Crear Sala Nueva</h2>
            </div>
            <div class="card-body">
              <form @submit.prevent="createRoom" class="room-form">
                <div class="form-group">
                  <label>Nombre de la sala:</label>
                  <input 
                    v-model="newRoom.name"
                    type="text" 
                    class="form-input"
                    placeholder="Mi conferencia HelloHand"
                  >
                </div>
                
                <div class="form-group">
                  <label>Máximo participantes:</label>
                  <select v-model="newRoom.maxParticipants" class="form-select">
                    <option value="5">5 participantes</option>
                    <option value="10">10 participantes</option>
                    <option value="20">20 participantes</option>
                  </select>
                </div>

                <button 
                  type="submit" 
                  :disabled="loading"
                  class="btn btn-primary"
                >
                  <span v-if="loading" class="loading-spinner"></span>
                  {{ loading ? 'Creando...' : 'Crear Sala' }}
                </button>
              </form>
            </div>
          </div>

          <!-- Unirse a Sala -->
          <div class="feature-card">
            <div class="card-header">
              <div class="card-icon">🔗</div>
              <h2>Unirse a Sala</h2>
            </div>
            <div class="card-body">
              <form @submit.prevent="joinRoom" class="room-form">
                <div class="form-group">
                  <label>ID de la sala:</label>
                  <input 
                    v-model="joinData.roomId"
                    type="text" 
                    class="form-input"
                    placeholder="ABC123"
                    maxlength="6"
                    style="text-transform: uppercase;"
                  >
                </div>
                
                <div class="form-group">
                  <label>Tu nombre:</label>
                  <input 
                    v-model="joinData.name"
                    type="text" 
                    class="form-input"
                    placeholder="Juan Pérez"
                  >
                </div>

                <button 
                  type="submit" 
                  :disabled="loading || !joinData.roomId"
                  class="btn btn-secondary"
                >
                  <span v-if="loading" class="loading-spinner"></span>
                  {{ loading ? 'Uniéndose...' : 'Unirse a Sala' }}
                </button>
              </form>
            </div>
          </div>
        </div>

        <!-- Señas Disponibles -->
        <div class="available-signs">
          <div class="signs-header">
            <div class="signs-icon">🤟</div>
            <h3>Señas Disponibles</h3>
          </div>
          <div class="signs-list">
            <span class="sign-tag">tonto</span>
            <span class="sign-tag">mal</span>
            <span class="sign-tag">bien</span>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="error" class="error-message">
          <div class="error-icon">⚠️</div>
          <span>{{ error }}</span>
          <button @click="error = ''" class="error-close">✕</button>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import { roomsAPI } from '@/services/api'

export default {
  name: 'HomeView',
  data() {
    return {
      loading: false,
      error: '',
      newRoom: {
        name: '',
        maxParticipants: 10
      },
      joinData: {
        roomId: '',
        name: ''
      }
    }
  },
  methods: {
    async createRoom() {
      this.loading = true
      this.error = ''
      
      try {
        const result = await roomsAPI.createRoom(this.newRoom)
        console.log('Sala creada:', result)
        
        // Redirigir a la sala creada
        this.$router.push({
          name: 'Room',
          params: { roomId: result.room_id },
          query: { name: 'Creador' }
        })
      } catch (error) {
        this.error = error.message
      } finally {
        this.loading = false
      }
    },

    async joinRoom() {
      this.loading = true
      this.error = ''
      
      try {
        // Redirigir a la sala con datos del participante
        this.$router.push({
          name: 'Room',
          params: { roomId: this.joinData.roomId.toUpperCase() },
          query: { name: this.joinData.name }
        })
      } catch (error) {
        this.error = error.message
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
.hello-hand-app {
  min-height: 100vh;
  background: linear-gradient(135deg, #1a0828 0%, #2d1b69 50%, #1a0828 100%);
  color: white;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
}

/* Header */
.app-header {
  padding: 3rem 0;
  text-align: center;
  position: relative;
}

.app-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: radial-gradient(ellipse at center, rgba(139, 92, 246, 0.1) 0%, transparent 70%);
  pointer-events: none;
}

.header-content {
  position: relative;
  z-index: 2;
}

.app-title {
  font-size: 3.5rem;
  font-weight: 800;
  margin: 0 0 1rem 0;
  background: linear-gradient(135deg, #8b5cf6, #e879f9, #8b5cf6);
  background-size: 200% 200%;
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: gradient-shift 3s ease-in-out infinite;
}

@keyframes gradient-shift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

.app-subtitle {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.8);
  margin: 0 0 2rem 0;
  font-weight: 300;
}

.feature-tags {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.tag {
  background: rgba(139, 92, 246, 0.2);
  border: 1px solid rgba(139, 92, 246, 0.4);
  padding: 0.5rem 1rem;
  border-radius: 2rem;
  font-size: 0.9rem;
  backdrop-filter: blur(10px);
}

/* Estado de conexión */
.connection-status {
  margin-top: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2rem;
  flex-wrap: wrap;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.7);
}

.status-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #10b981;
  box-shadow: 0 0 10px #10b981;
}

.status-indicator.active {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.verify-btn {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  color: white;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.verify-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(139, 92, 246, 0.4);
}

/* Contenido principal */
.main-content {
  padding: 2rem 0 4rem 0;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 2rem;
  margin-bottom: 3rem;
}

/* Tarjetas */
.feature-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 1.5rem;
  padding: 2rem;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.feature-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.1), rgba(232, 121, 249, 0.1));
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}

.feature-card:hover::before {
  opacity: 1;
}

.feature-card:hover {
  transform: translateY(-8px);
  border-color: rgba(139, 92, 246, 0.4);
  box-shadow: 0 20px 40px rgba(139, 92, 246, 0.2);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  position: relative;
  z-index: 2;
}

.card-icon {
  font-size: 2rem;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #8b5cf6, #e879f9);
  border-radius: 1rem;
  box-shadow: 0 8px 25px rgba(139, 92, 246, 0.3);
}

.card-header h2 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
}

.card-body {
  position: relative;
  z-index: 2;
}

/* Formularios */
.room-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-weight: 500;
  color: rgba(255, 255, 255, 0.9);
  font-size: 0.95rem;
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
  backdrop-filter: blur(10px);
}

.form-input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.form-input:focus,
.form-select:focus {
  outline: none;
  border-color: #8b5cf6;
  box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.2);
  background: rgba(255, 255, 255, 0.12);
}

.form-select option {
  background: #2d1b69;
  color: white;
}

/* Botones */
.btn {
  padding: 1rem 2rem;
  border: none;
  border-radius: 0.75rem;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 15px 35px rgba(139, 92, 246, 0.4);
}

.btn-secondary {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 15px 35px rgba(99, 102, 241, 0.4);
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

/* Señas disponibles */
.available-signs {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 1.5rem;
  padding: 2rem;
  text-align: center;
}

.signs-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.signs-icon {
  font-size: 2rem;
}

.signs-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
}

.signs-list {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.sign-tag {
  background: rgba(139, 92, 246, 0.2);
  border: 1px solid rgba(139, 92, 246, 0.4);
  padding: 0.5rem 1rem;
  border-radius: 2rem;
  font-size: 0.9rem;
  font-weight: 500;
}

/* Error message */
.error-message {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 1rem;
  padding: 1rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-top: 2rem;
  backdrop-filter: blur(10px);
}

.error-icon {
  font-size: 1.5rem;
}

.error-close {
  background: none;
  border: none;
  color: white;
  font-size: 1.2rem;
  cursor: pointer;
  margin-left: auto;
  padding: 0.25rem;
  border-radius: 0.25rem;
  transition: background 0.2s ease;
}

.error-close:hover {
  background: rgba(255, 255, 255, 0.1);
}

/* Responsive */
@media (max-width: 768px) {
  .container {
    padding: 0 1rem;
  }
  
  .app-title {
    font-size: 2.5rem;
  }
  
  .cards-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
  
  .feature-card {
    padding: 1.5rem;
  }
  
  .connection-status {
    flex-direction: column;
    gap: 1rem;
  }
}
</style>