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

-- *

-- 12. Отчёт по видам до обновления: у тигров 162 кормления (снимок на момент создания базы)
-- expect: value 162
SELECT feeding_count FROM mv_species_feeding_report WHERE species = 'Амурский тигр';

-- 13. Обновляем отчёт: добавилось кормление из шага 4, теперь 163
-- expect: value 163
REFRESH MATERIALIZED VIEW mv_species_feeding_report;
SELECT feeding_count FROM mv_species_feeding_report WHERE species = 'Амурский тигр';

-- 14. Поиск без фильтров: все животные
-- expect: rows 19
SELECT * FROM find_animals();

-- 15. Поиск по виду: только амурские тигры
-- expect: rows 2
SELECT * FROM find_animals(p_species => 'Амурский тигр');

-- 16. Поиск по весу: животные от 150 кг
-- expect: rows 4
SELECT * FROM find_animals(p_min_weight => 150);

-- **

-- 17. Меняем количество корма в записи 1: в журнале появляется строка с «было» и «стало»
-- expect: rows 1
UPDATE feedings SET amount_kg = 7.00 WHERE id = 1;
SELECT operation, old_data->>'amount_kg' AS was, new_data->>'amount_kg' AS became, changed_by
FROM feedings_log WHERE record_pk = 1;

-- 18. Состояние записи 1 час назад (до изменения): было 6.00
-- expect: true
SELECT (feeding_at(1, now() - interval '1 hour')->>'amount_kg')::numeric = 6.00;

-- 19. Состояние записи сейчас (после изменения): стало 7.00
-- expect: true
SELECT (feeding_at(1, clock_timestamp())->>'amount_kg')::numeric = 7.00;

-- 20. Удаляем запись 2: в журнале операция DELETE
-- expect: true
DELETE FROM feedings WHERE id = 2;
SELECT operation = 'DELETE' FROM feedings_log WHERE record_pk = 2;

-- 21. После удаления состояния записи 2 нет
-- expect: true
SELECT feeding_at(2, clock_timestamp()) IS NULL;

-- 22. А час назад запись 2 ещё существовала
-- expect: true
SELECT feeding_at(2, now() - interval '1 hour') IS NOT NULL;