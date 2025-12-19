-- Run monitored versions of the three scenarios. Assumes privileges to see SQL Monitor.
-- Executes the queries and leaves rows in v$SQL_MONITOR for later inspection.

-- Scenario 1: Function Killer (case-insensitive email lookup)
SELECT /*+ MONITOR */ cust_id, email
FROM customers
WHERE UPPER(email) = 'USER_500@GREENSTREAM.COM';

-- Scenario 2: Join Performance (orders + logistics)
SELECT /*+ MONITOR */ c.cust_id,
       COUNT(*) AS orders,
       COUNT(DISTINCT le.event_id) AS events
FROM customers c
JOIN orders o ON c.cust_id = o.cust_id
JOIN logistics_events le ON o.order_id = le.order_id
GROUP BY c.cust_id
ORDER BY orders DESC
FETCH FIRST 10 ROWS ONLY;

-- Scenario 3: Pagination Top-N (latest orders)
SELECT /*+ MONITOR */ order_id, cust_id, order_date, status
FROM orders
ORDER BY order_date DESC, cust_id DESC
FETCH FIRST 10 ROWS ONLY;
