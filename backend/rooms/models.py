# rooms/models.py - Modelos para el sistema de salas

from django.db import models
import uuid
from datetime import datetime, timedelta
from django.utils import timezone

class Room(models.Model):
    """
    Modelo principal para las salas de videollamada
    Cada sala tiene un ID único y puede tener múltiples participantes
    """
    
    # Choices para el estado de la sala
    STATUS_CHOICES = [
        ('waiting', 'Esperando'),      # Sala creada, esperando participantes
        ('active', 'Activa'),          # Sala con participantes activos
        ('ended', 'Terminada'),        # Sala finalizada
    ]
    
    # ID único de la sala (lo que ve el usuario)
    room_id = models.CharField(
        max_length=10, 
        unique=True, 
        default=None,
        help_text="ID único de 6 caracteres para la sala"
    )
    
    # Estado actual de la sala
    status = models.CharField(
        max_length=10, 
        choices=STATUS_CHOICES, 
        default='waiting',
        help_text="Estado actual de la sala"
    )
    
    # Nombre opcional de la sala
    name = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="Nombre descriptivo de la sala (opcional)"
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha y hora de creación de la sala"
    )
    
    started_at = models.DateTimeField(
        blank=True, 
        null=True,
        help_text="Fecha y hora cuando la sala se volvió activa"
    )
    
    ended_at = models.DateTimeField(
        blank=True, 
        null=True,
        help_text="Fecha y hora cuando la sala terminó"
    )
    
    # Configuración de la sala
    max_participants = models.IntegerField(
        default=10,
        help_text="Número máximo de participantes permitidos"
    )
    
    # Configuración de características habilitadas
    translation_enabled = models.BooleanField(
        default=True,
        help_text="Si la traducción de señas está habilitada"
    )
    
    stt_enabled = models.BooleanField(
        default=True,
        help_text="Si el speech-to-text está habilitado"
    )
    
    tts_enabled = models.BooleanField(
        default=True,
        help_text="Si el text-to-speech está habilitado"
    )

    class Meta:
        verbose_name = "Sala"
        verbose_name_plural = "Salas"
        ordering = ['-created_at']  # Más recientes primero

    def save(self, *args, **kwargs):
        """
        Override del save para generar automáticamente el room_id
        """
        if not self.room_id:
            # Generar ID único de 6 caracteres
            self.room_id = self.generate_room_id()
        super().save(*args, **kwargs)

    def generate_room_id(self):
        """
        Generar un ID único para la sala
        Formato: 6 caracteres alfanuméricos en mayúsculas
        """
        import random
        import string
        
        while True:
            # Generar ID de 6 caracteres (letras y números)
            room_id = ''.join(random.choices(
                string.ascii_uppercase + string.digits, 
                k=6
            ))
            
            # Verificar que no exista ya
            if not Room.objects.filter(room_id=room_id).exists():
                return room_id

    def activate(self):
        """
        Activar la sala cuando llegue el primer participante
        """
        if self.status == 'waiting':
            self.status = 'active'
            self.started_at = timezone.now()
            self.save(update_fields=['status', 'started_at'])

    def end_room(self):
        """
        Terminar la sala cuando todos los participantes se vayan
        """
        if self.status == 'active':
            self.status = 'ended'
            self.ended_at = timezone.now()
            self.save(update_fields=['status', 'ended_at'])

    def get_active_participants(self):
        """
        Obtener participantes actualmente conectados
        """
        return self.participants.filter(is_connected=True)

    def get_participants_count(self):
        """
        Contar participantes activos
        """
        return self.get_active_participants().count()

    def can_join(self):
        """
        Verificar si se puede unir a la sala
        """
        if self.status == 'ended':
            return False, "La sala ha terminado"
        
        if self.get_participants_count() >= self.max_participants:
            return False, "La sala está llena"
        
        return True, "OK"

    def is_expired(self):
        """
        Verificar si la sala ha expirado (más de 24 horas sin actividad)
        """
        if self.status == 'ended':
            return True
        
        # Si no se ha activado en 2 horas, considerarla expirada
        if self.status == 'waiting':
            return timezone.now() - self.created_at > timedelta(hours=2)
        
        # Si está activa pero sin participantes por 1 hora, considerarla expirada
        if self.status == 'active' and self.get_participants_count() == 0:
            last_activity = self.participants.filter(
                disconnected_at__isnull=False
            ).order_by('-disconnected_at').first()
            
            if last_activity:
                return timezone.now() - last_activity.disconnected_at > timedelta(hours=1)
        
        return False

    def __str__(self):
        return f"Sala {self.room_id} ({self.get_status_display()})"


class Participant(models.Model):
    """
    Modelo para participantes en las salas
    Por ahora sin usuarios registrados, solo conexiones anónimas
    """
    
    # Relación con la sala
    room = models.ForeignKey(
        Room, 
        on_delete=models.CASCADE, 
        related_name='participants',
        help_text="Sala a la que pertenece este participante"
    )
    
    # Identificador único del participante (para WebSocket)
    session_id = models.CharField(
        max_length=50, 
        unique=True,
        help_text="ID único de sesión para este participante"
    )
    
    # Nombre del participante (opcional)
    name = models.CharField(
        max_length=50, 
        default="Participante",
        help_text="Nombre que muestra el participante"
    )
    
    # Estado de conexión
    is_connected = models.BooleanField(
        default=True,
        help_text="Si el participante está actualmente conectado"
    )
    
    # Configuración del participante
    has_camera = models.BooleanField(
        default=True,
        help_text="Si el participante tiene cámara habilitada"
    )
    
    has_microphone = models.BooleanField(
        default=True,
        help_text="Si el participante tiene micrófono habilitado"
    )
    
    # Características de accesibilidad
    is_deaf = models.BooleanField(
        default=False,
        help_text="Si el participante es sordo (necesita traducción visual)"
    )
    
    is_mute = models.BooleanField(
        default=False,
        help_text="Si el participante es mudo (necesita traducción de señas)"
    )
    
    # Timestamps
    joined_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Cuándo se unió el participante"
    )
    
    disconnected_at = models.DateTimeField(
        blank=True, 
        null=True,
        help_text="Cuándo se desconectó el participante"
    )

    class Meta:
        verbose_name = "Participante"
        verbose_name_plural = "Participantes"
        # Un participante por sesión por sala
        unique_together = ['room', 'session_id']

    def disconnect(self):
        """
        Marcar participante como desconectado
        """
        self.is_connected = False
        self.disconnected_at = timezone.now()
        self.save(update_fields=['is_connected', 'disconnected_at'])
        
        # Si ya no hay participantes, terminar la sala
        if self.room.get_participants_count() == 0:
            self.room.end_room()

    def reconnect(self):
        """
        Reconectar participante
        """
        self.is_connected = True
        self.disconnected_at = None
        self.save(update_fields=['is_connected', 'disconnected_at'])
        
        # Reactivar sala si estaba inactiva
        if self.room.status == 'waiting':
            self.room.activate()

    def __str__(self):
        status = "conectado" if self.is_connected else "desconectado"
        return f"{self.name} en {self.room.room_id} ({status})"