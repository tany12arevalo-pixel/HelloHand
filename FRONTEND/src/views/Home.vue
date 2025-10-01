<!-- src/views/Home.vue -->
<template>
  <div class="hello-hand-landing">
    <div class="landing-container">
      <!-- Header completo -->
      <header class="landing-header">
        <div class="brand-section">
          <img src="@/assets/Logo.png" alt="HelloHand Logo" class="brand-logo">
          <div class="brand-text">
            <h1 class="brand-title">HelloHand</h1>
            <p class="brand-slogan">Conectando al mundo sin barreras.</p>
          </div>
        </div>
      </header>

      <!-- Contenido principal en grid -->
      <main class="main-content">
          <!-- Columna derecha - Navegación -->
        <div class="navigation-section">
          <h2 class="section-title">Elige tu modalidad</h2>
          
          <div class="navigation-buttons">
            <button @click="goToQuickConversation" class="nav-btn quick-btn">
              <div class="btn-icon">⚡</div>
              <div class="btn-content">
                <h3>Conversación Rápida</h3>
                <p>Chat instantáneo entre 2 personas</p>
                <span class="btn-badge">1 a 1</span>
              </div>
              <div class="btn-arrow">→</div>
            </button>

            <button @click="goToGroupMenu" class="nav-btn group-btn">
              <div class="btn-icon">👥</div>
              <div class="btn-content">
                <h3>Conversación Grupal</h3>
                <p>Crea o únete a una sala grupal</p>
                <span class="btn-badge">Hasta 10 personas</span>
              </div>
              <div class="btn-arrow">→</div>
            </button>
          </div>

          <div class="quick-info">
            <div class="info-badge">
              <span class="badge-icon">ℹ️</span>
              <span>No requiere registro ni instalación</span>
            </div>
          </div>
        </div>


        <!-- Columna izquierda - Info -->
        <div class="info-section">
          <div class="info-card">
            <h2 class="info-title">¿Qué es HelloHand?</h2>
            <p class="info-text">
              Una plataforma de videollamadas diseñada para la comunicación inclusiva, 
              permitiendo que personas sordas, mudas y oyentes se conecten sin barreras.
            </p>
          </div>

          <div class="features-grid">
            <div class="feature-item">
              <div class="feature-icon">🤟</div>
              <h3>Traducción de Señas</h3>
              <p>Reconocimiento en tiempo real de lenguaje de señas</p>
            </div>
            
            <div class="feature-item">
              <div class="feature-icon">🎤</div>
              <h3>Voz a Texto</h3>
              <p>Convierte tu voz en mensajes de texto automáticamente</p>
            </div>
            
            <div class="feature-item">
              <div class="feature-icon">🔊</div>
              <h3>Texto a Voz</h3>
              <p>Lee los mensajes en voz alta para mayor accesibilidad</p>
            </div>
            
            <div class="feature-item">
              <div class="feature-icon">📹</div>
              <h3>Videollamadas HD</h3>
              <p>Comunicación visual clara y fluida</p>
            </div>
          </div>

          <div class="info-card stats-card">
            <div class="stat-item">
              <div class="stat-number">3</div>
              <div class="stat-label">Señas Disponibles</div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-item">
              <div class="stat-number">10+</div>
              <div class="stat-label">Participantes por Sala</div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-item">
              <div class="stat-number">100%</div>
              <div class="stat-label">Gratis</div>
            </div>
          </div>
        </div>
      </main>

      <!-- Footer -->
      <footer class="landing-footer">
        <p class="footer-text">HelloHand - Proyecto de comunicación inclusiva</p>
        <div class="footer-tags">
          <span class="footer-tag">Tecnología</span>
          <span class="footer-tag">Accesibilidad</span>
          <span class="footer-tag">Inclusión</span>
        </div>
      </footer>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HomeView',
  methods: {
    goToQuickConversation() {
      this.$router.push('/create-quick')
    },
    
    goToGroupMenu() {
      this.$router.push('/menu-grupal')
    }
  }
}
</script>

<style scoped>
.hello-hand-landing {
  min-height: 100vh;
  background: linear-gradient(135deg, #1a0828 0%, #2d1b69 50%, #1a0828 100%);
  padding: 2rem;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  color: white;
}

.landing-container {
  max-width: 1600px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 4rem);
}

/* Header */
.landing-header {
  margin-bottom: 3rem;
}

.brand-section {
  display: flex;
  align-items: center;
  gap: 2rem;
  justify-content: center;
}

.brand-logo {
  width: 100px;
  height: 100px;
  filter: drop-shadow(0 10px 30px rgba(139, 92, 246, 0.4));
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-10px); }
}

.brand-text {
  text-align: left;
}

.brand-title {
  font-size: 4rem;
  font-weight: 800;
  margin: 0 0 0.5rem 0;
  background: linear-gradient(135deg, #8b5cf6, #ae00ff, #8b5cf6);
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

.brand-slogan {
  font-size: 1.5rem;
  color: rgba(255, 255, 255, 0.8);
  font-weight: 300;
  margin: 0;
}

/* Main Content Grid */
.main-content {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 3rem;
  margin-bottom: 3rem;
}

/* Info Section */
.info-section {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.info-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 1.5rem;
  padding: 2rem;
}

.info-title {
  font-size: 2rem;
  font-weight: 700;
  margin: 0 0 1rem 0;
  background: linear-gradient(135deg, #8b5cf6, #e879f9);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.info-text {
  font-size: 1.1rem;
  line-height: 1.6;
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
}

/* Features Grid */
.features-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
}

.feature-item {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(139, 92, 246, 0.2);
  border-radius: 1rem;
  padding: 1.5rem;
  transition: all 0.3s ease;
}

.feature-item:hover {
  transform: translateY(-5px);
  border-color: rgba(139, 92, 246, 0.5);
  box-shadow: 0 10px 30px rgba(139, 92, 246, 0.3);
}

.feature-icon {
  font-size: 2.5rem;
  margin-bottom: 0.75rem;
}

.feature-item h3 {
  font-size: 1.1rem;
  font-weight: 600;
  margin: 0 0 0.5rem 0;
}

.feature-item p {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  line-height: 1.4;
}

/* Stats Card */
.stats-card {
  display: flex;
  justify-content: space-around;
  align-items: center;
  padding: 2rem;
}

.stat-item {
  text-align: center;
}

.stat-number {
  font-size: 2.5rem;
  font-weight: 800;
  background: linear-gradient(135deg, #8b5cf6, #e879f9);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.7);
}

.stat-divider {
  width: 1px;
  height: 60px;
  background: rgba(139, 92, 246, 0.3);
}

/* Navigation Section */
.navigation-section {
  display: flex;
  flex-direction: column;
}

.section-title {
  font-size: 2rem;
  font-weight: 700;
  margin: 0 0 2rem 0;
  text-align: center;
  color: white;
}

.navigation-buttons {
  display: flex;
  flex-direction: column;
  gap: 2rem;
  flex: 1;
}

.nav-btn {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(20px);
  border: 2px solid rgba(139, 92, 246, 0.3);
  border-radius: 1.5rem;
  padding: 2.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 2rem;
  text-align: left;
  position: relative;
  overflow: hidden;
}

.nav-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.1), rgba(232, 121, 249, 0.1));
  opacity: 0;
  transition: opacity 0.3s ease;
}

.nav-btn:hover::before {
  opacity: 1;
}

.nav-btn:hover {
  transform: translateY(-8px);
  border-color: rgba(139, 92, 246, 0.6);
  box-shadow: 0 20px 40px rgba(139, 92, 246, 0.3);
}

.btn-icon {
  font-size: 4rem;
  width: 100px;
  height: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 1.5rem;
  flex-shrink: 0;
  position: relative;
  z-index: 2;
}

.quick-btn .btn-icon {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  box-shadow: 0 8px 25px rgba(245, 158, 11, 0.4);
}

.group-btn .btn-icon {
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  box-shadow: 0 8px 25px rgba(139, 92, 246, 0.4);
}

.btn-content {
  flex: 1;
  position: relative;
  z-index: 2;
}

.btn-content h3 {
  margin: 0 0 0.75rem 0;
  font-size: 2rem;
  font-weight: 700;
  color: white;
}

.btn-content p {
  margin: 0 0 1rem 0;
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.7);
}

.btn-badge {
  display: inline-block;
  background: rgba(139, 92, 246, 0.3);
  border: 1px solid rgba(139, 92, 246, 0.5);
  padding: 0.5rem 1rem;
  border-radius: 2rem;
  font-size: 0.9rem;
  font-weight: 600;
}

.btn-arrow {
  font-size: 3rem;
  color: rgba(255, 255, 255, 0.5);
  position: relative;
  z-index: 2;
  transition: all 0.3s ease;
}

.nav-btn:hover .btn-arrow {
  transform: translateX(10px);
  color: rgba(255, 255, 255, 0.9);
}

.quick-info {
  margin-top: 2rem;
  text-align: center;
}

.info-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.75rem;
  background: rgba(16, 185, 129, 0.2);
  border: 1px solid rgba(16, 185, 129, 0.4);
  padding: 1rem 2rem;
  border-radius: 3rem;
  font-size: 1.1rem;
  font-weight: 500;
}

.badge-icon {
  font-size: 1.5rem;
}

/* Footer */
.landing-footer {
  text-align: center;
  padding-top: 2rem;
  border-top: 1px solid rgba(139, 92, 246, 0.2);
}

.footer-text {
  margin: 0 0 1rem 0;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.95rem;
}

.footer-tags {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.footer-tag {
  background: rgba(139, 92, 246, 0.2);
  border: 1px solid rgba(139, 92, 246, 0.4);
  padding: 0.5rem 1rem;
  border-radius: 2rem;
  font-size: 0.85rem;
}

/* Responsive */
@media (max-width: 1200px) {
  .main-content {
    grid-template-columns: 1fr;
  }
  
  .features-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .brand-section {
    flex-direction: column;
    text-align: center;
  }
  
  .brand-text {
    text-align: center;
  }
  
  .brand-title {
    font-size: 2.5rem;
  }
  
  .brand-slogan {
    font-size: 1.1rem;
  }
  
  .features-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-card {
    flex-direction: column;
    gap: 2rem;
  }
  
  .stat-divider {
    width: 100px;
    height: 1px;
  }
  
  .nav-btn {
    flex-direction: column;
    text-align: center;
  }
  
  .btn-content h3 {
    font-size: 1.5rem;
  }
}
</style>