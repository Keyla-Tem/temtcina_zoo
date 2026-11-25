-- Изоляция READ COMMITTED: второе чтение внутри транзакции видит чужое зафиксированное изменение.

-- [setup]
DELETE FROM enclosures WHERE name = 'iso-test';
INSERT INTO enclosures (name, capacity) VALUES ('iso-test', 10);

-- [A] Окно A: первое чтение вместимости
-- expect: value 10
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT capacity FROM enclosures WHERE name = 'iso-test';

-- [B] Окно B меняет вместимость и фиксирует (без BEGIN изменение фиксируется сразу)
UPDATE enclosures SET capacity = 20 WHERE name = 'iso-test';

-- [A] Окно A: второе чтение в той же транзакции видит новое значение
-- expect: value 20
SELECT capacity FROM enclosures WHERE name = 'iso-test';
COMMIT;

-- [cleanup]
DELETE FROM enclosures WHERE name = 'iso-test';