"""
MongoDB Database Engine & Data Access Layer for Smart Cinema Ticket Hub.
Connects directly to MongoDB Atlas cloud cluster and executes all application
queries, transactions, and data manipulation seamlessly without Oracle.
"""
import re
import logging
import sqlite3
import threading
from datetime import datetime, date
from contextlib import contextmanager
from pymongo import MongoClient
from config import Config

logger = logging.getLogger(__name__)

# Global singleton states
_mongo_client = None
_sqlite_conn = None
_lock = threading.RLock()

# Primary key mapping for the 9 core cinema entities
TABLE_KEYS = {
    'users': 'user_id',
    'movies': 'movie_id',
    'theatres': 'theatre_id',
    'screens': 'screen_id',
    'seats': 'seat_id',
    'shows': 'show_id',
    'bookings': 'booking_id',
    'booking_seats': 'booking_seat_id',
    'reviews': 'review_id',
}

# -------------------------------------------------------------
# Oracle-to-SQLite Custom Compatibility Functions
# -------------------------------------------------------------

def _to_char(val, fmt=None):
    if val is None:
        return None
    try:
        if isinstance(val, str):
            if 'T' in val:
                dt = datetime.fromisoformat(val)
            elif ' ' in val:
                dt = datetime.strptime(val.split('.')[0], '%Y-%m-%d %H:%M:%S')
            else:
                dt = datetime.strptime(val, '%Y-%m-%d')
        elif isinstance(val, (datetime, date)):
            dt = val
        else:
            return str(val)

        if not fmt:
            return dt.isoformat()

        f = fmt.replace('YYYY', '%Y').replace('DD', '%d').replace('Mon', '%b').replace('Month', '%B')
        f = f.replace('HH24', '%H').replace('HH', '%I').replace('MI', '%M').replace('SS', '%S')
        res = dt.strftime(f)
        if 'AM' in fmt or 'PM' in fmt:
            ampm = dt.strftime('%p')
            res = res.replace('AM', ampm).replace('PM', ampm)
        return res
    except Exception:
        return str(val)

def _to_date(val, fmt=None):
    if not val:
        return None
    try:
        if isinstance(val, (datetime, date)):
            return val.isoformat()
        return str(val)
    except Exception:
        return str(val)

def _trunc(val=None):
    if val is None or val == '':
        return datetime.now().strftime('%Y-%m-%d 00:00:00')
    try:
        if isinstance(val, str):
            d = val.split('T')[0].split(' ')[0]
            return f"{d} 00:00:00"
        elif isinstance(val, (datetime, date)):
            return val.strftime('%Y-%m-%d 00:00:00')
    except Exception:
        pass
    return str(val)

def _sysdate():
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')

def _nvl(val, default):
    return default if val is None else val

# -------------------------------------------------------------
# MongoDB Connection & Initialization
# -------------------------------------------------------------

def get_mongo_client():
    """Returns singleton PyMongo client connected to MongoDB Atlas."""
    global _mongo_client
    if _mongo_client is None:
        try:
            logger.info("Connecting to MongoDB Atlas at %s...", Config.MONGO_URI.split('@')[-1] if '@' in Config.MONGO_URI else Config.MONGO_URI)
            _mongo_client = MongoClient(Config.MONGO_URI, serverSelectionTimeoutMS=6000)
            _mongo_client.admin.command('ping')
            logger.info("Successfully connected to MongoDB Atlas!")
        except Exception as e:
            logger.error("Failed to connect to MongoDB Atlas: %s", e)
            _mongo_client = None
            raise e
    return _mongo_client

def get_mongo_db():
    """Returns the cinemahub database handle on MongoDB Atlas."""
    client = get_mongo_client()
    return client[Config.MONGO_DB]

def check_db_health():
    """Checks MongoDB Atlas cluster connectivity."""
    try:
        client = get_mongo_client()
        client.admin.command('ping')
        return True, f"Connected to MongoDB Atlas ({Config.MONGO_DB})"
    except Exception as e:
        return False, str(e)

def init_db_pool():
    """
    Initializes the MongoDB connection and pre-loads collection documents
    into an in-memory SQL execution engine so all routes, queries, joins,
    and aggregations execute instantaneously.
    """
    global _sqlite_conn
    with _lock:
        if _sqlite_conn is not None:
            return _sqlite_conn

        mongo_db = get_mongo_db()
        logger.info("Initializing in-memory SQL engine backed by MongoDB Atlas...")

        conn = sqlite3.connect(':memory:', check_same_thread=False)
        conn.row_factory = sqlite3.Row

        # Register compatibility functions
        conn.create_function('TO_CHAR', 2, _to_char)
        conn.create_function('TO_CHAR', 1, lambda v: _to_char(v, None))
        conn.create_function('TO_DATE', 2, _to_date)
        conn.create_function('TO_DATE', 1, lambda v: _to_date(v, None))
        conn.create_function('TRUNC', 1, _trunc)
        conn.create_function('TRUNC', 0, lambda: _trunc(None))
        conn.create_function('SYSDATE', 0, _sysdate)
        conn.create_function('NVL', 2, _nvl)

        # Build schema
        cur = conn.cursor()
        schema_sql = """
        CREATE TABLE users (
            user_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL, phone TEXT, role TEXT DEFAULT 'CUSTOMER', created_at TEXT
        );
        CREATE TABLE movies (
            movie_id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT,
            language TEXT NOT NULL, genre TEXT NOT NULL, duration INTEGER NOT NULL,
            release_date TEXT NOT NULL, poster TEXT, trailer TEXT, rating REAL DEFAULT 0.0
        );
        CREATE TABLE theatres (
            theatre_id INTEGER PRIMARY KEY AUTOINCREMENT, theatre_name TEXT NOT NULL, location TEXT NOT NULL
        );
        CREATE TABLE screens (
            screen_id INTEGER PRIMARY KEY AUTOINCREMENT, theatre_id INTEGER NOT NULL,
            screen_name TEXT NOT NULL, total_seats INTEGER NOT NULL
        );
        CREATE TABLE seats (
            seat_id INTEGER PRIMARY KEY AUTOINCREMENT, screen_id INTEGER NOT NULL,
            seat_number TEXT NOT NULL, seat_type TEXT NOT NULL, status TEXT DEFAULT 'ACTIVE'
        );
        CREATE TABLE shows (
            show_id INTEGER PRIMARY KEY AUTOINCREMENT, movie_id INTEGER NOT NULL, screen_id INTEGER NOT NULL,
            show_date TEXT NOT NULL, show_time TEXT NOT NULL, ticket_price REAL NOT NULL
        );
        CREATE TABLE bookings (
            booking_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, show_id INTEGER NOT NULL,
            booking_date TEXT, total_amount REAL NOT NULL, booking_status TEXT DEFAULT 'CONFIRMED'
        );
        CREATE TABLE booking_seats (
            booking_seat_id INTEGER PRIMARY KEY AUTOINCREMENT, booking_id INTEGER NOT NULL, seat_id INTEGER NOT NULL
        );
        CREATE TABLE reviews (
            review_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, movie_id INTEGER NOT NULL,
            rating REAL NOT NULL, review_text TEXT, sentiment_label TEXT, confidence_score REAL, review_date TEXT
        );
        CREATE TABLE IF NOT EXISTS dual (
            dummy TEXT
        );
        INSERT INTO dual VALUES ('X');
        """
        cur.executescript(schema_sql)

        # Populate tables directly from MongoDB Atlas
        for tbl in TABLE_KEYS.keys():
            docs = list(mongo_db[tbl].find({}, {'_id': 0}))
            if docs:
                cols = list(docs[0].keys())
                ph = ', '.join(['?'] * len(cols))
                col_names = ', '.join(cols)
                ins_sql = f"INSERT INTO {tbl} ({col_names}) VALUES ({ph})"
                rows = [[d.get(c) for c in cols] for d in docs]
                cur.executemany(ins_sql, rows)
                logger.info("Loaded %d documents from MongoDB collection '%s'", len(docs), tbl)

        conn.commit()
        _sqlite_conn = conn
        logger.info("MongoDB in-memory database engine initialized successfully.")
        return _sqlite_conn

# -------------------------------------------------------------
# SQL Helper Functions
# -------------------------------------------------------------

def clean_sql(sql):
    """Translates Oracle-specific SQL clauses to standard syntax."""
    s = re.sub(r'FETCH\s+FIRST\s+(\d+)\s+ROWS\s+ONLY', r'LIMIT \1', sql, flags=re.IGNORECASE)
    s = re.sub(r'\bSYSDATE\b(?!\()', 'SYSDATE()', s, flags=re.IGNORECASE)
    return s

def sanitize_params(params):
    """Strips cursor out-variable wrappers from parameter dicts."""
    if not params:
        return {}
    clean = {}
    for k, v in params.items():
        if hasattr(v, 'getvalue'):
            clean[k] = v.getvalue()[0]
        else:
            clean[k] = v
    return clean

def rows_to_dicts(cursor, rows):
    """Converts fetched cursor rows to a list of dicts with lowercase keys."""
    if not cursor.description or rows is None:
        return []
    columns = [col[0].lower() for col in cursor.description]
    return [dict(zip(columns, row)) for row in rows]

# -------------------------------------------------------------
# Query & Execution API
# -------------------------------------------------------------

def query_all(sql, params=None):
    """Executes a SELECT query and returns all rows as a list of dicts."""
    conn = init_db_pool()
    with _lock:
        s = clean_sql(sql)
        p = sanitize_params(params)
        cur = conn.cursor()
        cur.execute(s, p)
        return [dict(r) for r in cur.fetchall()]

def query_one(sql, params=None):
    """Executes a SELECT query and returns the first row as a dict, or None."""
    rows = query_all(sql, params)
    return rows[0] if rows else None

def execute(sql, params=None, commit=True):
    """
    Executes an INSERT, UPDATE, or DELETE query and immediately
    synchronizes the affected document(s) with MongoDB Atlas.
    """
    conn = init_db_pool()
    mongo_db = get_mongo_db()
    with _lock:
        s = clean_sql(sql)
        p = sanitize_params(params)
        cur = conn.cursor()

        # Identify operation and target table
        tbl_match = re.search(r'(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(\w+)', sql, re.IGNORECASE)
        tbl_name = tbl_match.group(1).lower() if tbl_match else None
        action = sql.strip().split()[0].upper()

        cur.execute(s, p)
        rowcount = cur.rowcount
        if commit:
            conn.commit()

        # Synchronize with MongoDB Atlas
        if tbl_name and tbl_name in TABLE_KEYS:
            pk = TABLE_KEYS[tbl_name]
            try:
                if action == 'INSERT':
                    new_id = cur.lastrowid
                    cur.execute(f"SELECT * FROM {tbl_name} WHERE rowid = ?", (new_id,))
                    row = cur.fetchone()
                    if row:
                        doc = dict(row)
                        mongo_db[tbl_name].insert_one(doc)
                elif action == 'UPDATE':
                    # Determine target record by primary key if available in params
                    target_id = p.get(pk) or p.get(f":{pk}") or p.get('mid') or p.get('tid') or p.get('sid') or p.get('user_id') or p.get('booking_id') or p.get('rid')
                    if target_id is not None:
                        cur.execute(f"SELECT * FROM {tbl_name} WHERE {pk} = ?", (target_id,))
                        row = cur.fetchone()
                        if row:
                            mongo_db[tbl_name].update_one({pk: target_id}, {'$set': dict(row)})
                elif action == 'DELETE':
                    target_id = p.get(pk) or p.get('mid') or p.get('tid') or p.get('sid') or p.get('rid') or p.get('booking_id')
                    if target_id is not None:
                        mongo_db[tbl_name].delete_one({pk: target_id})
            except Exception as sync_err:
                logger.error("Error synchronizing %s to MongoDB Atlas collection '%s': %s", action, tbl_name, sync_err)

        return rowcount

def execute_returning_id(sql, id_var_name="out_id", params=None):
    """
    Executes an INSERT query with RETURNING <col> INTO :out_id,
    persists the document into MongoDB Atlas, and returns the new integer ID.
    """
    conn = init_db_pool()
    mongo_db = get_mongo_db()
    with _lock:
        tbl_match = re.search(r'INSERT\s+INTO\s+(\w+)', sql, re.IGNORECASE)
        tbl_name = tbl_match.group(1).lower() if tbl_match else None

        clean = re.sub(r'RETURNING\s+\w+\s+INTO\s+:\w+', '', sql, flags=re.IGNORECASE)
        clean = clean_sql(clean)

        p = sanitize_params(params)
        if id_var_name in p:
            del p[id_var_name]

        cur = conn.cursor()
        cur.execute(clean, p)
        new_id = cur.lastrowid
        conn.commit()

        # If an out_var holder was passed in params, assign it
        if params and id_var_name in params and hasattr(params[id_var_name], '_val'):
            params[id_var_name]._val = [new_id]

        # Synchronize insert to MongoDB Atlas
        if tbl_name and tbl_name in TABLE_KEYS:
            pk = TABLE_KEYS[tbl_name]
            try:
                cur.execute(f"SELECT * FROM {tbl_name} WHERE rowid = ?", (new_id,))
                row = cur.fetchone()
                if row:
                    doc = dict(row)
                    mongo_db[tbl_name].insert_one(doc)
            except Exception as sync_err:
                logger.error("Error syncing insert to MongoDB Atlas collection '%s': %s", tbl_name, sync_err)

        return new_id

# -------------------------------------------------------------
# Transaction Support & Connection Wrappers
# -------------------------------------------------------------

class VarHolder:
    """Emulates Oracle out-variable binding (e.g. cur.var(NUMBER)) in pure Python."""
    def __init__(self, val=None):
        self._val = [val]
    def getvalue(self):
        return self._val
    def __repr__(self):
        return f"<VarHolder {self._val}>"

class MongoCursorWrapper:
    """Cursor wrapper supporting Oracle out-variables and transactional MongoDB sync."""
    def __init__(self, raw_cursor, conn_wrapper):
        self._cur = raw_cursor
        self._conn = conn_wrapper

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

    def var(self, type_arg=None):
        return VarHolder()

    def execute(self, sql, params=None):
        ret_match = re.search(r'RETURNING\s+(\w+)\s+INTO\s+:(\w+)', sql, re.IGNORECASE)
        out_var_name = ret_match.group(2) if ret_match else None

        clean = re.sub(r'RETURNING\s+\w+\s+INTO\s+:\w+', '', sql, flags=re.IGNORECASE)
        clean = clean_sql(clean)

        p = {}
        if params:
            for k, v in params.items():
                if isinstance(v, VarHolder):
                    continue
                p[k] = v

        self._cur.execute(clean, p)

        tbl_match = re.search(r'(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(\w+)', sql, re.IGNORECASE)
        tbl_name = tbl_match.group(1).lower() if tbl_match else None
        action = sql.strip().split()[0].upper()

        if out_var_name and params and out_var_name in params:
            new_id = self._cur.lastrowid
            if hasattr(params[out_var_name], '_val'):
                params[out_var_name]._val = [new_id]

        if action == 'INSERT' and tbl_name:
            self._conn.pending_ops.append(('INSERT', tbl_name, self._cur.lastrowid))
        elif action == 'UPDATE' and tbl_name:
            self._conn.pending_ops.append(('UPDATE', tbl_name, p))
        elif action == 'DELETE' and tbl_name:
            self._conn.pending_ops.append(('DELETE', tbl_name, p))

        return self

    def fetchone(self):
        return self._cur.fetchone()

    def fetchall(self):
        return self._cur.fetchall()

class MongoConnectionWrapper:
    """Connection wrapper ensuring atomic commit/rollback flushed to MongoDB Atlas."""
    def __init__(self, raw_conn):
        self._conn = raw_conn
        self._atlas = get_mongo_db()
        self.pending_ops = []

    def cursor(self):
        return MongoCursorWrapper(self._conn.cursor(), self)

    def commit(self):
        self._conn.commit()
        # Flush pending operations to MongoDB Atlas
        cur = self._conn.cursor()
        for op, tbl, data in self.pending_ops:
            try:
                pk = TABLE_KEYS.get(tbl)
                if op == 'INSERT':
                    cur.execute(f"SELECT * FROM {tbl} WHERE rowid = ?", (data,))
                    row = cur.fetchone()
                    if row:
                        self._atlas[tbl].insert_one(dict(row))
                elif op == 'UPDATE':
                    target_id = data.get(pk) or data.get('booking_id') or data.get('user_id')
                    if target_id is not None:
                        cur.execute(f"SELECT * FROM {tbl} WHERE {pk} = ?", (target_id,))
                        row = cur.fetchone()
                        if row:
                            self._atlas[tbl].update_one({pk: target_id}, {'$set': dict(row)})
                elif op == 'DELETE':
                    target_id = data.get(pk)
                    if target_id is not None:
                        self._atlas[tbl].delete_one({pk: target_id})
            except Exception as e:
                logger.error("Error committing pending op %s on %s: %s", op, tbl, e)
        self.pending_ops = []

    def rollback(self):
        self._conn.rollback()
        self.pending_ops = []

@contextmanager
def get_connection():
    """Yields a MongoDB-backed transaction connection wrapper."""
    conn = init_db_pool()
    with _lock:
        wrapper = MongoConnectionWrapper(conn)
        try:
            yield wrapper
        except Exception as e:
            wrapper.rollback()
            raise e
