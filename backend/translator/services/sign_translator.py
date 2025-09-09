# translator/services/sign_translator.py - Servicio de traducción de señas

import os
import json
import pickle
import numpy as np
from django.conf import settings
from sklearn.ensemble import RandomForestClassifier
import logging

logger = logging.getLogger(__name__)

class SignTranslatorService:
    """
    Servicio para traducir landmarks de señas a texto
    Basado en tu realtime_translator.py pero adaptado para Django
    """
    
    def __init__(self):
        self.model = None
        self.label_encoder = {}
        self.reverse_label_encoder = {}
        self.is_loaded = False
        
        # Rutas de archivos
        self.model_path = os.path.join(settings.BASE_DIR, 'static', 'models', 'modelo_secuencias.pkl')
        self.dataset_path = os.path.join(settings.BASE_DIR, 'static', 'models', 'secuencias_dataset.json')
        
        # Cargar modelo al inicializar
        self.load_model()
    
    def load_model(self):
        """
        Cargar modelo entrenado desde archivo
        """
        try:
            if not os.path.exists(self.model_path):
                logger.warning(f"Modelo no encontrado en: {self.model_path}")
                return False
            
            with open(self.model_path, "rb") as f:
                model_data = pickle.load(f)
            
            self.model = model_data['model']
            self.label_encoder = model_data['label_encoder']
            self.reverse_label_encoder = model_data['reverse_label_encoder']
            
            self.is_loaded = True
            logger.info("Modelo de traducción cargado exitosamente")
            logger.info(f"Labels disponibles: {list(self.reverse_label_encoder.values())}")
            return True
            
        except Exception as e:
            logger.error(f"Error cargando modelo: {e}")
            self.is_loaded = False
            return False
    
    def reload_model(self):
        """
        Recargar modelo (útil después de reentrenar)
        """
        self.is_loaded = False
        return self.load_model()
    
    def sequence_to_features(self, frames):
        """
        Convertir secuencia de frames a vector de features
        Mismo método que en tu realtime_translator.py
        """
        if len(frames) < 5:  # Mínimo 5 frames
            return None
        
        # Normalizar secuencia a tamaño fijo
        normalized_frames = self.normalize_sequence_length(frames, target_length=16)
        
        features = []
        for frame in normalized_frames:
            frame_features = self.frame_to_features(frame)
            features.extend(frame_features)
        
        return features
    
    def normalize_sequence_length(self, frames, target_length=12):
        """
        Normalizar secuencia a longitud fija
        """
        if len(frames) == target_length:
            return frames
        
        # Crear índices para interpolación
        original_indices = np.linspace(0, len(frames) - 1, len(frames))
        target_indices = np.linspace(0, len(frames) - 1, target_length)
        
        normalized_frames = []
        for target_idx in target_indices:
            # Encontrar frame más cercano
            closest_idx = int(round(target_idx))
            closest_idx = min(closest_idx, len(frames) - 1)
            normalized_frames.append(frames[closest_idx])
        
        return normalized_frames
    
    def frame_to_features(self, frame):
        """
        Convertir frame individual a vector de features
        """
        features = []
        
        # Cara (primeros 20 puntos) - 60 features
        if frame.get("face") and len(frame["face"]) >= 20:
            for i in range(20):
                if i < len(frame["face"]):
                    face_point = frame["face"][i]
                    features.extend([face_point["x"], face_point["y"], face_point["z"]])
                else:
                    features.extend([0, 0, 0])
        else:
            features.extend([0] * 60)
        
        # Pose (6 puntos clave) - 18 features
        pose_points = ["hombro_der", "hombro_izq", "codo_der", "codo_izq", "muneca_der", "muneca_izq"]
        for punto in pose_points:
            if frame.get("pose") and punto in frame["pose"]:
                pose_point = frame["pose"][punto]
                features.extend([pose_point["x"], pose_point["y"], pose_point["z"]])
            else:
                features.extend([0, 0, 0])
        
        # Manos (21 puntos cada una) - 126 features
        for hand_key in ["left_hand", "right_hand"]:
            if frame.get(hand_key) and len(frame[hand_key]) >= 21:
                for i in range(21):
                    if i < len(frame[hand_key]):
                        hand_point = frame[hand_key][i]
                        features.extend([hand_point["x"], hand_point["y"], hand_point["z"]])
                    else:
                        features.extend([0, 0, 0])
            else:
                features.extend([0] * 63)
        
        return features  # Total: 60 + 18 + 126 = 204 features por frame
    
    def predict_from_landmarks(self, landmarks_sequence, min_confidence=0.4):
        """
        Predecir seña desde secuencia de landmarks
        
        Args:
            landmarks_sequence: Lista de frames con landmarks
            min_confidence: Confianza mínima para aceptar predicción
            
        Returns:
            dict: {
                'prediction': str,
                'confidence': float,
                'success': bool,
                'message': str
            }
        """
        if not self.is_loaded:
            return {
                'prediction': None,
                'confidence': 0.0,
                'success': False,
                'message': 'Modelo no cargado'
            }
        
        if not landmarks_sequence or len(landmarks_sequence) < 5:
            return {
                'prediction': None,
                'confidence': 0.0,
                'success': False,
                'message': 'Secuencia muy corta (mínimo 5 frames)'
            }
        
        try:
            # Convertir a features
            sequence_features = self.sequence_to_features(landmarks_sequence)
            
            if sequence_features is None:
                return {
                    'prediction': None,
                    'confidence': 0.0,
                    'success': False,
                    'message': 'Error procesando landmarks'
                }
            
            # Predecir
            prediction_idx = self.model.predict([sequence_features])[0]
            probabilities = self.model.predict_proba([sequence_features])[0]
            confidence = max(probabilities)
            
            # Convertir índice a label
            predicted_label = self.reverse_label_encoder.get(prediction_idx, "desconocido")
            
            # Verificar confianza mínima
            if confidence < min_confidence:
                return {
                    'prediction': predicted_label,
                    'confidence': confidence,
                    'success': False,
                    'message': f'Confianza muy baja ({confidence:.2f} < {min_confidence})'
                }
            
            return {
                'prediction': predicted_label,
                'confidence': confidence,
                'success': True,
                'message': 'Predicción exitosa'
            }
            
        except Exception as e:
            logger.error(f"Error en predicción: {e}")
            return {
                'prediction': None,
                'confidence': 0.0,
                'success': False,
                'message': f'Error interno: {str(e)}'
            }
    
    def get_available_signs(self):
        """
        Obtener lista de señas disponibles
        """
        if not self.is_loaded:
            return []
        
        return list(self.reverse_label_encoder.values())
    
    def get_model_info(self):
        """
        Obtener información del modelo
        """
        if not self.is_loaded:
            return {
                'loaded': False,
                'signs_count': 0,
                'signs': [],
                'model_path': self.model_path,
                'dataset_path': self.dataset_path
            }
        
        return {
            'loaded': True,
            'signs_count': len(self.reverse_label_encoder),
            'signs': list(self.reverse_label_encoder.values()),
            'model_path': self.model_path,
            'dataset_path': self.dataset_path,
            'model_type': type(self.model).__name__
        }


# Instancia global del servicio (singleton)
translator_service = SignTranslatorService()