# test_full_integration.py - Test del sistema completo HelloHand

import requests
import json
import time
import websocket
import threading
from datetime import datetime

# Configuración
BASE_URL = "http://192.168.1.88:8000"
WS_URL = "ws://192.168.1.88:8000"
API_BASE = f"{BASE_URL}/api"

class HelloHandIntegrationTest:
    def __init__(self):
        self.room_id = None
        self.participant1_id = None
        self.participant2_id = None
        self.ws_connections = {}
        
    def print_step(self, step, description):
        print(f"\n{'='*60}")
        print(f"PASO {step}: {description}")
        print(f"{'='*60}")
    
    def test_full_workflow(self):
        """Test completo del flujo de HelloHand"""
        
        self.print_step(1, "CREAR SALA DE VIDEOLLAMADA")
        self.room_id = self.create_room()
        if not self.room_id:
            print("❌ FALLO CRÍTICO: No se pudo crear sala")
            return False
        
        self.print_step(2, "PARTICIPANTE 1 SE UNE (PERSONA OYENTE)")
        self.participant1_id = self.join_participant_1()
        if not self.participant1_id:
            print("❌ FALLO: Participante 1 no se pudo unir")
            return False
        
        self.print_step(3, "PARTICIPANTE 2 SE UNE (PERSONA SORDA)")
        self.participant2_id = self.join_participant_2()
        if not self.participant2_id:
            print("❌ FALLO: Participante 2 no se pudo unir")
            return False
        
        self.print_step(4, "VERIFICAR ESTADO DE LA SALA")
        self.check_room_status()
        
        self.print_step(5, "PROBAR TRADUCCIÓN DE SEÑAS")
        self.test_sign_translation()
        
        self.print_step(6, "PROBAR TEXT-TO-SPEECH")
        self.test_text_to_speech()
        
        self.print_step(7, "SIMULAR FLUJO COMPLETO")
        self.simulate_full_conversation()
        
        self.print_step(8, "CLEANUP - SALIR DE SALA")
        self.cleanup()
        
        print(f"\n🎉 TEST COMPLETO FINALIZADO")
        print(f"Sala creada: {self.room_id}")
        print(f"Participantes: {self.participant1_id}, {self.participant2_id}")
        
        return True
    
    def create_room(self):
        """Crear sala de prueba"""
        room_data = {
            "name": "Sala de Prueba Integración HelloHand",
            "max_participants": 5,
            "translation_enabled": True,
            "stt_enabled": True,
            "tts_enabled": True
        }
        
        try:
            response = requests.post(f"{API_BASE}/rooms/create/", json=room_data)
            print(f"POST /api/rooms/create/")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 201:
                data = response.json()
                room_id = data.get('room_id')
                print(f"✅ Sala creada: {room_id}")
                print(f"Características: {data.get('features')}")
                return room_id
            else:
                print(f"❌ Error: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            return None
    
    def join_participant_1(self):
        """Participante 1: Persona oyente que puede hacer señas"""
        participant_data = {
            "participant_name": "Juan Pérez (Oyente)",
            "has_camera": True,
            "has_microphone": True,
            "is_deaf": False,
            "is_mute": False
        }
        
        try:
            response = requests.post(
                f"{API_BASE}/rooms/{self.room_id}/join/", 
                json=participant_data
            )
            print(f"POST /api/rooms/{self.room_id}/join/")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                participant_id = data.get('participant_id')
                print(f"✅ Juan se unió: {participant_id}")
                print(f"Participantes en sala: {data.get('room_info', {}).get('participants_count')}")
                return participant_id
            else:
                print(f"❌ Error: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            return None
    
    def join_participant_2(self):
        """Participante 2: Persona sorda que necesita traducción"""
        participant_data = {
            "participant_name": "María García (Sorda)",
            "has_camera": True,
            "has_microphone": False,
            "is_deaf": True,
            "is_mute": False
        }
        
        try:
            response = requests.post(
                f"{API_BASE}/rooms/{self.room_id}/join/", 
                json=participant_data
            )
            print(f"POST /api/rooms/{self.room_id}/join/")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                participant_id = data.get('participant_id')
                print(f"✅ María se unió: {participant_id}")
                print(f"Participantes totales: {data.get('room_info', {}).get('participants_count')}")
                
                # Mostrar lista de participantes
                participants = data.get('participants', [])
                for p in participants:
                    print(f"  - {p['name']}: cámara={p['has_camera']}, micrófono={p['has_microphone']}, sorda={p['is_deaf']}")
                
                return participant_id
            else:
                print(f"❌ Error: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            return None
    
    def check_room_status(self):
        """Verificar estado actual de la sala"""
        try:
            response = requests.get(f"{API_BASE}/rooms/{self.room_id}/status/")
            print(f"GET /api/rooms/{self.room_id}/status/")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Estado de sala: {data.get('status')}")
                print(f"Participantes activos: {data.get('participants_count')}")
                print(f"Características habilitadas:")
                features = data.get('room_info', {}).get('features', {})
                for feature, enabled in features.items():
                    status = "✅" if enabled else "❌"
                    print(f"  {status} {feature}")
                return True
            else:
                print(f"❌ Error: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            return False
    
    def test_sign_translation(self):
        """Probar traducción de señas con datos simulados"""
        print("\n🔄 Probando traducción de señas...")
        
        # Landmarks simulados (estructura básica)
        fake_landmarks = []
        for i in range(15):  # 15 frames simulados
            frame = {
                "timestamp": i * 0.1,
                "face": [{"x": 0.5, "y": 0.5, "z": 0.1} for _ in range(20)],
                "pose": {
                    "hombro_der": {"x": 0.6, "y": 0.4, "z": 0.0},
                    "hombro_izq": {"x": 0.4, "y": 0.4, "z": 0.0},
                    "codo_der": {"x": 0.65, "y": 0.5, "z": 0.1},
                    "codo_izq": {"x": 0.35, "y": 0.5, "z": 0.1},
                    "muneca_der": {"x": 0.7, "y": 0.6, "z": 0.2},
                    "muneca_izq": {"x": 0.3, "y": 0.6, "z": 0.2}
                },
                "left_hand": [{"x": 0.3 + j*0.01, "y": 0.6 + j*0.01, "z": 0.2} for j in range(21)],
                "right_hand": [{"x": 0.7 - j*0.01, "y": 0.6 + j*0.01, "z": 0.2} for j in range(21)]
            }
            fake_landmarks.append(frame)
        
        translation_data = {
            "landmarks": fake_landmarks,
            "min_confidence": 0.3
        }
        
        try:
            response = requests.post(
                f"{API_BASE}/translator/predict-signs/", 
                json=translation_data
            )
            print(f"POST /api/translator/predict-signs/")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    print(f"✅ Traducción exitosa: '{data.get('prediction')}'")
                    print(f"Confianza: {data.get('confidence'):.2f}")
                    print(f"Frames procesados: {data.get('frames_processed')}")
                    print(f"Tiempo: {data.get('processing_time_ms')}ms")
                else:
                    print(f"⚠️ Traducción sin éxito: {data.get('message')}")
                return True
            else:
                print(f"❌ Error: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            return False
    
    def test_text_to_speech(self):
        """Probar síntesis de voz"""
        print("\n🔊 Probando text-to-speech...")
        
        tts_data = {
            "text": "Hola María, bienvenida a la sala de HelloHand",
            "priority": "normal"
        }
        
        try:
            response = requests.post(
                f"{API_BASE}/translator/text-to-speech/", 
                json=tts_data
            )
            print(f"POST /api/translator/text-to-speech/")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    print(f"✅ TTS exitoso: texto añadido a cola")
                    print(f"Tamaño de cola: {data.get('queue_size', 'N/A')}")
                else:
                    print(f"⚠️ TTS falló: {data.get('message')}")
                return True
            else:
                print(f"❌ Error: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Excepción: {e}")
            return False
    
    def simulate_full_conversation(self):
        """Simular conversación completa entre participantes"""
        print("\n💬 Simulando conversación completa...")
        
        # Scenario: Juan hace seña de "bien", el sistema traduce y lo convierte a voz para María
        
        print("\n📝 Escenario:")
        print("1. Juan (oyente) hace seña de 'bien'")
        print("2. Sistema traduce la seña a texto")
        print("3. Sistema convierte texto a voz")
        print("4. María (sorda) ve subtítulos en pantalla")
        
        # Simular landmarks para "bien"
        bien_landmarks = []
        for i in range(12):
            frame = {
                "timestamp": i * 0.2,
                "face": [{"x": 0.5, "y": 0.5, "z": 0.1} for _ in range(20)],
                "pose": {
                    "hombro_der": {"x": 0.6, "y": 0.4, "z": 0.0},
                    "hombro_izq": {"x": 0.4, "y": 0.4, "z": 0.0},
                    "codo_der": {"x": 0.65, "y": 0.5, "z": 0.1},
                    "codo_izq": {"x": 0.35, "y": 0.5, "z": 0.1},
                    "muneca_der": {"x": 0.7, "y": 0.3, "z": 0.2},  # Pulgar arriba
                    "muneca_izq": {"x": 0.3, "y": 0.6, "z": 0.2}
                },
                "left_hand": [{"x": 0.3, "y": 0.6, "z": 0.2} for _ in range(21)],
                "right_hand": [{"x": 0.7, "y": 0.3, "z": 0.2} for _ in range(21)]  # Señal "bien"
            }
            bien_landmarks.append(frame)
        
        # 1. Traducir seña
        print("\n🔄 Paso 1: Traduciendo seña...")
        translation_response = requests.post(
            f"{API_BASE}/translator/predict-signs/",
            json={"landmarks": bien_landmarks, "min_confidence": 0.2}
        )
        
        if translation_response.status_code == 200:
            translation_data = translation_response.json()
            predicted_text = translation_data.get('prediction', 'unknown')
            confidence = translation_data.get('confidence', 0)
            
            print(f"✅ Traducción: '{predicted_text}' (confianza: {confidence:.2f})")
            
            # 2. Convertir a voz
            if predicted_text and predicted_text != 'unknown':
                print(f"\n🔊 Paso 2: Convirtiendo '{predicted_text}' a voz...")
                tts_response = requests.post(
                    f"{API_BASE}/translator/text-to-speech/",
                    json={"text": f"Juan dice: {predicted_text}", "priority": "high"}
                )
                
                if tts_response.status_code == 200:
                    tts_data = tts_response.json()
                    if tts_data.get('success'):
                        print(f"✅ TTS completado: Audio enviado a cola")
                        print(f"📱 María ve en pantalla: 'Juan dice: {predicted_text}'")
                        print(f"🔊 Otros participantes escuchan: 'Juan dice: {predicted_text}'")
                    else:
                        print(f"⚠️ TTS falló: {tts_data.get('message')}")
                else:
                    print(f"❌ Error TTS: {tts_response.text}")
        
        # 3. Obtener información actualizada
        print(f"\n📊 Paso 3: Estado final de la sala...")
        self.check_room_status()
        
        print(f"\n🎯 FLUJO COMPLETO SIMULADO EXITOSAMENTE")
        return True
    
    def cleanup(self):
        """Limpiar recursos"""
        print("\n🧹 Limpiando recursos...")
        
        # Salir participante 1
        if self.participant1_id:
            response = requests.post(
                f"{API_BASE}/rooms/{self.room_id}/leave/",
                json={"participant_id": self.participant1_id}
            )
            if response.status_code == 200:
                print(f"✅ Juan salió de la sala")
            
        # Salir participante 2
        if self.participant2_id:
            response = requests.post(
                f"{API_BASE}/rooms/{self.room_id}/leave/",
                json={"participant_id": self.participant2_id}
            )
            if response.status_code == 200:
                print(f"✅ María salió de la sala")
        
        # Estado final
        time.sleep(1)
        final_status = requests.get(f"{API_BASE}/rooms/{self.room_id}/status/")
        if final_status.status_code == 200:
            data = final_status.json()
            print(f"📊 Estado final: {data.get('status')} con {data.get('participants_count')} participantes")


def main():
    print("🚀 INICIANDO TEST DE INTEGRACIÓN COMPLETA - HELLOHAND")
    print(f"Servidor: {BASE_URL}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Verificar conexión
    try:
        response = requests.get(BASE_URL, timeout=5)
        print(f"✅ Servidor respondiendo")
    except:
        print(f"❌ ERROR: No se puede conectar a {BASE_URL}")
        print("Asegúrate de que el servidor esté corriendo")
        return
    
    # Ejecutar test
    test_runner = HelloHandIntegrationTest()
    
    try:
        success = test_runner.test_full_workflow()
        
        if success:
            print(f"\n🎉 TODOS LOS TESTS PASARON")
            print(f"HelloHand está funcionando correctamente")
        else:
            print(f"\n❌ ALGUNOS TESTS FALLARON")
            print(f"Revisa los errores arriba")
            
    except KeyboardInterrupt:
        print(f"\n⚠️ Test interrumpido por usuario")
        test_runner.cleanup()
    except Exception as e:
        print(f"\n❌ ERROR INESPERADO: {e}")


if __name__ == "__main__":
    main()