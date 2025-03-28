```sql
-- If You are Investigating Slow Queries
DROP TEMPORARY TABLE IF EXISTS temp_investigation_slow_queries;
CREATE TEMPORARY TABLE temp_investigation_slow_queries
  SELECT
  stm.statement_id,
  stm.sql_text AS query,
  IF(stm.end_event_id IS NULL, 'running', 'done') AS exec_state,
  ROUND(trx.timer_wait/1000000000000,3) AS `trx_running_time(sec)`,
  ROUND(stm.timer_wait/1000000000000,3) AS `exec_time(sec)`,
  trx.autocommit
    FROM
      performance_schema.events_transactions_current trx
    JOIN performance_schema.events_statements_current   stm USING (thread_id)
  WHERE
      trx.state = 'ACTIVE'
  AND trx.timer_wait > 1000000000000 * 1;

DROP TEMPORARY TABLE IF EXISTS temp_investigation_slow_queries_histories;
CREATE TEMPORARY TABLE temp_investigation_slow_queries_histories
SELECT
  ROUND(timer_wait/1000000000000,3) AS `exec_time(sec)`,
  ROUND(lock_time/1000000000000,3) AS `table_lock_waits(sec)`,
  SQL_TEXT,
  rows_sent,
  rows_examined,
  created_tmp_disk_tables,
  created_tmp_tables,
  select_full_join,
  select_full_range_join,
  select_range,
  select_range_check,
  select_scan,
  sort_merge_passes,
  sort_range,
  sort_rows,
  sort_scan,
  no_index_used,
  no_good_index_used,
  max_total_memory/1024/1024 AS consumed_memory_mb
  FROM performance_schema.events_statements_history_long where statement_id in
  (SELECT statement_id FROM temp_investigation_slow_queries);

SELECT * FROM  temp_investigation_slow_queries_histories\G

SHOW GLOBAL STATUS LIKE 'uptime'; -- check MySQL uptime
SHOW ENGINE INNODB STATUS\G; -- check InnoDB status


-- If You Suspect Lock Waits
SELECT * FROM data_locks; -- check for locksit
SELECT * FROM data_lock_waits; -- check for lock waits
SELECT * FROM metadata_locks WHERE LOCK_STATUS <> 'GRANTED'; -- check for metadata lock waits

-- Explain Against Long Running Transaction SQL_TEXT
EXPLAIN FORMAT=JSON <The Above SQL>;

--  CAUTION: EXPLAIN ANALYZE Actually Executes the Query
EXPLAIN ANALYZE <The Above SQL>;
SHOW WARNINGS;

-- If Explain Does not provide Sufficient Information, You Need to Dig Into Optimizer Trace.
SET optimizer_trace='enabled=on';
SET optimizer_trace_max_mem_size = 1048576; -- 1MiB
SELECT * FROM information_schema.optimizer_trace\G
```
