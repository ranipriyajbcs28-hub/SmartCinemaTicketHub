import os
import uuid
from flask import Blueprint, render_template, request, redirect, url_for, flash
from werkzeug.utils import secure_filename
from config import Config
from utils.auth import admin_required
from utils.validators import is_positive_number, is_valid_rating
from database.db import query_all, query_one, execute, execute_returning_id

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp', 'gif'}

def allowed_file(filename):
    """Checks if an uploaded file has a permitted image extension."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def save_uploaded_poster(file_obj):
    """Saves an uploaded movie poster file and returns its static relative URL path."""
    if not file_obj or file_obj.filename == '':
        return None
    if allowed_file(file_obj.filename):
        ext = file_obj.filename.rsplit('.', 1)[1].lower()
        unique_name = f"poster_{uuid.uuid4().hex[:10]}.{ext}"
        upload_dir = Config.UPLOAD_FOLDER
        os.makedirs(upload_dir, exist_ok=True)
        target_path = os.path.join(upload_dir, unique_name)
        file_obj.save(target_path)
        return f"/static/images/posters/{unique_name}"
    return None

def auto_generate_screen_seats(screen_id, row_specs=None, layout_preset='varying_cinematic', balcony_seats=20, premium_seats=30, regular_seats=50, seats_per_row=10):
    """
    Generates structured physical seats across distinct tiers with realistic non-grid variation:
    Theatres seats are NOT in a fixed grid: seat counts vary from row to row, and
    screens feature upper Balcony tiers (luxury recliners with fewer seats per row)
    separated from stalls below.
    """
    total_generated = 0

    # 1. Direct row specifications provided
    if row_specs and isinstance(row_specs, list) and len(row_specs) > 0:
        for r in row_specs:
            row_char = str(r.get('row', 'A')).upper().strip()
            tier = r.get('tier', 'Regular')
            cnt = max(1, int(r.get('seats', 10)))
            for num in range(1, cnt + 1):
                seat_num = f"{row_char}{num}"
                execute("""
                    INSERT INTO SEATS (screen_id, seat_number, seat_type, status)
                    VALUES (:sid, :num, :type, 'ACTIVE')
                """, {'sid': screen_id, 'num': seat_num, 'type': tier})
                total_generated += 1
        return total_generated

    # 2. Layout Presets (Varying Row Lengths with Balcony Tier)
    if layout_preset == 'varying_cinematic':
        specs = [
            {'row': 'A', 'tier': 'Balcony', 'seats': 8},
            {'row': 'B', 'tier': 'Balcony', 'seats': 10},
            {'row': 'C', 'tier': 'Premium', 'seats': 12},
            {'row': 'D', 'tier': 'Premium', 'seats': 14},
            {'row': 'E', 'tier': 'Regular', 'seats': 16},
            {'row': 'F', 'tier': 'Regular', 'seats': 14},
            {'row': 'G', 'tier': 'Regular', 'seats': 12},
        ]
        return auto_generate_screen_seats(screen_id, row_specs=specs)

    elif layout_preset == 'varying_boutique':
        specs = [
            {'row': 'A', 'tier': 'Balcony', 'seats': 6},
            {'row': 'B', 'tier': 'Balcony', 'seats': 8},
            {'row': 'C', 'tier': 'Premium', 'seats': 10},
            {'row': 'D', 'tier': 'Regular', 'seats': 12},
        ]
        return auto_generate_screen_seats(screen_id, row_specs=specs)

    elif layout_preset == 'varying_imax':
        specs = [
            {'row': 'A', 'tier': 'Balcony', 'seats': 10},
            {'row': 'B', 'tier': 'Balcony', 'seats': 12},
            {'row': 'C', 'tier': 'Premium', 'seats': 16},
            {'row': 'D', 'tier': 'Premium', 'seats': 18},
            {'row': 'E', 'tier': 'Regular', 'seats': 20},
            {'row': 'F', 'tier': 'Regular', 'seats': 18},
            {'row': 'G', 'tier': 'Regular', 'seats': 16},
        ]
        return auto_generate_screen_seats(screen_id, row_specs=specs)

    # 3. Dynamic row calculation with varying lengths from balcony to stalls
    row_letters = [chr(i) for i in range(ord('A'), ord('Z') + 1)]
    current_row_idx = 0

    tiers = [
        ('Balcony', max(0, balcony_seats)),
        ('Premium', max(0, premium_seats)),
        ('Regular', max(0, regular_seats))
    ]

    for seat_type, seat_target in tiers:
        if seat_target <= 0:
            continue
        remaining = seat_target
        if seat_type == 'Balcony':
            row_cap = max(4, min(seats_per_row, 8))
        elif seat_type == 'Premium':
            row_cap = seats_per_row
        else:
            row_cap = seats_per_row + 2

        while remaining > 0 and current_row_idx < len(row_letters):
            row_char = row_letters[current_row_idx]
            count_in_row = min(remaining, row_cap)
            for num in range(1, count_in_row + 1):
                seat_num = f"{row_char}{num}"
                execute("""
                    INSERT INTO SEATS (screen_id, seat_number, seat_type, status)
                    VALUES (:sid, :num, :type, 'ACTIVE')
                """, {'sid': screen_id, 'num': seat_num, 'type': seat_type})
                total_generated += 1
            remaining -= count_in_row
            current_row_idx += 1

    return total_generated

@admin_bp.route('', strict_slashes=False)
@admin_bp.route('/', strict_slashes=False)
@admin_bp.route('/dashboard', strict_slashes=False)
@admin_required
def dashboard():
    """Admin dashboard overview with live metrics and recent activity."""
    stats_sql = """
        SELECT 
            (SELECT COUNT(*) FROM USERS) as total_users,
            (SELECT COUNT(*) FROM MOVIES) as total_movies,
            (SELECT COUNT(*) FROM THEATRES) as total_theatres,
            (SELECT COUNT(*) FROM SCREENS) as total_screens,
            (SELECT COUNT(*) FROM SHOWS) as total_shows,
            (SELECT COUNT(*) FROM BOOKINGS WHERE booking_status = 'CONFIRMED') as total_bookings,
            (SELECT COUNT(*) FROM REVIEWS) as total_reviews,
            (SELECT NVL(SUM(total_amount), 0) FROM BOOKINGS WHERE booking_status = 'CONFIRMED') as total_revenue,
            (SELECT COUNT(*) FROM REVIEWS WHERE sentiment_label = 'Positive') as positive_reviews,
            (SELECT COUNT(*) FROM REVIEWS WHERE sentiment_label = 'Negative') as negative_reviews,
            (SELECT COUNT(*) FROM REVIEWS WHERE sentiment_label = 'Neutral') as neutral_reviews
        FROM DUAL
    """
    stats = query_one(stats_sql)

    # Recent bookings
    recent_bookings = query_all("""
        SELECT b.booking_id, b.total_amount, b.booking_status, b.booking_status as status,
               TO_CHAR(b.booking_date, 'DD Mon, HH:MI AM') as booking_date_str,
               u.name as user_name, m.title as movie_title, s.show_time,
               t.theatre_name, sc.screen_name
        FROM BOOKINGS b
        JOIN USERS u ON b.user_id = u.user_id
        JOIN SHOWS s ON b.show_id = s.show_id
        JOIN MOVIES m ON s.movie_id = m.movie_id
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
        ORDER BY b.booking_date DESC
        FETCH FIRST 5 ROWS ONLY
    """)

    # Recent reviews
    recent_reviews = query_all("""
        SELECT r.review_id, r.rating, r.sentiment_label, r.confidence_score,
               u.name as user_name, m.title as movie_title
        FROM REVIEWS r
        JOIN USERS u ON r.user_id = u.user_id
        JOIN MOVIES m ON r.movie_id = m.movie_id
        ORDER BY r.review_date DESC
        FETCH FIRST 5 ROWS ONLY
    """)

    return render_template(
        'admin/dashboard.html',
        stats=stats,
        recent_bookings=recent_bookings,
        recent_reviews=recent_reviews
    )

# ---------------------------------------------------------------------
# MOVIE MANAGEMENT
# ---------------------------------------------------------------------
@admin_bp.route('/movies', methods=['GET', 'POST'])
@admin_required
def manage_movies():
    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        description = request.form.get('description', '').strip()
        language = request.form.get('language', '').strip()
        genre = request.form.get('genre', '').strip()
        duration = request.form.get('duration', '').strip()
        release_date = request.form.get('release_date', '').strip()
        poster_url = request.form.get('poster', '').strip()
        trailer = request.form.get('trailer', '').strip()
        rating = request.form.get('rating', '0.0').strip()

        if not title or not language or not genre or not duration or not release_date:
            flash("Please fill in all mandatory movie fields.", "danger")
            return redirect(url_for('admin.manage_movies'))

        try:
            dur_int = int(duration)
            rating_float = float(rating)
        except ValueError:
            flash("Invalid numeric format for duration or rating.", "danger")
            return redirect(url_for('admin.manage_movies'))

        # Check for uploaded poster picture file
        uploaded_poster = None
        if 'poster_file' in request.files:
            uploaded_poster = save_uploaded_poster(request.files['poster_file'])

        final_poster = uploaded_poster or poster_url or 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop'

        sql = """
            INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
            VALUES (:title, :description, :language, :genre, :duration, TO_DATE(:release_date, 'YYYY-MM-DD'), :poster, :trailer, :rating)
        """
        execute(sql, {
            'title': title,
            'description': description,
            'language': language,
            'genre': genre,
            'duration': dur_int,
            'release_date': release_date,
            'poster': final_poster,
            'trailer': trailer,
            'rating': rating_float
        })
        flash(f"Movie '{title}' added successfully with poster image!", "success")
        return redirect(url_for('admin.manage_movies'))

    movies = query_all("""
        SELECT movie_id, title, language, genre, duration,
               TO_CHAR(release_date, 'YYYY-MM-DD') as release_date_str,
               rating, poster, trailer,
               (SELECT COUNT(*) FROM SHOWS WHERE movie_id = MOVIES.movie_id) as show_count,
               (SELECT COUNT(*) FROM REVIEWS WHERE movie_id = MOVIES.movie_id) as review_count
        FROM MOVIES
        ORDER BY movie_id DESC
    """)
    return render_template('admin/movies.html', movies=movies)

@admin_bp.route('/movie/<int:movie_id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_movie(movie_id):
    movie = query_one("""
        SELECT movie_id, title, description, language, genre, duration,
               TO_CHAR(release_date, 'YYYY-MM-DD') as release_date_str,
               poster, trailer, rating
        FROM MOVIES WHERE movie_id = :mid
    """, {'mid': movie_id})

    if not movie:
        flash("Movie not found.", "danger")
        return redirect(url_for('admin.manage_movies'))

    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        description = request.form.get('description', '').strip()
        language = request.form.get('language', '').strip()
        genre = request.form.get('genre', '').strip()
        duration = int(request.form.get('duration', movie['duration']))
        release_date = request.form.get('release_date', movie['release_date_str'])
        poster_url = request.form.get('poster', '').strip()
        trailer = request.form.get('trailer', movie['trailer'])
        rating = float(request.form.get('rating', movie['rating']))

        # Handle uploaded poster replacement
        uploaded_poster = None
        if 'poster_file' in request.files:
            uploaded_poster = save_uploaded_poster(request.files['poster_file'])

        final_poster = uploaded_poster or poster_url or movie['poster']

        sql = """
            UPDATE MOVIES 
            SET title = :title, description = :description, language = :language,
                genre = :genre, duration = :duration, release_date = TO_DATE(:release_date, 'YYYY-MM-DD'),
                poster = :poster, trailer = :trailer, rating = :rating
            WHERE movie_id = :mid
        """
        execute(sql, {
            'title': title, 'description': description, 'language': language,
            'genre': genre, 'duration': duration, 'release_date': release_date,
            'poster': final_poster, 'trailer': trailer, 'rating': rating, 'mid': movie_id
        })
        flash(f"Movie '{title}' updated successfully.", "success")
        return redirect(url_for('admin.manage_movies'))

    return render_template('admin/edit_movie.html', movie=movie)

@admin_bp.route('/movie/<int:movie_id>/delete', methods=['POST'])
@admin_required
def delete_movie(movie_id):
    execute("DELETE FROM MOVIES WHERE movie_id = :mid", {'mid': movie_id})
    flash("Movie and associated shows/reviews deleted successfully.", "success")
    return redirect(url_for('admin.manage_movies'))

# ---------------------------------------------------------------------
# THEATRE MANAGEMENT & SEAT CAPACITY INPUT
# ---------------------------------------------------------------------
@admin_bp.route('/theatres', methods=['GET', 'POST'])
@admin_required
def manage_theatres():
    if request.method == 'POST':
        name = request.form.get('theatre_name', '').strip()
        location = request.form.get('location', '').strip()
        screen_name = request.form.get('screen_name', '').strip() or "Screen 1 - Main Audi"
        
        # User defined seating capacity across tiers
        balcony_seats_str = request.form.get('balcony_seats', '20').strip()
        premium_seats_str = request.form.get('premium_seats', '30').strip()
        regular_seats_str = request.form.get('regular_seats', '50').strip()
        seats_per_row_str = request.form.get('seats_per_row', '10').strip()

        if not name or not location:
            flash("Please provide theatre name and location.", "danger")
            return redirect(url_for('admin.manage_theatres'))

        try:
            balcony_seats = max(0, int(balcony_seats_str)) if balcony_seats_str else 0
            premium_seats = max(0, int(premium_seats_str)) if premium_seats_str else 0
            regular_seats = max(0, int(regular_seats_str)) if regular_seats_str else 0
            seats_per_row = max(2, min(30, int(seats_per_row_str))) if seats_per_row_str else 10
        except ValueError:
            balcony_seats, premium_seats, regular_seats, seats_per_row = 20, 30, 50, 10

        total_seats = balcony_seats + premium_seats + regular_seats
        if total_seats <= 0:
            total_seats = 100
            balcony_seats, premium_seats, regular_seats = 20, 30, 50

        # 1. Insert Theatre
        theatre_id = execute_returning_id("""
            INSERT INTO THEATRES (theatre_name, location) 
            VALUES (:name, :loc)
            RETURNING theatre_id INTO :out_id
        """, params={'name': name, 'loc': location})

        # 2. Insert Initial Screen with configured total seats
        screen_id = execute_returning_id("""
            INSERT INTO SCREENS (theatre_id, screen_name, total_seats)
            VALUES (:tid, :name, :seats)
            RETURNING screen_id INTO :out_id
        """, params={'tid': theatre_id, 'name': screen_name, 'seats': total_seats})

        # 3. Generate individual physical seats by tier (Balcony, Premium, Regular)
        generated_count = auto_generate_screen_seats(
            screen_id,
            balcony_seats=balcony_seats,
            premium_seats=premium_seats,
            regular_seats=regular_seats,
            seats_per_row=seats_per_row
        )

        flash(f"Theatre '{name}' added successfully with screen '{screen_name}' ({generated_count} seats: {balcony_seats} Balcony, {premium_seats} Premium, {regular_seats} Regular)!", "success")
        return redirect(url_for('admin.manage_theatres'))

    theatres = query_all("""
        SELECT t.theatre_id, t.theatre_name, t.location,
               COUNT(s.screen_id) as screen_count,
               NVL(SUM(s.total_seats), 0) as total_seats
        FROM THEATRES t
        LEFT JOIN SCREENS s ON t.theatre_id = s.theatre_id
        GROUP BY t.theatre_id, t.theatre_name, t.location
        ORDER BY t.theatre_id DESC
    """)
    return render_template('admin/theatres.html', theatres=theatres)

@admin_bp.route('/theatre/<int:theatre_id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_theatre(theatre_id):
    theatre = query_one("SELECT * FROM THEATRES WHERE theatre_id = :tid", {'tid': theatre_id})
    if not theatre:
        flash("Theatre not found.", "danger")
        return redirect(url_for('admin.manage_theatres'))

    if request.method == 'POST':
        name = request.form.get('theatre_name', '').strip()
        location = request.form.get('location', '').strip()
        execute("""
            UPDATE THEATRES 
            SET theatre_name = :name, location = :loc 
            WHERE theatre_id = :tid
        """, {'name': name, 'loc': location, 'tid': theatre_id})
        flash("Theatre updated successfully.", "success")
        return redirect(url_for('admin.manage_theatres'))

    screens = query_all("""
        SELECT s.screen_id, s.screen_name, s.total_seats,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id AND seat_type = 'Balcony') as balcony_count,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id AND seat_type = 'Premium') as premium_count,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id AND seat_type = 'Regular') as regular_count
        FROM SCREENS s
        WHERE s.theatre_id = :tid
        ORDER BY s.screen_id ASC
    """, {'tid': theatre_id})

    return render_template('admin/edit_theatre.html', theatre=theatre, screens=screens)

@admin_bp.route('/theatre/<int:theatre_id>/delete', methods=['POST'])
@admin_required
def delete_theatre(theatre_id):
    execute("DELETE FROM THEATRES WHERE theatre_id = :tid", {'tid': theatre_id})
    flash("Theatre and its screens deleted successfully.", "success")
    return redirect(url_for('admin.manage_theatres'))

# ---------------------------------------------------------------------
# SCREEN MANAGEMENT & AUTO SEAT GENERATION
# ---------------------------------------------------------------------
@admin_bp.route('/screens', methods=['GET', 'POST'])
@admin_required
def manage_screens():
    if request.method == 'POST':
        theatre_id = request.form.get('theatre_id')
        screen_name = request.form.get('screen_name', '').strip()
        layout_mode = request.form.get('layout_mode', 'varying_cinematic').strip()

        if not theatre_id or not screen_name:
            flash("Theatre venue and screen name are required.", "danger")
            return redirect(url_for('admin.manage_screens'))

        try:
            tid = int(theatre_id)
        except ValueError:
            flash("Invalid theatre selection.", "danger")
            return redirect(url_for('admin.manage_screens'))

        row_specs = []
        # Check if custom row builder submitted
        if layout_mode == 'custom_rows':
            row_chars = request.form.getlist('custom_row_char[]')
            row_tiers = request.form.getlist('custom_row_tier[]')
            row_seats = request.form.getlist('custom_row_seats[]')

            for r_char, r_tier, r_cnt in zip(row_chars, row_tiers, row_seats):
                if r_char and r_cnt:
                    try:
                        c_val = max(1, min(30, int(r_cnt)))
                        row_specs.append({'row': r_char.upper().strip(), 'tier': r_tier or 'Regular', 'seats': c_val})
                    except ValueError:
                        pass

        if not row_specs and layout_mode == 'custom_rows':
            layout_mode = 'varying_cinematic'

        # Estimate total seats for screen insertion
        if row_specs:
            total_seats = sum(r['seats'] for r in row_specs)
        elif layout_mode == 'varying_cinematic':
            total_seats = 86
        elif layout_mode == 'varying_boutique':
            total_seats = 24
        elif layout_mode == 'varying_imax':
            total_seats = 110
        else:
            # Fallback legacy grid parsing
            b_seats = int(request.form.get('balcony_seats', 20) or 20)
            p_seats = int(request.form.get('premium_seats', 30) or 30)
            r_seats = int(request.form.get('regular_seats', 50) or 50)
            total_seats = b_seats + p_seats + r_seats

        screen_id = execute_returning_id("""
            INSERT INTO SCREENS (theatre_id, screen_name, total_seats)
            VALUES (:tid, :name, :seats)
            RETURNING screen_id INTO :out_id
        """, params={'tid': tid, 'name': screen_name, 'seats': total_seats})

        # Generate non-grid varying seats with Balcony
        if row_specs:
            generated_count = auto_generate_screen_seats(screen_id, row_specs=row_specs)
        elif layout_mode in ('varying_cinematic', 'varying_boutique', 'varying_imax'):
            generated_count = auto_generate_screen_seats(screen_id, layout_preset=layout_mode)
        else:
            b_s = int(request.form.get('balcony_seats', 20) or 20)
            p_s = int(request.form.get('premium_seats', 30) or 30)
            r_s = int(request.form.get('regular_seats', 50) or 50)
            s_p_r = int(request.form.get('seats_per_row', 10) or 10)
            generated_count = auto_generate_screen_seats(
                screen_id, balcony_seats=b_s, premium_seats=p_s, regular_seats=r_s, seats_per_row=s_p_r
            )

        # Update actual count
        execute("UPDATE SCREENS SET total_seats = :cnt WHERE screen_id = :sid", {'cnt': generated_count, 'sid': screen_id})

        flash(f"Auditorium '{screen_name}' created successfully with {generated_count} seats (varying from row to row, with Balcony tier)!", "success")
        return redirect(url_for('admin.manage_screens'))

    screens = query_all("""
        SELECT s.screen_id, s.screen_name, s.total_seats,
               t.theatre_id, t.theatre_name,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id AND seat_type = 'Balcony') as balcony_count,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id AND seat_type = 'Premium') as premium_count,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id AND seat_type = 'Regular') as regular_count,
               (SELECT COUNT(*) FROM SEATS WHERE screen_id = s.screen_id) as actual_seats_count,
               (SELECT COUNT(*) FROM SHOWS WHERE screen_id = s.screen_id) as show_count
        FROM SCREENS s
        JOIN THEATRES t ON s.theatre_id = t.theatre_id
        ORDER BY s.screen_id DESC
    """)
    theatres = query_all("SELECT theatre_id, theatre_name FROM THEATRES ORDER BY theatre_name")
    return render_template('admin/screens.html', screens=screens, theatres=theatres)

@admin_bp.route('/screen/<int:screen_id>/delete', methods=['POST'])
@admin_required
def delete_screen(screen_id):
    execute("DELETE FROM SCREENS WHERE screen_id = :sid", {'sid': screen_id})
    flash("Screen deleted successfully.", "success")
    return redirect(url_for('admin.manage_screens'))

# ---------------------------------------------------------------------
# SEAT MANAGEMENT
# ---------------------------------------------------------------------
@admin_bp.route('/seats/<int:screen_id>')
@admin_required
def manage_seats(screen_id):
    screen = query_one("""
        SELECT s.screen_id, s.screen_name, s.total_seats, t.theatre_id, t.theatre_name
        FROM SCREENS s
        JOIN THEATRES t ON s.theatre_id = t.theatre_id
        WHERE s.screen_id = :sid
    """, {'sid': screen_id})

    if not screen:
        flash("Screen not found.", "danger")
        return redirect(url_for('admin.manage_screens'))

    seats = query_all("""
        SELECT seat_id, seat_number, seat_type, status
        FROM SEATS
        WHERE screen_id = :sid
    """, {'sid': screen_id})

    # Natural numeric sorting: A1, A2... A9, A10...
    def seat_sort_key(s):
        num_str = s['seat_number']
        row = num_str[0] if num_str else 'A'
        digits = ''.join(filter(str.isdigit, num_str))
        val = int(digits) if digits else 0
        return (row, val)

    seats.sort(key=seat_sort_key)

    # Group seats by tier and row
    tier_order = ['Balcony', 'Premium', 'Regular']
    tiers_dict = {t: {} for t in tier_order}
    row_counts = {}

    for s in seats:
        stype = s.get('seat_type', 'Regular')
        if stype not in tiers_dict:
            tiers_dict[stype] = {}
        row = s['seat_number'][0] if s['seat_number'] else 'A'
        if row not in tiers_dict[stype]:
            tiers_dict[stype][row] = []
        tiers_dict[stype][row].append(s)
        row_counts[row] = row_counts.get(row, 0) + 1

    # Filter out empty tiers
    active_tiers = {k: v for k, v in tiers_dict.items() if v}

    # Calculate row variation metrics
    unique_row_counts = set(row_counts.values())
    is_varying = len(unique_row_counts) > 1

    # Determine next available row letter
    existing_letters = set(row_counts.keys())
    next_row_letter = 'A'
    for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        if c not in existing_letters:
            next_row_letter = c
            break

    balcony_count = sum(1 for s in seats if s.get('seat_type') == 'Balcony')
    premium_count = sum(1 for s in seats if s.get('seat_type') == 'Premium')
    regular_count = sum(1 for s in seats if s.get('seat_type') == 'Regular')

    return render_template(
        'admin/seats.html',
        screen=screen,
        seats=seats,
        tiers_dict=active_tiers,
        row_counts=row_counts,
        is_varying=is_varying,
        next_row_letter=next_row_letter,
        balcony_count=balcony_count,
        premium_count=premium_count,
        regular_count=regular_count,
        total_seats=len(seats)
    )

@admin_bp.route('/seats/<int:screen_id>/apply-profile', methods=['POST'])
@admin_required
def apply_seat_profile(screen_id):
    profile = request.form.get('profile', 'varying_cinematic')
    
    # Check if any bookings exist for shows on this screen
    booked = query_one("""
        SELECT COUNT(*) as c 
        FROM BOOKING_SEATS bs
        JOIN SEATS s ON bs.seat_id = s.seat_id
        WHERE s.screen_id = :sid
    """, {'sid': screen_id})
    
    if booked and booked['c'] > 0:
        flash(f"Cannot completely regenerate seat plan: {booked['c']} seats on this screen are associated with confirmed ticket bookings.", "warning")
        return redirect(url_for('admin.manage_seats', screen_id=screen_id))

    execute("DELETE FROM SEATS WHERE screen_id = :sid", {'sid': screen_id})
    new_count = auto_generate_screen_seats(screen_id, layout_preset=profile)
    execute("UPDATE SCREENS SET total_seats = :cnt WHERE screen_id = :sid", {'cnt': new_count, 'sid': screen_id})

    flash(f"Realistic non-grid seating profile '{profile}' applied successfully ({new_count} seats with Balcony & varying rows)!", "success")
    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

@admin_bp.route('/seats/<int:screen_id>/add-row', methods=['POST'])
@admin_required
def add_screen_row(screen_id):
    row_char = request.form.get('row_letter', '').upper().strip()
    seat_type = request.form.get('seat_type', 'Regular')
    count_str = request.form.get('seat_count', '10')

    if not row_char or len(row_char) != 1 or not row_char.isalpha():
        flash("Please provide a single valid letter (A-Z) for the row.", "danger")
        return redirect(url_for('admin.manage_seats', screen_id=screen_id))

    try:
        cnt = max(1, min(30, int(count_str)))
    except ValueError:
        cnt = 10

    # Check if row already exists
    existing = query_one("SELECT seat_id FROM SEATS WHERE screen_id = :sid AND seat_number LIKE :pat", {'sid': screen_id, 'pat': f"{row_char}%"})
    if existing:
        flash(f"Row {row_char} already exists on this screen. Use '+ Add Seat' to expand row capacity.", "warning")
        return redirect(url_for('admin.manage_seats', screen_id=screen_id))

    for i in range(1, cnt + 1):
        execute("""
            INSERT INTO SEATS (screen_id, seat_number, seat_type, status)
            VALUES (:sid, :num, :type, 'ACTIVE')
        """, {'sid': screen_id, 'num': f"{row_char}{i}", 'type': seat_type})

    # Update screen capacity
    cur_count = query_one("SELECT COUNT(*) as c FROM SEATS WHERE screen_id = :sid", {'sid': screen_id})
    execute("UPDATE SCREENS SET total_seats = :cnt WHERE screen_id = :sid", {'cnt': cur_count['c'], 'sid': screen_id})

    flash(f"Row {row_char} added with {cnt} {seat_type} seats successfully! Auditorium rows now vary in length.", "success")
    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

@admin_bp.route('/seats/<int:screen_id>/add-seat-to-row', methods=['POST'])
@admin_required
def add_seat_to_row(screen_id):
    row_char = request.form.get('row_letter', '').upper().strip()
    seat_type = request.form.get('seat_type', 'Regular')

    if not row_char:
        flash("Row letter required.", "danger")
        return redirect(url_for('admin.manage_seats', screen_id=screen_id))

    # Find maximum seat number in this row
    row_seats = query_all("SELECT seat_number, seat_type FROM SEATS WHERE screen_id = :sid AND seat_number LIKE :pat", {'sid': screen_id, 'pat': f"{row_char}%"})
    max_num = 0
    inferred_type = seat_type
    for s in row_seats:
        digits = ''.join(filter(str.isdigit, s['seat_number']))
        if digits:
            max_num = max(max_num, int(digits))
        inferred_type = s['seat_type']

    next_num = max_num + 1
    new_seat_num = f"{row_char}{next_num}"

    execute("""
        INSERT INTO SEATS (screen_id, seat_number, seat_type, status)
        VALUES (:sid, :num, :type, 'ACTIVE')
    """, {'sid': screen_id, 'num': new_seat_num, 'type': inferred_type})

    cur_count = query_one("SELECT COUNT(*) as c FROM SEATS WHERE screen_id = :sid", {'sid': screen_id})
    execute("UPDATE SCREENS SET total_seats = :cnt WHERE screen_id = :sid", {'cnt': cur_count['c'], 'sid': screen_id})

    flash(f"Seat {new_seat_num} added to Row {row_char}! (Row {row_char} capacity: {next_num} seats).", "success")
    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

@admin_bp.route('/seats/<int:screen_id>/remove-seat-from-row', methods=['POST'])
@admin_required
def remove_seat_from_row(screen_id):
    row_char = request.form.get('row_letter', '').upper().strip()

    row_seats = query_all("SELECT seat_id, seat_number FROM SEATS WHERE screen_id = :sid AND seat_number LIKE :pat", {'sid': screen_id, 'pat': f"{row_char}%"})
    if not row_seats:
        flash(f"No seats found in Row {row_char}.", "warning")
        return redirect(url_for('admin.manage_seats', screen_id=screen_id))

    # Find highest number seat
    highest_seat = None
    max_num = -1
    for s in row_seats:
        digits = ''.join(filter(str.isdigit, s['seat_number']))
        val = int(digits) if digits else 0
        if val > max_num:
            max_num = val
            highest_seat = s

    if highest_seat:
        # Check booking
        booked = query_one("SELECT booking_seat_id FROM BOOKING_SEATS WHERE seat_id = :sid", {'sid': highest_seat['seat_id']})
        if booked:
            flash(f"Seat {highest_seat['seat_number']} cannot be removed: already reserved in a customer booking.", "danger")
            return redirect(url_for('admin.manage_seats', screen_id=screen_id))

        execute("DELETE FROM SEATS WHERE seat_id = :sid", {'sid': highest_seat['seat_id']})
        cur_count = query_one("SELECT COUNT(*) as c FROM SEATS WHERE screen_id = :sid", {'sid': screen_id})
        execute("UPDATE SCREENS SET total_seats = :cnt WHERE screen_id = :sid", {'cnt': cur_count['c'], 'sid': screen_id})
        flash(f"Seat {highest_seat['seat_number']} removed from Row {row_char}.", "info")

    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

@admin_bp.route('/seats/<int:screen_id>/change-row-tier', methods=['POST'])
@admin_required
def change_row_tier(screen_id):
    row_char = request.form.get('row_letter', '').upper().strip()
    new_tier = request.form.get('new_tier', 'Regular')

    if row_char and new_tier in ('Balcony', 'Premium', 'Regular'):
        execute("UPDATE SEATS SET seat_type = :tier WHERE screen_id = :sid AND seat_number LIKE :pat", {
            'tier': new_tier, 'sid': screen_id, 'pat': f"{row_char}%"
        })
        flash(f"Row {row_char} converted to '{new_tier}' tier.", "success")

    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

@admin_bp.route('/seats/<int:screen_id>/toggle-seat-status/<int:seat_id>', methods=['POST'])
@admin_required
def toggle_seat_status(screen_id, seat_id):
    seat = query_one("SELECT seat_id, status, seat_number FROM SEATS WHERE seat_id = :sid AND screen_id = :scid", {'sid': seat_id, 'scid': screen_id})
    if seat:
        new_status = 'MAINTENANCE' if seat['status'] == 'ACTIVE' else 'ACTIVE'
        execute("UPDATE SEATS SET status = :st WHERE seat_id = :sid", {'st': new_status, 'sid': seat_id})
        flash(f"Seat {seat['seat_number']} status changed to {new_status}.", "info")
    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

@admin_bp.route('/seats/<int:screen_id>/delete-seat/<int:seat_id>', methods=['POST'])
@admin_required
def delete_seat(screen_id, seat_id):
    booked = query_one("SELECT booking_seat_id FROM BOOKING_SEATS WHERE seat_id = :sid", {'sid': seat_id})
    if booked:
        flash("Cannot delete a seat with active bookings.", "danger")
        return redirect(url_for('admin.manage_seats', screen_id=screen_id))

    execute("DELETE FROM SEATS WHERE seat_id = :sid AND screen_id = :scid", {'sid': seat_id, 'scid': screen_id})
    cur_count = query_one("SELECT COUNT(*) as c FROM SEATS WHERE screen_id = :sid", {'sid': screen_id})
    execute("UPDATE SCREENS SET total_seats = :cnt WHERE screen_id = :sid", {'cnt': cur_count['c'], 'sid': screen_id})
    flash("Seat removed successfully.", "info")
    return redirect(url_for('admin.manage_seats', screen_id=screen_id))

# ---------------------------------------------------------------------
# SHOW MANAGEMENT
# ---------------------------------------------------------------------
@admin_bp.route('/shows', methods=['GET', 'POST'])
@admin_required
def manage_shows():
    if request.method == 'POST':
        movie_id = request.form.get('movie_id')
        screen_id = request.form.get('screen_id')
        show_date = request.form.get('show_date')
        show_time = request.form.get('show_time', '').strip()
        ticket_price = request.form.get('ticket_price')

        if not movie_id or not screen_id or not show_date or not show_time or not ticket_price:
            flash("All show fields are required.", "danger")
            return redirect(url_for('admin.manage_shows'))

        try:
            mid = int(movie_id)
            scid = int(screen_id)
            price = float(ticket_price)
            if price <= 0:
                raise ValueError("Price must be positive")
        except ValueError:
            flash("Invalid ID or price number format.", "danger")
            return redirect(url_for('admin.manage_shows'))

        execute("""
            INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price)
            VALUES (:mid, :scid, TO_DATE(:sdate, 'YYYY-MM-DD'), :stime, :price)
        """, {
            'mid': mid, 'scid': scid, 'sdate': show_date, 'stime': show_time, 'price': price
        })
        flash("New cinema show scheduled successfully!", "success")
        return redirect(url_for('admin.manage_shows'))

    shows = query_all("""
        SELECT s.show_id, s.show_time, s.ticket_price,
               TO_CHAR(s.show_date, 'YYYY-MM-DD') as show_date_str,
               m.movie_id, m.title as movie_title,
               sc.screen_name, t.theatre_name,
               (SELECT COUNT(*) FROM BOOKINGS WHERE show_id = s.show_id AND booking_status = 'CONFIRMED') as confirmed_bookings_count
        FROM SHOWS s
        JOIN MOVIES m ON s.movie_id = m.movie_id
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
        ORDER BY s.show_date DESC, s.show_time ASC
    """)
    movies = query_all("SELECT movie_id, title FROM MOVIES ORDER BY title")
    screens = query_all("""
        SELECT s.screen_id, s.screen_name, t.theatre_name
        FROM SCREENS s
        JOIN THEATRES t ON s.theatre_id = t.theatre_id
        ORDER BY t.theatre_name, s.screen_name
    """)
    return render_template('admin/shows.html', shows=shows, movies=movies, screens=screens)

@admin_bp.route('/show/<int:show_id>/delete', methods=['POST'])
@admin_required
def delete_show(show_id):
    execute("DELETE FROM SHOWS WHERE show_id = :sid", {'sid': show_id})
    flash("Show deleted successfully.", "success")
    return redirect(url_for('admin.manage_shows'))

# ---------------------------------------------------------------------
# USER MANAGEMENT
# ---------------------------------------------------------------------
@admin_bp.route('/users')
@admin_required
def manage_users():
    users = query_all("""
        SELECT user_id, name, email, phone, role,
               (SELECT COUNT(*) FROM BOOKINGS WHERE user_id = USERS.user_id) as booking_count,
               (SELECT COUNT(*) FROM REVIEWS WHERE user_id = USERS.user_id) as review_count
        FROM USERS
        ORDER BY user_id ASC
    """)
    return render_template('admin/users.html', users=users)

@admin_bp.route('/user/<int:user_id>/toggle-role', methods=['POST'])
@admin_required
def toggle_user_role(user_id):
    user = query_one("SELECT user_id, email, role FROM USERS WHERE user_id = :user_id", {'user_id': user_id})
    if user:
        new_role = 'ADMIN' if user['role'] == 'USER' else 'USER'
        execute("UPDATE USERS SET role = :r WHERE user_id = :user_id", {'r': new_role, 'user_id': user_id})
        flash(f"User {user['email']} role changed to {new_role}.", "success")
    return redirect(url_for('admin.manage_users'))

# ---------------------------------------------------------------------
# BOOKING MANAGEMENT
# ---------------------------------------------------------------------
@admin_bp.route('/bookings')
@admin_required
def manage_bookings():
    status_filter = request.args.get('status', 'ALL').upper()
    sql = """
        SELECT b.booking_id, b.total_amount, b.booking_status, b.booking_status as status,
               TO_CHAR(b.booking_date, 'DD Mon YYYY, HH:MI AM') as booking_date_str,
               u.name as user_name, u.email as user_email,
               m.title as movie_title, s.show_time,
               TO_CHAR(s.show_date, 'DD Mon YYYY') as show_date_str,
               sc.screen_name, t.theatre_name,
               (SELECT LISTAGG(s2.seat_number, ', ') WITHIN GROUP (ORDER BY s2.seat_number)
                FROM BOOKING_SEATS bs2
                JOIN SEATS s2 ON bs2.seat_id = s2.seat_id
                WHERE bs2.booking_id = b.booking_id) as seat_list,
               (SELECT LISTAGG(s2.seat_number, ', ') WITHIN GROUP (ORDER BY s2.seat_number)
                FROM BOOKING_SEATS bs2
                JOIN SEATS s2 ON bs2.seat_id = s2.seat_id
                WHERE bs2.booking_id = b.booking_id) as seats_booked
        FROM BOOKINGS b
        JOIN USERS u ON b.user_id = u.user_id
        JOIN SHOWS s ON b.show_id = s.show_id
        JOIN MOVIES m ON s.movie_id = m.movie_id
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
    """
    params = {}
    if status_filter in ['CONFIRMED', 'CANCELLED']:
        sql += " WHERE b.booking_status = :status"
        params['status'] = status_filter

    sql += " ORDER BY b.booking_date DESC"
    bookings = query_all(sql, params)
    return render_template('admin/bookings.html', bookings=bookings, status_filter=status_filter)

# ---------------------------------------------------------------------
# REVIEW MODERATION
# ---------------------------------------------------------------------
@admin_bp.route('/reviews')
@admin_required
def manage_reviews():
    reviews = query_all("""
        SELECT r.review_id, r.rating, r.review_text, r.sentiment_label, r.confidence_score,
               TO_CHAR(r.review_date, 'DD Mon YYYY, HH:MI AM') as review_date_str,
               u.name as user_name, m.title as movie_title
        FROM REVIEWS r
        JOIN USERS u ON r.user_id = u.user_id
        JOIN MOVIES m ON r.movie_id = m.movie_id
        ORDER BY r.review_date DESC
    """)
    return render_template('admin/reviews.html', reviews=reviews)

@admin_bp.route('/review/<int:review_id>/delete', methods=['POST'])
@admin_required
def delete_review(review_id):
    review = query_one("SELECT movie_id FROM REVIEWS WHERE review_id = :rid", {'rid': review_id})
    execute("DELETE FROM REVIEWS WHERE review_id = :rid", {'rid': review_id})
    
    if review:
        mid = review['movie_id']
        avg_row = query_one("SELECT AVG(rating) as avg_r FROM REVIEWS WHERE movie_id = :mid", {'mid': mid})
        new_avg = round(float(avg_row['avg_r']), 1) if avg_row and avg_row['avg_r'] else 0.0
        execute("UPDATE MOVIES SET rating = :rating WHERE movie_id = :mid", {'rating': new_avg, 'mid': mid})

    flash("Review deleted successfully.", "success")
    return redirect(url_for('admin.manage_reviews'))
