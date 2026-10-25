from datetime import datetime
from database.db import query_one

def format_currency(amount):
    """Formats amount as Indian Rupee style or standard currency."""
    try:
        return f"Rs. {float(amount):,.2f}"
    except (ValueError, TypeError):
        return f"Rs. {amount}"

def get_stats_overview():
    """Fetches high-level summary counts from the database."""
    sql = """
        SELECT 
            (SELECT COUNT(*) FROM USERS) as total_users,
            (SELECT COUNT(*) FROM MOVIES) as total_movies,
            (SELECT COUNT(*) FROM THEATRES) as total_theatres,
            (SELECT COUNT(*) FROM SCREENS) as total_screens,
            (SELECT COUNT(*) FROM SHOWS) as total_shows,
            (SELECT COUNT(*) FROM BOOKINGS WHERE booking_status = 'CONFIRMED') as total_bookings,
            (SELECT COUNT(*) FROM REVIEWS) as total_reviews,
            (SELECT NVL(SUM(total_amount), 0) FROM BOOKINGS WHERE booking_status = 'CONFIRMED') as total_revenue
        FROM DUAL
    """
    return query_one(sql)
