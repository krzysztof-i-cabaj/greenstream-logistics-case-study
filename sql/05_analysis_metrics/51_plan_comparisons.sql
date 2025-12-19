-- 51_plan_comparisons.sql
-- Compare BEFORE vs AFTER execution plans for the three scenarios.
-- WARNING: This script temporarily drops and recreates indexes to simulate BEFORE state.
-- Run as vec_admin. Ensure you can recreate all indexes after.

SET SERVEROUTPUT ON

-- Helper: safe drop index
DECLARE
  PROCEDURE drop_index(p_name VARCHAR2) IS
  BEGIN EXECUTE IMMEDIATE 'DROP INDEX '||p_name; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN
  NULL;
END;
/

-- Clean plan table marks
DELETE FROM plan_table WHERE statement_id LIKE 'SCN%';

-------------------------------------------------------------------------------
-- Scenario 1: Function Killer (UPPER(email))
-------------------------------------------------------------------------------
BEGIN drop_index('IDX_CUSTOMERS_EMAIL_UPPER'); END;
/
EXPLAIN PLAN SET STATEMENT_ID = 'SCN1_BEFORE' FOR
SELECT cust_id, email FROM customers WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM';

-- AFTER: recreate function-based index
CREATE INDEX IDX_CUSTOMERS_EMAIL_UPPER ON customers(UPPER(email));
EXPLAIN PLAN SET STATEMENT_ID = 'SCN1_AFTER' FOR
SELECT cust_id, email FROM customers WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM';

PROMPT === SCENARIO 1: BEFORE ===
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','SCN1_BEFORE','BASIC +COST'));
PROMPT === SCENARIO 1: AFTER ===
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','SCN1_AFTER','BASIC +COST'));

-------------------------------------------------------------------------------
-- Scenario 2: Join Performance (ORDERS + LOGISTICS_EVENTS)
-------------------------------------------------------------------------------
BEGIN drop_index('IDX_ORDERS_CUST_ID'); END;
/
BEGIN drop_index('IDX_LOGISTICS_EVENTS_ORDER_ID'); END;
/
EXPLAIN PLAN SET STATEMENT_ID = 'SCN2_BEFORE' FOR
SELECT c.cust_id,
       COUNT(*) AS orders,
       COUNT(DISTINCT le.event_id) AS events
FROM customers c
JOIN orders o ON c.cust_id = o.cust_id
JOIN logistics_events le ON o.order_id = le.order_id
GROUP BY c.cust_id
ORDER BY orders DESC
FETCH FIRST 10 ROWS ONLY;

-- AFTER: recreate FK indexes
CREATE INDEX IDX_ORDERS_CUST_ID ON orders(cust_id);
CREATE INDEX IDX_LOGISTICS_EVENTS_ORDER_ID ON logistics_events(order_id);
EXPLAIN PLAN SET STATEMENT_ID = 'SCN2_AFTER' FOR
SELECT c.cust_id,
       COUNT(*) AS orders,
       COUNT(DISTINCT le.event_id) AS events
FROM customers c
JOIN orders o ON c.cust_id = o.cust_id
JOIN logistics_events le ON o.order_id = le.order_id
GROUP BY c.cust_id
ORDER BY orders DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT === SCENARIO 2: BEFORE ===
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','SCN2_BEFORE','BASIC +COST'));
PROMPT === SCENARIO 2: AFTER ===
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','SCN2_AFTER','BASIC +COST'));

-------------------------------------------------------------------------------
-- Scenario 3: Pagination Top-N (ORDER_DATE DESC)
-------------------------------------------------------------------------------
BEGIN drop_index('IDX_ORDERS_ORDER_DATE_CUST_DESC'); END;
/
EXPLAIN PLAN SET STATEMENT_ID = 'SCN3_BEFORE' FOR
SELECT order_id, cust_id, order_date, status
FROM orders
ORDER BY order_date DESC, cust_id DESC
FETCH FIRST 10 ROWS ONLY;

-- AFTER: recreate composite DESC index
CREATE INDEX IDX_ORDERS_ORDER_DATE_CUST_DESC ON orders(order_date DESC, cust_id DESC);
EXPLAIN PLAN SET STATEMENT_ID = 'SCN3_AFTER' FOR
SELECT order_id, cust_id, order_date, status
FROM orders
ORDER BY order_date DESC, cust_id DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT === SCENARIO 3: BEFORE ===
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','SCN3_BEFORE','BASIC +COST'));
PROMPT === SCENARIO 3: AFTER ===
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','SCN3_AFTER','BASIC +COST'));

PROMPT === DONE ===
