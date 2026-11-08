-- Журнал изменений главной таблицы feedings.

CREATE TABLE feedings_log (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operation  text        NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_pk  integer     NOT NULL,   -- номер записи в feedings (без внешнего ключа: удалённые записи остаются в журнале)
    old_data   jsonb,                  -- как было (пусто для INSERT)
    new_data   jsonb,                  -- как стало (пусто для DELETE)
    changed_by text        NOT NULL,   -- кто изменил
    changed_at timestamptz NOT NULL    -- когда
);

CREATE INDEX feedings_log_record_idx ON feedings_log (record_pk, changed_at);

-- Функция триггера: пишет строку в журнал.
CREATE FUNCTION log_feedings_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO feedings_log (operation, record_pk, old_data, new_data, changed_by, changed_at)
        VALUES (TG_OP, NEW.id, NULL, to_jsonb(NEW), session_user, clock_timestamp());
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO feedings_log (operation, record_pk, old_data, new_data, changed_by, changed_at)
        VALUES (TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW), session_user, clock_timestamp());
    ELSE
        INSERT INTO feedings_log (operation, record_pk, old_data, new_data, changed_by, changed_at)
        VALUES (TG_OP, OLD.id, to_jsonb(OLD), NULL, session_user, clock_timestamp());
    END IF;
    RETURN NULL;   -- у AFTER-триггера возвращаемое значение не используется
END $$;

CREATE TRIGGER trg_feedings_log
AFTER INSERT OR UPDATE OR DELETE ON feedings
FOR EACH ROW EXECUTE FUNCTION log_feedings_change();

-- Состояние записи кормления на указанный момент (jsonb), NULL если записи тогда не было.
CREATE FUNCTION feeding_at(p_id integer, p_at timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_entry feedings_log%ROWTYPE;
BEGIN
    -- Последнее изменение не позже указанного момента: запись стала такой.
    SELECT * INTO v_entry
    FROM feedings_log
    WHERE record_pk = p_id AND changed_at <= p_at
    ORDER BY changed_at DESC, id DESC
    LIMIT 1;
    IF FOUND THEN
        RETURN v_entry.new_data;   -- после DELETE пусто: записи уже нет
    END IF;

    -- Раньше изменений не было: запись была такой, какой была до первого следующего изменения.
    SELECT * INTO v_entry
    FROM feedings_log
    WHERE record_pk = p_id AND changed_at > p_at
    ORDER BY changed_at, id
    LIMIT 1;
    IF FOUND THEN
        RETURN v_entry.old_data;   -- у INSERT пусто: записи ещё не было
    END IF;

    -- В журнале записи нет: она не менялась с момента включения журнала.
    RETURN (SELECT to_jsonb(f) FROM feedings f WHERE f.id = p_id);
END $$;