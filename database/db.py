import oracledb
import logging
from contextlib import contextmanager
from config import Config

logger = logging.getLogger(__name__)

# Global connection pool
_pool = None

def init_db_pool():
    """Initializes the Oracle Database connection pool."""
    global _pool
    if _pool is not None:
        return _pool

    try:
        logger.info("Initializing Oracle connection pool for user %s on %s", Config.ORACLE_USER, Config.ORACLE_DSN)
        _pool = oracledb.create_pool(
            user=Config.ORACLE_USER,
            password=Config.ORACLE_PASSWORD,
            dsn=Config.ORACLE_DSN,
            min=2,
            max=10,
            increment=1
        )
        logger.info("Oracle Connection Pool created successfully.")
        return _pool
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        logger.error("Failed to initialize Oracle connection pool: %s (Code: %s)", error_obj.message, error_obj.code)
        _pool = None
        return None
    except Exception as e:
        logger.error("Unexpected error creating Oracle connection pool: %s", str(e))
        _pool = None
        return None

def check_db_health():
    """Checks whether the database is accessible."""
    try:
        pool = init_db_pool()
        if not pool:
            # Try a direct connection fallback
            conn = oracledb.connect(
                user=Config.ORACLE_USER,
                password=Config.ORACLE_PASSWORD,
                dsn=Config.ORACLE_DSN
            )
            with conn.cursor() as cur:
                cur.execute("SELECT 1 FROM DUAL")
            conn.close()
            return True, "Connected (direct)"
        
        with pool.acquire() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1 FROM DUAL")
            return True, "Connected (pool)"
    except Exception as e:
        return False, str(e)

@contextmanager
def get_connection():
    """Context manager that yields an Oracle connection and guarantees release."""
    pool = init_db_pool()
    conn = None
    if pool is not None:
        try:
            conn = pool.acquire()
            yield conn
        finally:
            if conn is not None:
                pool.release(conn)
    else:
        # Fallback direct connection
        try:
            conn = oracledb.connect(
                user=Config.ORACLE_USER,
                password=Config.ORACLE_PASSWORD,
                dsn=Config.ORACLE_DSN
            )
            yield conn
        finally:
            if conn is not None:
                conn.close()

def rows_to_dicts(cursor, rows):
    """Converts fetched cursor rows to a list of dicts with lowercase keys."""
    if not cursor.description or rows is None:
        return []
    columns = [col[0].lower() for col in cursor.description]
    return [dict(zip(columns, row)) for row in rows]

def query_all(sql, params=None):
    """Executes a SELECT query and returns all rows as a list of dicts."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or {})
            rows = cur.fetchall()
            return rows_to_dicts(cur, rows)

def query_one(sql, params=None):
    """Executes a SELECT query and returns the first row as a dict, or None."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or {})
            row = cur.fetchone()
            if row is None:
                return None
            columns = [col[0].lower() for col in cur.description]
            return dict(zip(columns, row))

def execute(sql, params=None, commit=True):
    """Executes an INSERT, UPDATE, or DELETE query and optionally commits."""
    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute(sql, params or {})
                rowcount = cur.rowcount
            if commit:
                conn.commit()
            return rowcount
        except Exception as e:
            if commit:
                conn.rollback()
            raise e

def execute_returning_id(sql, id_var_name="out_id", params=None):
    """
    Executes an INSERT query with RETURNING <col> INTO :out_id and returns generated identity ID.
    Example: INSERT INTO USERS (...) VALUES (...) RETURNING user_id INTO :out_id
    """
    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                out_id = cur.var(oracledb.NUMBER)
                exec_params = dict(params or {})
                exec_params[id_var_name] = out_id
                cur.execute(sql, exec_params)
                new_id = int(out_id.getvalue()[0])
            conn.commit()
            return new_id
        except Exception as e:
            conn.rollback()
            raise e
