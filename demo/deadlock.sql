-- Взаимоблокировка: два окна блокируют две строки вольеров в разном порядке.

-- [A] Окно A блокирует вольер 1
BEGIN;
SELECT id FROM enclosures WHERE id = 1 FOR UPDATE;

-- [B] Окно B блокирует вольер 2
BEGIN;
SELECT id FROM enclosures WHERE id = 2 FOR UPDATE;

-- [A] Окно A просит вольер 2, но он у окна B: ждёт
-- expect: blocked
SELECT id FROM enclosures WHERE id = 2 FOR UPDATE;

-- [B] Окно B просит вольер 1, но он у окна A: взаимоблокировка, база отменяет одно окно
-- expect: error deadlock
SELECT id FROM enclosures WHERE id = 1 FOR UPDATE;

-- [B]
ROLLBACK;

-- [A]
ROLLBACK;