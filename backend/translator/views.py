# translator/views.py - APIs de traducción de señas

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .services.sign_translator import translator_service
import logging

logger = logging.getLogger(__name__)


class PredictSignsView(APIView):
    """
    API principal para traducir landmarks de señas a texto
    POST /api/translator/predict-signs/
    
    Body:
    {
        "landmarks": [
            {
                "timestamp": 0.0,
                "face": [{"x": 0.1, "y": 0.2, "z": 0.3}, ...],
                "pose": {"hombro_der": {"x": 0.1, "y": 0.2, "z": 0.3}, ...},
                "left_hand": [{"x": 0.1, "y": 0.2, "z": 0.3}, ...],
                "right_hand": [{"x": 0.1, "y": 0.2, "z": 0.3}, ...]
            },
            ... (más frames)
        ],
        "min_confidence": 0.4  // opcional
    }
    
    Response:
    {
        "prediction": "bien",
        "confidence": 0.85,
        "success": true,
        "message": "Predicción exitosa",
        "frames_processed": 15,
        "processing_time_ms": 45
    }
    """
    
    def post(self, request):
        import time
        start_time = time.time()
        
        try:
            # Validar datos de entrada
            landmarks = request.data.get('landmarks')
            if not landmarks:
                return Response({
                    'error': 'Campo "landmarks" es requerido',
                    'success': False
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if not isinstance(landmarks, list):
                return Response({
                    'error': 'Campo "landmarks" debe ser una lista',
                    'success': False
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Confianza mínima (opcional)
            min_confidence = request.data.get('min_confidence', 0.4)
            if not isinstance(min_confidence, (int, float)) or min_confidence < 0 or min_confidence > 1:
                min_confidence = 0.4
            
            # Validar estructura básica de landmarks
            for i, frame in enumerate(landmarks):
                if not isinstance(frame, dict):
                    return Response({
                        'error': f'Frame {i} debe ser un objeto JSON',
                        'success': False
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                # Verificar que tenga al menos una estructura básica
                required_keys = ['face', 'pose', 'left_hand', 'right_hand']
                missing_keys = [key for key in required_keys if key not in frame]
                if missing_keys:
                    return Response({
                        'error': f'Frame {i} falta campos: {missing_keys}',
                        'success': False
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Realizar predicción
            result = translator_service.predict_from_landmarks(
                landmarks_sequence=landmarks,
                min_confidence=min_confidence
            )
            
            # Calcular tiempo de procesamiento
            processing_time = (time.time() - start_time) * 1000  # en ms
            
            # Preparar respuesta
            response_data = {
                'prediction': result['prediction'],
                'confidence': result['confidence'],
                'success': result['success'],
                'message': result['message'],
                'frames_processed': len(landmarks),
                'processing_time_ms': round(processing_time, 2),
                'min_confidence_used': min_confidence
            }
            
            # Status code según resultado
            if result['success']:
                response_status = status.HTTP_200_OK
            else:
                response_status = status.HTTP_200_OK  # Mantener 200 pero success=false
            
            return Response(response_data, status=response_status)
            
        except Exception as e:
            logger.error(f"Error en predicción de señas: {e}")
            return Response({
                'error': f'Error interno del servidor: {str(e)}',
                'success': False,
                'processing_time_ms': round((time.time() - start_time) * 1000, 2)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ModelInfoView(APIView):
    """
    API para obtener información del modelo de traducción
    GET /api/translator/model-info/
    
    Response:
    {
        "loaded": true,
        "signs_count": 3,
        "signs": ["bien", "mal", "tonto"],
        "model_type": "RandomForestClassifier",
        "model_path": "/path/to/modelo.pkl",
        "dataset_path": "/path/to/dataset.json"
    }
    """
    
    def get(self, request):
        try:
            model_info = translator_service.get_model_info()
            return Response(model_info, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error obteniendo info del modelo: {e}")
            return Response({
                'error': f'Error obteniendo información: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ReloadModelView(APIView):
    """
    API para recargar el modelo (útil después de reentrenar)
    POST /api/translator/reload-model/
    
    Response:
    {
        "success": true,
        "message": "Modelo recargado exitosamente",
        "signs_count": 3,
        "signs": ["bien", "mal", "tonto"]
    }
    """
    
    def post(self, request):
        try:
            success = translator_service.reload_model()
            
            if success:
                model_info = translator_service.get_model_info()
                return Response({
                    'success': True,
                    'message': 'Modelo recargado exitosamente',
                    'signs_count': model_info['signs_count'],
                    'signs': model_info['signs']
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Error recargando modelo',
                    'error': 'No se pudo cargar el archivo del modelo'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                
        except Exception as e:
            logger.error(f"Error recargando modelo: {e}")
            return Response({
                'success': False,
                'message': 'Error interno recargando modelo',
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AvailableSignsView(APIView):
    """
    API para obtener lista de señas disponibles
    GET /api/translator/available-signs/
    
    Response:
    {
        "signs": ["bien", "mal", "tonto"],
        "count": 3,
        "model_loaded": true
    }
    """
    
    def get(self, request):
        try:
            signs = translator_service.get_available_signs()
            is_loaded = translator_service.is_loaded
            
            return Response({
                'signs': signs,
                'count': len(signs),
                'model_loaded': is_loaded
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error obteniendo señas disponibles: {e}")
            return Response({
                'error': f'Error obteniendo señas: {str(e)}',
                'signs': [],
                'count': 0,
                'model_loaded': False
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class HealthCheckView(APIView):
    """
    API de health check para verificar que el servicio de traducción funciona
    GET /api/translator/health/
    
    Response:
    {
        "status": "healthy",
        "translator_loaded": true,
        "signs_available": 3,
        "timestamp": "2024-01-15T10:30:00Z"
    }
    """
    
    def get(self, request):
        from django.utils import timezone
        
        try:
            is_loaded = translator_service.is_loaded
            signs_count = len(translator_service.get_available_signs()) if is_loaded else 0
            
            return Response({
                'status': 'healthy' if is_loaded else 'model_not_loaded',
                'translator_loaded': is_loaded,
                'signs_available': signs_count,
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error en health check: {e}")
            return Response({
                'status': 'error',
                'translator_loaded': False,
                'signs_available': 0,
                'error': str(e),
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
# Añadir al final de translator/views.py

from .services.speech_service import tts_service, stt_service
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile

class TextToSpeechView(APIView):
    """
    API para convertir texto a voz
    POST /api/translator/text-to-speech/
    """
    
    def post(self, request):
        text = request.data.get('text', '')
        priority = request.data.get('priority', 'normal')
        
        if not text:
            return Response({'error': 'Campo "text" requerido'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        result = tts_service.speak_text(text, priority)
        return Response(result)

class SpeechToTextView(APIView):
    """
    API para convertir voz a texto
    POST /api/translator/speech-to-text/
    """
    
    def post(self, request):
        if 'audio' not in request.FILES:
            return Response({'error': 'Archivo de audio requerido'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        audio_file = request.FILES['audio']
        
        # Guardar temporalmente
        temp_path = default_storage.save(f'temp/{audio_file.name}', audio_file)
        
        try:
            result = stt_service.transcribe_audio_file(temp_path)
            return Response(result)
        finally:
            # Limpiar archivo temporal
            default_storage.delete(temp_path)