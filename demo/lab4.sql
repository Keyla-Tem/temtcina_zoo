-- Лаба 4. Откат транзакции и права ролей.
-- Запуск: dbcheck run demo/lab4.sql --sql

-- 1. Сколько кормлений в базе сейчас
SELECT count(*) AS feedings_total FROM feedings;

-- 2. Транзакция падает на середине: первое кормление нормальное, второе с отрицательным количеством
-- expect: error check
BEGIN;
INSERT INTO feedings (animal_id, keeper_id, fed_at, food, amount_kg) VALUES (1, 1, now(), 'Говядина', 5.00);
INSERT INTO feedings (animal_id, keeper_id, fed_at, food, amount_kg) VALUES (1, 1, now(), 'Говядина', -1.00);
COMMIT;

-- 3. Данные не изменились: первое кормление тоже отменено
-- expect: same 1
SELECT count(*) AS feedings_total FROM feedings;

-- 4. app_reader читает представление: 19 животных
-- expect: value 19
SET ROLE app_reader;
SELECT count(*) FROM v_animal_card;
RESET ROLE;

-- 5. app_reader пытается прочитать таблицу напрямую: нет прав
-- expect: error permission
SET ROLE app_reader;
SELECT * FROM animals;

-- 6. Возвращаемся к своей роли
RESET ROLE;

-- 7. app_reader пытается удалить кормление: нет прав
-- expect: error permission
SET ROLE app_reader;
DELETE FROM feedings WHERE id = 1;

-- 8. Возвращаемся к своей роли
RESET ROLE;

-- 9. app_writer пытается добавить животное напрямую в таблицу: нет прав
-- expect: error permission
SET ROLE app_writer;
INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
VALUES ('Прямая вставка', 10, 9, '2026-01-01', 10.00);

-- 10. Возвращаемся к своей роли
RESET ROLE;

-- 11. app_writer вызывает бизнес-операцию «покормить» (изменение откатывается)
-- expect: rows 1
BEGIN;
SET LOCAL ROLE app_writer;
SELECT feed_animal(1, 1, 'Говядина', 1.00);
ROLLBACK;

-- 12. app_writer вызывает безопасное заселение (изменение откатывается)
-- expect: rows 1
BEGIN;
SET LOCAL ROLE app_writer;
SELECT settle_animal('Тестовая рысь', 10, 9, DATE '2026-01-01', 20.00);
ROLLBACK;