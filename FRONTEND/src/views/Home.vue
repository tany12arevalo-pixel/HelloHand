<template>
  <div class="min-vh-100 bg-light">
    <!-- Header -->
    <header class="bg-primary text-white shadow">
      <div class="container py-4">
        <h1 class="display-4 fw-bold mb-2">HelloHand</h1>
        <p class="lead text-light">Traductor de lenguaje de señas en tiempo real</p>
      </div>
    </header>

    <!-- Main Content -->
    <main class="container py-5">
      <div class="row g-4">
        
        <!-- Crear Sala -->
        <div class="col-md-6">
          <div class="card shadow-sm">
            <div class="card-body">
              <h2 class="card-title h4 mb-4">Crear Nueva Sala</h2>
              <form @submit.prevent="createRoom">
                <div class="mb-3">
                  <label class="form-label">Nombre de la sala</label>
                  <input 
                    v-model="newRoom.name"
                    type="text" 
                    class="form-control"
                    placeholder="Mi sala de HelloHand"
                  >
                </div>
                
                <div class="mb-3">
                  <label class="form-label">Máximo participantes</label>
                  <select v-model="newRoom.maxParticipants" class="form-select">
                    <option value="5">5 participantes</option>
                    <option value="10">10 participantes</option>
                    <option value="20">20 participantes</option>
                  </select>
                </div>

                <button 
                  type="submit" 
                  :disabled="loading"
                  class="btn btn-primary w-100"
                >
                  <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
                  {{ loading ? 'Creando...' : 'Crear Sala' }}
                </button>
              </form>
            </div>
          </div>
        </div>

        <!-- Unirse a Sala -->
        <div class="col-md-6">
          <div class="card shadow-sm">
            <div class="card-body">
              <h2 class="card-title h4 mb-4">Unirse a Sala</h2>
              <form @submit.prevent="joinRoom">
                <div class="mb-3">
                  <label class="form-label">ID de la sala</label>
                  <input 
                    v-model="joinData.roomId"
                    type="text" 
                    class="form-control text-uppercase"
                    placeholder="ABC123"
                    maxlength="6"
                  >
                </div>
                
                <div class="mb-3">
                  <label class="form-label">Tu nombre</label>
                  <input 
                    v-model="joinData.name"
                    type="text" 
                    class="form-control"
                    placeholder="Juan Pérez"
                  >
                </div>

                <button 
                  type="submit" 
                  :disabled="loading || !joinData.roomId"
                  class="btn btn-success w-100"
                >
                  <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
                  {{ loading ? 'Uniéndose...' : 'Unirse a Sala' }}
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>

      <!-- Error Message -->
      <div v-if="error" class="alert alert-danger mt-4" role="alert">
        {{ error }}
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
          params: { roomId: result.room_id }
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