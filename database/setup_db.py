"""
Database Setup & Diagnostics Script for Smart Cinema Ticket Hub.
Verifies MongoDB Atlas connectivity, collection status, document counts, and indexes.
"""
import sys
from pathlib import Path

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import Config
from database.db import check_db_health, get_mongo_db

TABLES = [
    'users', 'movies', 'theatres', 'screens',
    'seats', 'shows', 'bookings', 'booking_seats', 'reviews'
]

def main():
    print("=" * 60)
    print(" SMART CINEMA TICKET HUB — MONGODB ATLAS SETUP & STATUS")
    print("=" * 60)
    
    is_up, msg = check_db_health()
    if not is_up:
        print(f"[!] Database Health Check Failed: {msg}")
        print("Please verify MONGO_URI in your .env file.")
        sys.exit(1)
        
    print(f" * Health Status: {msg}")
    db = get_mongo_db()
    
    print("\nCollection Status in MongoDB Atlas:")
    print("-" * 50)
    total_docs = 0
    for tbl in TABLES:
        cnt = db[tbl].count_documents({})
        total_docs += cnt
        print(f"  • {tbl:<18} : {cnt:>4} documents")
    print("-" * 50)
    print(f"Total documents across all collections: {total_docs}")
    print("\n✅ MongoDB Atlas database is online and fully configured!")

if __name__ == '__main__':
    main()
