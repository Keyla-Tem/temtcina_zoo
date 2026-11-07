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