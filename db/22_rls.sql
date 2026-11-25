-- ** Row Level Security (защита на уровне строк): смотритель видит только свои кормления.
CREATE ROLE app_keeper NOLOGIN;
GRANT SELECT ON feedings TO app_keeper;

ALTER TABLE feedings ENABLE ROW LEVEL SECURITY;

-- Номер смотрителя передаётся настройкой сессии app.keeper_id. Если она не задана, строк не видно.
CREATE POLICY keeper_own_feedings ON feedings
    FOR SELECT
    TO app_keeper
    USING (keeper_id = nullif(current_setting('app.keeper_id', true), '')::integer);