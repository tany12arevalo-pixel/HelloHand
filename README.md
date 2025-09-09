# HelloHand

Un proyecto de comunicación por videollamada con reconocimiento de gestos de manos usando MediaPipe, desarrollado con Django REST Framework y Vue.js.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Tecnologías Utilizadas](#tecnologías-utilizadas)
- [Prerrequisitos](#prerrequisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso](#uso)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Scripts Disponibles](#scripts-disponibles)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## ✨ Características

- 🤝 **Reconocimiento de gestos de manos** con MediaPipe Holistic
- 📹 **Videollamadas peer-to-peer** usando WebRTC
- 🔄 **Comunicación en tiempo real** con WebSockets (Django Channels)
- 🏠 **Sistema de salas** para organizar sesiones
- 🌐 **API REST** completa con Django REST Framework
- 📱 **Interfaz moderna y responsive** con Vue.js y Bootstrap
- 🔐 **Conexiones seguras** HTTPS/WSS
- 🎯 **Traducción de gestos** para comunicación inclusiva

## 🛠️ Tecnologías Utilizadas

### Backend
- **Python 3.10.12** - Lenguaje de programación principal
- **Django 4.x** - Framework web de Python
- **Django REST Framework** - API REST
- **Django Channels** - WebSockets y comunicación async
- **Daphne** - Servidor ASGI para WebSockets
- **Redis** - Cache y channel layer para WebSockets
- **SQLite** - Base de datos (desarrollo)

### Frontend  
- **Vue.js 3** - Framework progresivo de JavaScript
- **Vue Router 4** - Enrutamiento del lado del cliente
- **Bootstrap 5.3** - Framework CSS
- **Axios** - Cliente HTTP
- **Socket.io Client** - Cliente WebSocket
- **Simple Peer** - WebRTC peer-to-peer connections

### Inteligencia Artificial
- **MediaPipe** - Reconocimiento de gestos y poses
- **MediaPipe Holistic** - Detección integral del cuerpo y manos
- **OpenCV** - Procesamiento de imágenes

### Herramientas de Desarrollo
- **pyenv** - Gestión de versiones de Python
- **Vue CLI** - Herramientas de desarrollo para Vue.js
- **ESLint** - Linter para JavaScript
- **PWA** - Progressive Web App capabilities

## 📋 Prerrequisitos

Antes de comenzar, asegúrate de tener instalado:

- [Python 3.10.12](https://www.python.org/) (gestionado con pyenv)
- [pyenv](https://github.com/pyenv/pyenv) - Gestor de versiones de Python
- [Node.js](https://nodejs.org/) (versión 16 o superior)
- [npm](https://www.npmjs.com/) o [yarn](https://yarnpkg.com/)
- [Redis](https://redis.io/) - Para WebSockets en producción
- [Git](https://git-scm.com/)

### Certificados SSL (para desarrollo HTTPS)
El proyecto requiere certificados SSL para funcionar correctamente:
- `cert.pem` - Certificado SSL
- `key.pem` - Llave privada SSL

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/hellohand.git
cd hellohand
```

### 2. Configurar Python con pyenv

```bash
# Instalar Python 3.10.12 si no lo tienes
pyenv install 3.10.12

# Configurar la versión para el proyecto
pyenv local 3.10.12

# Verificar la versión
python --version  # Debe mostrar Python 3.10.12
```

### 3. Configurar el Backend (Django)

```bash
cd backend

# Crear entorno virtual
python -m venv hellohand_env

# Activar entorno virtual
# En Linux/Mac:
source hellohand_env/bin/activate
# En Windows:
# hellohand_env\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar migraciones
python manage.py makemigrations
python manage.py migrate

# Crear superusuario (opcional)
python manage.py createsuperuser
```

### 4. Configurar el Frontend (Vue.js)

```bash
cd ../frontend

# Instalar dependencias
npm install
```

### 5. Configurar Redis (Opcional para desarrollo)

```bash
# Ubuntu/Debian
sudo apt-get install redis-server

# macOS
brew install redis

# Iniciar Redis
redis-server
```

## ⚙️ Configuración

### Certificados SSL para Desarrollo

Genera certificados SSL auto-firmados para desarrollo:

```bash
cd backend

# Generar certificados SSL
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Durante la generación, usa 'localhost' como Common Name (CN)
```

### Variables de Entorno

#### Backend

El proyecto usa la configuración en `backend/hellohand/settings.py`. Para producción, crea un archivo `.env`:

```env
# Producción
SECRET_KEY=tu-secret-key-muy-seguro
DEBUG=False
ALLOWED_HOSTS=tu-dominio.com,www.tu-dominio.com

# Base de datos (para producción)
DATABASE_URL=postgresql://usuario:password@localhost:5432/hellohand_db

# Redis (para producción)
REDIS_URL=redis://localhost:6379/1

# CORS (ajustar según tu dominio)
CORS_ALLOWED_ORIGINS=https://tu-dominio.com,https://www.tu-dominio.com
```

#### Frontend

Para configuración específica, puedes crear `.env` en la carpeta `frontend`:

```env
VUE_APP_API_BASE_URL=https://127.0.0.1:8021
VUE_APP_WS_URL=wss://127.0.0.1:8021
VUE_APP_NAME=HelloHand
```

## 🏃‍♂️ Uso

### Desarrollo

#### 1. Iniciar Redis (si se usa)

```bash
redis-server
```

#### 2. Iniciar el Backend (Django)

```bash
cd backend

# Activar entorno virtual
source hellohand_env/bin/activate

# Iniciar servidor con HTTPS y WebSockets
daphne -e ssl:8021:privateKey=key.pem:certKey=cert.pem -b 127.0.0.1 hellohand.asgi:application
```

El backend estará disponible en: `https://127.0.0.1:8021`

#### 3. Iniciar el Frontend (Vue.js) - En otra terminal

```bash
cd frontend

# Iniciar servidor de desarrollo con HTTPS
npm run serve
```

El frontend estará disponible en: `https://localhost:8080`

### Comandos de Desarrollo Útiles

```bash
# Backend - Crear migraciones
python manage.py makemigrations

# Backend - Aplicar migraciones  
python manage.py migrate

# Backend - Ejecutar tests
python manage.py test

# Frontend - Build para producción
npm run build

# Frontend - Linting
npm run lint
```

## 📁 Estructura del Proyecto

```
hellohand/
├── backend/
│   ├── hellohand/                 # Configuración principal del proyecto
│   │   ├── __init__.py
│   │   ├── asgi.py               # Configuración ASGI para WebSockets
│   │   ├── settings.py           # Configuración Django
│   │   ├── urls.py               # URLs principales
│   │   └── wsgi.py               # Configuración WSGI
│   ├── rooms/                    # App de salas
│   │   ├── migrations/           # Migraciones de base de datos
│   │   ├── __init__.py
│   │   ├── admin.py              # Configuración del admin
│   │   ├── apps.py               # Configuración de la app
│   │   ├── consumers.py          # WebSocket consumers
│   │   ├── models.py             # Modelos de datos
│   │   ├── routing.py            # Routing de WebSockets
│   │   ├── tests.py              # Tests unitarios
│   │   ├── urls.py               # URLs de la app
│   │   └── views.py              # Vistas de la API
│   ├── translator/               # App de traducción (si existe)
│   │   ├── migrations/
│   │   ├── services/
│   │   ├── models.py
│   │   └── views.py
│   ├── static/                   # Archivos estáticos
│   ├── hellohand_env/           # Entorno virtual
│   ├── cert.pem                 # Certificado SSL
│   ├── key.pem                  # Llave privada SSL
│   ├── db.sqlite3               # Base de datos SQLite
│   ├── manage.py                # CLI de Django
│   └── requirements.txt         # Dependencias Python
├── frontend/
│   ├── public/                  # Archivos públicos
│   │   ├── index.html
│   │   ├── favicon.ico
│   │   └── manifest.json        # PWA manifest
│   ├── src/
│   │   ├── assets/              # Recursos (imágenes, estilos)
│   │   ├── components/          # Componentes Vue reutilizables
│   │   ├── router/              # Configuración de Vue Router
│   │   │   └── index.js
│   │   ├── services/            # Servicios API y WebSocket
│   │   ├── views/               # Páginas/Vistas principales
│   │   ├── App.vue              # Componente raíz
│   │   ├── main.js              # Punto de entrada
│   │   └── registerServiceWorker.js # PWA service worker
│   ├── babel.config.js          # Configuración Babel
│   ├── jsconfig.json           # Configuración JavaScript
│   ├── package.json            # Dependencias y scripts NPM
│   ├── package-lock.json       # Lock de dependencias
│   └── vue.config.js           # Configuración Vue CLI
├── .gitignore
├── README.md
└── requirements.txt            # Dependencias globales (si existe)
```

## 📜 Scripts Disponibles

### Backend (Django)

```bash
# Activar entorno virtual
source hellohand_env/bin/activate

# Servidor de desarrollo con WebSockets y SSL
daphne -e ssl:8021:privateKey=key.pem:certKey=cert.pem -b 127.0.0.1 hellohand.asgi:application

# Servidor de desarrollo simple (sin WebSockets)
python manage.py runserver

# Migraciones
python manage.py makemigrations
python manage.py migrate

# Tests
python manage.py test

# Crear superusuario
python manage.py createsuperuser

# Shell interactivo
python manage.py shell

# Collect static files (producción)
python manage.py collectstatic
```

### Frontend (Vue.js)

```bash
# Desarrollo con HTTPS
npm run serve

# Build para producción
npm run build

# Linting y corrección de código
npm run lint

# Instalar nueva dependencia
npm install nombre-paquete

# Actualizar dependencias
npm update
```

## 📚 API Documentation

### Endpoints Principales

#### Salas (Rooms)

```
GET    /api/rooms/          # Listar todas las salas
POST   /api/rooms/          # Crear nueva sala
GET    /api/rooms/{id}/     # Obtener sala específica
PUT    /api/rooms/{id}/     # Actualizar sala
DELETE /api/rooms/{id}/     # Eliminar sala
```

#### WebSocket Endpoints

```
ws://127.0.0.1:8021/ws/room/{room_id}/    # Conectar a sala específica
```

### Ejemplo de Uso de WebSockets

```javascript
// Conectar a una sala
const socket = io('wss://127.0.0.1:8021', {
  transports: ['websocket'],
  secure: true
});

// Unirse a una sala
socket.emit('join_room', {
  room_id: 'sala-123',
  user_id: 'usuario-456'
});

// Escuchar nuevos participantes
socket.on('user_joined', (data) => {
  console.log('Nuevo usuario:', data.user_id);
});

// Enviar datos de gestos
socket.emit('gesture_data', {
  room_id: 'sala-123',
  gesture: 'hello',
  coordinates: [x, y, z]
});
```

### Integración con MediaPipe

```javascript
// Ejemplo de configuración MediaPipe en Vue.js
import { Holistic } from '@mediapipe/holistic';
import { Camera } from '@mediapipe/camera_utils';

// Configurar MediaPipe Holistic
const holistic = new Holistic({
  locateFile: (file) => {
    return `https://cdn.jsdelivr.net/npm/@mediapipe/holistic/${file}`;
  }
});

holistic.setOptions({
  modelComplexity: 1,
  smoothLandmarks: true,
  enableSegmentation: true,
  smoothSegmentation: true,
  refineFaceLandmarks: true,
  minDetectionConfidence: 0.5,
  minTrackingConfidence: 0.5
});

// Procesar resultados
holistic.onResults((results) => {
  if (results.leftHandLandmarks || results.rightHandLandmarks) {
    // Enviar datos de gestos por WebSocket
    socket.emit('gesture_data', {
      leftHand: results.leftHandLandmarks,
      rightHand: results.rightHandLandmarks,
      timestamp: Date.now()
    });
  }
});
```

## 🚀 Deployment

### Requisitos para Producción

1. **Servidor con SSL válido** (Let's Encrypt recomendado)
2. **Base de datos PostgreSQL** (recomendado para producción)
3. **Redis** para WebSockets y caché
4. **Servidor web** (Nginx recomendado)

### Configuración con Docker

Crea un `docker-compose.yml`:

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8021:8021"
    environment:
      - DEBUG=False
      - REDIS_URL=redis://redis:6379/1
    depends_on:
      - redis
      - db

  frontend:
    build: ./frontend
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: hellohand
      POSTGRES_USER: hellohand
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Deploy en Heroku

```bash
# Instalar Heroku CLI y login
heroku login

# Crear aplicación
heroku create hellohand-app

# Configurar variables de entorno
heroku config:set SECRET_KEY=tu-secret-key
heroku config:set DEBUG=False
heroku config:set REDIS_URL=redis://...

# Agregar addons
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create heroku-redis:hobby-dev

# Deploy
git push heroku main
```

## 🔧 Troubleshooting

### Problemas Comunes

#### Error de certificados SSL
```bash
# Regenerar certificados
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

#### Error de MediaPipe en el navegador
- Asegurar que el sitio se sirva por HTTPS
- Verificar permisos de cámara y micrófono
- Comprobar que el navegador soporte WebRTC

#### Redis no conecta o no está disponible
```bash
# Verificar estado de Redis
redis-cli ping

# Reiniciar Redis
sudo systemctl restart redis-server

# Verificar logs de Redis
sudo journalctl -u redis-server -f

# Verificar puerto
netstat -tlnp | grep :6379
```

#### Error al cargar modelos de IA
- Verificar que los archivos `modelo_secuencias.pkl` y `secuencias_dataset.json` estén en `static/models/`
- Comprobar permisos de lectura en los archivos del modelo
- Verificar que las librerías de ML estén instaladas correctamente

#### Error de dependencias Python
```bash
# Reinstalar dependencias
pip freeze > requirements.txt
pip install -r requirements.txt
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -m 'Add: nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Abre un Pull Request

### Estructura de Commits

- `feat`: Nueva característica
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Cambios de formato
- `refactor`: Refactorización de código
- `test`: Añadir o modificar tests
- `chore`: Cambios en herramientas o configuración

## 📞 Soporte

Si encuentras algún problema o tienes preguntas:

- Abre un [issue](https://github.com/tu-usuario/hellohand/issues)
- Revisa la sección de [Troubleshooting](#troubleshooting)
- Contacta al equipo de desarrollo

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para más detalles.

---

⭐ **HelloHand - Comunicación inclusiva a través de gestos**

## 🎯 Roadmap

- [ ] Implementar más gestos de lenguaje de señas
- [ ] Añadir traducción en tiempo real
- [ ] Mejorar la precisión del reconocimiento
- [ ] Implementar grabación de sesiones
- [ ] Añadir chat de texto complementario
- [ ] Soporte para múltiples idiomas de señas
- [ ] App móvil nativa
- [ ] Integración con IA para mejor traducción

## 🙏 Agradecimientos

- **MediaPipe Team** - Por la increíble tecnología de reconocimiento
- **Django & Vue.js Communities** - Por los excelentes frameworks
- **WebRTC Contributors** - Por hacer posible la comunicación P2P
- **Comunidad de lenguaje de señas** - Por la inspiración y feedback