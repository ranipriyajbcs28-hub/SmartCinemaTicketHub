from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify
from utils.auth import login_required
from services.booking_service import get_seats_with_availability, create_booking, cancel_booking, get_show_details
from database.db import query_all, query_one

booking_bp = Blueprint('booking', __name__)

@booking_bp.route('/seats/<int:show_id>')
def seat_selection(show_id):
    """Interactive seat selection grid for a specific show."""
    data, error = get_seats_with_availability(show_id)
    if error or not data:
        flash(error or "Show not found.", "danger")
        return redirect(url_for('movie.index'))

    # Group seats by seat_type and row for structured tier presentation
    tiers_order = ['Balcony', 'Premium', 'Regular']
    tiers_dict = {t: {} for t in tiers_order}
    rows_dict = {}

    for s in data['seats']:
        stype = s.get('seat_type', 'Regular')
        if stype not in tiers_dict:
            tiers_dict[stype] = {}
        num = s['seat_number']
        row_letter = num[0] if num else 'A'
        
        if row_letter not in tiers_dict[stype]:
            tiers_dict[stype][row_letter] = []
        tiers_dict[stype][row_letter].append(s)

        if row_letter not in rows_dict:
            rows_dict[row_letter] = []
        rows_dict[row_letter].append(s)

    # Natural numeric sorting for seats within each row (1, 2, 3... 10)
    for t_name, rows in tiers_dict.items():
        for r_letter in rows:
            rows[r_letter].sort(key=lambda x: int(x['seat_number'][1:]) if x['seat_number'][1:].isdigit() else x['seat_number'])

    for r_letter in rows_dict:
        rows_dict[r_letter].sort(key=lambda x: int(x['seat_number'][1:]) if x['seat_number'][1:].isdigit() else x['seat_number'])

    # Filter out empty tiers while maintaining priority order
    active_tiers = {k: v for k, v in tiers_dict.items() if v}

    return render_template(
        'seat_selection.html',
        show=data['show'],
        rows_dict=rows_dict,
        tiers_dict=active_tiers,
        total_seats=data['total_seats'],
        available_count=data['available_count'],
        booked_count=data['booked_count']
    )

@booking_bp.route('/api/seats/<int:show_id>')
def api_seats(show_id):
    """JSON API returning seat layout and current availability for the show."""
    data, error = get_seats_with_availability(show_id)
    if error:
        return jsonify({'success': False, 'error': error}), 404
    return jsonify({'success': True, 'data': data})

@booking_bp.route('/book', methods=['POST'])
@login_required
def book_tickets():
    """Handles booking submission, performs atomic backend verification and creates transaction."""
    user_id = session.get('user_id')
    show_id = request.form.get('show_id')
    seat_ids = request.form.getlist('seat_ids')

    if not show_id:
        flash("Invalid show selected.", "danger")
        return redirect(url_for('movie.index'))

    try:
        show_id = int(show_id)
    except ValueError:
        flash("Invalid show ID format.", "danger")
        return redirect(url_for('movie.index'))

    if not seat_ids or len(seat_ids) == 0:
        flash("Please select at least one seat to proceed with booking.", "warning")
        return redirect(url_for('booking.seat_selection', show_id=show_id))

    # Convert seat_ids to integers
    try:
        parsed_seat_ids = [int(sid) for sid in seat_ids]
    except ValueError:
        flash("Invalid seat selection format.", "danger")
        return redirect(url_for('booking.seat_selection', show_id=show_id))

    # Execute booking transaction via service
    result, error_msg = create_booking(user_id, show_id, parsed_seat_ids)
    if error_msg:
        flash(error_msg, "danger")
        return redirect(url_for('booking.seat_selection', show_id=show_id))

    booking_id = result['booking_id']
    flash("Congratulations! Your cinema tickets have been booked successfully.", "success")
    return redirect(url_for('booking.confirmation', booking_id=booking_id))

@booking_bp.route('/booking/<int:booking_id>')
@login_required
def confirmation(booking_id):
    """Displays detailed booking confirmation voucher."""
    user_id = session.get('user_id')
    is_admin = session.get('role') == 'ADMIN'

    sql = """
        SELECT b.booking_id, b.user_id, b.show_id, 
               TO_CHAR(b.booking_date, 'DD Mon YYYY, HH:MI AM') as booking_date_str,
               b.total_amount, b.booking_status,
               u.name as user_name, u.email as user_email, u.phone as user_phone,
               m.movie_id, m.title as movie_title, m.poster as movie_poster,
               m.duration, m.language, m.genre,
               s.show_time, TO_CHAR(s.show_date, 'Dy, DD Mon YYYY') as show_date_str,
               s.ticket_price,
               sc.screen_name,
               t.theatre_name, t.location
        FROM BOOKINGS b
        JOIN USERS u ON b.user_id = u.user_id
        JOIN SHOWS s ON b.show_id = s.show_id
        JOIN MOVIES m ON s.movie_id = m.movie_id
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
        WHERE b.booking_id = :bid
    """
    booking = query_one(sql, {'bid': booking_id})
    if not booking:
        flash("Booking record not found.", "danger")
        return redirect(url_for('movie.index'))

    # Security check: only the owner or an admin can view this booking voucher
    if not is_admin and booking['user_id'] != user_id:
        flash("Unauthorized to view this booking voucher.", "danger")
        return redirect(url_for('booking.history'))

    # Fetch booked seat details
    seats_sql = """
        SELECT s.seat_id, s.seat_number, s.seat_type
        FROM BOOKING_SEATS bs
        JOIN SEATS s ON bs.seat_id = s.seat_id
        WHERE bs.booking_id = :bid
        ORDER BY s.seat_number ASC
    """
    seats = query_all(seats_sql, {'bid': booking_id})
    seat_numbers = [s['seat_number'] for s in seats]

    return render_template(
        'booking_confirmation.html',
        booking=booking,
        seats=seats,
        seat_numbers=seat_numbers,
        seat_count=len(seats)
    )

@booking_bp.route('/bookings')
@login_required
def history():
    """User booking history with status, show details, and cancel action."""
    user_id = session.get('user_id')

    sql = """
        SELECT b.booking_id, b.show_id,
               TO_CHAR(b.booking_date, 'DD Mon YYYY, HH:MI AM') as booking_date_str,
               b.total_amount, b.booking_status, b.booking_status as status,
               m.movie_id, m.title as movie_title, m.poster as movie_poster,
               s.show_time, TO_CHAR(s.show_date, 'DD Mon YYYY') as show_date_str,
               s.show_date,
               sc.screen_name, t.theatre_name, t.location,
               (SELECT LISTAGG(s2.seat_number, ', ') WITHIN GROUP (ORDER BY s2.seat_number)
                FROM BOOKING_SEATS bs2
                JOIN SEATS s2 ON bs2.seat_id = s2.seat_id
                WHERE bs2.booking_id = b.booking_id) as seat_list,
               (SELECT LISTAGG(s2.seat_number, ', ') WITHIN GROUP (ORDER BY s2.seat_number)
                FROM BOOKING_SEATS bs2
                JOIN SEATS s2 ON bs2.seat_id = s2.seat_id
                WHERE bs2.booking_id = b.booking_id) as seats_list,
               (SELECT COUNT(*) FROM BOOKING_SEATS bs3 WHERE bs3.booking_id = b.booking_id) as ticket_count
        FROM BOOKINGS b
        JOIN SHOWS s ON b.show_id = s.show_id
        JOIN MOVIES m ON s.movie_id = m.movie_id
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
        WHERE b.user_id = :user_id
        ORDER BY b.booking_date DESC
    """
    bookings = query_all(sql, {'user_id': user_id})

    return render_template('booking_history.html', bookings=bookings)

@booking_bp.route('/booking/<int:booking_id>/cancel', methods=['POST'])
@login_required
def cancel(booking_id):
    """Cancels a booking and frees its seats."""
    user_id = session.get('user_id')
    is_admin = session.get('role') == 'ADMIN'

    success, msg = cancel_booking(booking_id, user_id=user_id, is_admin=is_admin)
    if success:
        flash(msg, "success")
    else:
        flash(msg, "danger")

    return redirect(url_for('booking.history'))
