-- Триггеры. Функция триггера создаётся раньше самого триггера.

-- 1. Правило темы: хищника нельзя поселить к травоядным (и наоборот).
-- Всеядные (медведи, кабан, енотовидная собака) ограничений не имеют.
CREATE FUNCTION check_predator_herbivore() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_diet diet_type;
BEGIN
    SELECT diet INTO v_diet FROM species WHERE id = NEW.species_id;

    IF v_diet = 'predator' AND EXISTS (
        SELECT 1
        FROM animals a
        JOIN species s ON s.id = a.species_id
        WHERE a.enclosure_id = NEW.enclosure_id
          AND a.id IS DISTINCT FROM NEW.id
          AND s.diet = 'herbivore'
    ) THEN
        RAISE EXCEPTION 'Хищника нельзя поселить в вольер %, где живут травоядные', NEW.enclosure_id;
    END IF;

    IF v_diet = 'herbivore' AND EXISTS (
        SELECT 1
        FROM animals a
        JOIN species s ON s.id = a.species_id
        WHERE a.enclosure_id = NEW.enclosure_id
          AND a.id IS DISTINCT FROM NEW.id
          AND s.diet = 'predator'
    ) THEN
        RAISE EXCEPTION 'Травоядное нельзя поселить в вольер %, где живут хищники', NEW.enclosure_id;
    END IF;

    RETURN NEW;
END $$;

CREATE TRIGGER trg_predator_herbivore
BEFORE INSERT OR UPDATE OF species_id, enclosure_id ON animals
FOR EACH ROW EXECUTE FUNCTION check_predator_herbivore();

-- 2. Служебный триггер: время последнего изменения записи животного.
ALTER TABLE animals ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

CREATE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE TRIGGER trg_animals_updated_at
BEFORE UPDATE ON animals
FOR EACH ROW EXECUTE FUNCTION set_updated_at();