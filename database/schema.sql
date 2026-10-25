-- =====================================================================
-- SMART CINEMA TICKET HUB
-- Oracle Database Schema (9 Core Entities based on ER Diagram & SRS)
-- =====================================================================

-- 1. DROP EXISTING TABLES IF ANY (in reverse dependency order)
DROP TABLE BOOKING_SEATS CASCADE CONSTRAINTS;
DROP TABLE REVIEWS CASCADE CONSTRAINTS;
DROP TABLE BOOKINGS CASCADE CONSTRAINTS;
DROP TABLE SHOWS CASCADE CONSTRAINTS;
DROP TABLE SEATS CASCADE CONSTRAINTS;
DROP TABLE SCREENS CASCADE CONSTRAINTS;
DROP TABLE THEATRES CASCADE CONSTRAINTS;
DROP TABLE MOVIES CASCADE CONSTRAINTS;
DROP TABLE USERS CASCADE CONSTRAINTS;

-- ---------------------------------------------------------------------
-- TABLE 1: USERS
-- Stores customer accounts and administrative users (distinguished by role)
-- ---------------------------------------------------------------------
CREATE TABLE USERS (
    user_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(150) NOT NULL UNIQUE,
    password    VARCHAR2(255) NOT NULL,
    phone       VARCHAR2(20),
    role        VARCHAR2(20) DEFAULT 'USER' NOT NULL,
    CONSTRAINT chk_user_role CHECK (role IN ('USER', 'ADMIN'))
);

-- ---------------------------------------------------------------------
-- TABLE 2: MOVIES
-- Stores movie catalog information, metadata, duration, ratings, links
-- ---------------------------------------------------------------------
CREATE TABLE MOVIES (
    movie_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200) NOT NULL,
    description  VARCHAR2(2000),
    language     VARCHAR2(50) NOT NULL,
    genre        VARCHAR2(50) NOT NULL,
    duration     NUMBER NOT NULL,
    release_date DATE NOT NULL,
    poster       VARCHAR2(500),
    trailer      VARCHAR2(500),
    rating       NUMBER(3,1) DEFAULT 0.0,
    CONSTRAINT chk_movie_rating CHECK (rating >= 0.0 AND rating <= 5.0)
);

-- ---------------------------------------------------------------------
-- TABLE 3: THEATRES
-- Stores cinema theatre venues and their physical locations
-- ---------------------------------------------------------------------
CREATE TABLE THEATRES (
    theatre_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    theatre_name VARCHAR2(150) NOT NULL,
    location     VARCHAR2(255) NOT NULL
);

-- ---------------------------------------------------------------------
-- TABLE 4: SCREENS
-- Auditoriums/screens belonging to a specific theatre
-- ---------------------------------------------------------------------
CREATE TABLE SCREENS (
    screen_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    theatre_id  NUMBER NOT NULL,
    screen_name VARCHAR2(100) NOT NULL,
    total_seats NUMBER NOT NULL,
    CONSTRAINT fk_screens_theatre FOREIGN KEY (theatre_id) 
        REFERENCES THEATRES(theatre_id) ON DELETE CASCADE,
    CONSTRAINT chk_total_seats CHECK (total_seats > 0)
);

-- ---------------------------------------------------------------------
-- TABLE 5: SEATS
-- Physical seats for a specific screen (Regular / Premium)
-- ---------------------------------------------------------------------
CREATE TABLE SEATS (
    seat_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    screen_id   NUMBER NOT NULL,
    seat_number VARCHAR2(10) NOT NULL,
    seat_type   VARCHAR2(30) DEFAULT 'Regular' NOT NULL,
    status      VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT fk_seats_screen FOREIGN KEY (screen_id) 
        REFERENCES SCREENS(screen_id) ON DELETE CASCADE,
    CONSTRAINT chk_seat_type CHECK (seat_type IN ('Regular', 'Premium', 'Balcony')),
    CONSTRAINT chk_seat_status CHECK (status IN ('ACTIVE', 'MAINTENANCE', 'DISABLED')),
    CONSTRAINT uq_screen_seat UNIQUE (screen_id, seat_number)
);

-- ---------------------------------------------------------------------
-- TABLE 6: SHOWS
-- Screening schedule associating a movie, a screen, a date, and a time
-- ---------------------------------------------------------------------
CREATE TABLE SHOWS (
    show_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    movie_id     NUMBER NOT NULL,
    screen_id    NUMBER NOT NULL,
    show_date    DATE NOT NULL,
    show_time    VARCHAR2(20) NOT NULL,
    ticket_price NUMBER(8,2) NOT NULL,
    CONSTRAINT fk_shows_movie FOREIGN KEY (movie_id) 
        REFERENCES MOVIES(movie_id) ON DELETE CASCADE,
    CONSTRAINT fk_shows_screen FOREIGN KEY (screen_id) 
        REFERENCES SCREENS(screen_id) ON DELETE CASCADE,
    CONSTRAINT chk_ticket_price CHECK (ticket_price > 0)
);

-- ---------------------------------------------------------------------
-- TABLE 7: BOOKINGS
-- Header for customer ticket reservations
-- ---------------------------------------------------------------------
CREATE TABLE BOOKINGS (
    booking_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id        NUMBER NOT NULL,
    show_id        NUMBER NOT NULL,
    booking_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_amount   NUMBER(10,2) NOT NULL,
    booking_status VARCHAR2(30) DEFAULT 'CONFIRMED' NOT NULL,
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) 
        REFERENCES USERS(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_bookings_show FOREIGN KEY (show_id) 
        REFERENCES SHOWS(show_id) ON DELETE CASCADE,
    CONSTRAINT chk_booking_status CHECK (booking_status IN ('CONFIRMED', 'CANCELLED'))
);

-- ---------------------------------------------------------------------
-- TABLE 8: BOOKING_SEATS
-- Resolving M:N relationship between BOOKINGS and SEATS
-- ---------------------------------------------------------------------
CREATE TABLE BOOKING_SEATS (
    booking_seat_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id      NUMBER NOT NULL,
    seat_id         NUMBER NOT NULL,
    CONSTRAINT fk_bseats_booking FOREIGN KEY (booking_id) 
        REFERENCES BOOKINGS(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_bseats_seat FOREIGN KEY (seat_id) 
        REFERENCES SEATS(seat_id) ON DELETE CASCADE,
    CONSTRAINT uq_booking_seat UNIQUE (booking_id, seat_id)
);

-- ---------------------------------------------------------------------
-- TABLE 9: REVIEWS
-- User reviews for movies, storing rating, review text, and ML outputs
-- ---------------------------------------------------------------------
CREATE TABLE REVIEWS (
    review_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          NUMBER NOT NULL,
    movie_id         NUMBER NOT NULL,
    rating           NUMBER(2,1) NOT NULL,
    review_text      VARCHAR2(2000) NOT NULL,
    sentiment_label  VARCHAR2(20) NOT NULL,
    confidence_score NUMBER(5,2) NOT NULL,
    review_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) 
        REFERENCES USERS(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_movie FOREIGN KEY (movie_id) 
        REFERENCES MOVIES(movie_id) ON DELETE CASCADE,
    CONSTRAINT chk_review_rating CHECK (rating >= 1.0 AND rating <= 5.0),
    CONSTRAINT chk_sentiment_label CHECK (sentiment_label IN ('Positive', 'Negative', 'Neutral'))
);

-- Indexes for query performance
CREATE INDEX idx_shows_movie ON SHOWS(movie_id);
CREATE INDEX idx_shows_date ON SHOWS(show_date);
CREATE INDEX idx_bookings_user ON BOOKINGS(user_id);
CREATE INDEX idx_bookings_show ON BOOKINGS(show_id);
CREATE INDEX idx_bseats_booking ON BOOKING_SEATS(booking_id);
CREATE INDEX idx_bseats_seat ON BOOKING_SEATS(seat_id);
CREATE INDEX idx_reviews_movie ON REVIEWS(movie_id);
CREATE INDEX idx_reviews_user ON REVIEWS(user_id);
CREATE INDEX idx_seats_screen ON SEATS(screen_id);
