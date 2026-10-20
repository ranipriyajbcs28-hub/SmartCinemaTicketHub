import re
import sys
from pathlib import Path
import oracledb

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import Config
from database.db import get_connection, check_db_health

def remove_comments(sql_text):
    """Removes single-line and multi-line SQL comments."""
    # Remove multi-line comments /* ... */
    sql_text = re.sub(r'/\*.*?\*/', '', sql_text, flags=re.DOTALL)
    # Remove single-line comments -- ...
    sql_text = re.sub(r'--.*$', '', sql_text, flags=re.MULTILINE)
    return sql_text

def execute_sql_file(file_path):
    """Executes an SQL file containing multiple Oracle statements separated by semicolons."""
    print(f"\n--- Executing {file_path.name} ---")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    cleaned_content = remove_comments(content)

    # Split statements by semicolon while respecting single quotes
    statements = []
    current = []
    in_quote = False
    for char in cleaned_content:
        if char == "'":
            in_quote = not in_quote
        if char == ';' and not in_quote:
            stmt = "".join(current).strip()
            if stmt:
                statements.append(stmt)
            current = []
        else:
            current.append(char)
    tail = "".join(current).strip()
    if tail:
        statements.append(tail)

    with get_connection() as conn:
        with conn.cursor() as cur:
            for stmt in statements:
                cleaned_stmt = stmt.strip()
                if not cleaned_stmt:
                    continue
                if cleaned_stmt.upper() == 'COMMIT':
                    conn.commit()
                    continue
                try:
                    cur.execute(cleaned_stmt)
                    # print short preview
                    preview = " ".join(cleaned_stmt.split())[:55]
                    print(f"OK: {preview}...")
                except oracledb.DatabaseError as e:
                    error_obj, = e.args
                    # ORA-00942: table or view does not exist (safe to ignore during DROP)
                    if error_obj.code == 942 and cleaned_stmt.upper().startswith("DROP"):
                        preview = " ".join(cleaned_stmt.split())[:55]
                        print(f"Notice (Table did not exist): {preview}...")
                    else:
                        preview = " ".join(cleaned_stmt.split())[:65]
                        print(f"Error on: {preview}... => {error_obj.message}")
                        raise e
        conn.commit()
    print(f"--- Completed {file_path.name} successfully ---\n")

def main():
    print("Connecting to Oracle Database...")
    is_healthy, msg = check_db_health()
    if not is_healthy:
        print(f"Database health check failed: {msg}")
        sys.exit(1)
    print(f"Database connection verified: {msg}")

    base_dir = Path(__file__).resolve().parent
    schema_path = base_dir / 'schema.sql'
    data_path = base_dir / 'sample_data.sql'

    try:
        execute_sql_file(schema_path)
        execute_sql_file(data_path)
        print("Database initialized with schema and sample data successfully!")
    except Exception as e:
        print(f"Fatal error during database setup: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
