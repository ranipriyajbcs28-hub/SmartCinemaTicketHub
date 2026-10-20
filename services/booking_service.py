import logging
from datetime import datetime
import oracledb
from database.db import get_connection, query_one, query_all

logger = logging.getLogger(__name__)

def get_show_details(show_id):
    """Fetches full show information including movie, screen, and theatre details."""
    sql = """
        SELECT s.show_id, s.movie_id, s.screen_id, 
               TO_CHAR(s.show_date, 'YYYY-MM-DD') as show_date,
               s.show_time, s.ticket_price,
               m.title as movie_title, m.poster as movie_poster,
               m.duration, m.language, m.genre,
               sc.screen_name, sc.total_seats,
               t.theatre_id, t.theatre_name, t.location
        FROM SHOWS s
        JOIN MOVIES m ON s.movie_id = m.movie_id
        JOIN SCREENS sc ON s.screen_id = sc.screen_id
        JOIN THEATRES t ON sc.theatre_id = t.theatre_id
        WHERE s.show_id = :show_id
    """
    return query_one(sql, {'show_id': show_id})

def get_seats_with_availability(show_id):
    """
    Fetches all physical seats for the screen hosting the show,
    marking each seat as 'available' or 'booked' relative to this specific show.
    """
    # 1. Fetch show and screen
    show = get_show_details(show_id)
    if not show:
        return None, "Show not found"

    screen_id = show['screen_id']

    # 2. Fetch all seats on this screen
    seats_sql = """
        SELECT seat_id, screen_id, seat_number, seat_type, status
        FROM SEATS
        WHERE screen_id = :screen_id AND status = 'ACTIVE'
        ORDER BY seat_number ASC
    """
    all_seats = query_all(seats_sql, {'screen_id': screen_id})

    # 3. Fetch currently confirmed booked seats for THIS show
    booked_sql = """
        SELECT bs.seat_id
        FROM BOOKING_SEATS bs
        JOIN BOOKINGS b ON bs.booking_id = b.booking_id
        WHERE b.show_id = :show_id AND b.booking_status = 'CONFIRMED'
    """
    booked_rows = query_all(booked_sql, {'show_id': show_id})
    booked_seat_ids = {row['seat_id'] for row in booked_rows}

    # 4. Annotate each seat with availability
    for s in all_seats:
        s['is_booked'] = (s['seat_id'] in booked_seat_ids)
        s['is_available'] = not s['is_booked']

    return {
        'show': show,
        'seats': all_seats,
        'total_seats': len(all_seats),
        'booked_count': len(booked_seat_ids),
        'available_count': len(all_seats) - len(booked_seat_ids)
    }, None

def create_booking(user_id, show_id, seat_ids):
    """
    Executes an atomic Oracle transaction to reserve seats for a show.
    Guarantees no duplicate bookings even under concurrent requests.
    """
    if not seat_ids or len(seat_ids) == 0:
        return None, "No seats selected for booking."

    # Remove duplicates if any passed
    seat_ids = list(set(int(sid) for sid in seat_ids))

    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                # 1. Verify show exists and retrieve details
                show_sql = """
                    SELECT s.show_id, s.screen_id, s.ticket_price, s.show_date, s.show_time,
                           m.title as movie_title, t.theatre_name, sc.screen_name
                    FROM SHOWS s
                    JOIN MOVIES m ON s.movie_id = m.movie_id
                    JOIN SCREENS sc ON s.screen_id = sc.screen_id
                    JOIN THEATRES t ON sc.theatre_id = t.theatre_id
                    WHERE s.show_id = :show_id
                """
                cur.execute(show_sql, {'show_id': show_id})
                show_row = cur.fetchone()
                if not show_row:
                    return None, "Selected show does not exist."

                screen_id = show_row[1]
                ticket_price = float(show_row[2])

                # 2. Verify seats belong to this screen and are active
                placeholders = ', '.join([f':s{i}' for i in range(len(seat_ids))])
                seat_check_params = {f's{i}': sid for i, sid in enumerate(seat_ids)}
                seat_check_params['screen_id'] = screen_id

                cur.execute(f"""
                    SELECT seat_id, seat_number, seat_type
                    FROM SEATS
                    WHERE screen_id = :screen_id AND status = 'ACTIVE'
                      AND seat_id IN ({placeholders})
                """, seat_check_params)
                valid_seats = cur.fetchall()

                if len(valid_seats) != len(seat_ids):
                    return None, "One or more selected seats do not belong to this screen or are unavailable."

                # Calculate pricing (Regular: 1.0x, Premium: +25% / 1.25x, Balcony: +50% / 1.50x)
                total_amount = 0.0
                for s in valid_seats:
                    s_type = s[2]
                    if s_type == 'Balcony':
                        multiplier = 1.50
                    elif s_type == 'Premium':
                        multiplier = 1.25
                    else:
                        multiplier = 1.0
                    total_amount += round(ticket_price * multiplier, 2)

                # 3. ATOMIC CHECK: Check if any of these seats are ALREADY booked for this show
                conflict_params = {f's{i}': sid for i, sid in enumerate(seat_ids)}
                conflict_params['show_id'] = show_id

                cur.execute(f"""
                    SELECT bs.seat_id, s.seat_number
                    FROM BOOKING_SEATS bs
                    JOIN BOOKINGS b ON bs.booking_id = b.booking_id
                    JOIN SEATS s ON bs.seat_id = s.seat_id
                    WHERE b.show_id = :show_id 
                      AND b.booking_status = 'CONFIRMED'
                      AND bs.seat_id IN ({placeholders})
                """, conflict_params)
                conflicts = cur.fetchall()

                if conflicts:
                    taken_seats = ", ".join([c[1] for c in conflicts])
                    conn.rollback()
                    return None, f"Booking failed: Seat(s) {taken_seats} were already booked by another customer. Please choose different seats."

                # 4. Insert BOOKING record
                booking_id_var = cur.var(oracledb.NUMBER)
                cur.execute("""
                    INSERT INTO BOOKINGS (user_id, show_id, booking_date, total_amount, booking_status)
                    VALUES (:user_id, :show_id, CURRENT_TIMESTAMP, :total_amount, 'CONFIRMED')
                    RETURNING booking_id INTO :out_booking_id
                """, {
                    'user_id': user_id,
                    'show_id': show_id,
                    'total_amount': total_amount,
                    'out_booking_id': booking_id_var
                })
                booking_id = int(booking_id_var.getvalue()[0])

                # 5. Insert BOOKING_SEATS records
                for sid in seat_ids:
                    cur.execute("""
                        INSERT INTO BOOKING_SEATS (booking_id, seat_id)
                        VALUES (:booking_id, :seat_id)
                    """, {
                        'booking_id': booking_id,
                        'seat_id': sid
                    })

                # Commit transaction atomically
                conn.commit()

                logger.info("Successfully booked %d seats for user %d, show %d, booking_id %d", 
                            len(seat_ids), user_id, show_id, booking_id)

                return {
                    'booking_id': booking_id,
                    'total_amount': total_amount,
                    'seat_count': len(seat_ids),
                    'seats': [s[1] for s in valid_seats]
                }, None

        except Exception as e:
            conn.rollback()
            logger.error("Booking transaction failed: %s", e)
            return None, f"Database transaction error: {str(e)}"

def cancel_booking(booking_id, user_id=None, is_admin=False):
    """
    Cancels an existing booking. Releasing seats so they become available again for that show.
    """
    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                check_sql = "SELECT booking_id, user_id, booking_status FROM BOOKINGS WHERE booking_id = :booking_id"
                cur.execute(check_sql, {'booking_id': booking_id})
                booking = cur.fetchone()
                if not booking:
                    return False, "Booking not found."

                # If user is not admin, verify ownership
                if not is_admin and user_id is not None and booking[1] != user_id:
                    return False, "Unauthorized to cancel this booking."

                if booking[2] == 'CANCELLED':
                    return False, "Booking is already cancelled."

                # Update booking status to CANCELLED
                cur.execute("""
                    UPDATE BOOKINGS 
                    SET booking_status = 'CANCELLED' 
                    WHERE booking_id = :booking_id
                """, {'booking_id': booking_id})
                conn.commit()

                return True, "Booking cancelled successfully. Reserved seats have been released."
        except Exception as e:
            conn.rollback()
            return False, f"Cancellation failed: {str(e)}"
