-- Та же гонка, но заселение идёт через settle_animal: она блокирует строку вольера.

-- [setup] Пустой вольер для теста
DELETE FROM animals WHERE enclosure_id IN (SELECT id FROM enclosures WHERE name = 'race-test');
DELETE FROM enclosures WHERE name = 'race-test';
INSERT INTO enclosures (name, capacity) VALUES ('race-test', 5);

-- [A] Окно A: селим тигра, вольер блокируется до конца транзакции
BEGIN;
SELECT settle_animal('race-tiger', 1, (SELECT id FROM enclosures WHERE name = 'race-test'), DATE '2024-01-01', 150);
-- [B] Окно B: селим оленя, но вольер заблокирован окном A, поэтому окно B ждёт.
-- Когда A зафиксирует, триггер увидит тигра и откажет в заселении оленя.
-- expect: blocked
-- expect: error raise
BEGIN;
SELECT settle_animal('race-deer', 5, (SELECT id FROM enclosures WHERE name = 'race-test'), DATE '2024-01-01', 90);

-- [A] Окно A фиксирует: блокировка снята, окно B продолжает, видит тигра и получает ошибку триггера
COMMIT;

-- [B]
COMMIT;

-- [check] Правило соблюдено: в вольере нет хищника вместе с травоядным?
-- expect: true
SELECT NOT (count(*) FILTER (WHERE s.diet = 'predator') > 0
        AND count(*) FILTER (WHERE s.diet = 'herbivore') > 0)
FROM animals a
JOIN species s    ON s.id = a.species_id
JOIN enclosures e ON e.id = a.enclosure_id
WHERE e.name = 'race-test';

-- [cleanup]
DELETE FROM animals WHERE enclosure_id IN (SELECT id FROM enclosures WHERE name = 'race-test');
DELETE FROM enclosures WHERE name = 'race-test';