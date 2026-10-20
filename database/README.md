# Database Management & Oracle Schema

This directory contains the database setup files and scripts for the **Smart Cinema Ticket Hub** project.

## Core Entities (ER Diagram)
The database strictly follows the 9 core entities defined in the normalized ER Diagram:

1. `USERS`: User credentials, profile info, and `role` (`USER` or `ADMIN`).
2. `MOVIES`: Title, description, language, genre, duration, release date, poster, trailer, and rating.
3. `THEATRES`: Cinema names and physical venue locations.
4. `SCREENS`: Auditoriums belonging to theatres with seat capacities.
5. `SEATS`: Seat numbers, types (`Regular`, `Premium`), and active statuses.
6. `SHOWS`: Showtimes binding a movie to a screen, date, time, and ticket price.
7. `BOOKINGS`: Customer reservation header records with total amounts and status (`CONFIRMED`, `CANCELLED`).
8. `BOOKING_SEATS`: Junction table resolving the M:N relationship between bookings and seats.
9. `REVIEWS`: User ratings, feedback text, sentiment label (`Positive`, `Negative`, `Neutral`), and confidence score.

## Files
- `schema.sql`: Oracle SQL DDL script creating tables, constraints, foreign keys with cascade rules, and query indexes.
- `sample_data.sql`: Realistic demonstration dataset for admin, customers, movies, theatres, screens, seats, shows, bookings, and reviews.
- `db.py`: Centralized Python connection pool and database utility functions using `oracledb`.
- `setup_db.py`: Automated Python runner that executes `schema.sql` and `sample_data.sql` against Oracle.

## How to Initialize or Reset the Database
Make sure your `.env` file is properly configured with your Oracle credentials, then run:

```bash
python database/setup_db.py
```
