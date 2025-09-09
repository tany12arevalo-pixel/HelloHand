# rooms/consumers.py - WebSocket consumers para comunicación en tiempo real

import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import Room, Participant
from translator.services.sign_translator import translator_service

logger = logging.getLogger(__name__)

class RoomConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer para salas de HelloHand
    Maneja comunicación en tiempo real entre participantes
    """
    
    async def connect(self):
        """Conectar participante a la sala"""
        # Obtener room_id de la URL
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'room_{self.room_id}'
        
        # Obtener participant_id de query parameters
        query_string = self.scope['query_string'].decode()
        query_params = {}
        if query_string:
            for param in query_string.split('&'):
                if '=' in param:
                    key, value = param.split('=', 1)
                    query_params[key] = value

        self.participant_id = query_params.get('participant_id')
        
        if not self.participant_id:
            # Rechazar conexión si no hay participant_id
            await self.close()
            return
        
        try:
            # Verificar que la sala y participante existen
            room_exists = await self.check_room_exists(self.room_id)
            participant_exists = await self.check_participant_exists(
                self.room_id, self.participant_id
            )
            
            if not room_exists:
                await self.close(code=4404)  # Room not found
                return
            
            if not participant_exists:
                await self.close(code=4403)  # Participant not found
                return
            
            # Unirse al grupo de la sala
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            
            # Aceptar conexión WebSocket
            await self.accept()
            
            # Notificar a otros participantes
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'participant_joined',
                    'participant_id': self.participant_id,
                    'message': f'Participante {self.participant_id} se conectó'
                }
            )
            
            logger.info(f"Participante {self.participant_id} conectado a sala {self.room_id}")
            
        except Exception as e:
            logger.error(f"Error conectando participante: {e}")
            await self.close()
    
    async def disconnect(self, close_code):
        """Desconectar participante de la sala"""
        try:
            # Notificar a otros participantes
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'participant_left',
                    'participant_id': self.participant_id,
                    'message': f'Participante {self.participant_id} se desconectó'
                }
            )
            
            # Salir del grupo
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )
            
            logger.info(f"Participante {self.participant_id} desconectado de sala {self.room_id}")
            
        except Exception as e:
            logger.error(f"Error desconectando participante: {e}")
    
    async def receive(self, text_data):
        """Recibir mensaje del WebSocket"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            # Enrutar según tipo de mensaje
            if message_type == 'translation_request':
                await self.handle_translation_request(data)
            elif message_type == 'chat_message':
                await self.handle_chat_message(data)
            elif message_type == 'webrtc_signal':
                await self.handle_webrtc_signal(data)
            elif message_type == 'participant_status':
                await self.handle_participant_status(data)
            else:
                logger.warning(f"Tipo de mensaje desconocido: {message_type}")
                
        except json.JSONDecodeError:
            logger.error("Error decodificando JSON del WebSocket")
        except Exception as e:
            logger.error(f"Error procesando mensaje WebSocket: {e}")
    
    async def handle_translation_request(self, data):
        """
        Manejar solicitud de traducción de señas
        
        Expected data:
        {
            'type': 'translation_request',
            'landmarks': [...],
            'participant_id': 'uuid'
        }
        """
        try:
            landmarks = data.get('landmarks', [])
            requester_id = data.get('participant_id', self.participant_id)
            
            if not landmarks:
                return
            
            # Realizar traducción (de forma síncrona para ser más rápido)
            result = await database_sync_to_async(
                translator_service.predict_from_landmarks
            )(landmarks)
            
            # Enviar resultado a todos en la sala
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'translation_result',
                    'requester_id': requester_id,
                    'prediction': result.get('prediction'),
                    'confidence': result.get('confidence'),
                    'success': result.get('success'),
                    'message': result.get('message'),
                    'timestamp': self.get_timestamp()
                }
            )
            
        except Exception as e:
            logger.error(f"Error en traducción: {e}")
            await self.send_error('Error en traducción de señas')
    
    async def handle_chat_message(self, data):
        """
        Manejar mensaje de chat de texto
        
        Expected data:
        {
            'type': 'chat_message',
            'message': 'Hola a todos',
            'participant_id': 'uuid'
        }
        """
        try:
            message = data.get('message', '').strip()
            sender_id = data.get('participant_id', self.participant_id)
            
            if not message:
                return
            
            # Obtener nombre del participante
            participant_name = await self.get_participant_name(sender_id)
            
            # Enviar mensaje a todos en la sala
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message_broadcast',
                    'sender_id': sender_id,
                    'sender_name': participant_name,
                    'message': message,
                    'timestamp': self.get_timestamp()
                }
            )
            
        except Exception as e:
            logger.error(f"Error en mensaje de chat: {e}")
    
    async def handle_webrtc_signal(self, data):
        """
        Manejar señales WebRTC para videollamada
        
        Expected data:
        {
            'type': 'webrtc_signal',
            'signal_type': 'offer|answer|ice-candidate',
            'signal_data': {...},
            'target_participant': 'uuid',
            'sender_id': 'uuid'
        }
        """
        try:
            signal_type = data.get('signal_type')
            signal_data = data.get('signal_data')
            target_participant = data.get('target_participant')
            sender_id = data.get('sender_id', self.participant_id)
            
            if not target_participant:
                # Broadcast a todos si no hay target específico
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'webrtc_signal_broadcast',
                        'signal_type': signal_type,
                        'signal_data': signal_data,
                        'sender_id': sender_id
                    }
                )
            else:
                # Enviar solo al participante específico
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'webrtc_signal_targeted',
                        'signal_type': signal_type,
                        'signal_data': signal_data,
                        'sender_id': sender_id,
                        'target_participant': target_participant
                    }
                )
                
        except Exception as e:
            logger.error(f"Error en señal WebRTC: {e}")
    
    async def handle_participant_status(self, data):
        """
        Manejar cambios de estado del participante
        
        Expected data:
        {
            'type': 'participant_status',
            'has_camera': true,
            'has_microphone': false,
            'participant_id': 'uuid'
        }
        """
        try:
            participant_id = data.get('participant_id', self.participant_id)
            has_camera = data.get('has_camera')
            has_microphone = data.get('has_microphone')
            
            # Actualizar estado en base de datos
            await self.update_participant_status(
                participant_id, has_camera, has_microphone
            )
            
            # Notificar a otros participantes
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'participant_status_update',
                    'participant_id': participant_id,
                    'has_camera': has_camera,
                    'has_microphone': has_microphone
                }
            )
            
        except Exception as e:
            logger.error(f"Error actualizando estado participante: {e}")
    
    # Métodos para recibir mensajes del grupo
    
    async def participant_joined(self, event):
        """Notificar que un participante se unió"""
        await self.send(text_data=json.dumps({
            'type': 'participant_joined',
            'participant_id': event['participant_id'],
            'message': event['message']
        }))
    
    async def participant_left(self, event):
        """Notificar que un participante se fue"""
        await self.send(text_data=json.dumps({
            'type': 'participant_left',
            'participant_id': event['participant_id'],
            'message': event['message']
        }))
    
    async def translation_result(self, event):
        """Enviar resultado de traducción"""
        await self.send(text_data=json.dumps({
            'type': 'translation_result',
            'requester_id': event['requester_id'],
            'prediction': event['prediction'],
            'confidence': event['confidence'],
            'success': event['success'],
            'message': event['message'],
            'timestamp': event['timestamp']
        }))
    
    async def chat_message_broadcast(self, event):
        """Enviar mensaje de chat"""
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'sender_id': event['sender_id'],
            'sender_name': event['sender_name'],
            'message': event['message'],
            'timestamp': event['timestamp']
        }))
    
    async def webrtc_signal_broadcast(self, event):
        """Enviar señal WebRTC a todos"""
        await self.send(text_data=json.dumps({
            'type': 'webrtc_signal',
            'signal_type': event['signal_type'],
            'signal_data': event['signal_data'],
            'sender_id': event['sender_id']
        }))
    
    async def webrtc_signal_targeted(self, event):
        """Enviar señal WebRTC solo al participante objetivo"""
        if self.participant_id == event['target_participant']:
            await self.send(text_data=json.dumps({
                'type': 'webrtc_signal',
                'signal_type': event['signal_type'],
                'signal_data': event['signal_data'],
                'sender_id': event['sender_id']
            }))
    
    async def participant_status_update(self, event):
        """Notificar cambio de estado de participante"""
        await self.send(text_data=json.dumps({
            'type': 'participant_status_update',
            'participant_id': event['participant_id'],
            'has_camera': event['has_camera'],
            'has_microphone': event['has_microphone']
        }))
    
    # Métodos auxiliares
    
    async def send_error(self, message):
        """Enviar mensaje de error al cliente"""
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': message
        }))
    
    def get_timestamp(self):
        """Obtener timestamp actual"""
        from django.utils import timezone
        return timezone.now().isoformat()
    
    # Métodos de base de datos (síncronos convertidos a async)
    
    @database_sync_to_async
    def check_room_exists(self, room_id):
        """Verificar si la sala existe"""
        return Room.objects.filter(room_id=room_id.upper()).exists()
    
    @database_sync_to_async
    def check_participant_exists(self, room_id, participant_id):
        """Verificar si el participante existe en la sala"""
        return Participant.objects.filter(
            room__room_id=room_id.upper(),
            session_id=participant_id,
            is_connected=True
        ).exists()
    
    @database_sync_to_async
    def get_participant_name(self, participant_id):
        """Obtener nombre del participante"""
        try:
            participant = Participant.objects.get(
                room__room_id=self.room_id.upper(),
                session_id=participant_id
            )
            return participant.name
        except Participant.DoesNotExist:
            return "Participante"
    
    @database_sync_to_async
    def update_participant_status(self, participant_id, has_camera, has_microphone):
        """Actualizar estado del participante"""
        try:
            participant = Participant.objects.get(
                room__room_id=self.room_id.upper(),
                session_id=participant_id
            )
            if has_camera is not None:
                participant.has_camera = has_camera
            if has_microphone is not None:
                participant.has_microphone = has_microphone
            participant.save()
            return True
        except Participant.DoesNotExist:
            return False