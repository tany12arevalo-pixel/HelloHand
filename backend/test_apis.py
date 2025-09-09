# test_apis.py - Script para probar las APIs de HelloHand

import requests
import json
import time
from datetime import datetime

# Configuración del servidor
BASE_URL = "http://127.0.0.1:8000"
API_BASE = f"{BASE_URL}/api/rooms"

def print_separator(title):
    """Imprimir separador visual"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def print_response(response, title="Respuesta"):
    """Imprimir respuesta formateada"""
    print(f"\n{title}:")
    print(f"Status Code: {response.status_code}")
    try:
        print(f"JSON: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    except:
        print(f"Texto: {response.text}")

def test_create_room():
    """Test 1: Crear una sala nueva"""
    print_separator("TEST 1: CREAR SALA")
    
    # Datos para crear sala
    room_data = {
        "name": "Sala de Prueba HelloHand",
        "max_participants": 5,
        "translation_enabled": True,
        "stt_enabled": True,
        "tts_enabled": True
    }
    
    print(f"POST {API_BASE}/create/")
    print(f"Body: {json.dumps(room_data, indent=2)}")
    
    try:
        response = requests.post(f"{API_BASE}/create/", json=room_data)
        print_response(response, "Respuesta - Crear Sala")
        
        if response.status_code == 201:
            room_data = response.json()
            room_id = room_data.get('room_id')
            print(f"\n✅ SALA CREADA EXITOSAMENTE: {room_id}")
            return room_id
        else:
            print(f"\n❌ ERROR CREANDO SALA")
            return None
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return None

def test_join_room(room_id):
    """Test 2: Unirse a una sala"""
    print_separator("TEST 2: UNIRSE A SALA")
    
    # Datos del primer participante
    participant_data = {
        "participant_name": "Juan Pérez",
        "has_camera": True,
        "has_microphone": True,
        "is_deaf": False,
        "is_mute": False
    }
    
    print(f"POST {API_BASE}/{room_id}/join/")
    print(f"Body: {json.dumps(participant_data, indent=2)}")
    
    try:
        response = requests.post(f"{API_BASE}/{room_id}/join/", json=participant_data)
        print_response(response, "Respuesta - Unirse a Sala")
        
        if response.status_code == 200:
            join_data = response.json()
            participant_id = join_data.get('participant_id')
            print(f"\n✅ UNIÓN EXITOSA. Participant ID: {participant_id}")
            return participant_id
        else:
            print(f"\n❌ ERROR UNIÉNDOSE A SALA")
            return None
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return None

def test_room_status(room_id):
    """Test 3: Obtener estado de la sala"""
    print_separator("TEST 3: ESTADO DE SALA")
    
    print(f"GET {API_BASE}/{room_id}/status/")
    
    try:
        response = requests.get(f"{API_BASE}/{room_id}/status/")
        print_response(response, "Respuesta - Estado de Sala")
        
        if response.status_code == 200:
            print(f"\n✅ ESTADO OBTENIDO EXITOSAMENTE")
            return response.json()
        else:
            print(f"\n❌ ERROR OBTENIENDO ESTADO")
            return None
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return None

def test_join_second_participant(room_id):
    """Test 4: Segundo participante se une"""
    print_separator("TEST 4: SEGUNDO PARTICIPANTE")
    
    # Datos del segundo participante (persona sorda)
    participant_data = {
        "participant_name": "María García",
        "has_camera": True,
        "has_microphone": False,
        "is_deaf": True,
        "is_mute": False
    }
    
    print(f"POST {API_BASE}/{room_id}/join/")
    print(f"Body: {json.dumps(participant_data, indent=2)}")
    
    try:
        response = requests.post(f"{API_BASE}/{room_id}/join/", json=participant_data)
        print_response(response, "Respuesta - Segundo Participante")
        
        if response.status_code == 200:
            join_data = response.json()
            participant_id = join_data.get('participant_id')
            print(f"\n✅ SEGUNDO PARTICIPANTE UNIDO. ID: {participant_id}")
            return participant_id
        else:
            print(f"\n❌ ERROR CON SEGUNDO PARTICIPANTE")
            return None
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return None

def test_list_rooms():
    """Test 5: Listar salas"""
    print_separator("TEST 5: LISTAR SALAS")
    
    print(f"GET {API_BASE}/list/")
    
    try:
        response = requests.get(f"{API_BASE}/list/")
        print_response(response, "Respuesta - Listar Salas")
        
        if response.status_code == 200:
            print(f"\n✅ LISTA OBTENIDA EXITOSAMENTE")
            return response.json()
        else:
            print(f"\n❌ ERROR LISTANDO SALAS")
            return None
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return None

def test_leave_room(room_id, participant_id):
    """Test 6: Salir de sala"""
    print_separator("TEST 6: SALIR DE SALA")
    
    leave_data = {
        "participant_id": participant_id
    }
    
    print(f"POST {API_BASE}/{room_id}/leave/")
    print(f"Body: {json.dumps(leave_data, indent=2)}")
    
    try:
        response = requests.post(f"{API_BASE}/{room_id}/leave/", json=leave_data)
        print_response(response, "Respuesta - Salir de Sala")
        
        if response.status_code == 200:
            print(f"\n✅ SALIDA EXITOSA")
            return True
        else:
            print(f"\n❌ ERROR SALIENDO DE SALA")
            return False
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return False

def test_invalid_room():
    """Test 7: Probar sala inexistente"""
    print_separator("TEST 7: SALA INEXISTENTE")
    
    fake_room_id = "NOEXIST"
    print(f"GET {API_BASE}/{fake_room_id}/status/")
    
    try:
        response = requests.get(f"{API_BASE}/{fake_room_id}/status/")
        print_response(response, "Respuesta - Sala Inexistente")
        
        if response.status_code == 404:
            print(f"\n✅ ERROR 404 MANEJADO CORRECTAMENTE")
            return True
        else:
            print(f"\n❌ RESPUESTA INESPERADA")
            return False
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return False

def main():
    """Ejecutar todos los tests"""
    print_separator("INICIANDO TESTS DE APIS HELLOHAND")
    print(f"Servidor: {BASE_URL}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Verificar conexión al servidor
    try:
        response = requests.get(BASE_URL, timeout=5)
        print(f"\n✅ Servidor respondiendo en {BASE_URL}")
    except:
        print(f"\n❌ ERROR: No se puede conectar a {BASE_URL}")
        print("Asegúrate de que el servidor Django esté corriendo:")
        print("python manage.py runserver")
        return
    
    # Variables para mantener estado
    room_id = None
    participant1_id = None
    participant2_id = None
    
    # Ejecutar tests en secuencia
    try:
        # Test 1: Crear sala
        room_id = test_create_room()
        if not room_id:
            print("\n❌ FALLO CRÍTICO: No se pudo crear sala")
            return
        
        time.sleep(1)  # Pequeña pausa entre requests
        
        # Test 2: Primer participante
        participant1_id = test_join_room(room_id)
        if not participant1_id:
            print("\n❌ FALLO: No se pudo unir primer participante")
        
        time.sleep(1)
        
        # Test 3: Estado de sala
        test_room_status(room_id)
        
        time.sleep(1)
        
        # Test 4: Segundo participante
        participant2_id = test_join_second_participant(room_id)
        
        time.sleep(1)
        
        # Test 5: Listar salas
        test_list_rooms()
        
        time.sleep(1)
        
        # Test 6: Salir de sala
        if participant1_id:
            test_leave_room(room_id, participant1_id)
        
        time.sleep(1)
        
        # Test 7: Sala inexistente
        test_invalid_room()
        
        # Resumen final
        print_separator("RESUMEN FINAL")
        print(f"Sala creada: {room_id}")
        print(f"Participante 1: {participant1_id}")
        print(f"Participante 2: {participant2_id}")
        print(f"\n✅ TESTS COMPLETADOS")
        print("\nRevisa los resultados arriba para verificar que todo funciona correctamente.")
        
    except KeyboardInterrupt:
        print("\n\n⚠️ Tests interrumpidos por el usuario")
    except Exception as e:
        print(f"\n\n❌ ERROR INESPERADO: {e}")

if __name__ == "__main__":
    main()