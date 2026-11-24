-- Сгенерированные данные: кормления за 40 дней для каждой пары «животное - смотритель вольера».
-- Пар 38 (19 животных, у каждого вольера по два смотрителя), строк 38 * 40 = 1520.
-- Смотритель всегда закреплён за вольером животного, корм зависит от питания вида.
INSERT INTO feedings (animal_id, keeper_id, fed_at, food, amount_kg)
SELECT
    a.id,
    ke.keeper_id,
    timestamptz '2026-01-01 08:00:00+10'
        + d * interval '1 day'
        + (ke.keeper_id % 10) * interval '17 minutes',
    CASE s.diet
        WHEN 'predator'  THEN 'Мясо'
        WHEN 'herbivore' THEN 'Сено и веточки'
        ELSE 'Смешанный корм'
    END,
    GREATEST(round((a.weight_kg / 40 * (0.5 + random()))::numeric, 2), 0.10)
FROM animals a
JOIN species s            ON s.id = a.species_id
JOIN keeper_enclosures ke ON ke.enclosure_id = a.enclosure_id
CROSS JOIN generate_series(1, 40) AS d;