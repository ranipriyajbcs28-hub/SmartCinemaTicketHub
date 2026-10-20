import re
import sys
from pathlib import Path
import pandas as pd
import numpy as np
import joblib
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

BASE_DIR = Path(__file__).resolve().parent
DATASET_PATH = BASE_DIR / 'dataset' / 'reviews_training.csv'
MODEL_PATH = BASE_DIR / 'sentiment_model.pkl'
VECTORIZER_PATH = BASE_DIR / 'tfidf_vectorizer.pkl'

def clean_text(text):
    """Clean text by lowercasing, removing URLs, special characters, and extra spaces."""
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = re.sub(r'https?://\S+|www\.\S+', '', text)
    text = re.sub(r'[^a-zA-Z0-9\s.,!?]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def train_sentiment_model():
    print(f"Loading training dataset from {DATASET_PATH}...")
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f"Training dataset not found at {DATASET_PATH}")

    df = pd.read_csv(DATASET_PATH)
    print(f"Loaded {len(df)} records. Sentiment distribution:")
    print(df['sentiment'].value_counts())

    # Preprocess text
    df['cleaned_text'] = df['review_text'].apply(clean_text)

    # Train / Test split
    X_train, X_test, y_train, y_test = train_test_split(
        df['cleaned_text'],
        df['sentiment'],
        test_size=0.20,
        random_state=42,
        stratify=df['sentiment']
    )
    print(f"\nTraining set size: {len(X_train)}, Test set size: {len(X_test)}")

    # TF-IDF Vectorization
    print("Fitting TF-IDF Vectorizer (unigrams + bigrams)...")
    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        max_features=5000,
        stop_words='english',
        sublinear_tf=True
    )
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)

    # Train Logistic Regression
    print("Training Logistic Regression model...")
    model = LogisticRegression(
        max_iter=1000,
        C=1.5,
        solver='lbfgs',
        random_state=42
    )
    model.fit(X_train_vec, y_train)

    # Evaluation
    print("\n--- Model Evaluation on Test Set ---")
    y_pred = model.predict(X_test_vec)
    acc = accuracy_score(y_test, y_pred)
    print(f"Accuracy: {acc * 100:.2f}%\n")
    print("Classification Report:")
    print(classification_report(y_test, y_pred))

    print("Confusion Matrix:")
    labels = model.classes_
    cm = confusion_matrix(y_test, y_pred, labels=labels)
    cm_df = pd.DataFrame(cm, index=[f"Actual {l}" for l in labels], columns=[f"Pred {l}" for l in labels])
    print(cm_df)

    # Save artifacts
    print(f"\nSaving model to {MODEL_PATH}...")
    joblib.dump(model, MODEL_PATH)
    print(f"Saving vectorizer to {VECTORIZER_PATH}...")
    joblib.dump(vectorizer, VECTORIZER_PATH)
    print("Sentiment analysis model and vectorizer saved successfully!")

    # Demonstration test
    sample_tests = [
        "What an incredible experience! Visuals and music were unbelievable.",
        "Terrible waste of time. Boring, dull and the acting was horrible.",
        "It was an okay watch. Decent acting but nothing special overall."
    ]
    print("\n--- Sample Prediction Verification ---")
    for sample in sample_tests:
        cleaned = clean_text(sample)
        vec = vectorizer.transform([cleaned])
        pred_label = model.predict(vec)[0]
        probs = model.predict_proba(vec)[0]
        confidence = float(np.max(probs)) * 100.0
        print(f"Review: '{sample}'")
        print(f"Predicted: {pred_label} (Confidence: {confidence:.2f}%)\n")

if __name__ == '__main__':
    train_sentiment_model()
