import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent

# Load .env file
load_dotenv(BASE_DIR / '.env')

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'Rani2007')
    
    # Oracle Database Settings
    #ORACLE_USER = os.getenv('ORACLE_USER', 'cinemahub')
    #ORACLE_PASSWORD = os.getenv('ORACLE_PASSWORD', 'cinemapass123')
    #ORACLE_DSN = os.getenv('ORACLE_DSN', 'localhost:1521/orclpdb')
    
    # MongoDB Settings
    MONGO_URI = os.getenv('MONGO_URI', 'mongodb+srv://ranipriya32007_db_user:Rani2007@cinema-cluster.blgigpj.mongodb.net/')
    MONGO_DB = os.getenv('MONGO_DB', 'cinemahub')
    DATABASE_TYPE = os.getenv('DATABASE_TYPE', 'mongodb') # 'mongodb' or 'oracle'
    
    # ML Models Paths
    ML_DIR = BASE_DIR / 'ml'
    SENTIMENT_MODEL_PATH = ML_DIR / 'sentiment_model.pkl'
    TFIDF_VECTORIZER_PATH = ML_DIR / 'tfidf_vectorizer.pkl'
    
    # Upload and Generated File Paths
    STATIC_DIR = BASE_DIR / 'static'
    UPLOAD_FOLDER = STATIC_DIR / 'images' / 'posters'
    GENERATED_FOLDER = STATIC_DIR / 'generated'
    
    # Session lifetime
    SESSION_PERMANENT = False
