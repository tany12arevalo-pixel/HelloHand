# translator/services/speech_service.py - Servicios de STT y TTS para Django (Español)

import subprocess
import tempfile
import os
import threading
import queue
import time
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class TextToSpeechService:
    """
    Servicio TTS basado en tu simple_tts.py
    Adaptado para Django con configuración en español
    """
    
    def __init__(self):
        self.is_available = False
        self.method = 'powershell'  # o 'espeak'
        self.speech_queue = queue.Queue(maxsize=10)
        self.is_processing = False
        self.process_thread = None
        
        # Configuración por defecto para español
        self.config = {
            'rate': -1,      # Velocidad (0-10)
            'volume': 80,   # Volumen (0-100)
            'voice': 'female',  # 'male' o 'female'
            'language': 'es'    # Idioma español
        }
        
        # Detectar método disponible
        self._detect_tts_method()
    
    def _detect_tts_method(self):
        """Detectar qué método TTS está disponible"""
        try:
            # Probar PowerShell en Windows/WSL
            result = subprocess.run(
                ['powershell', '-Command', 'Add-Type -AssemblyName System.Speech; "OK"'],
                capture_output=True,
                timeout=3,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            )
            if result.returncode == 0:
                self.method = 'powershell'
                self.is_available = True
                logger.info("TTS: PowerShell disponible para español")
                return
        except:
            pass
        
        try:
            # Probar espeak en Linux
            result = subprocess.run(['espeak', '--version'], capture_output=True, timeout=2)
            if result.returncode == 0:
                self.method = 'espeak'
                self.is_available = True
                logger.info("TTS: espeak disponible para español")
                return
        except:
            pass
        
        logger.warning("TTS: No se encontró método disponible")
        self.is_available = False
    
    def speak_text(self, text, priority='normal'):
        """
        Añadir texto a la cola de síntesis
        
        Args:
            text: Texto a sintetizar
            priority: 'normal' o 'high'
            
        Returns:
            dict: {'success': bool, 'message': str, 'queued': bool}
        """
        if not self.is_available:
            return {
                'success': False,
                'message': 'Servicio TTS no disponible',
                'queued': False
            }
        
        if not text or len(text.strip()) == 0:
            return {
                'success': False,
                'message': 'Texto vacío',
                'queued': False
            }
        
        # Limpiar y procesar texto
        processed_text = self._preprocess_text(text)
        
        try:
            # Si es alta prioridad, limpiar cola
            if priority == 'high':
                self._clear_queue()
            
            # Crear item para cola
            speech_item = {
                'text': processed_text,
                'original_text': text,
                'timestamp': time.time(),
                'priority': priority
            }
            
            # Añadir a cola
            self.speech_queue.put(speech_item, timeout=1)
            
            # Iniciar procesamiento si no está activo
            if not self.is_processing:
                self._start_processing()
            
            return {
                'success': True,
                'message': 'Texto añadido a cola de síntesis',
                'queued': True,
                'queue_size': self.speech_queue.qsize()
            }
            
        except queue.Full:
            return {
                'success': False,
                'message': 'Cola de síntesis llena',
                'queued': False
            }
        except Exception as e:
            logger.error(f"Error añadiendo a cola TTS: {e}")
            return {
                'success': False,
                'message': f'Error interno: {str(e)}',
                'queued': False
            }
    
    def _preprocess_text(self, text):
        """Procesar texto antes de síntesis para español"""
        text = text.strip()
        
        # Limpiar caracteres problemáticos
        text = text.replace('"', "'")
        text = text.replace('`', "'")
        text = text.replace('$', "dólar")
        
        # Expandir abreviaciones en español
        replacements = {
            'IA': 'inteligencia artificial',
            'TTS': 'texto a voz',
            'STT': 'voz a texto',
            'API': 'api',
            'URL': 'url',
            'HTTP': 'http',
            'JSON': 'json',
            'DB': 'base de datos',
            'OK': 'vale',
            'GPS': 'gps',
            'SMS': 'mensaje de texto',
            'PC': 'computadora',
            'TV': 'televisión'
        }
        
        for abbr, full in replacements.items():
            text = text.replace(abbr, full)
        
        return text
    
    def _start_processing(self):
        """Iniciar procesamiento de cola en hilo separado"""
        if self.is_processing:
            return
        
        self.is_processing = True
        self.process_thread = threading.Thread(target=self._process_queue, daemon=True)
        self.process_thread.start()
    
    def _process_queue(self):
        """Procesar cola de síntesis"""
        while self.is_processing:
            try:
                # Obtener siguiente item (con timeout)
                speech_item = self.speech_queue.get(timeout=2)
                
                # Sintetizar
                success = self._synthesize_speech(speech_item['text'])
                
                if success:
                    logger.info(f"TTS exitoso: {speech_item['text'][:50]}...")
                else:
                    logger.warning(f"TTS falló: {speech_item['text'][:50]}...")
                
                # Marcar como completado
                self.speech_queue.task_done()
                
            except queue.Empty:
                # Sin elementos en cola, continuar esperando
                continue
            except Exception as e:
                logger.error(f"Error procesando cola TTS: {e}")
    
    def _synthesize_speech(self, text):
        """Sintetizar texto usando subprocess"""
        try:
            if self.method == 'powershell':
                return self._speak_with_powershell(text)
            elif self.method == 'espeak':
                return self._speak_with_espeak(text)
            else:
                return False
        except Exception as e:
            logger.error(f"Error en síntesis: {e}")
            return False
    
    def _speak_with_powershell(self, text):
        """Sintetizar con PowerShell en español"""
        try:
            # Comando PowerShell configurado para español
            ps_command = f'''
            Add-Type -AssemblyName System.Speech
            $voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
            
            # Buscar voces en español instaladas
            $spanishVoices = $voice.GetInstalledVoices() | Where-Object {{ 
                $_.VoiceInfo.Culture.Name -like "es-*" 
            }}
            
            # Si hay voces en español, usar la primera
            if ($spanishVoices.Count -gt 0) {{
                $voice.SelectVoice($spanishVoices[0].VoiceInfo.Name)
                Write-Host "Usando voz: " $spanishVoices[0].VoiceInfo.Name
            }} else {{
                # Si no hay voces en español, buscar voz femenina/masculina
                $voices = $voice.GetInstalledVoices()
                $targetGender = if ("{self.config['voice']}" -eq "female") {{ "Female" }} else {{ "Male" }}
                $genderVoice = $voices | Where-Object {{ $_.VoiceInfo.Gender -eq $targetGender }}
                if ($genderVoice) {{
                    $voice.SelectVoice($genderVoice[0].VoiceInfo.Name)
                }}
            }}
            
            $voice.Rate = {self.config['rate']}
            $voice.Volume = {self.config['volume']}
            $voice.Speak("{text}")
            '''
            
            result = subprocess.run(
                ['powershell', '-Command', ps_command],
                capture_output=True,
                text=True,
                timeout=30,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            )
            
            return result.returncode == 0
            
        except subprocess.TimeoutExpired:
            logger.warning("Timeout en síntesis PowerShell")
            return False
        except Exception as e:
            logger.error(f"Error PowerShell: {e}")
            return False
    
    def _speak_with_espeak(self, text):
        """Sintetizar con espeak en español"""
        try:
            # Configurar espeak para español
            voice_option = 'es+f3' if self.config['voice'] == 'female' else 'es+m3'
            speed = 150 + self.config["rate"] * 20
            
            cmd = [
                'espeak', 
                '-v', voice_option,           # Voz en español
                f'-s{speed}',                 # Velocidad
                f'-a{self.config["volume"]}', # Volumen
                text
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            return result.returncode == 0
            
        except Exception as e:
            logger.error(f"Error espeak: {e}")
            return False
    
    def _clear_queue(self):
        """Limpiar cola de síntesis"""
        try:
            while not self.speech_queue.empty():
                self.speech_queue.get_nowait()
                self.speech_queue.task_done()
        except:
            pass
    
    def get_status(self):
        """Obtener estado del servicio TTS"""
        return {
            'available': self.is_available,
            'method': self.method,
            'language': self.config['language'],
            'queue_size': self.speech_queue.qsize(),
            'is_processing': self.is_processing,
            'config': self.config.copy()
        }
    
    def update_config(self, **kwargs):
        """Actualizar configuración del TTS"""
        for key, value in kwargs.items():
            if key in self.config:
                self.config[key] = value
        
        return self.config.copy()
    
    def test_voice(self):
        """Probar configuración de voz"""
        test_text = "Hola, soy el sistema de síntesis de voz de HelloHand en español"
        return self.speak_text(test_text, priority='high')


class SpeechToTextService:
    """
    Servicio STT simplificado para Django
    Configurado para español
    """
    
    def __init__(self):
        self.is_available = False
        self.default_language = 'es-ES'  # Español de España por defecto
        self.supported_languages = [
            'es-ES',  # Español España
            'es-MX',  # Español México  
            'es-AR',  # Español Argentina
            'es-CO',  # Español Colombia
            'es-US',  # Español Estados Unidos
        ]
        self._check_dependencies()
    
    def _check_dependencies(self):
        """Verificar si las dependencias están disponibles"""
        try:
            import speech_recognition as sr
            import pyaudio
            self.is_available = True
            logger.info("STT: Dependencias disponibles para español")
        except ImportError as e:
            logger.warning(f"STT: Dependencias no disponibles: {e}")
            self.is_available = False
    
    def transcribe_audio_file(self, audio_file_path, language=None):
        """
        Transcribir archivo de audio a texto en español
        
        Args:
            audio_file_path: Ruta al archivo de audio
            language: Idioma para reconocimiento (default: es-ES)
            
        Returns:
            dict: {'success': bool, 'text': str, 'message': str, 'language_used': str}
        """
        if not self.is_available:
            return {
                'success': False,
                'text': '',
                'message': 'Servicio STT no disponible - faltan dependencias',
                'language_used': None
            }
        
        # Usar idioma por defecto si no se especifica
        if not language:
            language = self.default_language
        
        # Validar idioma soportado
        if language not in self.supported_languages:
            language = self.default_language
        
        try:
            import speech_recognition as sr
            
            # Crear reconocedor
            recognizer = sr.Recognizer()
            
            # Configurar parámetros para mejor reconocimiento en español
            recognizer.energy_threshold = 300
            recognizer.dynamic_energy_adjustment_damping = 0.15
            recognizer.dynamic_energy_adjustment_ratio = 1.5
            recognizer.pause_threshold = 0.8
            
            # Cargar archivo de audio
            with sr.AudioFile(audio_file_path) as source:
                # Ajustar para ruido ambiente más tiempo para español
                recognizer.adjust_for_ambient_noise(source, duration=1.0)
                
                # Escuchar el audio
                audio_data = recognizer.record(source)
            
            # Reconocer texto en español
            text = recognizer.recognize_google(audio_data, language=language)
            
            # Post-procesar texto en español
            processed_text = self._postprocess_spanish_text(text)
            
            return {
                'success': True,
                'text': processed_text,
                'message': 'Transcripción exitosa en español',
                'language_used': language
            }
            
        except sr.UnknownValueError:
            return {
                'success': False,
                'text': '',
                'message': 'No se pudo entender el audio en español',
                'language_used': language
            }
        except sr.RequestError as e:
            return {
                'success': False,
                'text': '',
                'message': f'Error del servicio de reconocimiento: {e}',
                'language_used': language
            }
        except Exception as e:
            logger.error(f"Error en transcripción: {e}")
            return {
                'success': False,
                'text': '',
                'message': f'Error interno: {str(e)}',
                'language_used': language
            }
    
    def _postprocess_spanish_text(self, text):
        """Post-procesar texto reconocido en español"""
        if not text:
            return text
        
        # Capitalizar primera letra
        text = text.strip().capitalize()
        
        # Correcciones comunes para español
        corrections = {
            'api': 'API',
            'url': 'URL',
            'http': 'HTTP',
            'json': 'JSON',
            'hello hand': 'HelloHand',
            'hola hand': 'HelloHand',
            'ola hand': 'HelloHand'
        }
        
        text_lower = text.lower()
        for wrong, correct in corrections.items():
            if wrong in text_lower:
                # Reemplazar manteniendo capitalización
                text = text.replace(wrong, correct)
                text = text.replace(wrong.capitalize(), correct)
                text = text.replace(wrong.upper(), correct)
        
        return text
    
    def get_status(self):
        """Obtener estado del servicio STT"""
        return {
            'available': self.is_available,
            'default_language': self.default_language,
            'supported_languages': self.supported_languages,
            'supported_formats': ['wav', 'flac', 'aiff'] if self.is_available else []
        }
    
    def set_default_language(self, language):
        """Cambiar idioma por defecto"""
        if language in self.supported_languages:
            self.default_language = language
            return True
        return False


# Instancias globales de los servicios
tts_service = TextToSpeechService()
stt_service = SpeechToTextService()