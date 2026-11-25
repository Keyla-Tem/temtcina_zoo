-- Row Level Security: смотритель видит только свои кормления.

-- 1. Смотритель 1 видит только свои кормления (162)
-- expect: value 162
SET ROLE app_keeper;
SET app.keeper_id = '1';
SELECT count(*) FROM feedings;

-- 2. Чужих кормлений он не видит
-- expect: value 0
SELECT count(*) FROM feedings WHERE keeper_id <> 1;

-- 3. Смотритель 10 видит свои 81 кормление
-- expect: value 81
SET app.keeper_id = '10';
SELECT count(*) FROM feedings;

-- 4. Смотритель 11 ничего не кормил: 0
-- expect: value 0
SET app.keeper_id = '11';
SELECT count(*) FROM feedings;

-- 5. Если смотритель не указан, не видно ничего
-- expect: value 0
RESET app.keeper_id;
SELECT count(*) FROM feedings;

-- 6. Владелец базы политику не замечает: видит все 1539 кормлений
-- expect: value 1539
RESET ROLE;
SELECT count(*) FROM feedings;