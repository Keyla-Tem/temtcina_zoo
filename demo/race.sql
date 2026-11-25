-- Гонка: в пустой вольер одновременно селят хищника и травоядное.
-- Триггер правила не видит незафиксированную вставку другого окна, поэтому пропускает обоих.

-- [setup] Пустой вольер для теста, остатки прошлого запуска удаляются
DELETE FROM animals WHERE enclosure_id IN (SELECT id FROM enclosures WHERE name = 'race-test');
DELETE FROM enclosures WHERE name = 'race-test';
INSERT INTO enclosures (name, capacity) VALUES ('race-test', 5);

-- [A] Окно A: селим тигра, травоядных в вольере нет, триггер пропускает
BEGIN;
INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
SELECT 'race-tiger', 1, id, DATE '2024-01-01', 150 FROM enclosures WHERE name = 'race-test';

-- [B] Окно B в тот же момент: хищника ещё не видно (окно A не зафиксировало), селим оленя, триггер пропускает
BEGIN;
INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
SELECT 'race-deer', 5, id, DATE '2024-01-01', 90 FROM enclosures WHERE name = 'race-test';

-- [A]
COMMIT;

-- [B]
COMMIT;

-- [check] Правило соблюдено: в вольере нет хищника вместе с травоядным?
-- expect: false
SELECT NOT (count(*) FILTER (WHERE s.diet = 'predator') > 0
        AND count(*) FILTER (WHERE s.diet = 'herbivore') > 0)
FROM animals a
JOIN species s    ON s.id = a.species_id
JOIN enclosures e ON e.id = a.enclosure_id
WHERE e.name = 'race-test';

-- [cleanup]
DELETE FROM animals WHERE enclosure_id IN (SELECT id FROM enclosures WHERE name = 'race-test');
DELETE FROM enclosures WHERE name = 'race-test';