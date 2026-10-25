"""
MongoDB Setup and Migration Script for Smart Cinema Ticket Hub.
Migrates all tables and data from Oracle Database (or sample dataset) into MongoDB.
"""
import sys
import os
from pathlib import Path
from datetime import datetime, date
import pymongo

# Add project root to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from config import Config

MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
DB_NAME = os.getenv('MONGO_DB', 'cinemahub')

TABLES = [
    'USERS', 'MOVIES', 'THEATRES', 'SCREENS',
    'SEATS', 'SHOWS', 'BOOKINGS', 'BOOKING_SEATS', 'REVIEWS'
]

def serialize_value(val):
    """Converts dates/timestamps to ISO string or native format suitable for Mongo."""
    if isinstance(val, (datetime, date)):
        return val.isoformat()
    return val

def migrate_from_oracle(mongo_db):
    """Pulls existing data from Oracle DB and copies it into MongoDB collections."""
    try:
        from database.db import query_all, check_db_health
        is_up, msg = check_db_health()
        if not is_up:
            print(f"[!] Oracle DB health check failed: {msg}. Will try fallback data.")
            return False
    except Exception as e:
        print(f"[!] Could not connect to Oracle: {e}")
        return False

    print(">>> Connected to Oracle Database. Exporting tables into MongoDB...")
    for table in TABLES:
        col_name = table.lower()
        rows = query_all(f"SELECT * FROM {table}")
        
        # Clean rows
        cleaned_rows = []
        for r in rows:
            clean_doc = {k.lower(): serialize_value(v) for k, v in r.items()}
            cleaned_rows.append(clean_doc)

        col = mongo_db[col_name]
        col.drop() # Reset collection
        if cleaned_rows:
            col.insert_many(cleaned_rows)
            print(f"  [OK] Collection '{col_name}': Inserted {len(cleaned_rows)} documents.")
        else:
            print(f"  [--] Collection '{col_name}': Table was empty.")
    return True

def create_indexes(mongo_db):
    """Creates proper MongoDB indexes for query performance."""
    print(">>> Creating MongoDB indexes...")
    mongo_db.users.create_index([("email", pymongo.ASCENDING)], unique=True)
    mongo_db.users.create_index([("user_id", pymongo.ASCENDING)], unique=True)
    mongo_db.movies.create_index([("movie_id", pymongo.ASCENDING)], unique=True)
    mongo_db.theatres.create_index([("theatre_id", pymongo.ASCENDING)], unique=True)
    mongo_db.screens.create_index([("screen_id", pymongo.ASCENDING)], unique=True)
    mongo_db.screens.create_index([("theatre_id", pymongo.ASCENDING)])
    mongo_db.seats.create_index([("seat_id", pymongo.ASCENDING)], unique=True)
    mongo_db.seats.create_index([("screen_id", pymongo.ASCENDING), ("seat_number", pymongo.ASCENDING)])
    mongo_db.shows.create_index([("show_id", pymongo.ASCENDING)], unique=True)
    mongo_db.shows.create_index([("movie_id", pymongo.ASCENDING)])
    mongo_db.shows.create_index([("show_date", pymongo.ASCENDING)])
    mongo_db.bookings.create_index([("booking_id", pymongo.ASCENDING)], unique=True)
    mongo_db.bookings.create_index([("user_id", pymongo.ASCENDING)])
    mongo_db.booking_seats.create_index([("booking_seat_id", pymongo.ASCENDING)], unique=True)
    mongo_db.booking_seats.create_index([("booking_id", pymongo.ASCENDING)])
    mongo_db.reviews.create_index([("review_id", pymongo.ASCENDING)], unique=True)
    mongo_db.reviews.create_index([("movie_id", pymongo.ASCENDING)])
    mongo_db.reviews.create_index([("user_id", pymongo.ASCENDING)])
    print("  [OK] Indexes created successfully.")

def main():
    print("=" * 60)
    print(" SMART CINEMA TICKET HUB — MONGODB MIGRATION & SETUP")
    print("=" * 60)
    print(f"Connecting to MongoDB at: {MONGO_URI}")
    
    try:
        client = pymongo.MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
        client.server_info() # verify connection
        print("MongoDB connection verified successfully!")
    except Exception as e:
        print(f"[FATAL] Cannot connect to MongoDB: {e}")
        print("Please make sure MongoDB server (mongod) is running.")
        sys.exit(1)

    mongo_db = client[DB_NAME]
    
    success = migrate_from_oracle(mongo_db)
    if not success:
        print("[!] Could not migrate from Oracle directly.")
        sys.exit(1)

    create_indexes(mongo_db)

    print("\n" + "=" * 60)
    print(" MongoDB migration complete! Collections & document counts:")
    print("=" * 60)
    for col_name in mongo_db.list_collection_names():
        if not col_name.startswith("system."):
            count = mongo_db[col_name].count_documents({})
            print(f"  Collection: {col_name:<20} | Documents: {count}")
    print("=" * 60)
    print("All tables and data are now in MongoDB database 'cinemahub'!")

if __name__ == '__main__':
    main()
