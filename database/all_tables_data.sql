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

-- TABLE: USERS (7 records)
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (1, 'System Administrator', 'admin@cinema.com', 'scrypt:32768:8:1$YIOmzOTfGIDyl1Sq$5f0843a09057ad48f51b29bcc1a5dfd27e4e8c3f05052de876abe5e7859595abffa56c3805b601f31082ffa212aa7753bf39f97b93002ea2d4e7ba25a930b8d9', '9876543210', 'ADMIN', NULL);
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (2, 'Rani Priya', 'rani@cinema.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543211', 'USER', NULL);
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (3, 'Muthu Lekshmi', 'muthu@cinema.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543212', 'USER', NULL);
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (4, 'John Smith', 'john@example.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543213', 'USER', NULL);
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (5, 'Priya Sharma', 'priya@example.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543214', 'USER', NULL);
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (21, 'Jeya priya', 'jeya@gmail.com', 'scrypt:32768:8:1$i7afvd4L4wMdmS2s$65ff6139428448cb1df3d30dbc2fc16099655967e6fb93433e507a040ed8b1d71d227d90742db18ed1d8217daa9c9c8163d1049c663727deacae3851afa5aae2', '09150834717', 'USER', NULL);
INSERT INTO USERS (user_id, name, email, password, phone, role, created_at) VALUES (41, 'Muthu Lekshmi', 'bmuthulekshmi@gmail.com', 'scrypt:32768:8:1$YTwwI5Szfv61bApp$66d4d889996858f1a5f70e803735517a4119c8d69feff91a09e2f6b67d14d87d8f9bfdc2343188eb47a3e61a32e5551d419107e6990f3a78ca3d6d8f23674662', '9487810522', 'USER', NULL);

-- TABLE: MOVIES (10 records)
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (1, 'Interstellar: Beyond Horizons', 'A team of courageous explorers travels through a newly discovered wormhole in space in an attempt to ensure humanity survival as Earth faces catastrophic collapse.', 'English', 'Sci-Fi', 169, '2024-03-15T00:00:00', 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=zSWdZVtXT7E', 3.6);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (2, 'Oppenheimer', 'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II and the subsequent moral fallout.', 'English', 'Drama', 180, '2024-04-10T00:00:00', 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=uYPbbksJxIg', 3.9);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (3, 'Dune: Part Two', 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family and facing a choice between love and destiny.', 'English', 'Sci-Fi', 166, '2024-05-01T00:00:00', 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=Way9Dexny3w', 4.7);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (4, 'Spider-Man: Spider-Verse', 'Miles Morales catapults across the Multiverse, encountering a society of Spider-People charged with protecting its very existence.', 'English', 'Animation', 140, '2024-06-15T00:00:00', 'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=cqGjhVJWtEg', 4.8);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (5, 'Leo: Bloody Sweet', 'A mild-mannered cafe owner gets caught up in a bloody confrontation with gangsters who believe he is a ruthless mobster from their past.', 'Tamil', 'Action', 164, '2024-07-20T00:00:00', 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=Po3jVh2CAT8', 4.3);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (6, 'Avatar: Fire and Ash', 'Jake Sully and Neytiri return in an exhilarating journey into new territories of Pandora, encountering the hostile Ash People in an epic struggle for survival.', 'English', 'Sci-Fi', 175, '2026-12-18T00:00:00', 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop', 'https://www.youtube.com/watch?v=d9MyW72ELq0', 0.0);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (21, 'spiderman1', 'action movie', 'English', 'animation', 100, '2026-03-02T00:00:00', 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop', NULL, 4.5);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (41, 'sister', 'good movie', 'English', 'drama', 100, '2026-09-02T00:00:00', '/static/images/posters/poster_1b2e9cf66b.jpeg', NULL, 4.5);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (61, 'Remo', 'nice movie', 'tamil', 'Action', 160, '2025-09-09T00:00:00', '/static/images/posters/poster_5cc2498a62.png', NULL, 4.5);
INSERT INTO MOVIES (movie_id, title, description, language, genre, duration, release_date, poster, trailer, rating) VALUES (81, 'Interseller1', 'feel good movie', 'English', 'drama', 100, '2026-10-09T00:00:00', 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&auto=format&fit=crop', NULL, 3.6);

-- TABLE: THEATRES (4 records)
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (1, 'PVR INOX Grand Mall', 'MG Road, Bengaluru');
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (2, 'Cinepolis Forum Mega', 'Koramangala, Bengaluru');
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (3, 'IMAX Regal Symphony', 'Indiranagar 100ft Road, Bengaluru');
INSERT INTO THEATRES (theatre_id, theatre_name, location) VALUES (21, 'Rani Hall', 'Bengaluru');

-- TABLE: SCREENS (8 records)
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (1, 1, 'Screen 1 - Dolby Atmos', 24);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (2, 1, 'Screen 2 - Gold Class', 18);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (3, 2, 'Audi 1 - 4DX Experience', 24);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (4, 2, 'Audi 2 - Laser Ultra', 24);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (5, 3, 'IMAX Screen 1 - Laser 3D', 30);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (21, 21, 'Screen 1 - Main Audi', 80);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (22, 21, 'Screen 1 - Main Audi', 12);
INSERT INTO SCREENS (screen_id, theatre_id, screen_name, total_seats) VALUES (41, 21, 'Screen 1 - Main Audi', 100);

-- TABLE: SEATS (306 records)
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
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (101, 4, 'A1', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (102, 4, 'A2', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (103, 4, 'A3', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (104, 4, 'A4', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (105, 4, 'A5', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (106, 4, 'A6', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (107, 4, 'A7', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (108, 4, 'A8', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (109, 4, 'B1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (110, 4, 'B2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (111, 4, 'B3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (112, 4, 'B4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (113, 4, 'B5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (114, 4, 'B6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (115, 4, 'B7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (116, 4, 'B8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (117, 4, 'C1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (118, 4, 'C2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (119, 4, 'C3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (120, 4, 'C4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (121, 4, 'C5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (122, 4, 'C6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (123, 4, 'C7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (124, 4, 'C8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (125, 21, 'A1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (126, 21, 'A2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (127, 21, 'A3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (128, 21, 'A4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (129, 21, 'A5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (130, 21, 'A6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (131, 21, 'A7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (132, 21, 'A8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (133, 21, 'A9', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (134, 21, 'A10', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (135, 21, 'B1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (136, 21, 'B2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (137, 21, 'B3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (138, 21, 'B4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (139, 21, 'B5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (140, 21, 'B6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (141, 21, 'B7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (142, 21, 'B8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (143, 21, 'B9', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (144, 21, 'B10', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (145, 21, 'C1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (146, 21, 'C2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (147, 21, 'C3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (148, 21, 'C4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (149, 21, 'C5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (150, 21, 'C6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (151, 21, 'C7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (152, 21, 'C8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (153, 21, 'C9', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (154, 21, 'C10', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (155, 21, 'D1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (156, 21, 'D2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (157, 21, 'D3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (158, 21, 'D4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (159, 21, 'D5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (160, 21, 'D6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (161, 21, 'D7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (162, 21, 'D8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (163, 21, 'D9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (164, 21, 'D10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (165, 21, 'E1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (166, 21, 'E2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (167, 21, 'E3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (168, 21, 'E4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (169, 21, 'E5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (170, 21, 'E6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (171, 21, 'E7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (172, 21, 'E8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (173, 21, 'E9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (174, 21, 'E10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (175, 21, 'F1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (176, 21, 'F2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (177, 21, 'F3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (178, 21, 'F4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (179, 21, 'F5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (180, 21, 'F6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (181, 21, 'F7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (182, 21, 'F8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (183, 21, 'F9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (184, 21, 'F10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (185, 21, 'G1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (186, 21, 'G2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (187, 21, 'G3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (188, 21, 'G4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (189, 21, 'G5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (190, 21, 'G6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (191, 21, 'G7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (192, 21, 'G8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (193, 21, 'G9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (194, 21, 'G10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (195, 21, 'H1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (196, 21, 'H2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (197, 21, 'H3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (198, 21, 'H4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (199, 21, 'H5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (200, 21, 'H6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (201, 21, 'H7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (202, 21, 'H8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (203, 21, 'H9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (204, 21, 'H10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (205, 22, 'A1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (206, 22, 'A2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (207, 22, 'A3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (208, 22, 'B1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (209, 22, 'B2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (210, 22, 'B3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (211, 22, 'C1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (212, 22, 'C2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (213, 22, 'C3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (214, 22, 'D1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (215, 22, 'D2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (216, 22, 'D3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (221, 41, 'A1', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (222, 41, 'A2', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (223, 41, 'A3', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (224, 41, 'A4', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (225, 41, 'A5', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (226, 41, 'A6', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (227, 41, 'A7', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (228, 41, 'A8', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (229, 41, 'A9', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (230, 41, 'A10', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (231, 41, 'B1', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (232, 41, 'B2', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (233, 41, 'B3', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (234, 41, 'B4', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (235, 41, 'B5', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (236, 41, 'B6', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (237, 41, 'B7', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (238, 41, 'B8', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (239, 41, 'B9', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (240, 41, 'B10', 'Balcony', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (241, 41, 'C1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (242, 41, 'C2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (243, 41, 'C3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (244, 41, 'C4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (245, 41, 'C5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (246, 41, 'C6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (247, 41, 'C7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (248, 41, 'C8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (249, 41, 'C9', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (250, 41, 'C10', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (251, 41, 'D1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (252, 41, 'D2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (253, 41, 'D3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (254, 41, 'D4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (255, 41, 'D5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (256, 41, 'D6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (257, 41, 'D7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (258, 41, 'D8', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (259, 41, 'D9', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (260, 41, 'D10', 'Premium', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (261, 41, 'E1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (262, 41, 'E2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (263, 41, 'E3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (264, 41, 'E4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (265, 41, 'E5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (266, 41, 'E6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (267, 41, 'E7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (268, 41, 'E8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (269, 41, 'E9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (270, 41, 'E10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (271, 41, 'F1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (272, 41, 'F2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (273, 41, 'F3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (274, 41, 'F4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (275, 41, 'F5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (276, 41, 'F6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (277, 41, 'F7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (278, 41, 'F8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (279, 41, 'F9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (280, 41, 'F10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (281, 41, 'G1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (282, 41, 'G2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (283, 41, 'G3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (284, 41, 'G4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (285, 41, 'G5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (286, 41, 'G6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (287, 41, 'G7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (288, 41, 'G8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (289, 41, 'G9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (290, 41, 'G10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (291, 41, 'H1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (292, 41, 'H2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (293, 41, 'H3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (294, 41, 'H4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (295, 41, 'H5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (296, 41, 'H6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (297, 41, 'H7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (298, 41, 'H8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (299, 41, 'H9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (300, 41, 'H10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (301, 41, 'I1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (302, 41, 'I2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (303, 41, 'I3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (304, 41, 'I4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (305, 41, 'I5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (306, 41, 'I6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (307, 41, 'I7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (308, 41, 'I8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (309, 41, 'I9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (310, 41, 'I10', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (311, 41, 'J1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (312, 41, 'J2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (313, 41, 'J3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (314, 41, 'J4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (315, 41, 'J5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (316, 41, 'J6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (317, 41, 'J7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (318, 41, 'J8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (319, 41, 'J9', 'Regular', 'ACTIVE');
INSERT INTO SEATS (seat_id, screen_id, seat_number, seat_type, status) VALUES (320, 41, 'J10', 'Regular', 'ACTIVE');

-- TABLE: SHOWS (28 records)
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (1, 1, 1, '2026-10-18T00:00:00', '09:30 PM', 250.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (2, 1, 1, '2026-10-18T00:00:00', '10:30 PM', 280.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (3, 1, 5, '2026-10-18T00:00:00', '11:15 PM', 400.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (4, 2, 2, '2026-10-18T00:00:00', '09:45 PM', 350.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (5, 2, 2, '2026-10-18T00:00:00', '10:15 PM', 350.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (6, 3, 3, '2026-10-18T00:00:00', '09:30 PM', 300.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (7, 3, 5, '2026-10-18T00:00:00', '10:45 PM', 450.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (8, 4, 1, '2026-10-18T00:00:00', '09:15 PM', 220.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (9, 5, 3, '2026-10-18T00:00:00', '10:00 PM', 250.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (21, 1, 1, '2026-10-19T00:00:00', '10:30 AM', 250.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (22, 1, 5, '2026-10-19T00:00:00', '06:45 PM', 400.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (23, 2, 2, '2026-10-19T00:00:00', '02:30 PM', 350.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (24, 2, 2, '2026-10-19T00:00:00', '07:00 PM', 380.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (25, 3, 3, '2026-10-19T00:00:00', '01:15 PM', 300.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (26, 3, 5, '2026-10-19T00:00:00', '09:30 PM', 450.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (27, 4, 1, '2026-10-19T00:00:00', '11:00 AM', 220.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (28, 4, 4, '2026-10-19T00:00:00', '04:30 PM', 260.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (29, 5, 3, '2026-10-19T00:00:00', '06:30 PM', 250.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (30, 5, 3, '2026-10-19T00:00:00', '10:00 PM', 280.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (31, 21, 1, '2026-10-18T00:00:00', '09:15 PM', 200.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (32, 21, 1, '2026-10-19T00:00:00', '03:15 PM', 220.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (33, 61, 2, '2026-10-18T00:00:00', '09:30 PM', 180.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (34, 61, 2, '2026-10-19T00:00:00', '05:30 PM', 200.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (35, 41, 4, '2026-10-18T00:00:00', '09:45 PM', 190.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (36, 41, 4, '2026-10-19T00:00:00', '06:00 PM', 210.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (37, 6, 3, '2026-10-18T00:00:00', '10:30', 108.5);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (41, 81, 21, '2026-10-20T00:00:00', '10:30', 250.0);
INSERT INTO SHOWS (show_id, movie_id, screen_id, show_date, show_time, ticket_price) VALUES (42, 1, 3, '2026-10-22T00:00:00', '10:30', 250.0);

-- TABLE: BOOKINGS (24 records)
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (1, 2, 1, '2026-09-24T05:44:46.820000', 500.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (2, 3, 1, '2026-09-24T06:44:46.827000', 500.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (3, 4, 3, '2026-09-24T06:59:46.832000', 1200.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (21, 2, 5, '2026-09-24T13:59:37.998000', 437.5, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (41, 2, 1, '2026-10-18T21:15:41.702000', 250.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (42, 2, 31, '2026-10-18T21:33:38.868000', 450.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (61, 2, 21, '2026-10-19T22:17:42.084000', 812.5, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (62, 2, 6, '2026-10-18T14:30:00', 1350.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (63, 3, 6, '2026-10-19T18:15:00', 900.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (64, 4, 6, '2026-10-20T20:00:00', 1350.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (65, 2, 8, '2026-10-18T16:00:00', 440.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (66, 5, 8, '2026-10-19T17:30:00', 780.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (67, 3, 8, '2026-10-20T19:45:00', 440.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (68, 4, 9, '2026-10-18T15:20:00', 750.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (69, 2, 9, '2026-10-19T19:00:00', 500.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (70, 5, 9, '2026-10-20T21:30:00', 1120.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (71, 2, 37, '2026-10-18T11:00:00', 325.5, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (72, 3, 37, '2026-10-19T14:00:00', 217.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (73, 4, 35, '2026-10-18T13:45:00', 380.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (74, 5, 35, '2026-10-19T18:30:00', 420.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (75, 2, 33, '2026-10-18T17:15:00', 360.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (76, 3, 33, '2026-10-19T20:45:00', 600.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (77, 4, 41, '2026-10-20T12:00:00', 500.0, 'CONFIRMED');
INSERT INTO BOOKINGS (booking_id, user_id, show_id, booking_date, total_amount, booking_status) VALUES (78, 5, 41, '2026-10-21T15:30:00', 500.0, 'CONFIRMED');

-- TABLE: BOOKING_SEATS (56 records)
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (1, 1, 1);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (2, 1, 2);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (3, 2, 17);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (4, 2, 18);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (5, 3, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (6, 3, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (7, 3, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (21, 21, 34);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (41, 41, 6);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (42, 42, 19);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (43, 42, 11);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (61, 61, 17);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (62, 61, 2);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (63, 61, 11);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (64, 62, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (65, 62, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (66, 62, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (67, 63, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (68, 63, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (69, 64, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (70, 64, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (71, 64, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (72, 65, 1);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (73, 65, 2);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (74, 66, 1);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (75, 66, 2);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (76, 66, 3);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (77, 67, 1);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (78, 67, 2);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (79, 68, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (80, 68, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (81, 68, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (82, 69, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (83, 69, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (84, 70, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (85, 70, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (86, 70, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (87, 70, 46);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (88, 71, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (89, 71, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (90, 71, 45);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (91, 72, 43);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (92, 72, 44);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (93, 73, 101);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (94, 73, 102);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (95, 74, 101);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (96, 74, 102);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (97, 75, 25);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (98, 75, 26);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (99, 76, 25);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (100, 76, 26);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (101, 76, 27);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (102, 77, 125);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (103, 77, 126);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (104, 78, 125);
INSERT INTO BOOKING_SEATS (booking_seat_id, booking_id, seat_id) VALUES (105, 78, 126);

-- TABLE: REVIEWS (25 records)
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (1, 2, 1, 5.0, 'Exceptional cinematic experience with breathtaking sci-fi world-building, stellar sound design and spellbinding performances!', 'Positive', 73.21, '2026-10-24 01:40:22');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (2, 3, 1, 4.5, 'Phenomenal storytelling and acting by Matthew McConaughey. Emotional, scientifically thrilling, and visually stunning on the big screen.', 'Positive', 94.2, '2026-09-24T07:44:46.842000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (3, 4, 1, 3.0, 'The scientific aspects were decent and visuals impressive, but the pacing felt a bit long and stretched out towards the third act.', 'Neutral', 68.5, '2026-09-24T07:44:46.844000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (4, 5, 1, 2.0, 'Too confusing and overly dramatic sound mixing made dialogues hard to understand. Not my cup of tea.', 'Negative', 89.1, '2026-09-24T07:44:46.846000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (5, 2, 2, 5.0, 'Oppenheimer is Christopher Nolan finest cinematic achievement. Cillian Murphy delivers an Oscar-worthy performance of rare depth and intensity.', 'Positive', 81.22, '2026-09-24T14:00:51.013000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (6, 3, 2, 4.5, 'Masterful direction, intense sound design, and razor sharp editing. A historic epic executed to perfection.', 'Positive', 93.8, '2026-09-24T07:44:46.850000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (7, 4, 2, 3.5, 'Very engaging history lesson with great performances, though dialogue heavy and slightly repetitive in the court hearing scenes.', 'Neutral', 72.3, '2026-09-24T07:44:46.852000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (8, 5, 2, 2.5, 'Disappointing and slow paced narrative. Expected more about the technical breakthroughs rather than bureaucratic hearings.', 'Negative', 85.6, '2026-09-24T07:44:46.853000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (9, 2, 3, 5.0, 'Dune Part Two is pure visual poetry. The worm-riding sequences and desert warfare are unmatched in cinema history. Astounding spectacle.', 'Positive', 97.4, '2026-09-24T07:44:46.856000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (10, 3, 3, 4.0, 'Incredible scale and world building. Austin Butler and Timothee Chalamet gave commanding performances.', 'Positive', 91.5, '2026-09-24T07:44:46.858000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (11, 4, 3, 3.0, 'Good production values but felt exhausting by the end due to its unrelenting volume and dark atmosphere.', 'Neutral', 65.2, '2026-09-24T07:44:46.860000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (12, 2, 4, 5.0, 'The animation styles and creativity blew my mind! Every single frame belongs in an art museum. Thrilling story and music.', 'Positive', 97.8, '2026-09-24T07:44:46.862000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (13, 3, 4, 3.5, 'Entertaining multiverse story with nice colors, though the cliffhanger ending was slightly abrupt.', 'Neutral', 70.4, '2026-09-24T07:44:46.863000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (14, 4, 5, 4.5, 'Thalapathy Vijay and Lokesh Kanagaraj delivered a high-octane action thriller! Anirudh background score elevated every fight scene.', 'Positive', 95.1, '2026-09-24T07:44:46.865000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (15, 5, 5, 2.0, 'Terrible second half with ridiculous plot logic and pointless flashback sequences. Completely wasted potential.', 'Negative', 92.3, '2026-09-24T07:44:46.867000');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (16, 2, 6, 5.0, 'Spectacular Pandora world-building with breathtaking underwater visual effects and emotional family drama. James Cameron masterclass!', 'Positive', 96.5, '2026-10-18T18:30:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (17, 3, 6, 4.5, 'Jaw-dropping CGI and stunning IMAX 3D action sequences that set a new benchmark for sci-fi cinema.', 'Positive', 94.0, '2026-10-19T20:15:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (18, 4, 6, 3.5, 'Visually extraordinary and thrilling soundtrack, though the narrative pacing feels slightly prolonged in the middle act.', 'Neutral', 71.2, '2026-10-20T14:00:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (19, 2, 21, 4.5, 'Exhilarating superhero adventure with amazing web-slinging action sequences, sharp humor, and delightful character chemistry.', 'Positive', 92.4, '2026-10-19T16:20:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (20, 3, 21, 4.0, 'Fun comic-book adaptation with dazzling animated visuals and a great energetic soundtrack.', 'Positive', 88.6, '2026-10-20T17:40:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (21, 4, 41, 4.5, 'Touching emotional drama with remarkable realistic performances by the lead cast and an inspiring storyline.', 'Positive', 93.1, '2026-10-19T13:10:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (22, 5, 41, 4.0, 'Heartwarming family moments, lovely background score, and thoughtful direction throughout.', 'Positive', 89.5, '2026-10-20T15:30:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (23, 2, 61, 4.5, 'Super fun romantic comedy! Sivakarthikeyan and Keerthy Suresh chemistry was delightful and Anirudh songs are super catchy.', 'Positive', 95.0, '2026-10-19T21:00:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (24, 3, 61, 4.0, 'Charming lighthearted entertainer with humorous scenes, great colorful frames, and feel-good romance.', 'Positive', 90.2, '2026-10-20T11:45:00');
INSERT INTO REVIEWS (review_id, user_id, movie_id, rating, review_text, sentiment_label, confidence_score, review_date) VALUES (25, 4, 81, 4.0, 'Inspiring cosmic space exploration theme with philosophical concepts, beautiful nebula visuals, and great sound design.', 'Positive', 91.8, '2026-10-20T19:00:00');

COMMIT;
