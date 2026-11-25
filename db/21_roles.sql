-- Лаба 4. Роли приложения. Пароли берутся из переменных окружения контейнера (файл .env).
\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD

CREATE ROLE app_reader LOGIN PASSWORD :'reader_password';
CREATE ROLE app_writer LOGIN PASSWORD :'writer_password' IN ROLE app_reader;

-- Бизнес-операция кормления работает с правами владельца: писателю не нужен прямой доступ к таблицам.
ALTER FUNCTION feed_animal(integer, integer, text, numeric)
    SECURITY DEFINER SET search_path = public, pg_temp;

-- Закрываем всё по умолчанию.
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;

-- Читатель видит только представления.
GRANT SELECT ON v_animal_card, v_enclosure_occupancy, mv_species_feeding_report TO app_reader;

-- Писатель (он же читатель) может только вызывать бизнес-операции.
GRANT EXECUTE ON FUNCTION feed_animal(integer, integer, text, numeric) TO app_writer;
GRANT EXECUTE ON FUNCTION settle_animal(text, integer, integer, date, numeric) TO app_writer;