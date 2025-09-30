# rooms/views.py - APIs completas para el sistema de salas

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Room, Participant
import uuid


class CreateRoomView(APIView):
    """
    API para crear una nueva sala (sin unir al creador automáticamente)
    POST /api/rooms/create/
    """
    
    def post(self, request):
        try:
            # Obtener datos del request
            room_name = request.data.get('name', '')
            max_participants = request.data.get('max_participants', 10)
            translation_enabled = request.data.get('translation_enabled', True)
            stt_enabled = request.data.get('stt_enabled', True)
            tts_enabled = request.data.get('tts_enabled', True)
            room_type = request.data.get('room_type', 'group')
            
            # Validar max_participants
            if not isinstance(max_participants, int) or max_participants < 2 or max_participants > 50:
                return Response({
                    'error': 'max_participants debe ser un número entre 2 y 50'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Crear la sala
            room = Room.objects.create(
                name=room_name,
                max_participants=max_participants,
                room_type=room_type,
                translation_enabled=translation_enabled,
                stt_enabled=stt_enabled,
                tts_enabled=tts_enabled
            )
            
            # Preparar respuesta
            response_data = {
                'room_id': room.room_id,
                'status': 'created',
                'room_name': room.name or f'Sala {room.room_id}',
                'features': {
                    'translation_enabled': room.translation_enabled,
                    'stt_enabled': room.stt_enabled,
                    'tts_enabled': room.tts_enabled
                },
                'max_participants': room.max_participants,
                'created_at': room.created_at.isoformat(),
                'room_status': room.status
            }
            
            return Response(response_data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'error': f'Error creando sala: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class JoinRoomView(APIView):
    """
    API para unirse a una sala existente
    POST /api/rooms/{room_id}/join/
    
    Body:
    {
        "name": "Juan Pérez",
        "hasCamera": true,
        "hasMicrophone": true,
        "isDeaf": false,
        "isMute": false
    }
    """
    
    def post(self, request, room_id):
        try:
            # Buscar la sala
            room = get_object_or_404(Room, room_id=room_id.upper())
            
            # Verificar si se puede unir
            can_join, message = room.can_join()
            if not can_join:
                return Response({
                    'error': message,
                    'room_status': room.status,
                    'participants_count': room.get_participants_count()
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Obtener datos del participante (soportar ambos formatos camelCase y snake_case)
            participant_name = request.data.get('name') or request.data.get('participant_name', 'Participante')
            has_camera = request.data.get('hasCamera', request.data.get('has_camera', True))
            has_microphone = request.data.get('hasMicrophone', request.data.get('has_microphone', True))
            is_deaf = request.data.get('isDeaf', request.data.get('is_deaf', False))
            is_mute = request.data.get('isMute', request.data.get('is_mute', False))
            
            # Generar session_id único
            session_id = str(uuid.uuid4())
            
            # Crear participante
            participant = Participant.objects.create(
                room=room,
                session_id=session_id,
                name=participant_name[:50],
                has_camera=has_camera,
                has_microphone=has_microphone,
                is_deaf=is_deaf,
                is_mute=is_mute
            )
            
            # Activar sala si es el primer participante
            if room.status == 'waiting':
                room.activate()
            
            # Obtener lista de participantes activos
            active_participants = []
            for p in room.get_active_participants():
                active_participants.append({
                    'id': p.session_id,
                    'name': p.name,
                    'has_camera': p.has_camera,
                    'has_microphone': p.has_microphone,
                    'is_deaf': p.is_deaf,
                    'is_mute': p.is_mute,
                    'joined_at': p.joined_at.isoformat()
                })
            
            # Preparar respuesta
            response_data = {
                'status': 'joined',
                'room_id': room.room_id,
                'participant_id': session_id,
                'room_info': {
                    'name': room.name or f'Sala {room.room_id}',
                    'status': room.status,
                    'participants_count': room.get_participants_count(),
                    'max_participants': room.max_participants,
                    'features': {
                        'translation_enabled': room.translation_enabled,
                        'stt_enabled': room.stt_enabled,
                        'tts_enabled': room.tts_enabled
                    },
                    'created_at': room.created_at.isoformat(),
                    'started_at': room.started_at.isoformat() if room.started_at else None
                },
                'participants': active_participants
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Room.DoesNotExist:
            return Response({
                'error': f'Sala {room_id} no encontrada'
            }, status=status.HTTP_404_NOT_FOUND)
            
        except Exception as e:
            return Response({
                'error': f'Error uniéndose a la sala: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class RoomStatusView(APIView):
    """
    API para obtener el estado actual de una sala
    GET /api/rooms/{room_id}/status/
    """
    
    def get(self, request, room_id):
        try:
            # Buscar la sala
            room = get_object_or_404(Room, room_id=room_id.upper())
            
            # Verificar si la sala ha expirado
            if room.is_expired():
                room.end_room()
            
            # Obtener participantes activos
            active_participants = []
            for participant in room.get_active_participants():
                active_participants.append({
                    'id': participant.session_id,
                    'name': participant.name,
                    'has_camera': participant.has_camera,
                    'has_microphone': participant.has_microphone,
                    'is_deaf': participant.is_deaf,
                    'is_mute': participant.is_mute,
                    'joined_at': participant.joined_at.isoformat()
                })
            
            # Preparar respuesta
            response_data = {
                'room_id': room.room_id,
                'status': room.status,
                'participants_count': len(active_participants),
                'max_participants': room.max_participants,
                'room_info': {
                    'name': room.name or f'Sala {room.room_id}',
                    'created_at': room.created_at.isoformat(),
                    'started_at': room.started_at.isoformat() if room.started_at else None,
                    'ended_at': room.ended_at.isoformat() if room.ended_at else None,
                    'features': {
                        'translation_enabled': room.translation_enabled,
                        'stt_enabled': room.stt_enabled,
                        'tts_enabled': room.tts_enabled
                    }
                },
                'participants': active_participants,
                'can_join': room.can_join()[0]
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Room.DoesNotExist:
            return Response({
                'error': f'Sala {room_id} no encontrada'
            }, status=status.HTTP_404_NOT_FOUND)
            
        except Exception as e:
            return Response({
                'error': f'Error obteniendo estado de sala: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LeaveRoomView(APIView):
    """
    API para salir de una sala
    POST /api/rooms/{room_id}/leave/
    """
    
    def post(self, request, room_id):
        try:
            # Buscar la sala
            room = get_object_or_404(Room, room_id=room_id.upper())
            
            # Obtener participant_id
            participant_id = request.data.get('participant_id')
            if not participant_id:
                return Response({
                    'error': 'participant_id es requerido'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Buscar el participante
            try:
                participant = Participant.objects.get(
                    room=room,
                    session_id=participant_id,
                    is_connected=True
                )
            except Participant.DoesNotExist:
                return Response({
                    'error': 'Participante no encontrado o ya desconectado'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Desconectar participante
            participant.disconnect()
            
            # Obtener estado actual
            participants_count = room.get_participants_count()
            
            # Preparar respuesta
            response_data = {
                'status': 'left',
                'room_id': room.room_id,
                'participants_count': participants_count,
                'room_status': room.status
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Room.DoesNotExist:
            return Response({
                'error': f'Sala {room_id} no encontrada'
            }, status=status.HTTP_404_NOT_FOUND)
            
        except Exception as e:
            return Response({
                'error': f'Error saliendo de la sala: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ListRoomsView(APIView):
    """
    API para listar salas (principalmente para debug y administración)
    GET /api/rooms/list/
    """
    
    def get(self, request):
        try:
            # Parámetros de filtro
            status_filter = request.GET.get('status')
            limit = min(int(request.GET.get('limit', 20)), 100)
            
            # Query base
            rooms_query = Room.objects.all()
            
            # Filtrar por status si se especifica
            if status_filter and status_filter in ['waiting', 'active', 'ended']:
                rooms_query = rooms_query.filter(status=status_filter)
            
            # Obtener total count
            total_count = rooms_query.count()
            
            # Limitar resultados
            rooms = rooms_query.order_by('-created_at')[:limit]
            
            # Preparar lista de salas
            rooms_list = []
            for room in rooms:
                rooms_list.append({
                    'room_id': room.room_id,
                    'name': room.name or f'Sala {room.room_id}',
                    'status': room.status,
                    'participants_count': room.get_participants_count(),
                    'max_participants': room.max_participants,
                    'created_at': room.created_at.isoformat(),
                    'started_at': room.started_at.isoformat() if room.started_at else None,
                    'features': {
                        'translation_enabled': room.translation_enabled,
                        'stt_enabled': room.stt_enabled,
                        'tts_enabled': room.tts_enabled
                    }
                })
            
            return Response({
                'rooms': rooms_list,
                'total_count': total_count,
                'returned_count': len(rooms_list)
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': f'Error listando salas: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class RoomInfoView(APIView):
    """
    API para obtener información básica de una sala
    GET /api/rooms/{room_id}/info/
    """
    
    def get(self, request, room_id):
        try:
            room = Room.objects.get(room_id=room_id)
            
            return Response({
                'success': True,
                'room': {
                    'room_id': room.room_id,
                    'name': room.name,
                    'room_type': room.room_type,
                    'max_participants': room.max_participants,
                    'participant_count': room.participants.count(),
                    'created_at': room.created_at,
                    'status': room.status
                }
            })
        except Room.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Sala no encontrada'
            }, status=status.HTTP_404_NOT_FOUND)