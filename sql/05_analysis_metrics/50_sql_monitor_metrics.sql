-- Pull SQL Monitor metrics for the latest executions by current user.
-- Outputs elapsed/cpu in seconds plus buffer_gets/disk_reads/fetches.

SELECT sql_id,
       status,
       TO_CHAR(ROUND(elapsed_time/1e6,3), 'FM9999990.000') AS elapsed_s,
       TO_CHAR(ROUND(cpu_time/1e6,3), 'FM9999990.000') AS cpu_s,
       buffer_gets,
       disk_reads,
       fetches,
       TO_CHAR(last_refresh_time,'YYYY-MM-DD HH24:MI:SS') AS last_refresh,
       SUBSTR(sql_text,1,120) AS sql_text
FROM sys.v_$sql_monitor
WHERE username = USER
ORDER BY last_refresh_time DESC
FETCH FIRST 10 ROWS ONLY;
