from flask import Blueprint, render_template, request, session, redirect, url_for, flash
from database.db import query_all, query_one
from services.recommendation_service import get_recommendations_for_user

movie_bp = Blueprint('movie', __name__)

@movie_bp.route('/')
@movie_bp.route('/welcome')
def welcome():
    """Welcome landing page for Smart Cinema Ticket Hub with platform overview and next login CTA."""
    try:
        movie_count = query_one("SELECT COUNT(*) as c FROM MOVIES")
        theatre_count = query_one("SELECT COUNT(*) as c FROM THEATRES")
        screen_count = query_one("SELECT COUNT(*) as c FROM SCREENS")
        stats = {
            'movies': movie_count.get('c', 8) if movie_count else 8,
            'theatres': theatre_count.get('c', 3) if theatre_count else 3,
            'screens': screen_count.get('c', 6) if screen_count else 6,
        }
    except Exception:
        stats = {'movies': 8, 'theatres': 3, 'screens': 6}
    return render_template('welcome.html', stats=stats)

@movie_bp.route('/home')
def index():
    """Cinema home page displaying running movies, upcoming releases, and personalized recommendations."""
    # 1. Currently running movies
    running_sql = """
        SELECT m.movie_id, m.title, m.description, m.language, m.genre, 
               m.duration, TO_CHAR(m.release_date, 'DD Mon YYYY') as release_date_str, 
               m.poster, m.trailer, m.rating,
               COUNT(s.show_id) as active_shows_count
        FROM MOVIES m
        LEFT JOIN SHOWS s ON m.movie_id = s.movie_id AND s.show_date >= TRUNC(SYSDATE)
        WHERE m.release_date <= TRUNC(SYSDATE)
        GROUP BY m.movie_id, m.title, m.description, m.language, m.genre, 
                 m.duration, m.release_date, m.poster, m.trailer, m.rating
        ORDER BY m.rating DESC
    """
    running_movies = query_all(running_sql)

    # 2. Upcoming movies
    upcoming_sql = """
        SELECT movie_id, title, description, language, genre, duration, 
               TO_CHAR(release_date, 'DD Mon YYYY') as release_date_str, 
               poster, trailer, rating
        FROM MOVIES
        WHERE release_date > TRUNC(SYSDATE)
        ORDER BY release_date ASC
    """
    upcoming_movies = query_all(upcoming_sql)

    # 3. Personalized SVD Recommendations if user is logged in
    recommendations_data = None
    if 'user_id' in session:
        user_id = session['user_id']
        recommendations_data = get_recommendations_for_user(user_id, top_n=4)

    # 4. Featured hero movie (top rated currently running)
    hero_movie = running_movies[0] if running_movies else None

    return render_template(
        'index.html',
        running_movies=running_movies,
        upcoming_movies=upcoming_movies,
        hero_movie=hero_movie,
        recommendations_data=recommendations_data
    )

@movie_bp.route('/movies')
def catalog():
    """Movie catalog with search by title and filtering by language, genre, theatre, and release date."""
    search_query = request.args.get('q', '').strip()
    selected_language = request.args.get('language', '').strip()
    selected_genre = request.args.get('genre', '').strip()
    selected_theatre = request.args.get('theatre_id', '').strip()
    status_filter = request.args.get('status', 'all').strip() # 'running', 'upcoming', or 'all'

    # Base query
    sql = """
        SELECT DISTINCT m.movie_id, m.title, m.description, m.language, m.genre, 
               m.duration, TO_CHAR(m.release_date, 'DD Mon YYYY') as release_date_str, 
               m.poster, m.trailer, m.rating,
               CASE WHEN m.release_date > TRUNC(SYSDATE) THEN 1 ELSE 0 END as is_upcoming
        FROM MOVIES m
        LEFT JOIN SHOWS s ON m.movie_id = s.movie_id
        LEFT JOIN SCREENS sc ON s.screen_id = sc.screen_id
        WHERE 1=1
    """
    params = {}

    if search_query:
        sql += " AND (LOWER(m.title) LIKE :q OR LOWER(m.description) LIKE :q)"
        params['q'] = f"%{search_query.lower()}%"

    if selected_language:
        sql += " AND m.language = :lang"
        params['lang'] = selected_language

    if selected_genre:
        sql += " AND m.genre = :genre"
        params['genre'] = selected_genre

    if selected_theatre:
        sql += " AND sc.theatre_id = :theatre_id"
        params['theatre_id'] = int(selected_theatre)

    if status_filter == 'running':
        sql += " AND m.release_date <= TRUNC(SYSDATE)"
    elif status_filter == 'upcoming':
        sql += " AND m.release_date > TRUNC(SYSDATE)"

    sql += " ORDER BY m.rating DESC, m.movie_id DESC"

    movies = query_all(sql, params)

    # Fetch filter options from database
    languages = [r['language'] for r in query_all("SELECT DISTINCT language FROM MOVIES ORDER BY language")]
    genres = [r['genre'] for r in query_all("SELECT DISTINCT genre FROM MOVIES ORDER BY genre")]
    theatres = query_all("SELECT theatre_id, theatre_name FROM THEATRES ORDER BY theatre_name")

    return render_template(
        'movies.html',
        movies=movies,
        languages=languages,
        genres=genres,
        theatres=theatres,
        search_query=search_query,
        selected_language=selected_language,
        selected_genre=selected_genre,
        selected_theatre=selected_theatre,
        status_filter=status_filter
    )

@movie_bp.route('/theatres')
@movie_bp.route('/theatres/<path:loc_path>')
def browse_theatres(loc_path=None):
    """
    Browse theatres available near the customer's selected location.
    Shows auditoriums, screens, upper Balcony amenities, and current scheduled showtimes.
    """
    selected_loc = request.args.get('location') or loc_path or session.get('selected_location') or ''
    if selected_loc.lower() in ('all', 'any', 'none'):
        selected_loc = ''

    if selected_loc:
        session['selected_location'] = selected_loc

    # Fetch all distinct locations for quick switcher pills
    loc_rows = query_all("SELECT DISTINCT location FROM THEATRES ORDER BY location")
    all_locations = [r['location'] for r in loc_rows if r.get('location')]

    # Query theatres matching location
    sql = """
        SELECT t.theatre_id, t.theatre_name, t.location,
               COUNT(DISTINCT sc.screen_id) as screen_count,
               NVL(SUM(sc.total_seats), 0) as total_seats,
               (SELECT COUNT(*) FROM SEATS s JOIN SCREENS sc2 ON s.screen_id = sc2.screen_id WHERE sc2.theatre_id = t.theatre_id AND s.seat_type = 'Balcony') as balcony_seats
        FROM THEATRES t
        LEFT JOIN SCREENS sc ON t.theatre_id = sc.theatre_id
        WHERE (:loc IS NULL OR :loc = '' OR LOWER(t.location) LIKE :loc_pat)
        GROUP BY t.theatre_id, t.theatre_name, t.location
        ORDER BY t.theatre_name
    """
    theatres = query_all(sql, {
        'loc': selected_loc,
        'loc_pat': f"%{selected_loc.lower()}%"
    })

    # For each theatre, fetch active shows & playing movies
    for t in theatres:
        tid = t['theatre_id']
        shows = query_all("""
            SELECT s.show_id, s.show_date, s.show_time, s.ticket_price,
                   TO_CHAR(s.show_date, 'Dy, DD Mon') as show_date_formatted,
                   m.movie_id, m.title as movie_title, m.poster, m.genre, m.language, m.rating,
                   sc.screen_name
            FROM SHOWS s
            JOIN MOVIES m ON s.movie_id = m.movie_id
            JOIN SCREENS sc ON s.screen_id = sc.screen_id
            WHERE sc.theatre_id = :tid AND s.show_date >= TRUNC(SYSDATE)
            ORDER BY s.show_date ASC, s.show_time ASC
            LIMIT 6
        """, {'tid': tid})
        t['shows'] = shows

    return render_template(
        'theatres.html',
        theatres=theatres,
        all_locations=all_locations,
        selected_location=selected_loc
    )

@movie_bp.route('/set-location', methods=['POST'])
def set_location():
    """Customer location switcher form endpoint."""
    loc = request.form.get('location', '').strip()
    session['selected_location'] = loc
    next_url = request.form.get('next')
    if loc and loc.lower() != 'all':
        flash(f"Location updated to: {loc}. Showing nearby theatres.", "info")
        return redirect(next_url or url_for('movie.browse_theatres', location=loc))
    else:
        session.pop('selected_location', None)
        flash("Viewing all cinema locations.", "info")
        return redirect(next_url or url_for('movie.browse_theatres'))

@movie_bp.route('/movie/<int:movie_id>')
def details(movie_id):
    """Detailed movie page showing metadata, available shows grouped by theatre/date, and reviews summary."""
    movie = query_one("""
        SELECT movie_id, title, description, language, genre, duration, 
               TO_CHAR(release_date, 'DD Mon YYYY') as release_date_str, 
               poster, trailer, rating,
               CASE WHEN release_date > TRUNC(SYSDATE) THEN 1 ELSE 0 END as is_upcoming
        FROM MOVIES 
        WHERE movie_id = :mid
    """, {'mid': movie_id})

    if not movie:
        return render_template('error.html', error_title="Movie Not Found", error_message="The requested movie could not be located in our catalog."), 404

    # Fetch shows for this movie
    shows_sql = """
        SELECT s.show_id, s.movie_id, s.screen_id,
               TO_CHAR(s.show_date, 'YYYY-MM-DD') as show_date,
               TO_CHAR(s.show_date, 'Dy, DD Mon') as show_date_formatted,
               s.show_time, s.ticket_price,
               sc.screen_name, sc.total_seats,
               t.theatre_id, t.theatre_name, t.location
        FROM SHOWS s
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
        WHERE s.movie_id = :mid AND s.show_date >= TRUNC(SYSDATE)
        ORDER BY s.show_date ASC, s.show_time ASC
    """
    shows = query_all(shows_sql, {'mid': movie_id})

    # Group shows by theatre and date
    theatres_dict = {}
    for s in shows:
        tid = s['theatre_id']
        if tid not in theatres_dict:
            theatres_dict[tid] = {
                'theatre_name': s['theatre_name'],
                'location': s['location'],
                'dates': {}
            }
        date_key = s['show_date_formatted']
        if date_key not in theatres_dict[tid]['dates']:
            theatres_dict[tid]['dates'][date_key] = []
        theatres_dict[tid]['dates'][date_key].append(s)

    # Fetch recent reviews
    reviews_sql = """
        SELECT r.review_id, r.rating, r.review_text, r.sentiment_label, r.confidence_score,
               TO_CHAR(r.review_date, 'DD Mon YYYY') as review_date_str,
               u.name as reviewer_name
        FROM REVIEWS r
        JOIN USERS u ON r.user_id = u.user_id
        WHERE r.movie_id = :mid
        ORDER BY r.review_date DESC
    """
    reviews = query_all(reviews_sql, {'mid': movie_id})

    # Sentiment distribution statistics
    sentiment_counts = {'Positive': 0, 'Negative': 0, 'Neutral': 0}
    total_reviews = len(reviews)
    avg_rating = movie['rating']

    if total_reviews > 0:
        for r in reviews:
            lbl = r['sentiment_label']
            if lbl in sentiment_counts:
                sentiment_counts[lbl] += 1
        avg_calc = sum([r['rating'] for r in reviews]) / total_reviews
    # Check viewer booking verification & admin status
    user_id = session.get('user_id')
    user_role = session.get('role')
    is_admin = (user_role == 'ADMIN')
    has_watched = False

    if user_id and not is_admin:
        bcheck = query_one("""
            SELECT b.booking_id 
            FROM BOOKINGS b
            JOIN SHOWS s ON b.show_id = s.show_id
            WHERE b.user_id = :uid AND s.movie_id = :mid AND b.booking_status = 'CONFIRMED'
        """, {'uid': user_id, 'mid': movie_id})
        if bcheck:
            has_watched = True

    can_review = bool(has_watched and not is_admin)

    return render_template(
        'movie_details.html',
        movie=movie,
        theatres_dict=theatres_dict,
        has_shows=len(shows) > 0,
        reviews=reviews,
        total_reviews=total_reviews,
        avg_rating=avg_rating,
        sentiment_counts=sentiment_counts,
        has_watched=has_watched,
        is_admin=is_admin,
        can_review=can_review
    )
