-- =====================================================================
-- SMART CINEMA TICKET HUB
-- Sample Data (Demonstration dataset for Viva and Testing)
-- =====================================================================

-- 1. USERS
-- Admin: admin@cinema.com / Admin@123
-- Customers: Password@123
INSERT INTO USERS (name, email, password, phone, role) 
VALUES ('System Administrator', 'admin@cinema.com', 'scrypt:32768:8:1$YIOmzOTfGIDyl1Sq$5f0843a09057ad48f51b29bcc1a5dfd27e4e8c3f05052de876abe5e7859595abffa56c3805b601f31082ffa212aa7753bf39f97b93002ea2d4e7ba25a930b8d9', '9876543210', 'ADMIN');

INSERT INTO USERS (name, email, password, phone, role) 
VALUES ('Rani Priya', 'rani@cinema.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543211', 'USER');

INSERT INTO USERS (name, email, password, phone, role) 
VALUES ('Muthu Lekshmi', 'muthu@cinema.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543212', 'USER');

INSERT INTO USERS (name, email, password, phone, role) 
VALUES ('John Smith', 'john@example.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543213', 'USER');

INSERT INTO USERS (name, email, password, phone, role) 
VALUES ('Priya Sharma', 'priya@example.com', 'scrypt:32768:8:1$Ae9GZkvGtT7urXtX$e371b2d008e176fe63e1c4cfa571f244ef330ff8ab81262018251dbdda1e14f6644074018cc08d2d36af5dd346428d9152d21f9e67865eff047f14d51ea72872', '9876543214', 'USER');

-- 2. THEATRES
INSERT INTO THEATRES (theatre_name, location) 
VALUES ('PVR INOX Grand Mall', 'MG Road, Bengaluru');

INSERT INTO THEATRES (theatre_name, location) 
VALUES ('Cinepolis Forum Mega', 'Koramangala, Bengaluru');

INSERT INTO THEATRES (theatre_name, location) 
VALUES ('IMAX Regal Symphony', 'Indiranagar 100ft Road, Bengaluru');

-- 3. SCREENS
INSERT INTO SCREENS (theatre_id, screen_name, total_seats) 
VALUES (1, 'Screen 1 - Dolby Atmos', 24);

INSERT INTO SCREENS (theatre_id, screen_name, total_seats) 
VALUES (1, 'Screen 2 - Gold Class', 18);

INSERT INTO SCREENS (theatre_id, screen_name, total_seats) 
VALUES (2, 'Audi 1 - 4DX Experience', 24);

INSERT INTO SCREENS (theatre_id, screen_name, total_seats) 
VALUES (2, 'Audi 2 - Laser Ultra', 24);

INSERT INTO SCREENS (theatre_id, screen_name, total_seats) 
VALUES (3, 'IMAX Screen 1 - Laser 3D', 30);

-- 4. SEATS
-- Generating seats for Screen 1 (Rows A, B Regular; Row C Premium)
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'A8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B7', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'B8', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C7', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (1, 'C8', 'Premium', 'ACTIVE');

-- Generating seats for Screen 2 (Gold Class: Rows A, B, C)
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'G1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'G2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'G3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'G4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'G5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'G6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'H1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'H2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'H3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'H4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'H5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'H6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'J1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'J2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'J3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'J4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'J5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (2, 'J6', 'Premium', 'ACTIVE');

-- Generating seats for Screen 3 (Audi 1)
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'A1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'A2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'A3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'A4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'A5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'A6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'B1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'B2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'B3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'B4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'B5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'B6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'C1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'C2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'C3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'C4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'C5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'C6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'D1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'D2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'D3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'D4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'D5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (3, 'D6', 'Premium', 'ACTIVE');

-- Generating seats for Screen 5 (IMAX)
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'I1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'I2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'I3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'I4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'I5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'I6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'M1', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'M2', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'M3', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'M4', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'M5', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'M6', 'Regular', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'A1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'A2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'A3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'A4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'A5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'A6', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'X1', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'X2', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'X3', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'X4', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'X5', 'Premium', 'ACTIVE');
INSERT INTO SEATS (screen_id, seat_number, seat_type, status) VALUES (5, 'X6', 'Premium', 'ACTIVE');

-- 5. MOVIES
INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
VALUES (
    'Interstellar: Beyond Horizons',
    'A team of courageous explorers travels through a newly discovered wormhole in space in an attempt to ensure humanity survival as Earth faces catastrophic collapse.',
    'English',
    'Sci-Fi',
    169,
    DATE '2024-03-15',
    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop',
    'https://www.youtube.com/watch?v=zSWdZVtXT7E',
    4.8
);

INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
VALUES (
    'Oppenheimer',
    'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II and the subsequent moral fallout.',
    'English',
    'Drama',
    180,
    DATE '2024-04-10',
    'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=600&auto=format&fit=crop',
    'https://www.youtube.com/watch?v=uYPbbksJxIg',
    4.9
);

INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
VALUES (
    'Dune: Part Two',
    'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family and facing a choice between love and destiny.',
    'English',
    'Sci-Fi',
    166,
    DATE '2024-05-01',
    'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop',
    'https://www.youtube.com/watch?v=Way9Dexny3w',
    4.7
);

INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
VALUES (
    'Spider-Man: Spider-Verse',
    'Miles Morales catapults across the Multiverse, encountering a society of Spider-People charged with protecting its very existence.',
    'English',
    'Animation',
    140,
    DATE '2024-06-15',
    'https://images.unsplash.com/photo-1635805737707-575885ab0820?w=600&auto=format&fit=crop',
    'https://www.youtube.com/watch?v=cqGjhVJWtEg',
    4.8
);

INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
VALUES (
    'Leo: Bloody Sweet',
    'A mild-mannered cafe owner gets caught up in a bloody confrontation with gangsters who believe he is a ruthless mobster from their past.',
    'Tamil',
    'Action',
    164,
    DATE '2024-07-20',
    'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=600&auto=format&fit=crop',
    'https://www.youtube.com/watch?v=Po3jVh2CAT8',
    4.3
);

INSERT INTO MOVIES (title, description, language, genre, duration, release_date, poster, trailer, rating)
VALUES (
    'Avatar: Fire and Ash',
    'Jake Sully and Neytiri return in an exhilarating journey into new territories of Pandora, encountering the hostile Ash People in an epic struggle for survival.',
    'English',
    'Sci-Fi',
    175,
    DATE '2026-12-18',
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop',
    'https://www.youtube.com/watch?v=d9MyW72ELq0',
    0.0
);

-- 6. SHOWS (for today and upcoming dates)
INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (1, 1, TRUNC(SYSDATE), '10:30 AM', 250.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (1, 1, TRUNC(SYSDATE), '02:30 PM', 280.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (1, 5, TRUNC(SYSDATE), '06:45 PM', 400.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (2, 2, TRUNC(SYSDATE), '11:00 AM', 350.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (2, 2, TRUNC(SYSDATE), '04:00 PM', 350.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (3, 3, TRUNC(SYSDATE), '01:15 PM', 300.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (3, 5, TRUNC(SYSDATE), '09:30 PM', 450.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (4, 1, TRUNC(SYSDATE + 1), '10:00 AM', 220.00);

INSERT INTO SHOWS (movie_id, screen_id, show_date, show_time, ticket_price) 
VALUES (5, 3, TRUNC(SYSDATE + 1), '06:30 PM', 250.00);

-- 7. INITIAL BOOKINGS & BOOKING_SEATS
-- User 2 (Rani) books Show 1 (Seats A1, A2)
INSERT INTO BOOKINGS (user_id, show_id, booking_date, total_amount, booking_status) 
VALUES (2, 1, CURRENT_TIMESTAMP - INTERVAL '2' HOUR, 500.00, 'CONFIRMED');

INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (1, 1);
INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (1, 2);

-- User 3 (Muthu) books Show 1 (Seats C1, C2)
INSERT INTO BOOKINGS (user_id, show_id, booking_date, total_amount, booking_status) 
VALUES (3, 1, CURRENT_TIMESTAMP - INTERVAL '1' HOUR, 500.00, 'CONFIRMED');

INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (2, 17);
INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (2, 18);

-- User 4 (John) books Show 3 (Seats I1, I2, I3)
INSERT INTO BOOKINGS (user_id, show_id, booking_date, total_amount, booking_status) 
VALUES (4, 3, CURRENT_TIMESTAMP - INTERVAL '45' MINUTE, 1200.00, 'CONFIRMED');

INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (3, 43);
INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (3, 44);
INSERT INTO BOOKING_SEATS (booking_id, seat_id) VALUES (3, 45);

-- 8. REVIEWS WITH REALISTIC TEXT & SENTIMENT LABELS
INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (2, 1, 5.0, 'An absolute masterpiece of modern cinema! Hans Zimmer score together with breathtaking visuals gave me goosebumps throughout the entire film. Best sci-fi ever.', 'Positive', 96.40);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (3, 1, 4.5, 'Phenomenal storytelling and acting by Matthew McConaughey. Emotional, scientifically thrilling, and visually stunning on the big screen.', 'Positive', 94.20);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (4, 1, 3.0, 'The scientific aspects were decent and visuals impressive, but the pacing felt a bit long and stretched out towards the third act.', 'Neutral', 68.50);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (5, 1, 2.0, 'Too confusing and overly dramatic sound mixing made dialogues hard to understand. Not my cup of tea.', 'Negative', 89.10);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (2, 2, 5.0, 'Oppenheimer is Christopher Nolan finest cinematic achievement. Cillian Murphy delivers an Oscar-worthy performance of rare depth and intensity.', 'Positive', 98.15);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (3, 2, 4.5, 'Masterful direction, intense sound design, and razor sharp editing. A historic epic executed to perfection.', 'Positive', 93.80);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (4, 2, 3.5, 'Very engaging history lesson with great performances, though dialogue heavy and slightly repetitive in the court hearing scenes.', 'Neutral', 72.30);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (5, 2, 2.5, 'Disappointing and slow paced narrative. Expected more about the technical breakthroughs rather than bureaucratic hearings.', 'Negative', 85.60);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (2, 3, 5.0, 'Dune Part Two is pure visual poetry. The worm-riding sequences and desert warfare are unmatched in cinema history. Astounding spectacle.', 'Positive', 97.40);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (3, 3, 4.0, 'Incredible scale and world building. Austin Butler and Timothee Chalamet gave commanding performances.', 'Positive', 91.50);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (4, 3, 3.0, 'Good production values but felt exhausting by the end due to its unrelenting volume and dark atmosphere.', 'Neutral', 65.20);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (2, 4, 5.0, 'The animation styles and creativity blew my mind! Every single frame belongs in an art museum. Thrilling story and music.', 'Positive', 97.80);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (3, 4, 3.5, 'Entertaining multiverse story with nice colors, though the cliffhanger ending was slightly abrupt.', 'Neutral', 70.40);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (4, 5, 4.5, 'Thalapathy Vijay and Lokesh Kanagaraj delivered a high-octane action thriller! Anirudh background score elevated every fight scene.', 'Positive', 95.10);

INSERT INTO REVIEWS (user_id, movie_id, rating, review_text, sentiment_label, confidence_score) 
VALUES (5, 5, 2.0, 'Terrible second half with ridiculous plot logic and pointless flashback sequences. Completely wasted potential.', 'Negative', 92.30);

COMMIT;
