```sql

SHOW GLOBAL STATUS LIKE 'uptime'; -- check MySQL uptime
SHOW ENGINE INNODB STATUS\G; -- check InnoDB status

USE performance_schema;

-- If You are Suspecting Lock Waits
SELECT * FROM data_locks; -- check for locks
SELECT * FROM data_lock_waits; -- check for lock waits
SELECT * FROM metadata_locks WHERE LOCK_STATUS <> 'GRANTED'; -- check for metadata lock waits

-- If You are Investigating Slow Queries

-- Current Long Running Transactions(1 second or more)
SELECT
  ROUND(trx.timer_wait/1000000000000,3) AS trx_runtime,
  trx.thread_id AS thread_id,
  trx.event_id AS trx_event_id,
  trx.isolation_level,
  trx.autocommit,
  stm.current_schema AS db,
  stm.sql_text AS query,
  stm.rows_examined AS rows_examined,
  stm.rows_affected AS rows_affected,
  stm.rows_sent AS rows_sent,
  IF(stm.end_event_id IS NULL, 'running', 'done') AS exec_state,
  ROUND(stm.timer_wait/1000000000000,3) AS exec_time
FROM
       performance_schema.events_transactions_current trx
JOIN performance_schema.events_statements_current   stm USING (thread_id)
WHERE
      trx.state = 'ACTIVE'
  AND trx.timer_wait > 1000000000000 * 1;


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
