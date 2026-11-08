-- Лаба 1. Схема базы: таблицы, ключи, ограничения.
-- Скрипты из db/ выполняются по порядку имён при первом docker compose up.
-- Следующие лабы добавляют новые файлы (02_seed.sql, 03_..., 10_views.sql и так далее), этот файл остаётся.
--

-- Тип питания
CREATE TYPE diet_type AS ENUM ('predator', 'herbivore', 'omnivore');

-- Виды животных
CREATE TABLE species (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text      NOT NULL UNIQUE,
    diet diet_type NOT NULL
);

-- Вольеры
CREATE TABLE enclosures (
    id       integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name     text    NOT NULL UNIQUE,
    capacity integer NOT NULL CHECK (capacity > 0)
);

-- Смотрители
CREATE TABLE keepers (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    last_name  text    NOT NULL,
    first_name text    NOT NULL,
    patronymic text,
    age        integer NOT NULL CHECK (age BETWEEN 18 AND 90),
    phone      text    NOT NULL UNIQUE CHECK (phone ~ '^[+]7[0-9]{10}$')
);

-- Животные
CREATE TABLE animals (
    id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         text          NOT NULL,
    species_id   integer       NOT NULL REFERENCES species (id)    ON DELETE RESTRICT,
    enclosure_id integer       NOT NULL REFERENCES enclosures (id) ON DELETE RESTRICT,
    birth_date   date,
    weight_kg    numeric(8, 2) NOT NULL CHECK (weight_kg > 0)
);

-- Связующая таблица N:M: смотритель:вольер
CREATE TABLE keeper_enclosures (
    keeper_id    integer NOT NULL REFERENCES keepers (id)    ON DELETE CASCADE,
    enclosure_id integer NOT NULL REFERENCES enclosures (id) ON DELETE CASCADE,
    PRIMARY KEY (keeper_id, enclosure_id)
);

-- Кормления: кто, кого, когда и чем кормил
CREATE TABLE feedings (
    id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    animal_id integer       NOT NULL REFERENCES animals (id) ON DELETE CASCADE,
    keeper_id integer       NOT NULL REFERENCES keepers (id) ON DELETE RESTRICT,
    fed_at    timestamptz   NOT NULL,
    food      text          NOT NULL,
    amount_kg numeric(6, 2) NOT NULL CHECK (amount_kg > 0)
);