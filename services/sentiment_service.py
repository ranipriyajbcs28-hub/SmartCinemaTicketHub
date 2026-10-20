import re
import logging
from pathlib import Path
import joblib
import numpy as np
from config import Config

logger = logging.getLogger(__name__)

_model = None
_vectorizer = None

def clean_text(text):
    """Clean review text for vectorization."""
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = re.sub(r'https?://\S+|www\.\S+', '', text)
    text = re.sub(r'[^a-zA-Z0-9\s.,!?]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def load_sentiment_artifacts():
    """Loads the trained model and TF-IDF vectorizer."""
    global _model, _vectorizer
    if _model is not None and _vectorizer is not None:
        return _model, _vectorizer

    model_path = Config.SENTIMENT_MODEL_PATH
    vec_path = Config.TFIDF_VECTORIZER_PATH

    if not model_path.exists() or not vec_path.exists():
        logger.warning("Sentiment model or vectorizer not found. Triggering training...")
        from ml.train_model import train_sentiment_model
        train_sentiment_model()

    try:
        _model = joblib.load(model_path)
        _vectorizer = joblib.load(vec_path)
        logger.info("Sentiment model and vectorizer loaded successfully.")
        return _model, _vectorizer
    except Exception as e:
        logger.error("Failed to load sentiment model artifacts: %s", e)
        return None, None

def analyze_sentiment(review_text):
    """
    Analyzes review text and returns (sentiment_label, confidence_score).
    sentiment_label: 'Positive', 'Negative', or 'Neutral'
    confidence_score: float percentage (e.g., 87.45)
    """
    if not review_text or not review_text.strip():
        return 'Neutral', 50.0

    model, vectorizer = load_sentiment_artifacts()
    if model is None or vectorizer is None:
        # Graceful fallback if ML artifacts failed to load
        return 'Neutral', 50.0

    cleaned = clean_text(review_text)
    vec = vectorizer.transform([cleaned])
    
    # Predict label
    pred_label = model.predict(vec)[0]
    
    # Predict probability distribution
    probs = model.predict_proba(vec)[0]
    confidence = float(np.max(probs)) * 100.0
    
    # Round confidence to 2 decimal places
    confidence = round(confidence, 2)
    
    return str(pred_label), confidence
