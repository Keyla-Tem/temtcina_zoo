-- Лаба 4. Исправление гонки: безопасная операция заселения животного.
-- Обычный INSERT в animals по-прежнему возможен, но защищён только триггером,
-- а он не видит незафиксированную вставку другого окна. Эта функция заселяет по очереди.
CREATE FUNCTION settle_animal(
    p_name      text,
    p_species   integer,
    p_enclosure integer,
    p_birth     date,
    p_weight    numeric
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_id integer;
BEGIN
    -- Блокируем строку вольера до конца транзакции: заселения в один вольер идут по очереди.
    PERFORM 1 FROM enclosures WHERE id = p_enclosure FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Вольера % нет в базе', p_enclosure;
    END IF;

    IF free_places(p_enclosure) < 1 THEN
        RAISE EXCEPTION 'В вольере % нет свободных мест', p_enclosure;
    END IF;

    -- Триггер правила срабатывает уже после блокировки и видит всех, кто успел заселиться.
    INSERT INTO animals (name, species_id, enclosure_id, birth_date, weight_kg)
    VALUES (p_name, p_species, p_enclosure, p_birth, p_weight)
    RETURNING id INTO v_id;

    RETURN v_id;
END $$;