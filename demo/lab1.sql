-- Лаба 1. Сценарий для показа. Формат описан в docs/scenarios.md.
-- Запуск: dbcheck run demo/lab1.sql, или в psql: \i /demo/lab1.sql

-- 1. Таблицы на месте: 6 таблиц
-- expect: rows 6
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY 1;

-- 2. Отрицательное количество корма: ошибка CHECK
-- expect: error check
INSERT INTO feedings (animal_id, keeper_id, fed_at, food, amount_kg)
VALUES (1, 1, '2026-10-15 09:00:00+10', 'Говядина', -2.00);

-- 3. Несуществующий вольер (вольера № 999 нет): ошибка внешнего ключа
-- expect: error fk
INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
VALUES ('Призрак', 1, 999, '2020-01-01', 50.00);

-- 4. Вид с названием, которое уже есть: ошибка UNIQUE
-- expect: error unique
INSERT INTO species (name, diet) VALUES ('Амурский тигр', 'predator');