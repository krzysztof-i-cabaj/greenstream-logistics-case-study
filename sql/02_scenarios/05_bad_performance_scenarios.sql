/* * ======================================================================================
 * SCRIPT: 05_bad_performance_scenarios.sql
 * AUTHOR: KCB Kris
 * PL: Zbiór zapytań generujących problemy wydajnościowe (Case Study)
 * EN: Set of queries generating performance issues (Case Study)
 * ======================================================================================
 */

SET TIMING ON
-- PL: Włączenie podglądu planu wykonania
-- EN: Enabling execution plan preview
SET AUTOTRACE ON EXPLAIN

PROMPT ========================================================
PROMPT SCENARIO 1: The "Function Killer"
PROMPT ========================================================
-- PL: Wyszukiwanie bez indeksu funkcyjnego. Baza musi przeskanować całą tabelę (Full Table Scan),
--     aby obliczyć UPPER() dla każdego wiersza.
-- EN: Search without a function-based index. DB must scan the full table (Full Table Scan)
--     to calculate UPPER() for every row.
SELECT * FROM customers WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM';


PROMPT ========================================================
PROMPT SCENARIO 2: Implicit Conversion & Missing FK
PROMPT ========================================================
-- PL: Łączenie tabel (JOIN) bez indeksów na kluczach obcych.
--     Optymalizator wybierze kosztowny HASH JOIN zamiast szybkiego NESTED LOOPS.
-- EN: Joining tables without indexes on foreign keys.
--     Optimizer will choose expensive HASH JOIN instead of fast NESTED LOOPS.
SELECT 
    c.full_name,
    o.status,
    count(le.event_id) as scan_count
FROM customers c
JOIN orders o ON c.cust_id = o.cust_id
JOIN logistics_events le ON o.order_id = le.order_id
WHERE o.status = 'SHIPPED'
  AND c.region = 'EMEA'
GROUP BY c.full_name, o.status;


PROMPT ========================================================
PROMPT SCENARIO 3: The "Pagination Nightmare"
PROMPT ========================================================
-- PL: Sortowanie dużej ilości danych PRZED pobraniem pierwszych 10 wyników.
--     Powoduje ogromne zużycie pamięci PGA (Sort Order By).
-- EN: Sorting large amounts of data BEFORE fetching the first 10 rows.
--     Causes massive PGA memory usage (Sort Order By).
SELECT * FROM (
    SELECT o.*, c.email 
    FROM orders o 
    JOIN customers c ON o.cust_id = c.cust_id
    ORDER BY o.order_date DESC
) WHERE ROWNUM <= 10;


PROMPT ========================================================
PROMPT SCENARIO 4: Lock Contention (Simulation)
PROMPT ========================================================
-- PL: Symulacja blokady. Uruchomienie UPDATE bez COMMIT.
--     Inna sesja próbująca edytować ten wiersz zostanie "zamrożona".
-- EN: Lock simulation. Running UPDATE without COMMIT.
--     Another session trying to edit this row will be "frozen".
UPDATE orders 
SET status = 'PROCESSING_DELAY' 
WHERE order_id = (SELECT MIN(order_id) FROM orders WHERE status = 'NEW');

-- PL: Pamiętaj o wycofaniu zmian po teście!
-- EN: Remember to rollback after testing!
-- ROLLBACK;
