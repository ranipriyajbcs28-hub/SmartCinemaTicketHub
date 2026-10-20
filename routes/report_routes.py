from flask import Blueprint, render_template, jsonify
from utils.auth import admin_required
from database.db import query_all, query_one

report_bp = Blueprint('report', __name__, url_prefix='/admin')

@report_bp.route('/reports')
@admin_required
def analytics_reports():
    """Generates dynamic analytical reports aggregated directly from transactional tables."""
    # 1. High-level totals
    summary_sql = """
        SELECT 
            (SELECT COUNT(*) FROM BOOKINGS WHERE booking_status = 'CONFIRMED') as total_bookings,
            (SELECT NVL(SUM(total_amount), 0) FROM BOOKINGS WHERE booking_status = 'CONFIRMED') as total_revenue,
            (SELECT COUNT(*) FROM USERS WHERE role = 'USER') as total_customers,
            (SELECT COUNT(*) FROM REVIEWS) as total_reviews
        FROM DUAL
    """
    summary = query_one(summary_sql)

    # 2. Movie Performance: Bookings & Revenue per Movie
    movie_perf_sql = """
        SELECT m.movie_id, m.title, m.genre, m.language,
               COUNT(b.booking_id) as booking_count,
               NVL(SUM(b.total_amount), 0) as total_revenue,
               NVL(ROUND(AVG(r.rating), 1), 0.0) as avg_rating,
               COUNT(DISTINCT r.review_id) as review_count
        FROM MOVIES m
        LEFT JOIN SHOWS s ON m.movie_id = s.movie_id
        LEFT JOIN BOOKINGS b ON s.show_id = b.show_id AND b.booking_status = 'CONFIRMED'
        LEFT JOIN REVIEWS r ON m.movie_id = r.movie_id
        GROUP BY m.movie_id, m.title, m.genre, m.language
        ORDER BY total_revenue DESC, booking_count DESC
    """
    movie_perf = query_all(movie_perf_sql)

    # 3. Theatre Performance: Bookings & Revenue per Theatre
    theatre_perf_sql = """
        SELECT t.theatre_id, t.theatre_name, t.location,
               COUNT(DISTINCT s.screen_id) as screen_count,
               COUNT(b.booking_id) as booking_count,
               NVL(SUM(b.total_amount), 0) as total_revenue
        FROM THEATRES t
        LEFT JOIN SCREENS s ON t.theatre_id = s.theatre_id
        LEFT JOIN SHOWS sh ON s.screen_id = sh.screen_id
        LEFT JOIN BOOKINGS b ON sh.show_id = b.show_id AND b.booking_status = 'CONFIRMED'
        GROUP BY t.theatre_id, t.theatre_name, t.location
        ORDER BY total_revenue DESC
    """
    theatre_perf = query_all(theatre_perf_sql)

    # 4. Sentiment Analytics per Movie
    sentiment_perf_sql = """
        SELECT m.title as movie_title,
               COUNT(CASE WHEN r.sentiment_label = 'Positive' THEN 1 END) as pos_count,
               COUNT(CASE WHEN r.sentiment_label = 'Negative' THEN 1 END) as neg_count,
               COUNT(CASE WHEN r.sentiment_label = 'Neutral' THEN 1 END) as neu_count,
               COUNT(r.review_id) as total_reviews
        FROM MOVIES m
        JOIN REVIEWS r ON m.movie_id = r.movie_id
        GROUP BY m.movie_id, m.title
        ORDER BY total_reviews DESC
    """
    sentiment_perf = query_all(sentiment_perf_sql)

    # 5. Top Active Customers
    user_activity_sql = """
        SELECT u.user_id, u.name, u.email,
               COUNT(b.booking_id) as booking_count,
               NVL(SUM(b.total_amount), 0) as total_spent,
               (SELECT COUNT(*) FROM REVIEWS WHERE user_id = u.user_id) as review_count
        FROM USERS u
        LEFT JOIN BOOKINGS b ON u.user_id = b.user_id AND b.booking_status = 'CONFIRMED'
        WHERE u.role = 'USER'
        GROUP BY u.user_id, u.name, u.email
        ORDER BY booking_count DESC, total_spent DESC
        FETCH FIRST 10 ROWS ONLY
    """
    user_activity = query_all(user_activity_sql)

    return render_template(
        'admin/reports.html',
        summary=summary,
        movie_perf=movie_perf,
        theatre_perf=theatre_perf,
        sentiment_perf=sentiment_perf,
        user_activity=user_activity
    )

@report_bp.route('/api/reports/summary')
@admin_required
def api_reports_summary():
    """Returns JSON payload for potential dynamic frontend graphing."""
    sql = """
        SELECT m.title, NVL(SUM(b.total_amount), 0) as revenue
        FROM MOVIES m
        LEFT JOIN SHOWS s ON m.movie_id = s.movie_id
        LEFT JOIN BOOKINGS b ON s.show_id = b.show_id AND b.booking_status = 'CONFIRMED'
        GROUP BY m.movie_id, m.title
        ORDER BY revenue DESC
    """
    data = query_all(sql)
    return jsonify(data)
