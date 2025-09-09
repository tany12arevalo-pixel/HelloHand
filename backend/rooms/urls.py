# rooms/urls.py - URLs para las APIs de salas

from django.urls import path
from . import views

# Namespace para las URLs de rooms
app_name = 'rooms'

urlpatterns = [
    # API para crear sala nueva
    # POST /api/rooms/create/
    path('create/', views.CreateRoomView.as_view(), name='create_room'),
    
    # API para unirse a una sala
    # POST /api/rooms/{room_id}/join/
    path('<str:room_id>/join/', views.JoinRoomView.as_view(), name='join_room'),
    
    # API para obtener estado de la sala
    # GET /api/rooms/{room_id}/status/
    path('<str:room_id>/status/', views.RoomStatusView.as_view(), name='room_status'),
    
    # API para listar salas activas (opcional, para debug)
    # GET /api/rooms/list/
    path('list/', views.ListRoomsView.as_view(), name='list_rooms'),
    
    # API para salir de una sala
    # POST /api/rooms/{room_id}/leave/
    path('<str:room_id>/leave/', views.LeaveRoomView.as_view(), name='leave_room'),
]