import os
import random
import sys
from datetime import date, datetime, timedelta
from decimal import Decimal

import mysql.connector
from faker import Faker

SEED = 20261016

random.seed(SEED)
Faker.seed(SEED)
fake = Faker("en_US")


def build_reference_rows(base_entries, prefix, label):
    rows = []

    for i in range(1, 51):
        if i <= len(base_entries):
            code, name = base_entries[i - 1]
            details = "Standard fictional training value."
        else:
            code = f"DEMO_{prefix}{i:03d}"
            name = f"Demonstration {label} {i:03d}"
            details = "Demonstration data added to meet the 50-row requirement."

        rows.append((code, name, details))

    return rows


def random_datetime(start, end):
    seconds = int((end - start).total_seconds())
    return start + timedelta(seconds=random.randint(0, seconds))


def create_unique_pairs(target_count, special_pairs, left_max, right_max):
    pairs = []
    used = set()

    for pair in special_pairs:
        if pair not in used:
            used.add(pair)
            pairs.append(pair)

    while len(pairs) < target_count:
        pair = (
            random.randint(1, left_max),
            random.randint(1, right_max)
        )

        if pair not in used:
            used.add(pair)
            pairs.append(pair)

    return pairs


def insert_rows(cursor, sql, rows):
    if rows:
        cursor.executemany(sql, rows)


airline_rows = build_reference_rows(
    [
        ("AL001", "HarborWing Air"),
        ("AL002", "Coral Route Air"),
        ("AL003", "Island Link Airways"),
        ("AL004", "Blue Coast Regional"),
        ("AL005", "Seabreeze Air")
    ],
    "AL",
    "Airline"
)

aircraft_rows = build_reference_rows(
    [
        ("AC001", "Regional Propeller"),
        ("AC002", "Small Regional Jet"),
        ("AC003", "Twin Engine Turboprop"),
        ("AC004", "Coastal Passenger Jet"),
        ("AC005", "Island Connector Aircraft")
    ],
    "AC",
    "Aircraft Type"
)

reservation_status_rows = build_reference_rows(
    [
        ("CONFIRMED", "Confirmed"),
        ("PENDING", "Pending"),
        ("CANCELLED", "Cancelled"),
        ("WAITLISTED", "Waitlisted"),
        ("COMPLETED", "Completed")
    ],
    "RS",
    "Reservation Status"
)

payment_status_rows = build_reference_rows(
    [
        ("PAID", "Paid"),
        ("PENDING", "Pending"),
        ("FAILED", "Failed"),
        ("REFUNDED", "Refunded"),
        ("PARTIAL", "Partially Paid")
    ],
    "PS",
    "Payment Status"
)

ticket_type_rows = build_reference_rows(
    [
        ("STANDARD", "Standard"),
        ("FLEXIBLE", "Flexible"),
        ("REFUNDABLE", "Refundable"),
        ("NONREFUNDABLE", "Non-refundable"),
        ("GROUP", "Group Ticket")
    ],
    "TT",
    "Ticket Type"
)

travel_class_rows = build_reference_rows(
    [
        ("ECONOMY", "Economy"),
        ("PREMIUM_ECONOMY", "Premium Economy"),
        ("BUSINESS", "Business"),
        ("FIRST", "First Class"),
        ("REGIONAL_PLUS", "Regional Plus")
    ],
    "TC",
    "Travel Class"
)

airline_codes = [row[0] for row in airline_rows[:5]]
aircraft_codes = [row[0] for row in aircraft_rows[:5]]
reservation_status_codes = [
    row[0] for row in reservation_status_rows[:5]
]
payment_status_codes = [
    row[0] for row in payment_status_rows[:5]
]
ticket_type_codes = [row[0] for row in ticket_type_rows[:5]]
travel_class_codes = [row[0] for row in travel_class_rows[:5]]


agent_rows = []

for i in range(1, 61):
    agent_rows.append(
        (
            f"{fake.company()} Booking Office {i:03d}",
            f"+800-555-{random.randint(1000, 9999)}",
            f"agent{i:03d}@example.test",
            "Synthetic booking agent record."
        )
    )


passenger_rows = []

for i in range(1, 101):
    passenger_rows.append(
        (
            fake.first_name(),
            fake.first_name() if random.random() < 0.35 else None,
            fake.last_name(),
            f"+800-555-{random.randint(1000, 9999)}",
            f"passenger{i:03d}@example.test",
            f"{random.randint(1, 9999)} {fake.street_name()}",
            None,
            f"Coastal City {random.randint(1, 90):03d}",
            f"Island Province {random.randint(1, 12):02d}",
            "Fictional Islands",
            "Synthetic passenger record generated for coursework."
        )
    )


airport_rows = []

for i in range(1, 61):
    airport_rows.append(
        (
            f"HWA{i:03d}",
            f"HarborWing Synthetic Airport {i:03d}",
            f"Island District {i:03d}, Fictional Archipelago",
            "Fictional airport for database demonstration."
        )
    )

airport_codes = [row[0] for row in airport_rows]


calendar_rows = []
current_date = date(2025, 1, 1)
last_date = date(2028, 12, 31)

while current_date <= last_date:
    calendar_rows.append(
        (
            current_date,
            current_date.day,
            current_date.weekday() < 5
        )
    )
    current_date += timedelta(days=1)


schedule_rows = []
schedule_info = {}
base_datetime = datetime(2026, 10, 16)

for i in range(100):
    flight_number = f"HW{1001 + i}"
    route_index = i % 10
    day_offset = i // 10

    scheduled_departure = base_datetime + timedelta(
        days=day_offset,
        hours=6,
        minutes=route_index * 100
    )

    scheduled_arrival = scheduled_departure + timedelta(hours=1)

    airline_code = airline_codes[i % len(airline_codes)]
    aircraft_type_code = aircraft_codes[i % len(aircraft_codes)]
    origin_airport_code = airport_codes[route_index]
    destination_airport_code = airport_codes[route_index + 1]

    schedule_rows.append(
        (
            flight_number,
            airline_code,
            aircraft_type_code,
            origin_airport_code,
            destination_airport_code,
            scheduled_departure,
            scheduled_arrival
        )
    )

    schedule_info[flight_number] = {
        "aircraft_type_code": aircraft_type_code,
        "origin_airport_code": origin_airport_code,
        "destination_airport_code": destination_airport_code,
        "scheduled_departure": scheduled_departure,
        "scheduled_arrival": scheduled_arrival
    }


leg_rows = []
selected_schedule_indexes = list(range(100))

for _ in range(50):
    selected_schedule_indexes.append(random.randrange(100))

for schedule_index in selected_schedule_indexes:
    flight = schedule_rows[schedule_index]
    flight_number = flight[0]
    info = schedule_info[flight_number]

    scheduled_departure = info["scheduled_departure"]
    scheduled_arrival = info["scheduled_arrival"]

    if random.random() < 0.20:
        actual_departure = None
    else:
        actual_departure = scheduled_departure + timedelta(
            minutes=random.randint(-15, 45)
        )

    if random.random() < 0.20:
        actual_arrival = None
    else:
        actual_arrival = scheduled_arrival + timedelta(
            minutes=random.randint(-15, 60)
        )

    if (
        actual_departure is not None
        and actual_arrival is not None
        and actual_arrival <= actual_departure
    ):
        actual_arrival = actual_departure + timedelta(minutes=30)

    leg_rows.append(
        (
            flight_number,
            info["origin_airport_code"],
            info["destination_airport_code"],
            actual_departure,
            actual_arrival
        )
    )


reservation_rows = []
reservation_start = datetime(2026, 6, 1)
reservation_end = datetime(2026, 10, 15, 23, 59, 59)

for i in range(1, 151):
    passenger_id = ((i - 1) % 100) + 1

    if random.random() < 0.40:
        agent_id = None
    else:
        agent_id = random.randint(1, 60)

    reservation_rows.append(
        (
            passenger_id,
            agent_id,
            random.choice(reservation_status_codes),
            random.choice(ticket_type_codes),
            random.choice(travel_class_codes),
            random_datetime(reservation_start, reservation_end),
            random.randint(1, 6)
        )
    )


payment_rows = []
payment_start = datetime(2026, 6, 1)
payment_end = datetime(2026, 10, 25, 23, 59, 59)

for i in range(100):
    amount = Decimal(random.randint(2500, 250000)) / Decimal("100")

    payment_rows.append(
        (
            random.choice(payment_status_codes),
            random_datetime(payment_start, payment_end),
            amount
        )
    )


flight_cost_rows = []

cost_periods = [
    (date(2025, 1, 1), date(2025, 12, 31)),
    (date(2026, 1, 1), date(2027, 12, 31))
]

for flight in schedule_rows:
    flight_number = flight[0]
    aircraft_type_code = flight[2]

    for valid_from_date, valid_to_date in cost_periods:
        cost_amount = (
            Decimal(random.randint(10000, 500000)) / Decimal("100")
        )

        flight_cost_rows.append(
            (
                flight_number,
                aircraft_type_code,
                valid_from_date,
                valid_to_date,
                cost_amount
            )
        )


reservation_payment_rows = create_unique_pairs(
    220,
    [
        (1, 1),
        (1, 2),
        (1, 3),
        (2, 1),
        (3, 1)
    ],
    150,
    100
)


reservation_leg_rows = create_unique_pairs(
    280,
    [
        (1, 1),
        (1, 2),
        (1, 3),
        (2, 1),
        (3, 1)
    ],
    150,
    150
)


table_names = [
    "airline",
    "aircraft_type",
    "reservation_status",
    "payment_status",
    "ticket_type",
    "travel_class",
    "booking_agent",
    "passenger",
    "airport",
    "calendar_date",
    "flight_schedule",
    "flight_leg",
    "reservation",
    "payment",
    "flight_cost",
    "reservation_payment",
    "reservation_leg"
]


delete_order = [
    "reservation_leg",
    "reservation_payment",
    "flight_cost",
    "payment",
    "reservation",
    "flight_leg",
    "flight_schedule",
    "calendar_date",
    "airport",
    "passenger",
    "booking_agent",
    "travel_class",
    "ticket_type",
    "reservation_status",
    "payment_status",
    "aircraft_type",
    "airline"
]


def main():
    print("HarborWing Air synthetic data generator")
    print("This process clears existing records before generating new data.")
    confirmation = input("Type YES to continue: ").strip()

    if confirmation != "YES":
        print("Cancelled. No data was changed.")
        return

    connection = None
    cursor = None

    try:
        connection = mysql.connector.connect(
            host=os.getenv("DB_HOST", "127.0.0.1"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "root"),
            password=os.getenv("DB_PASSWORD", ""),
            database=os.getenv("DB_NAME", "harborwing_air")
        )

        cursor = connection.cursor()

        for table in delete_order:
            cursor.execute(f"DELETE FROM {table}")

        for table in [
            "booking_agent",
            "passenger",
            "flight_leg",
            "reservation",
            "payment"
        ]:
            cursor.execute(f"ALTER TABLE {table} AUTO_INCREMENT = 1")

        connection.commit()

        insert_rows(
            cursor,
            "INSERT INTO airline "
            "(airline_code, airline_name, other_details) "
            "VALUES (%s, %s, %s)",
            airline_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO aircraft_type "
            "(aircraft_type_code, aircraft_type_name, other_details) "
            "VALUES (%s, %s, %s)",
            aircraft_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO reservation_status "
            "(reservation_status_code, status_name, other_details) "
            "VALUES (%s, %s, %s)",
            reservation_status_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO payment_status "
            "(payment_status_code, status_name, other_details) "
            "VALUES (%s, %s, %s)",
            payment_status_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO ticket_type "
            "(ticket_type_code, ticket_type_name, other_details) "
            "VALUES (%s, %s, %s)",
            ticket_type_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO travel_class "
            "(travel_class_code, travel_class_name, other_details) "
            "VALUES (%s, %s, %s)",
            travel_class_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO booking_agent "
            "(agent_name, phone, email, other_details) "
            "VALUES (%s, %s, %s, %s)",
            agent_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO passenger "
            "(first_name, second_name, last_name, phone, email, "
            "address_line1, address_line2, city, "
            "state_province_county, country, other_details) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            passenger_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO airport "
            "(airport_code, airport_name, location, other_details) "
            "VALUES (%s, %s, %s, %s)",
            airport_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO calendar_date "
            "(calendar_date, day_of_month, is_business_day) "
            "VALUES (%s, %s, %s)",
            calendar_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO flight_schedule "
            "(flight_number, airline_code, aircraft_type_code, "
            "origin_airport_code, destination_airport_code, "
            "scheduled_departure, scheduled_arrival) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            schedule_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO flight_leg "
            "(flight_number, origin_airport_code, "
            "destination_airport_code, actual_departure, actual_arrival) "
            "VALUES (%s, %s, %s, %s, %s)",
            leg_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO reservation "
            "(passenger_id, agent_id, reservation_status_code, "
            "ticket_type_code, travel_class_code, created_at, party_size) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            reservation_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO payment "
            "(payment_status_code, payment_date, amount) "
            "VALUES (%s, %s, %s)",
            payment_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO flight_cost "
            "(flight_number, aircraft_type_code, valid_from_date, "
            "valid_to_date, cost_amount) "
            "VALUES (%s, %s, %s, %s, %s)",
            flight_cost_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO reservation_payment "
            "(reservation_id, payment_id) "
            "VALUES (%s, %s)",
            reservation_payment_rows
        )

        insert_rows(
            cursor,
            "INSERT INTO reservation_leg "
            "(reservation_id, leg_id) "
            "VALUES (%s, %s)",
            reservation_leg_rows
        )

        connection.commit()

        print()
        print("Data inserted successfully.")
        print("Row counts:")

        for table in table_names:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"{table}: {count} rows")

        print()
        print("All tables have at least 50 rows.")
        print("Seed used:", SEED)

    except mysql.connector.Error as error:
        if connection is not None and connection.is_connected():
            connection.rollback()

        print("MySQL error:", error)
        sys.exit(1)

    except Exception as error:
        if connection is not None and connection.is_connected():
            connection.rollback()

        print("Error:", error)
        sys.exit(1)

    finally:
        if cursor is not None:
            cursor.close()

        if connection is not None and connection.is_connected():
            connection.close()


if __name__ == "__main__":
    main()
