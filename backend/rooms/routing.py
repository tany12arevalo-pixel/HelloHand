# rooms/routing.py - Routing para WebSockets

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # WebSocket para salas
    # ws://192.168.1.88:8000/ws/room/ABC123/?participant_id=uuid
    re_path(r'ws/room/(?P<room_id>\w+)/$', consumers.RoomConsumer.as_asgi()),
]