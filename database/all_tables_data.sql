-- =========================================================
-- SMART CINEMA TICKET HUB — ALL DATABASE TABLES AND DATA
-- Complete Oracle Database Export (9 Core Entities)
-- =========================================================

-- 1. DDL: TABLE DEFINITIONS & CONSTRAINTS
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


-- 2. DML: POPULATED TABLE RECORDS

-- TABLE: USERS (5 records)
INSERT INTO USERS (user_id, name, email, password, phone, role) VALUES (1, 'System Administrator', 'admin@cinema.com', 'scrypt:32768:8:1$YIOmzOTfGIDyl1Sq$5f0843a09057ad48f51b29bcc1a5dfd27e4e8c3f05052de876abe5e7859595abffa56c3805b601f31082ffa212aa7753bf39f97b93002ea2d4e7ba25a930b8d9', '9876543210', 'ADMIN');
INSERT INTO USERS (user_id, name, email, password, phone, role) VALUES (2, 'Rani Priya', 'rani@cinema.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543211', 'USER');
INSERT INTO USERS (user_id, name, email, password, phone, role) VALUES (3, 'Muthu Lekshmi', 'muthu@cinema.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543212', 'USER');
INSERT INTO USERS (user_id, name, email, password, phone, role) VALUES (4, 'John Smith', 'john@example.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543213', 'USER');
INSERT INTO USERS (user_id, name, email, password, phone, role) VALUES (5, 'Priya Sharma', 'priya@example.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543214', 'USER');

-- TABLE: MOVIES (8 records)
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (1, 'Interstellar: Beyond Horizons', 'A team of courageous explorers travels through a newly discovered wormhole in space in an attempt to ensure humanity survival as Earth faces catastrophic collapse.', 'English', 'Sci-Fi', 169, '2024-03-15 00:00:00', 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=zSWdZVtXT7E', 4.8);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (2, 'Oppenheimer', 'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II and the subsequent moral fallout.', 'English', 'Drama', 180, '2024-04-10 00:00:00', 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=uYPbbksJxIg', 3.9);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (3, 'Dune: Part Two', 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family and facing a choice between love and destiny.', 'English', 'Sci-Fi', 166, '2024-05-01 00:00:00', 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=Way9Dexny3w', 4.7);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (4, 'Spider-Man: Spider-Verse', 'Miles Morales catapults across the Multiverse, encountering a society of Spider-People charged with protecting its very existence.', 'English', 'Animation', 140, '2024-06-15 00:00:00', 'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=cqGjhVJWtEg', 4.8);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (5, 'Leo: Bloody Sweet', 'A mild-mannered cafe owner gets caught up in a bloody confrontation with gangsters who believe he is a ruthless mobster from their past.', 'Tamil', 'Action', 164, '2024-07-20 00:00:00', 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=Po3jVh2CAT8', 4.3);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (6, 'Avatar: Fire and Ash', 'Jake Sully and Neytiri return in an exhilarating journey into new territories of Pandora, encountering the hostile Ash People in an epic struggle for survival.', 'English', 'Sci-Fi', 175, '2026-12-18 00:00:00', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=d9MyW72ELq0', 0.0);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (21, 'spiderman1', 'action movie', 'English', 'animation', 100, '2026-03-02 00:00:00', 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop', NULL, 4.5);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (41, 'sister', 'good movie', 'English', 'drama', 100, '2026-09-02 00:00:00', '/static/images/posters/poster_1b2e9cf66b.jpeg', NULL, 4.5);

-- TABLE: THEATRES (3 records)
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (1, 'PVR INOX Grand Mall', 'MG Road, Bengaluru');
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (2, 'Cinepolis Forum Mega', 'Koramangala, Bengaluru');
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (3, 'IMAX Regal Symphony', 'Indiranagar 100ft Road, Bengaluru');

-- TABLE: SCREENS (5 records)
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (1, 1, 'Screen 1 - Dolby Atmos', 24);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (2, 1, 'Screen 2 - Gold Class', 18);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (3, 2, 'Audi 1 - 4DX Experience', 24);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (4, 2, 'Audi 2 - Laser Ultra', 24);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (5, 3, 'IMAX Screen 1 - Laser 3D', 30);

-- TABLE: SEATS (90 records)
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (1, 1, 'A1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (2, 1, 'A2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (3, 1, 'A3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (4, 1, 'A4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (5, 1, 'A5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (6, 1, 'A6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (7, 1, 'A7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (8, 1, 'A8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (9, 1, 'B1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (10, 1, 'B2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (11, 1, 'B3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (12, 1, 'B4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (13, 1, 'B5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (14, 1, 'B6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (15, 1, 'B7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (16, 1, 'B8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (17, 1, 'C1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (18, 1, 'C2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (19, 1, 'C3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (20, 1, 'C4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (21, 1, 'C5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (22, 1, 'C6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (23, 1, 'C7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (24, 1, 'C8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (25, 2, 'G1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (26, 2, 'G2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (27, 2, 'G3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (28, 2, 'G4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (29, 2, 'G5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (30, 2, 'G6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (31, 2, 'H1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (32, 2, 'H2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (33, 2, 'H3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (34, 2, 'H4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (35, 2, 'H5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (36, 2, 'H6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (37, 2, 'J1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (38, 2, 'J2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (39, 2, 'J3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (40, 2, 'J4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (41, 2, 'J5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (42, 2, 'J6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (43, 3, 'A1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (44, 3, 'A2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (45, 3, 'A3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (46, 3, 'A4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (47, 3, 'A5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (48, 3, 'A6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (49, 3, 'B1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (50, 3, 'B2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (51, 3, 'B3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (52, 3, 'B4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (53, 3, 'B5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (54, 3, 'B6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (55, 3, 'C1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (56, 3, 'C2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (57, 3, 'C3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (58, 3, 'C4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (59, 3, 'C5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (60, 3, 'C6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (61, 3, 'D1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (62, 3, 'D2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (63, 3, 'D3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (64, 3, 'D4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (65, 3, 'D5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (66, 3, 'D6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (67, 5, 'I1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (68, 5, 'I2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (69, 5, 'I3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (70, 5, 'I4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (71, 5, 'I5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (72, 5, 'I6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (73, 5, 'M1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (74, 5, 'M2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (75, 5, 'M3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (76, 5, 'M4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (77, 5, 'M5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (78, 5, 'M6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (79, 5, 'A1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (80, 5, 'A2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (81, 5, 'A3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (82, 5, 'A4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (83, 5, 'A5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (84, 5, 'A6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (85, 5, 'X1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (86, 5, 'X2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (87, 5, 'X3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (88, 5, 'X4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (89, 5, 'X5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (90, 5, 'X6', 'Premium', 'ACTIVE');

-- TABLE: SHOWS (9 records)
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (1, 1, 1, '2026-09-24 00:00:00', '10:30 AM', 250.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (2, 1, 1, '2026-09-24 00:00:00', '02:30 PM', 280.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (3, 1, 5, '2026-09-24 00:00:00', '06:45 PM', 400.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (4, 2, 2, '2026-09-24 00:00:00', '11:00 AM', 350.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (5, 2, 2, '2026-09-24 00:00:00', '04:00 PM', 350.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (6, 3, 3, '2026-09-24 00:00:00', '01:15 PM', 300.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (7, 3, 5, '2026-09-24 00:00:00', '09:30 PM', 450.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (8, 4, 1, '2026-09-25 00:00:00', '10:00 AM', 220.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (9, 5, 3, '2026-09-25 00:00:00', '06:30 PM', 250.0);

-- TABLE: BOOKINGS (4 records)
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (1, 2, 1, '2026-09-24 05:44:46.820000', 500.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (2, 3, 1, '2026-09-24 06:44:46.827000', 500.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (3, 4, 3, '2026-09-24 06:59:46.832000', 1200.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (21, 2, 5, '2026-09-24 13:59:37.998000', 437.5, 'CONFIRMED');

-- TABLE: BOOKING_SEATS (8 records)
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (1, 1, 1);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (2, 1, 2);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (3, 2, 17);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (4, 2, 18);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (5, 3, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (6, 3, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (7, 3, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (21, 21, 34);

-- TABLE: REVIEWS (15 records)
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (1, 2, 1, 5.0, 'An absolute masterpiece of modern cinema! Hans Zimmer score together with breathtaking visuals gave me goosebumps throughout the entire film. Best sci-fi ever.', 'Positive', 96.4, '2026-09-24 07:44:46.839000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (2, 3, 1, 4.5, 'Phenomenal storytelling and acting by Matthew McConaughey. Emotional, scientifically thrilling, and visually stunning on the big screen.', 'Positive', 94.2, '2026-09-24 07:44:46.842000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (3, 4, 1, 3.0, 'The scientific aspects were decent and visuals impressive, but the pacing felt a bit long and stretched out towards the third act.', 'Neutral', 68.5, '2026-09-24 07:44:46.844000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (4, 5, 1, 2.0, 'Too confusing and overly dramatic sound mixing made dialogues hard to understand. Not my cup of tea.', 'Negative', 89.1, '2026-09-24 07:44:46.846000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (5, 2, 2, 5.0, 'Oppenheimer is Christopher Nolan finest cinematic achievement. Cillian Murphy delivers an Oscar-worthy performance of rare depth and intensity.', 'Positive', 81.22, '2026-09-24 14:00:51.013000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (6, 3, 2, 4.5, 'Masterful direction, intense sound design, and razor sharp editing. A historic epic executed to perfection.', 'Positive', 93.8, '2026-09-24 07:44:46.850000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (7, 4, 2, 3.5, 'Very engaging history lesson with great performances, though dialogue heavy and slightly repetitive in the court hearing scenes.', 'Neutral', 72.3, '2026-09-24 07:44:46.852000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (8, 5, 2, 2.5, 'Disappointing and slow paced narrative. Expected more about the technical breakthroughs rather than bureaucratic hearings.', 'Negative', 85.6, '2026-09-24 07:44:46.853000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (9, 2, 3, 5.0, 'Dune Part Two is pure visual poetry. The worm-riding sequences and desert warfare are unmatched in cinema history. Astounding spectacle.', 'Positive', 97.4, '2026-09-24 07:44:46.856000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (10, 3, 3, 4.0, 'Incredible scale and world building. Austin Butler and Timothee Chalamet gave commanding performances.', 'Positive', 91.5, '2026-09-24 07:44:46.858000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (11, 4, 3, 3.0, 'Good production values but felt exhausting by the end due to its unrelenting volume and dark atmosphere.', 'Neutral', 65.2, '2026-09-24 07:44:46.860000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (12, 2, 4, 5.0, 'The animation styles and creativity blew my mind! Every single frame belongs in an art museum. Thrilling story and music.', 'Positive', 97.8, '2026-09-24 07:44:46.862000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (13, 3, 4, 3.5, 'Entertaining multiverse story with nice colors, though the cliffhanger ending was slightly abrupt.', 'Neutral', 70.4, '2026-09-24 07:44:46.863000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (14, 4, 5, 4.5, 'Thalapathy Vijay and Lokesh Kanagaraj delivered a high-octane action thriller! Anirudh background score elevated every fight scene.', 'Positive', 95.1, '2026-09-24 07:44:46.865000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (15, 5, 5, 2.0, 'Terrible second half with ridiculous plot logic and pointless flashback sequences. Completely wasted potential.', 'Negative', 92.3, '2026-09-24 07:44:46.867000');

COMMIT;
