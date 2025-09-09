# translator/urls.py
from django.urls import path
from . import views

app_name = 'translator'

urlpatterns = [
    path('predict-signs/', views.PredictSignsView.as_view(), name='predict_signs'),
    path('model-info/', views.ModelInfoView.as_view(), name='model_info'),
    path('reload-model/', views.ReloadModelView.as_view(), name='reload_model'),
    path('available-signs/', views.AvailableSignsView.as_view(), name='available_signs'),
    path('health/', views.HealthCheckView.as_view(), name='health'),
    path('text-to-speech/', views.TextToSpeechView.as_view(), name='text_to_speech'),
    path('speech-to-text/', views.SpeechToTextView.as_view(), name='speech_to_text'),
]