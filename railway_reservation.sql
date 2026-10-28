-- =====================================================================
-- Railway Reservation System - Database Schema & Seed Data
-- Database Engine: MySQL 8+
-- ---------------------------------------------------------------------
-- Tables: users, trains, train_classes, train_seats_availability,
--         bookings, passengers, payments (SIMULATED), cancellations
--
-- Seat inventory is tracked PER (train, journey_date, travel_class).
-- Bookings record the travel class, per-passenger base fare and a
-- SIMULATED payment transaction record (no real money is ever processed).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS railway_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE railway_db;

-- Disable foreign key checks during schema (re)creation
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS passengers;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS cancellations;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS train_seats_availability;
DROP TABLE IF EXISTS train_classes;
DROP TABLE IF EXISTS trains;
DROP TABLE IF EXISTS users;

-- ---------------------------------------------------------------------
-- Table 1: users
-- Stores registered system users and administrators.
-- Passwords stored exclusively as BCrypt hashes (never plain text).
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role ENUM('ADMIN', 'USER') NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_users_email (email),
    INDEX idx_users_role (role)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 2: trains
-- Stores train schedules, routes, running days and base defaults.
-- running_days is a 7-character mask, Mon..Sun, 'Y' = runs, 'N' = does not.
-- fare / seat_capacity here are base defaults only; bookable inventory and
-- fares are defined per travel class in train_classes.
-- ---------------------------------------------------------------------
CREATE TABLE trains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    train_number VARCHAR(20) NOT NULL UNIQUE,
    train_name VARCHAR(100) NOT NULL,
    source_station VARCHAR(100) NOT NULL,
    destination_station VARCHAR(100) NOT NULL,
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    fare DECIMAL(10, 2) NOT NULL,
    seat_capacity INT NOT NULL,
    running_days CHAR(7) NOT NULL DEFAULT 'YYYYYYY',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_trains_route (source_station, destination_station, is_active),
    INDEX idx_trains_number (train_number)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 3: train_classes
-- Per-train travel classes (e.g. SL, 3A, 2A, CC) with their own fare and
-- seat capacity. Availability is maintained per (train, journey_date, class).
-- ---------------------------------------------------------------------
CREATE TABLE train_classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    class_code VARCHAR(10) NOT NULL,
    class_name VARCHAR(50) NOT NULL,
    fare DECIMAL(10, 2) NOT NULL,
    capacity INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE KEY uq_train_class (train_id, class_code),
    INDEX idx_train_classes_code (class_code),
    CONSTRAINT fk_train_classes_train FOREIGN KEY (train_id)
        REFERENCES trains(id) ON DELETE CASCADE,
    CONSTRAINT chk_class_fare CHECK (fare > 0),
    CONSTRAINT chk_class_capacity CHECK (capacity > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 4: train_seats_availability
-- Tracks seat inventory separately per train, journey date AND travel class.
-- Atomically locked and updated during booking and cancellation.
-- Check constraints guarantee seats never go negative or exceed total.
-- ---------------------------------------------------------------------
CREATE TABLE train_seats_availability (
    id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    journey_date DATE NOT NULL,
    class_code VARCHAR(10) NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_train_date_class (train_id, journey_date, class_code),
    INDEX idx_avail_train_date_class (train_id, journey_date, class_code),
    CONSTRAINT fk_avail_train FOREIGN KEY (train_id)
        REFERENCES trains(id) ON DELETE CASCADE,
    CONSTRAINT chk_avail_non_negative CHECK (available_seats >= 0),
    CONSTRAINT chk_avail_le_total CHECK (available_seats <= total_seats)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 5: bookings
-- Stores ticket reservations, PNR, journey date, travel class and status.
-- base_fare  = per-passenger fare for the booked class.
-- total_fare = base_fare * passenger_count.
-- payment_status is SIMULATED only; no real payment gateway is used.
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pnr VARCHAR(20) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    train_id INT NOT NULL,
    journey_date DATE NOT NULL,
    class_code VARCHAR(10) NOT NULL,
    passenger_count INT NOT NULL,
    base_fare DECIMAL(10, 2) NOT NULL,
    total_fare DECIMAL(10, 2) NOT NULL,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('CONFIRMED', 'CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
    payment_status ENUM('PENDING', 'PAID') NOT NULL DEFAULT 'PAID',
    INDEX idx_bookings_pnr (pnr),
    INDEX idx_bookings_user (user_id),
    INDEX idx_bookings_train_date_class (train_id, journey_date, class_code),
    INDEX idx_bookings_status (status),
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_train FOREIGN KEY (train_id)
        REFERENCES trains(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 6: passengers
-- Individual passenger details belonging to a booking.
-- seat_number encodes the allocated coach, seat and berth (e.g. S1-12-LB).
-- berth_preference is the passenger's requested preference.
-- ---------------------------------------------------------------------
CREATE TABLE passengers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender VARCHAR(10) NOT NULL,
    seat_number VARCHAR(20) NOT NULL,
    berth_preference VARCHAR(20) NOT NULL,
    INDEX idx_passengers_booking (booking_id),
    CONSTRAINT fk_passengers_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 7: payments  (SIMULATED / DEMO ONLY)
-- Records a simulated payment transaction for each booking. This is NOT a
-- real payment gateway integration; no actual money is ever processed.
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    pnr VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(30) NOT NULL DEFAULT 'SIMULATED_DEMO',
    payment_status ENUM('PENDING', 'PAID', 'REFUNDED') NOT NULL DEFAULT 'PAID',
    transaction_ref VARCHAR(60) NOT NULL,
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payments_booking (booking_id),
    INDEX idx_payments_pnr (pnr),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Table 8: cancellations
-- Audit record created whenever a confirmed booking is cancelled.
-- ---------------------------------------------------------------------
CREATE TABLE cancellations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    pnr VARCHAR(20) NOT NULL,
    cancelled_by_user_id INT NOT NULL,
    passenger_count INT NOT NULL,
    refund_amount DECIMAL(10, 2) NOT NULL,
    cancellation_reason VARCHAR(100) NOT NULL DEFAULT 'User cancellation',
    cancelled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cancellations_booking (booking_id),
    INDEX idx_cancellations_pnr (pnr),
    CONSTRAINT fk_cancellations_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(id) ON DELETE CASCADE,
    CONSTRAINT fk_cancellations_user FOREIGN KEY (cancelled_by_user_id)
        REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- Seed Data
-- =====================================================================

-- Default Users:
-- Admin: admin@railway.com / Admin@123
-- User:  rahul.sharma@example.com / User@123
-- User:  priya.patel@example.com / User@123
INSERT INTO users (id, full_name, email, password_hash, phone, role) VALUES
(1, 'System Administrator', 'admin@railway.com', '$2a$12$o.RerH59CtxRLS2adK8SAeUMttwhijBPXNUmHlOgxr.Rc3NGmLxri', '9876543210', 'ADMIN'),
(2, 'Rahul Sharma', 'rahul.sharma@example.com', '$2a$12$kgInUfHJ9tmv0KdD4nw2vuyEMurOFvenBKcYLtQl3m2myE2TvPH3W', '9811223344', 'USER'),
(3, 'Priya Patel', 'priya.patel@example.com', '$2a$12$kgInUfHJ9tmv0KdD4nw2vuyEMurOFvenBKcYLtQl3m2myE2TvPH3W', '9822334455', 'USER');

-- Default Trains across prominent routes.
-- running_days: Mon Tue Wed Thu Fri Sat Sun  (Y = runs)
INSERT INTO trains (id, train_number, train_name, source_station, destination_station, departure_time, arrival_time, fare, seat_capacity, running_days, is_active) VALUES
(1,  '12002', 'Bhopal Shatabdi Express',   'New Delhi',         'Bhopal Jn',         '06:00:00', '14:40:00', 1250.00, 120, 'YYYYYYY', TRUE),
(2,  '12952', 'Mumbai Rajdhani Express',    'New Delhi',         'Mumbai Central',    '16:55:00', '08:35:00', 2150.00, 150, 'YYYYYYY', TRUE),
(3,  '22436', 'Vande Bharat Express',      'New Delhi',         'Varanasi Jn',       '06:00:00', '14:00:00', 1750.00, 100, 'YYYYYYY', TRUE),
(4,  '12268', 'Mumbai Duronto Express',     'Ahmedabad Jn',      'Mumbai Central',    '23:45:00', '06:00:00', 1450.00, 120, 'YYYYYYN', TRUE),
(5,  '12626', 'Kerala Express',            'New Delhi',         'Thiruvananthapuram','20:10:00', '14:15:00', 2450.00, 180, 'YYYYYYY', TRUE),
(6,  '12301', 'Howrah Rajdhani Express',   'Howrah Jn',         'New Delhi',         '16:50:00', '10:05:00', 2200.00, 150, 'YYYYYYY', TRUE),
(7,  '12138', 'Punjab Mail',              'Firozpur Cantt',    'Mumbai CSMT',       '21:40:00', '07:35:00', 1850.00, 160, 'YYYYYYY', TRUE),
(8,  '12724', 'Telangana Express',         'New Delhi',         'Hyderabad Deccan',  '16:00:00', '17:10:00', 1980.00, 140, 'YYYYYYY', TRUE),
(9,  '12059', 'Kota Jan Shatabdi',         'Hazrat Nizamuddin', 'Kota Jn',           '12:45:00', '18:55:00',  650.00, 100, 'NYYYYYY', TRUE),
(10, '12840', 'Howrah Mail',              'Chennai Central',   'Howrah Jn',         '23:45:00', '03:50:00', 1650.00, 140, 'YYYYYYY', TRUE);

-- Per-train travel classes.
-- Fares: SL = base*0.6, 3A = base*1.0, 2A = base*1.5  (rounded to whole rupees).
-- Capacity split: SL 50%, 3A 30%, 2A 20% of seat_capacity.
INSERT INTO train_classes (train_id, class_code, class_name, fare, capacity, is_active) VALUES
(1,  'SL', 'Sleeper',      750.00,  60, TRUE),
(1,  '3A', 'AC 3 Tier',   1250.00,  36, TRUE),
(1,  '2A', 'AC 2 Tier',   1875.00,  24, TRUE),
(2,  'SL', 'Sleeper',     1290.00,  75, TRUE),
(2,  '3A', 'AC 3 Tier',   2150.00,  45, TRUE),
(2,  '2A', 'AC 2 Tier',   3225.00,  30, TRUE),
(3,  'SL', 'Sleeper',     1050.00,  50, TRUE),
(3,  '3A', 'AC 3 Tier',   1750.00,  30, TRUE),
(3,  '2A', 'AC 2 Tier',   2625.00,  20, TRUE),
(4,  'SL', 'Sleeper',      870.00,  60, TRUE),
(4,  '3A', 'AC 3 Tier',   1450.00,  36, TRUE),
(4,  '2A', 'AC 2 Tier',   2175.00,  24, TRUE),
(5,  'SL', 'Sleeper',     1470.00,  90, TRUE),
(5,  '3A', 'AC 3 Tier',   2450.00,  54, TRUE),
(5,  '2A', 'AC 2 Tier',   3675.00,  36, TRUE),
(6,  'SL', 'Sleeper',     1320.00,  75, TRUE),
(6,  '3A', 'AC 3 Tier',   2200.00,  45, TRUE),
(6,  '2A', 'AC 2 Tier',   3300.00,  30, TRUE),
(7,  'SL', 'Sleeper',     1110.00,  80, TRUE),
(7,  '3A', 'AC 3 Tier',   1850.00,  48, TRUE),
(7,  '2A', 'AC 2 Tier',   2775.00,  32, TRUE),
(8,  'SL', 'Sleeper',     1188.00,  70, TRUE),
(8,  '3A', 'AC 3 Tier',   1980.00,  42, TRUE),
(8,  '2A', 'AC 2 Tier',   2970.00,  28, TRUE),
(9,  'SL', 'Sleeper',      390.00,  50, TRUE),
(9,  '3A', 'AC 3 Tier',    650.00,  30, TRUE),
(9,  '2A', 'AC 2 Tier',    975.00,  20, TRUE),
(10, 'SL', 'Sleeper',      990.00,  70, TRUE),
(10, '3A', 'AC 3 Tier',   1650.00,  42, TRUE),
(10, '2A', 'AC 2 Tier',   2475.00,  28, TRUE);

-- Pre-populate per-class availability for today + 1, +2, +3, +7 days.
INSERT INTO train_seats_availability (train_id, journey_date, class_code, total_seats, available_seats)
SELECT tc.train_id, CURDATE(), tc.class_code, tc.capacity, tc.capacity
FROM train_classes tc WHERE tc.is_active = TRUE;

INSERT INTO train_seats_availability (train_id, journey_date, class_code, total_seats, available_seats)
SELECT tc.train_id, DATE_ADD(CURDATE(), INTERVAL 1 DAY), tc.class_code, tc.capacity, tc.capacity
FROM train_classes tc WHERE tc.is_active = TRUE;

INSERT INTO train_seats_availability (train_id, journey_date, class_code, total_seats, available_seats)
SELECT tc.train_id, DATE_ADD(CURDATE(), INTERVAL 2 DAY), tc.class_code, tc.capacity, tc.capacity
FROM train_classes tc WHERE tc.is_active = TRUE;

INSERT INTO train_seats_availability (train_id, journey_date, class_code, total_seats, available_seats)
SELECT tc.train_id, DATE_ADD(CURDATE(), INTERVAL 3 DAY), tc.class_code, tc.capacity, tc.capacity
FROM train_classes tc WHERE tc.is_active = TRUE;

INSERT INTO train_seats_availability (train_id, journey_date, class_code, total_seats, available_seats)
SELECT tc.train_id, DATE_ADD(CURDATE(), INTERVAL 7 DAY), tc.class_code, tc.capacity, tc.capacity
FROM train_classes tc WHERE tc.is_active = TRUE;

-- Sample Seed Booking for Rahul Sharma (User ID 2) on Train 12952 (Train ID 2),
-- class 3A, tomorrow, 2 passengers. base_fare = 2150, total = 4300.
INSERT INTO bookings (id, pnr, user_id, train_id, journey_date, class_code, passenger_count, base_fare, total_fare, status, payment_status) VALUES
(1, 'PNR84729103', 2, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '3A', 2, 2150.00, 4300.00, 'CONFIRMED', 'PAID');

-- Deduct 2 seats from availability for Train 2, tomorrow, class 3A.
UPDATE train_seats_availability
SET available_seats = available_seats - 2
WHERE train_id = 2 AND journey_date = DATE_ADD(CURDATE(), INTERVAL 1 DAY) AND class_code = '3A';

-- Simulated payment record for the sample booking.
INSERT INTO payments (booking_id, pnr, amount, payment_method, payment_status, transaction_ref) VALUES
(1, 'PNR84729103', 4300.00, 'SIMULATED_DEMO', 'PAID', 'DEMO-TXN-84729103');

-- Sample Passenger records for Booking 1.
INSERT INTO passengers (booking_id, name, age, gender, seat_number, berth_preference) VALUES
(1, 'Rahul Sharma', 32, 'Male',   'S1-12-LB', 'Lower'),
(1, 'Anjali Sharma', 29, 'Female', 'S1-13-UB', 'Middle');

-- End of script
