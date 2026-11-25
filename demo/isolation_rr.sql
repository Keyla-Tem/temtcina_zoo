-- Изоляция REPEATABLE READ: вся транзакция видит данные на момент первого запроса.

-- [setup]
DELETE FROM enclosures WHERE name = 'iso-test';
INSERT INTO enclosures (name, capacity) VALUES ('iso-test', 10);

-- [A] Окно A: первое чтение вместимости
-- expect: value 10
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT capacity FROM enclosures WHERE name = 'iso-test';

-- [B] Окно B меняет вместимость и фиксирует
UPDATE enclosures SET capacity = 20 WHERE name = 'iso-test';

-- [A] Окно A: второе чтение всё ещё видит прежнее значение
-- expect: value 10
SELECT capacity FROM enclosures WHERE name = 'iso-test';
COMMIT;

-- [cleanup]
DELETE FROM enclosures WHERE name = 'iso-test';