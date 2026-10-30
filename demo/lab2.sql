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

-- 3. Кто, кого и чем кормил 14 октября 2026 года (по времени Владивостока)?
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

-- 10. В вольер рысей поступил новый рысёнок: сколько животных было и стало?
-- expect: value 20
BEGIN;
SELECT count(*) AS before FROM animals;
INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
VALUES ('Рысик', 10, 9, '2026-05-20', 3.20);
SELECT count(*) AS after FROM animals;
ROLLBACK;

-- 11. Пятнистые олени набрали 5% веса: каким стал их средний вес?
-- expect: value 117.25
BEGIN;
SELECT round(avg(weight_kg), 2) AS before FROM animals WHERE species_id = 5;
UPDATE animals SET weight_kg = round(weight_kg * 1.05, 2) WHERE species_id = 5;
SELECT round(avg(weight_kg), 2) AS after FROM animals WHERE species_id = 5;
ROLLBACK;

-- 12. Удаляем записи о кормлениях до 10 января 2026: сколько записей осталось?
-- expect: value 1235
BEGIN;
SELECT count(*) AS before FROM feedings;
DELETE FROM feedings WHERE fed_at < '2026-01-10 00:00:00+10';
SELECT count(*) AS after FROM feedings;
ROLLBACK;