"""
Smart Cinema Ticket Hub - Table Retrieval & Query Tool
Retrieve any table or run custom SQL queries on your cinema database.

Usage:
    python query_table.py                    # Lists all tables and record counts
    python query_table.py <table_name>       # Displays all rows of the table
    python query_table.py <table_name> 10    # Displays first 10 rows
    python query_table.py --sql "SELECT ..." # Runs a custom SQL query
"""

import sys
import sqlite3
from pathlib import Path
import pandas as pd

DB_PATH = Path(__file__).resolve().parent / "database" / "offline_cinema.db"

def get_connection():
    if not DB_PATH.exists():
        print(f"Error: Database file not found at {DB_PATH}")
        sys.exit(1)
    return sqlite3.connect(DB_PATH)

def list_tables(conn):
    cursor = conn.cursor()
    cursor.execute("""
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name NOT IN ('sqlite_sequence', 'dual')
        ORDER BY name;
    """)
    tables = [r[0] for r in cursor.fetchall()]
    
    print("\n" + "=" * 60)
    print("        SMART CINEMA TICKET HUB — DATABASE TABLES")
    print("=" * 60)
    print(f"{'Table Name':<20} | {'Record Count':<15} | Description")
    print("-" * 60)
    
    descriptions = {
        'users': 'Registered customers and admin credentials',
        'theatres': 'Cinema venues across 8 project districts',
        'screens': 'Auditoriums and projection types per theatre',
        'seats': 'Balcony & Regular seating rows and recliners',
        'movies': 'Movies catalog, release dates, ratings, posters',
        'shows': 'Scheduled movie showtimes and ticket pricing',
        'bookings': 'Customer reservation orders & payment states',
        'booking_seats': 'Individual reserved seats mapped to bookings',
        'reviews': 'Audience ratings, review text, & ML sentiment'
    }
    
    for t in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {t}")
        cnt = cursor.fetchone()[0]
        desc = descriptions.get(t.lower(), '')
        print(f"{t:<20} | {cnt:<15} | {desc}")
    print("=" * 60)
    print("\nTip: Run 'python query_table.py <table_name>' to view all records in a table.")
    print("Example: python query_table.py movies\n")

def show_table(conn, table_name, limit=None):
    # Validate table name against sqlite_master
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND LOWER(name)=LOWER(?);", (table_name,))
    row = cursor.fetchone()
    if not row:
        print(f"\n[ERROR] Table '{table_name}' does not exist.")
        list_tables(conn)
        return
    
    actual_name = row[0]
    query = f"SELECT * FROM {actual_name}"
    if limit:
        query += f" LIMIT {int(limit)}"
        
    df = pd.read_sql_query(query, conn)
    
    print("\n" + "=" * 80)
    print(f" TABLE: {actual_name.upper()} (Total rows shown: {len(df)})")
    print("=" * 80)
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', 1000)
    pd.set_option('display.max_colwidth', 40)
    print(df.to_string(index=False))
    print("=" * 80 + "\n")

def run_custom_sql(conn, sql):
    print("\n" + "=" * 80)
    print(f" EXECUTING CUSTOM SQL QUERY:")
    print(f" {sql}")
    print("=" * 80)
    try:
        df = pd.read_sql_query(sql, conn)
        pd.set_option('display.max_columns', None)
        pd.set_option('display.width', 1000)
        pd.set_option('display.max_colwidth', 40)
        print(df.to_string(index=False))
        print(f"\nTotal rows returned: {len(df)}")
    except Exception as e:
        print(f"[SQL ERROR]: {e}")
    print("=" * 80 + "\n")

if __name__ == '__main__':
    conn = get_connection()
    args = sys.argv[1:]
    
    if not args:
        list_tables(conn)
    elif args[0] == '--sql':
        if len(args) < 2:
            print("Please provide SQL string. E.g.: python query_table.py --sql \"SELECT * FROM movies\"")
        else:
            run_custom_sql(conn, " ".join(args[1:]))
    else:
        table = args[0]
        limit = args[1] if len(args) > 1 else None
        show_table(conn, table, limit)
    
    conn.close()
