DROP DATABASE IF EXISTS harborwing_air;

CREATE DATABASE harborwing_air;

USE harborwing_air;

CREATE TABLE airline (
    airline_code VARCHAR(10) NOT NULL,
    airline_name VARCHAR(120) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (airline_code)
) ENGINE=InnoDB;

CREATE TABLE aircraft_type (
    aircraft_type_code VARCHAR(20) NOT NULL,
    aircraft_type_name VARCHAR(120) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (aircraft_type_code)
) ENGINE=InnoDB;

CREATE TABLE reservation_status (
    reservation_status_code VARCHAR(30) NOT NULL,
    status_name VARCHAR(100) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (reservation_status_code)
) ENGINE=InnoDB;

CREATE TABLE payment_status (
    payment_status_code VARCHAR(30) NOT NULL,
    status_name VARCHAR(100) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (payment_status_code)
) ENGINE=InnoDB;

CREATE TABLE ticket_type (
    ticket_type_code VARCHAR(30) NOT NULL,
    ticket_type_name VARCHAR(100) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (ticket_type_code)
) ENGINE=InnoDB;

CREATE TABLE travel_class (
    travel_class_code VARCHAR(30) NOT NULL,
    travel_class_name VARCHAR(100) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (travel_class_code)
) ENGINE=InnoDB;

CREATE TABLE booking_agent (
    agent_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    agent_name VARCHAR(150) NOT NULL,
    phone VARCHAR(40) NULL,
    email VARCHAR(254) NULL,
    other_details TEXT NULL,
    PRIMARY KEY (agent_id),
    INDEX idx_agent_name (agent_name)
) ENGINE=InnoDB;

CREATE TABLE passenger (
    passenger_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    second_name VARCHAR(100) NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(40) NULL,
    email VARCHAR(254) NULL,
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200) NULL,
    city VARCHAR(100) NOT NULL,
    state_province_county VARCHAR(100) NULL,
    country VARCHAR(100) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (passenger_id),
    INDEX idx_passenger_email (email),
    INDEX idx_passenger_name (last_name, first_name)
) ENGINE=InnoDB;

CREATE TABLE airport (
    airport_code VARCHAR(10) NOT NULL,
    airport_name VARCHAR(150) NOT NULL,
    location VARCHAR(200) NOT NULL,
    other_details TEXT NULL,
    PRIMARY KEY (airport_code),
    INDEX idx_airport_name (airport_name)
) ENGINE=InnoDB;

CREATE TABLE calendar_date (
    calendar_date DATE NOT NULL,
    day_of_month TINYINT UNSIGNED NOT NULL,
    is_business_day BOOLEAN NOT NULL,
    PRIMARY KEY (calendar_date),
    CHECK (day_of_month BETWEEN 1 AND 31)
) ENGINE=InnoDB;

CREATE TABLE flight_schedule (
    flight_number VARCHAR(20) NOT NULL,
    airline_code VARCHAR(10) NOT NULL,
    aircraft_type_code VARCHAR(20) NOT NULL,
    origin_airport_code VARCHAR(10) NOT NULL,
    destination_airport_code VARCHAR(10) NOT NULL,
    scheduled_departure DATETIME NOT NULL,
    scheduled_arrival DATETIME NOT NULL,
    PRIMARY KEY (flight_number),
    INDEX idx_schedule_departure (scheduled_departure),
    INDEX idx_schedule_origin (origin_airport_code),
    INDEX idx_schedule_destination (destination_airport_code),
    CONSTRAINT chk_schedule_airports
        CHECK (origin_airport_code <> destination_airport_code),
    CONSTRAINT chk_schedule_times
        CHECK (scheduled_arrival > scheduled_departure),
    CONSTRAINT fk_schedule_airline
        FOREIGN KEY (airline_code)
        REFERENCES airline (airline_code)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_schedule_aircraft
        FOREIGN KEY (aircraft_type_code)
        REFERENCES aircraft_type (aircraft_type_code)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_schedule_origin
        FOREIGN KEY (origin_airport_code)
        REFERENCES airport (airport_code),
    CONSTRAINT fk_schedule_destination
        FOREIGN KEY (destination_airport_code)
        REFERENCES airport (airport_code)
) ENGINE=InnoDB;

CREATE TABLE flight_leg (
    leg_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    flight_number VARCHAR(20) NOT NULL,
    origin_airport_code VARCHAR(10) NOT NULL,
    destination_airport_code VARCHAR(10) NOT NULL,
    actual_departure DATETIME NULL,
    actual_arrival DATETIME NULL,
    PRIMARY KEY (leg_id),
    INDEX idx_leg_flight_number (flight_number),
    INDEX idx_leg_origin (origin_airport_code),
    INDEX idx_leg_destination (destination_airport_code),
    CONSTRAINT chk_leg_airports
        CHECK (origin_airport_code <> destination_airport_code),
    CONSTRAINT chk_leg_actual_times
        CHECK (
            actual_departure IS NULL
            OR actual_arrival IS NULL
            OR actual_arrival > actual_departure
        ),
    CONSTRAINT fk_leg_schedule
        FOREIGN KEY (flight_number)
        REFERENCES flight_schedule (flight_number)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_leg_origin
        FOREIGN KEY (origin_airport_code)
        REFERENCES airport (airport_code),
    CONSTRAINT fk_leg_destination
        FOREIGN KEY (destination_airport_code)
        REFERENCES airport (airport_code)
) ENGINE=InnoDB;

CREATE TABLE reservation (
    reservation_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    passenger_id INT UNSIGNED NOT NULL,
    agent_id INT UNSIGNED NULL,
    reservation_status_code VARCHAR(30) NOT NULL,
    ticket_type_code VARCHAR(30) NOT NULL,
    travel_class_code VARCHAR(30) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    party_size INT UNSIGNED NOT NULL,
    PRIMARY KEY (reservation_id),
    INDEX idx_reservation_passenger_created
        (passenger_id, created_at),
    INDEX idx_reservation_agent (agent_id),
    INDEX idx_reservation_status (reservation_status_code),
    CONSTRAINT chk_reservation_party_size
        CHECK (party_size > 0),
    CONSTRAINT fk_reservation_passenger
        FOREIGN KEY (passenger_id)
        REFERENCES passenger (passenger_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reservation_agent
        FOREIGN KEY (agent_id)
        REFERENCES booking_agent (agent_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_reservation_status
        FOREIGN KEY (reservation_status_code)
        REFERENCES reservation_status (reservation_status_code)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reservation_ticket
        FOREIGN KEY (ticket_type_code)
        REFERENCES ticket_type (ticket_type_code)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reservation_class
        FOREIGN KEY (travel_class_code)
        REFERENCES travel_class (travel_class_code)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payment (
    payment_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    payment_status_code VARCHAR(30) NOT NULL,
    payment_date DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (payment_id),
    INDEX idx_payment_date (payment_date),
    INDEX idx_payment_status (payment_status_code),
    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),
    CONSTRAINT fk_payment_status
        FOREIGN KEY (payment_status_code)
        REFERENCES payment_status (payment_status_code)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE flight_cost (
    flight_number VARCHAR(20) NOT NULL,
    aircraft_type_code VARCHAR(20) NOT NULL,
    valid_from_date DATE NOT NULL,
    valid_to_date DATE NOT NULL,
    cost_amount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (
        flight_number,
        aircraft_type_code,
        valid_from_date
    ),
    INDEX idx_flight_cost_validity (
        aircraft_type_code,
        valid_from_date,
        valid_to_date
    ),
    CONSTRAINT chk_flight_cost_amount
        CHECK (cost_amount >= 0),
    CONSTRAINT chk_flight_cost_dates
        CHECK (valid_to_date >= valid_from_date),
    CONSTRAINT fk_cost_schedule
        FOREIGN KEY (flight_number)
        REFERENCES flight_schedule (flight_number)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cost_aircraft
        FOREIGN KEY (aircraft_type_code)
        REFERENCES aircraft_type (aircraft_type_code)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cost_valid_from
        FOREIGN KEY (valid_from_date)
        REFERENCES calendar_date (calendar_date),
    CONSTRAINT fk_cost_valid_to
        FOREIGN KEY (valid_to_date)
        REFERENCES calendar_date (calendar_date)
) ENGINE=InnoDB;

CREATE TABLE reservation_payment (
    reservation_id INT UNSIGNED NOT NULL,
    payment_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (reservation_id, payment_id),
    INDEX idx_reservation_payment_payment (payment_id),
    CONSTRAINT fk_rp_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rp_payment
        FOREIGN KEY (payment_id)
        REFERENCES payment (payment_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reservation_leg (
    reservation_id INT UNSIGNED NOT NULL,
    leg_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (reservation_id, leg_id),
    INDEX idx_reservation_leg_leg (leg_id),
    CONSTRAINT fk_rl_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rl_leg
        FOREIGN KEY (leg_id)
        REFERENCES flight_leg (leg_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
