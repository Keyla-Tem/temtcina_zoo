-- Лаба 3. Логика в базе
-- Сценарий для показа: представления, функции, триггеры.
-- Запуск: dbcheck run demo/lab3.sql --sql, или в psql: \i /demo/lab3.sql

-- 1. Карточки всех животных: вид, питание, вольер
-- expect: rows 19
SELECT * FROM v_animal_card ORDER BY enclosure, animal;

-- 2. Заполненность вольеров: сколько животных, сколько мест свободно
-- expect: rows 10
SELECT * FROM v_enclosure_occupancy ORDER BY id;

-- 3. Сколько свободных мест в вольере рысей (вместимость 3, живёт 1)
-- expect: value 2
SELECT free_places(9);

-- 4. Бизнес-операция: смотритель 1 кормит Амурчика (животное 1)
-- expect: rows 1
SELECT feed_animal(1, 1, 'Говядина', 6.50);

-- 5. Результат в таблице: у Амурчика теперь 82 записи о кормлении (было 81)
-- expect: value 82
SELECT count(*) FROM feedings WHERE animal_id = 1;

-- 6. Смотритель 10 не закреплён за вольером тигров: ошибка функции
-- expect: error raise
-- expect: error "не закреплён"
SELECT feed_animal(1, 10, 'Говядина', 5.00);

-- 7. Тигра селят в вольер оленей: ошибка триггера
-- expect: error raise
-- expect: error "нельзя поселить"
INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
VALUES ('Шерхан', 1, 5, '2024-01-01', 90.00);

-- 8. Оленя переселяют в вольер леопардов: ошибка триггера
-- expect: error raise
-- expect: error "нельзя поселить"
UPDATE animals SET enclosure_id = 2 WHERE id = 9;

-- 9. Оленя переселяют в вольер к другим травоядным: правило не нарушено
-- expect: value 6
UPDATE animals SET enclosure_id = 6 WHERE id = 9;
SELECT enclosure_id FROM animals WHERE id = 9;

-- 10. Служебный триггер, до изменения: запись Амурчика менялась раньше этой транзакции
-- expect: true
SELECT updated_at < now() FROM animals WHERE id = 1;

-- 11. Служебный триггер, после изменения веса: updated_at обновился
-- expect: true
UPDATE animals SET weight_kg = weight_kg + 1 WHERE id = 1;
SELECT updated_at = now() FROM animals WHERE id = 1;