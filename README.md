# HarborWing Air Database

## Project Description

HarborWing Air is a fictional regional airline. This project uses a MySQL relational database to organize passenger details, reservations, payments, airports, flights, and flight costs.

The database replaces spreadsheets and helps reduce repeated information and inconsistent records.

## Software Requirements

- MySQL Server
- MySQL Workbench
- Python
- Visual Studio Code
- Python Faker
- MySQL Connector for Python

## Project Files

- `schema.sql` - Creates the database tables, keys, constraints, and indexes.
- `seed.py` - Generates fictional data and inserts it into the database.
- `requirements.txt` - Lists the Python packages.
- `queries.sql` - Contains the four required example queries.
- `row_counts.sql` - Counts the records in all 17 tables.
- `harborwing_air.mwb` - MySQL Workbench model file.
- `diagram/harborwing_air.png` - Exported EER diagram.
- `screenshots/` - Contains screenshots of query results and verification.

## Database Tables

The database contains 17 tables.

The 11 core tables are `booking_agent`, `passenger`, `reservation`, `payment`, `airport`, `flight_schedule`, `flight_leg`, `calendar_date`, `flight_cost`, `reservation_payment`, and `reservation_leg`.

The six supporting tables are `airline`, `aircraft_type`, `reservation_status`, `payment_status`, `ticket_type`, and `travel_class`.

The supporting tables store codes and descriptions used by the main tables. Demonstration codes are included to satisfy the requirement of at least 50 rows in every table.

## Relationships

A passenger can have many reservations. Each reservation has exactly one main passenger and may have a booking agent.

A reservation can be linked to many payments, and a payment can be linked to many reservations. The `reservation_payment` table handles this many-to-many relationship.

A reservation can also include multiple flight legs, and a flight leg can be linked to multiple reservations. The `reservation_leg` table handles this relationship.

Each flight leg belongs to one scheduled flight. Flights and legs reference origin and destination airports.

Flight costs reference a scheduled flight, an aircraft type, and two dates from the calendar table.

## Important Design Choices

### Scheduled and Actual Times

Scheduled departure and arrival times are stored in `flight_schedule`. Actual departure and arrival times are stored separately in `flight_leg`.

Actual times can be NULL when they are not yet known. This prevents actual flight information from overwriting the schedule.

### Composite Keys

The `flight_cost` table uses a composite primary key consisting of `flight_number`, `aircraft_type_code`, and `valid_from_date`.

This allows a flight and aircraft type to have different cost records for different validity periods.

The `reservation_payment` and `reservation_leg` tables also use composite primary keys to prevent duplicate pairs.

### Deletion Rules

Foreign keys help protect records that are referenced by other tables. Most referenced records cannot be deleted while they are in use.

Deleting a booking agent sets the optional agent reference in a reservation to NULL. Deleting a reservation, payment, or flight leg cascades to its associated linking-table records.

The schema can be recreated for testing, but historical airline records should normally be retained in a production system.

## Design Limitations

1. Shared payment links do not show the exact amount allocated to each reservation.
2. Party size records the number of people but does not identify every traveler.
3. Separating information reduces duplication but requires joins to retrieve related details.
4. Flight-cost validity periods must not overlap for the same flight and aircraft type. The generator creates non-overlapping periods, but future database operations must also check this rule.

## Simplifying Assumption

This project treats flight number as a unique schedule identifier.

A production airline system would usually use a flight-instance identifier or include the scheduled departure date or time in the key because the same flight number may operate on different days.

## Setup Instructions

### 1. Create the Database

Start MySQL Server.

Open `schema.sql` in MySQL Workbench and execute the complete file. It creates the `harborwing_air` database and its 17 tables.

Warning: The script drops and recreates the database. Running it again deletes the existing database records.

### 2. Install Python Packages

Open the project folder in the VS Code terminal.

Create and activate a virtual environment if one does not already exist:

```powershell
py -m venv .venv
.venv\Scripts\activate
```

Install the required packages:

```powershell
python -m pip install -r requirements.txt
```

### 3. Configure the Database Connection

The generator uses these default settings:

- Host: `127.0.0.1`
- Port: `3306`
- Username: `root`
- Database: `harborwing_air`

If your MySQL username or password is different, set the appropriate environment variables in the terminal before running the script.

For example, set your password using `DB_PASSWORD`. Do not save real passwords in this README or upload them to GitHub.

### 4. Generate the Data

Run:

```powershell
python seed.py
```

Type `YES` when prompted to confirm that existing test records will be cleared and regenerated.

The generator uses seed `20261016` for repeatable synthetic data. Using the same code, seed, and Faker version helps reproduce the dataset.

### 5. Verify the Records

Open `row_counts.sql` in MySQL Workbench and execute it.

Check that every table contains at least 50 rows.

### 6. Run the Example Queries

Open `queries.sql` in MySQL Workbench and execute the queries to view reservations, find reservations using a flight leg, find linked payments, and retrieve a flight cost for a specific date.

Use values that exist in the generated data when testing individual queries.

## Synthetic Data

All passenger records, contact details, booking agents, airports, and demonstration codes are fictional data generated for coursework. No real passenger records are intended to be used.

## Reset Instructions

For a complete reset, execute `schema.sql` to recreate the database and then run `seed.py` to generate the records again.

Running `seed.py` alone clears and replaces the existing test records. Do not run either reset process against a database containing information you need to keep.

## Completion

The project is ready for review when another developer can create the database, generate the data, verify the row counts, and execute the example queries using the submitted files.