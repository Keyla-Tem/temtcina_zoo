-- Лаба 2. Запросы к своим данным
-- Запуск: dbcheck run demo/lab2.sql --sql, или в psql: \i /demo/lab2.sql

-- 1. Как называется вид каждого животного и чем он питается?
-- expect: rows 19
SELECT a.name AS animal, s.name AS species, s.diet
FROM animals a
JOIN species s ON s.id = a.species_id
ORDER BY s.name, a.name;

-- 2. В каких вольерах живут хищники?
-- expect: rows 5
SELECT a.name AS animal, s.name AS species, e.name AS enclosure
FROM animals a
JOIN species s    ON s.id = a.species_id
JOIN enclosures e ON e.id = a.enclosure_id
WHERE s.diet = 'predator'
ORDER BY e.name, a.name;

-- 3. Кто, кого и чем кормил 14 октября 2026 года?
-- expect: rows 19
SELECT f.fed_at AT TIME ZONE 'Asia/Vladivostok' AS fed_at_vladivostok, a.name AS animal, k.last_name || ' ' || k.first_name AS keeper, f.food, f.amount_kg
FROM feedings f
JOIN animals a ON a.id = f.animal_id
JOIN keepers k ON k.id = f.keeper_id
WHERE f.fed_at >= '2026-10-14 00:00:00+10' AND f.fed_at < '2026-10-15 00:00:00+10'
ORDER BY f.fed_at;

-- 4. Сколько животных каждого вида живёт в зоопарке?
-- expect: rows 11
SELECT s.name AS species, count(a.id) AS animal_count
FROM species s
JOIN animals a ON a.species_id = s.id
GROUP BY s.id, s.name
ORDER BY animal_count DESC, s.name;

-- 5. В каких вольерах живут минимум два животных и сколько именно?
-- expect: rows 6
SELECT e.name AS enclosure, e.capacity, count(a.id) AS animal_count
FROM enclosures e
JOIN animals a ON a.enclosure_id = e.id
GROUP BY e.id, e.name, e.capacity
HAVING count(a.id) >= 2
ORDER BY animal_count DESC, e.name;

-- 6. Какие виды есть в справочнике, но в зоопарке не представлены ни одним животным?
-- expect: rows 1
SELECT s.name, s.diet
FROM species s
LEFT JOIN animals a ON a.species_id = s.id
WHERE a.id IS NULL;

-- 7. Какие смотрители не закреплены ни за одним вольером?
-- expect: rows 1
SELECT k.last_name, k.first_name
FROM keepers k
LEFT JOIN keeper_enclosures ke ON ke.keeper_id = k.id
WHERE ke.keeper_id IS NULL;

-- 8. Какие животные тяжелее среднего веса по всему зоопарку?
-- expect: rows 9
SELECT name, weight_kg
FROM animals
WHERE weight_kg > (SELECT avg(weight_kg) FROM animals)
ORDER BY weight_kg DESC;

-- 9. Какие смотрители ухаживают за вольерами, где живут хищники?
-- expect: rows 5
SELECT k.last_name, k.first_name
FROM keepers k
WHERE k.id IN (
    SELECT ke.keeper_id
    FROM keeper_enclosures ke
    JOIN animals a ON a.enclosure_id = ke.enclosure_id
    JOIN species s ON s.id = a.species_id
    WHERE s.diet = 'predator'
)
ORDER BY k.last_name;

-- 10. В вольер рысей поступил новый рысёнок
BEGIN;

SELECT count(*) AS before FROM animals;

INSERT INTO animals
    (name, species_id, enclosure_id, birth_date, weight_kg)
VALUES
    ('Рысик', 10, 9, '2026-05-20', 3.20);

-- expect: value 20
SELECT count(*) AS after FROM animals;
ROLLBACK;


-- 11. Пятнистые олени набрали 5% веса
BEGIN;

SELECT round(avg(weight_kg), 2) AS before
FROM animals
WHERE species_id = 5;

UPDATE animals
SET weight_kg = round(weight_kg * 1.05, 2)
WHERE species_id = 5;

-- expect: value 117.25
SELECT round(avg(weight_kg), 2) AS after
FROM animals
WHERE species_id = 5;

ROLLBACK;
-- 12. Удаляем старые записи о кормлениях
BEGIN;

SELECT count(*) AS before FROM feedings;

DELETE FROM feedings
WHERE fed_at < TIMESTAMPTZ '2026-01-10 00:00:00+10';

-- expect: value 1235
SELECT count(*) AS after FROM feedings;

ROLLBACK;

-- 13. Какие три самых тяжёлых животных
-- есть внутри каждого вида?
WITH ranked_animals AS (
    SELECT
        s.name AS species,
        a.name AS animal,
        a.weight_kg,
        ROW_NUMBER() OVER (
            PARTITION BY s.id
            ORDER BY a.weight_kg DESC, a.id
        ) AS position
    FROM animals a
    JOIN species s ON s.id = a.species_id
)
SELECT species, animal, weight_kg, position
FROM ranked_animals
WHERE position <= 3
ORDER BY species, position;

-- 14. Как накапливалось общее количество
-- кормлений зоопарка по дням?
WITH daily_feedings AS (
    SELECT
        (fed_at AT TIME ZONE
            'Asia/Vladivostok')::date AS day,
        count(*) AS feeding_count
    FROM feedings
    GROUP BY 1
)
SELECT
    day,
    feeding_count,
    sum(feeding_count) OVER (
        ORDER BY day
        ROWS BETWEEN UNBOUNDED PRECEDING
                 AND CURRENT ROW
    ) AS total_feedings
FROM daily_feedings
ORDER BY day;

-- 15. Как менялось число кормлений
-- по месяцам и на сколько процентов?
WITH monthly AS (
    SELECT
        date_trunc(
            'month',
            fed_at AT TIME ZONE
                'Asia/Vladivostok'
        )::date AS month,
        count(*) AS feeding_count
    FROM feedings
    GROUP BY 1
),
comparison AS (
    SELECT
        month,
        feeding_count,
        LAG(feeding_count) OVER (
            ORDER BY month
        ) AS previous_count
    FROM monthly
)
SELECT
    month,
    feeding_count,
    previous_count,
    round(
        100.0 * (feeding_count - previous_count)
        / NULLIF(previous_count, 0),
        2
    ) AS change_percent
FROM comparison
ORDER BY month;

-- 16. Сколько кормлений было каждый день
-- октября 2026, включая дни без кормлений?
WITH RECURSIVE calendar(day) AS (
    SELECT DATE '2026-10-01'

    UNION ALL

    SELECT day + 1
    FROM calendar
    WHERE day < DATE '2026-10-31'
),
daily_feedings AS (
    SELECT
        (fed_at AT TIME ZONE
            'Asia/Vladivostok')::date AS day,
        count(*) AS feeding_count
    FROM feedings
    WHERE fed_at >= TIMESTAMPTZ
        '2026-10-01 00:00:00+10'
      AND fed_at < TIMESTAMPTZ
        '2026-11-01 00:00:00+10'
    GROUP BY 1
)
SELECT
    c.day,
    COALESCE(d.feeding_count, 0) AS feeding_count
FROM calendar c
LEFT JOIN daily_feedings d ON d.day = c.day
ORDER BY c.day;


-- 17. Сколько кормлений было по каждому виду животных,
-- сколько утром и вечером и какой процент пришёлся на утро?
SELECT
    s.name AS species,
    count(*) AS total_feedings,

    count(*) FILTER (
        WHERE (f.fed_at AT TIME ZONE 'Asia/Vladivostok')::time
              >= TIME '06:00'
          AND (f.fed_at AT TIME ZONE 'Asia/Vladivostok')::time
              < TIME '12:00'
    ) AS morning_feedings,

    count(*) FILTER (
        WHERE (f.fed_at AT TIME ZONE 'Asia/Vladivostok')::time
              >= TIME '18:00'
    ) AS evening_feedings,

    round(
        100.0 * count(*) FILTER (
            WHERE (f.fed_at AT TIME ZONE 'Asia/Vladivostok')::time
                  >= TIME '06:00'
              AND (f.fed_at AT TIME ZONE 'Asia/Vladivostok')::time
                  < TIME '12:00'
        ) / count(*),
        2
    ) AS morning_percent

FROM feedings f
JOIN animals a ON a.id = f.animal_id
JOIN species s ON s.id = a.species_id
GROUP BY s.id, s.name
ORDER BY s.name;
  