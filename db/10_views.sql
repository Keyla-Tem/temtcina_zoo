-- Лаба 3. Представления: сохранённые запросы с именем. Данные они не хранят.

-- Карточка животного: вид, питание и вольер в одном месте
CREATE VIEW v_animal_card AS
SELECT a.id,
       a.name AS animal,
       s.name AS species,
       s.diet,
       e.name AS enclosure,
       a.weight_kg,
       a.birth_date
FROM animals a
JOIN species s    ON s.id = a.species_id
JOIN enclosures e ON e.id = a.enclosure_id;

-- Заполненность вольеров: сколько животных, сколько мест свободно, сколько смотрителей
CREATE VIEW v_enclosure_occupancy AS
SELECT e.id,
       e.name AS enclosure,
       e.capacity,
       (SELECT count(*) FROM animals a WHERE a.enclosure_id = e.id) AS animal_count,
       e.capacity - (SELECT count(*) FROM animals a WHERE a.enclosure_id = e.id) AS free_places,
       (SELECT count(*) FROM keeper_enclosures ke WHERE ke.enclosure_id = e.id) AS keeper_count
FROM enclosures e;

-- Материализованное представление: отчёт по видам животных.
-- Хранит снимок данных и обновляется только командой REFRESH MATERIALIZED VIEW.
CREATE MATERIALIZED VIEW mv_species_feeding_report AS
SELECT s.name AS species,
       count(*) AS feeding_count,
       round(sum(f.amount_kg), 2) AS total_kg,
       round(avg(f.amount_kg), 2) AS avg_portion_kg
FROM feedings f
JOIN animals a ON a.id = f.animal_id
JOIN species s ON s.id = a.species_id
GROUP BY s.id, s.name;