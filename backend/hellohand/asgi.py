import os
import django

# IMPORTANTE: Configurar Django ANTES de importar anything else
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hellohand.settings')
django.setup()

# Ahora sí podemos importar
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import rooms.routing

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(
            rooms.routing.websocket_urlpatterns
        )
    ),
})