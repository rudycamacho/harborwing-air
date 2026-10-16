USE harborwing_air;

SELECT
    r.reservation_id,
    CONCAT_WS(
        ' ',
        p.first_name,
        p.second_name,
        p.last_name
    ) AS main_passenger,
    COALESCE(ba.agent_name, 'Direct booking') AS booking_method,
    rs.status_name AS reservation_status,
    r.created_at,
    r.party_size,
    COALESCE(pay_summary.payment_details, 'No payments')
        AS payment_details,
    COALESCE(leg_summary.leg_details, 'No legs')
        AS leg_details
FROM reservation r
JOIN passenger p
    ON r.passenger_id = p.passenger_id
LEFT JOIN booking_agent ba
    ON r.agent_id = ba.agent_id
JOIN reservation_status rs
    ON r.reservation_status_code = rs.reservation_status_code
LEFT JOIN (
    SELECT
        rp.reservation_id,
        GROUP_CONCAT(
            CONCAT(
                'Payment ',
                pm.payment_id,
                ': ',
                ps.status_name,
                ', amount ',
                pm.amount
            )
            ORDER BY pm.payment_id
            SEPARATOR '; '
        ) AS payment_details
    FROM reservation_payment rp
    JOIN payment pm
        ON rp.payment_id = pm.payment_id
    JOIN payment_status ps
        ON pm.payment_status_code = ps.payment_status_code
    GROUP BY rp.reservation_id
) pay_summary
    ON r.reservation_id = pay_summary.reservation_id
LEFT JOIN (
    SELECT
        rl.reservation_id,
        GROUP_CONCAT(
            CONCAT(
                'Leg ',
                fl.leg_id,
                ': flight ',
                fs.flight_number,
                ', ',
                ao.airport_code,
                ' to ',
                ad.airport_code
            )
            ORDER BY fl.leg_id
            SEPARATOR '; '
        ) AS leg_details
    FROM reservation_leg rl
    JOIN flight_leg fl
        ON rl.leg_id = fl.leg_id
    JOIN flight_schedule fs
        ON fl.flight_number = fs.flight_number
    JOIN airport ao
        ON fl.origin_airport_code = ao.airport_code
    JOIN airport ad
        ON fl.destination_airport_code = ad.airport_code
    GROUP BY rl.reservation_id
) leg_summary
    ON r.reservation_id = leg_summary.reservation_id
WHERE r.reservation_id = 1;

SELECT
    r.reservation_id,
    CONCAT_WS(
        ' ',
        p.first_name,
        p.second_name,
        p.last_name
    ) AS main_passenger,
    fl.leg_id,
    fs.flight_number,
    ao.airport_name AS origin_airport,
    ad.airport_name AS destination_airport
FROM reservation_leg rl
JOIN reservation r
    ON rl.reservation_id = r.reservation_id
JOIN passenger p
    ON r.passenger_id = p.passenger_id
JOIN flight_leg fl
    ON rl.leg_id = fl.leg_id
JOIN flight_schedule fs
    ON fl.flight_number = fs.flight_number
JOIN airport ao
    ON fl.origin_airport_code = ao.airport_code
JOIN airport ad
    ON fl.destination_airport_code = ad.airport_code
WHERE rl.leg_id = 1
ORDER BY r.reservation_id;

SELECT
    pm.payment_id,
    ps.status_name AS payment_status,
    pm.payment_date,
    pm.amount
FROM reservation_payment rp
JOIN payment pm
    ON rp.payment_id = pm.payment_id
JOIN payment_status ps
    ON pm.payment_status_code = ps.payment_status_code
WHERE rp.reservation_id = 1
ORDER BY pm.payment_date, pm.payment_id;

SET @flight_number = 'HW1001';
SET @aircraft_type_code = 'AC001';
SET @travel_date = '2026-10-16';

SELECT
    flight_number,
    aircraft_type_code,
    valid_from_date,
    valid_to_date,
    cost_amount
FROM flight_cost
WHERE flight_number = @flight_number
  AND aircraft_type_code = @aircraft_type_code
  AND @travel_date BETWEEN valid_from_date AND valid_to_date
ORDER BY valid_from_date DESC
LIMIT 1;
