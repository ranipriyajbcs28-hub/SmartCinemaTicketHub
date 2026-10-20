"""
MongoDB Database Connection and Query Utility Module for Smart Cinema Ticket Hub.
"""
import logging
from pymongo import MongoClient
from config import Config

logger = logging.getLogger(__name__)

_mongo_client = None

def get_mongo_client():
    """Returns a singleton PyMongo MongoClient instance."""
    global _mongo_client
    if _mongo_client is None:
        try:
            _mongo_client = MongoClient(Config.MONGO_URI, serverSelectionTimeoutMS=3000)
            # Trigger server_info to test connection
            _mongo_client.server_info()
            logger.info("Connected to MongoDB successfully at %s", Config.MONGO_URI)
        except Exception as e:
            logger.error("Failed to connect to MongoDB: %s", e)
            _mongo_client = None
            raise e
    return _mongo_client

def get_mongo_db():
    """Returns the cinema database handle."""
    client = get_mongo_client()
    return client[Config.MONGO_DB]

def check_mongo_health():
    """Checks if the MongoDB service is reachable."""
    try:
        client = get_mongo_client()
        client.admin.command('ping')
        return True, f"Connected to MongoDB ({Config.MONGO_DB})"
    except Exception as e:
        return False, str(e)

# -------------------------------------------------------------
# Data Retrieval Helper Functions
# -------------------------------------------------------------

def find_all(collection_name, filter_dict=None, projection=None, sort=None, limit=0):
    """
    Retrieves documents from a MongoDB collection.
    Example: find_all('movies', {'genre': 'Sci-Fi'}, sort=[('rating', -1)], limit=5)
    """
    db = get_mongo_db()
    col = db[collection_name.lower()]
    cursor = col.find(filter_dict or {}, projection)
    if sort:
        cursor = cursor.sort(sort)
    if limit > 0:
        cursor = cursor.limit(limit)
    return list(cursor)

def find_one(collection_name, filter_dict=None, projection=None):
    """
    Retrieves a single document from a MongoDB collection.
    Example: find_one('users', {'email': 'admin@cinema.com'})
    """
    db = get_mongo_db()
    col = db[collection_name.lower()]
    return col.find_one(filter_dict or {}, projection)

def insert_one(collection_name, document):
    """Inserts a single document and returns its inserted_id."""
    db = get_mongo_db()
    col = db[collection_name.lower()]
    result = col.insert_one(document)
    return result.inserted_id

def update_one(collection_name, filter_dict, update_dict):
    """Updates a single document matching the filter."""
    db = get_mongo_db()
    col = db[collection_name.lower()]
    result = col.update_one(filter_dict, {'$set': update_dict})
    return result.modified_count

def count_documents(collection_name, filter_dict=None):
    """Returns the count of documents in a collection."""
    db = get_mongo_db()
    col = db[collection_name.lower()]
    return col.count_documents(filter_dict or {})
