-- Функция, которая возвращает значение: сколько свободных мест в вольере.
CREATE FUNCTION free_places(p_enclosure integer)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT (e.capacity - (SELECT count(*) FROM animals a WHERE a.enclosure_id = e.id))::integer
    FROM enclosures e
    WHERE e.id = p_enclosure;
$$;

-- Бизнес-операция одной командой: покормить животное.
-- Проверяет, что животное есть и что смотритель закреплён за его вольером,
-- затем записывает кормление и возвращает его номер.
CREATE FUNCTION feed_animal(p_animal integer, p_keeper integer, p_food text, p_amount numeric)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_enclosure integer;
    v_id        integer;
BEGIN
    SELECT enclosure_id INTO v_enclosure FROM animals WHERE id = p_animal;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Животного % нет в базе', p_animal;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM keeper_enclosures
        WHERE keeper_id = p_keeper AND enclosure_id = v_enclosure
    ) THEN
        RAISE EXCEPTION 'Смотритель % не закреплён за вольером животного %', p_keeper, p_animal;
    END IF;

    INSERT INTO feedings (animal_id, keeper_id, fed_at, food, amount_kg)
    VALUES (p_animal, p_keeper, now(), p_food, p_amount)
    RETURNING id INTO v_id;

    RETURN v_id;
END $$;


-- Поиск животных с необязательными фильтрами, как форма на сайте.
-- Любой фильтр можно не передавать (тогда он NULL и условие пропускается).
CREATE FUNCTION find_animals(
    p_species    text    DEFAULT NULL,
    p_enclosure  integer DEFAULT NULL,
    p_min_weight numeric DEFAULT NULL
)
RETURNS TABLE (animal text, species text, enclosure text, weight_kg numeric)
LANGUAGE sql
STABLE
AS $$
    SELECT a.name, s.name, e.name, a.weight_kg
    FROM animals a
    JOIN species s    ON s.id = a.species_id
    JOIN enclosures e ON e.id = a.enclosure_id
    WHERE (p_species    IS NULL OR s.name = p_species)
      AND (p_enclosure  IS NULL OR a.enclosure_id = p_enclosure)
      AND (p_min_weight IS NULL OR a.weight_kg >= p_min_weight)
    ORDER BY a.name;
$$;