/* * ======================================================================================
 * SCRIPT: 07_performance_fixes.sql
 * AUTHOR: AI Performance Optimization Agent (Oracle DBA)
 * PL: Naprawa problemów wydajnościowych w GreenStream Logistics (Indeksowanie)
 * EN: Performance fixes for GreenStream Logistics (Indexing)
 * ORACLE VERSION: 23ai
 * ======================================================================================
 */

SET TIMING ON
SET SERVEROUTPUT ON

PROMPT ========================================================
PROMPT PERFORMANCE FIX 1: Function-Based Index for Email Search
PROMPT ========================================================
-- PL: Problem: Zapytanie SELECT * FROM customers WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM'
--     powoduje Full Table Scan (koszt 13), ponieważ każdy wiersz musi być przetworzony
--     przez funkcję UPPER() przed porównaniem.
--
-- Rozwiązanie: Indeks funkcyjny na UPPER(email) pozwala optymalizatorowi 
--     przeskoczyć zbędy Full Table Scan i bezpośrednio poszukać wartości w indeksie.
--
-- EN: Problem: Query SELECT * FROM customers WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM'
--     causes Full Table Scan (cost 13) because every row must be processed
--     by the UPPER() function before comparison.
--
-- Solution: Function-based index on UPPER(email) allows the optimizer
--     to skip unnecessary Full Table Scan and directly search the index value.

CREATE INDEX idx_customers_email_upper ON customers(UPPER(email));
ALTER INDEX idx_customers_email_upper UNUSABLE;
ALTER INDEX idx_customers_email_upper REBUILD;

BEGIN
    DBMS_OUTPUT.PUT_LINE('[SUCCESS] Created function-based index: idx_customers_email_upper');
END;
/

PROMPT ========================================================
PROMPT PERFORMANCE FIX 2: Foreign Key Indexes for Join Performance
PROMPT ========================================================
-- PL: Problem: Łączenie tabel (orders.cust_id, logistics_events.order_id) bez indeksów
--     powoduje kosztowne HASH JOIN (koszt 142). Baza musi przeskanować całe tabele.
--
-- Rozwiązanie: Tradycyjne indeksy B-Tree na kolumnach kluczy obcych umożliwiają
--     optymalizatorowi wybranie szybszej strategii NESTED LOOPS.
--     Dodatkowo indeks na logistics_events.order_id radykalnie zmniejsza Large Table Scan.
--
-- EN: Problem: Joining tables (orders.cust_id, logistics_events.order_id) without indexes
--     causes expensive HASH JOIN (cost 142). Database must scan entire tables.
--
-- Solution: Traditional B-Tree indexes on foreign key columns enable the optimizer
--     to choose faster NESTED LOOPS strategy.
--     Additionally, index on logistics_events.order_id drastically reduces Large Table Scan.

CREATE INDEX idx_orders_cust_id ON orders(cust_id);
CREATE INDEX idx_logistics_events_order_id ON logistics_events(order_id);

BEGIN
    DBMS_OUTPUT.PUT_LINE('[SUCCESS] Created foreign key indexes:');
    DBMS_OUTPUT.PUT_LINE('  - idx_orders_cust_id');
    DBMS_OUTPUT.PUT_LINE('  - idx_logistics_events_order_id');
END;
/

PROMPT ========================================================
PROMPT PERFORMANCE FIX 3: Descending Index for Pagination (Top-N Optimization)
PROMPT ========================================================
-- PL: Problem: Zapytanie z ROWNUM <= 10 i ORDER BY order_date DESC sortuje ~10k wierszy
--     przed pobraniem 10 wyników. Zużywa 26MB Temp Tablespace (koszt 4472!).
--
-- Rozwiązanie: Indeks DESC na order_date wspiera Top-N Optimization.
--     Optymalizator może pobrać pierwsze 10 wierszy bezpośrednio z indeksu
--     bez kosztownego sortowania całego zbioru danych.
--
-- EN: Problem: Query with ROWNUM <= 10 and ORDER BY order_date DESC sorts ~10k rows
--     before fetching 10 results. Consumes 26MB Temp Tablespace (cost 4472!).
--
-- Solution: Descending index on order_date supports Top-N Optimization.
--     Optimizer can fetch first 10 rows directly from index
--     without costly sorting of entire dataset.

CREATE INDEX idx_orders_order_date_desc ON orders(order_date DESC);

BEGIN
    DBMS_OUTPUT.PUT_LINE('[SUCCESS] Created descending index: idx_orders_order_date_desc');
END;
/

PROMPT ========================================================
PROMPT VERIFICATION: Checking All Indexes Created
PROMPT ========================================================
SELECT index_name, table_name, status, num_rows
FROM user_indexes
WHERE table_name IN ('CUSTOMERS', 'ORDERS', 'LOGISTICS_EVENTS')
ORDER BY table_name, index_name;

PROMPT ========================================================
PROMPT RE-EXECUTE SCENARIO 1 (after optimization)
PROMPT ========================================================
EXPLAIN PLAN FOR
SELECT * FROM customers WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT ========================================================
PROMPT RE-EXECUTE SCENARIO 2 (after optimization)
PROMPT ========================================================
EXPLAIN PLAN FOR
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

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT ========================================================
PROMPT RE-EXECUTE SCENARIO 3 (after optimization)
PROMPT ========================================================
EXPLAIN PLAN FOR
SELECT * FROM (
    SELECT o.*, c.email 
    FROM orders o 
    JOIN customers c ON o.cust_id = c.cust_id
    ORDER BY o.order_date DESC
) WHERE ROWNUM <= 10;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT ========================================================
PROMPT SUCCESS: All performance fixes applied!
PROMPT ========================================================
