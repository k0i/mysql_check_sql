-- 1. Active Transactions: Latest
-- It reports the latest query for all transactions active longer than 1 second.
-- This report answers the question: which transactions are long-running and what are they doing right now?
-- To increase the time, change the last '1'
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
-- RESULTS:
-- trx_runtime: How long the transaction has been running (active) in seconds with millisecond precision. (I forgot about this transaction, which is why it’s been active for almost six hours in the example.)
-- thread_id: The thread ID of the client connection that is executing the transaction. This is used in “Active Transaction: History”. Performance Schema events use thread IDs and event IDs to link data to client connections and events, respectively. Thread IDs are different than process IDs common to other parts of MySQL.
-- trx_event_id: The transaction event ID. This is used in “Active Transaction: History”.
-- isolation_level: Transaction isolation level: READ REPEATABLE or READ COMMITTED. (The other isolation levels, SERIALIZABLE and READ UNCOMMITTED, are rarely used; if you see them, it might be an application bug.) Recall “Row Locking”: the transaction isolation level affects row locking and whether or not SELECT uses a consistent snapshot.
-- autocommit: If YES, then autocommit is enabled and it’s a single-statement transaction. If NO, then the transaction was started with BEGIN (or START TRANSACTION) and it’s most likely a multistatement transaction.
-- db: Current database of query. The current database means USE db. The query can access other databases with database-qualified table names, such as db.table.
-- query: The latest query either executed by or executing in the transaction. If exec_state = running, then query is currently executing in the transaction. If exec_state = done, then query is the last query that the transaction executed. In both cases the transaction is active (not committed), but in the latter case it’s idle with respect to executing a query.
-- rows_examined: Total number of rows examined by query. This does not include past queries executed in the transaction.
-- rows_examined: Total number of rows modified by query. This does not include past queries executed in the transaction.
-- rows_sent: Total number of rows sent (result set) by query. This does not include past queries executed in the transaction.
-- exec_state: If done, then the transaction is idle with respect to executing a query, and query was the last query that it executed. If running, then transaction is currently executing query. In both cases, the transaction is active (not committed).
-- exec_time Execution time of query in seconds (with millisecond precision).

-- 2. Active Transactions: Summary
-- It reports the summary of queries executed for all transactions active longer than 1 second.
-- This report answers the question: which transactions are long-running and how much work have they been doing? (including stalled transactions: not currently executing a query)
SELECT
  trx.thread_id AS thread_id,
  MAX(trx.event_id) AS trx_event_id,
  MAX(ROUND(trx.timer_wait/1000000000000,3)) AS trx_runtime,
  SUM(ROUND(stm.timer_wait/1000000000000,3)) AS exec_time,
  SUM(stm.rows_examined) AS rows_examined,
  SUM(stm.rows_affected) AS rows_affected,
  SUM(stm.rows_sent) AS rows_sent
FROM
       performance_schema.events_transactions_current trx
  JOIN performance_schema.events_statements_history   stm
    ON stm.thread_id = trx.thread_id AND stm.nesting_event_id = trx.event_id
WHERE
      stm.event_name LIKE 'statement/sql/%'
  AND trx.state = 'ACTIVE'
  AND trx.timer_wait > 1000000000000 * 1
GROUP BY trx.thread_id;

-- 3. Active Transaction: History
-- It reports the history of queries executed for a single transaction.
-- This report answers the question: how much work did each query transaction do?
-- You must replace the zeros with thread_id and trx_event_id values from the output of 1
-- Replace the zero in stm.thread_id = 0 with thread_id.
-- Replace the zero in stm.nesting_event_id = 0 with trx_event_id.
SELECT
  stm.rows_examined AS rows_examined,
  stm.rows_affected AS rows_affected,
  stm.rows_sent AS rows_sent,
  ROUND(stm.timer_wait/1000000000000,3) AS exec_time,
  stm.sql_text AS query
FROM
  performance_schema.events_statements_history stm
WHERE
       stm.thread_id = 0
  AND  stm.nesting_event_id = 0
ORDER BY stm.event_id;

-- 4. Committed Transactions: Summary
-- The previous three reports are for active transactions, but committed transactions are also revealing.  
-- It reports basic metrics for committed (completed) transactions. It’s like a slow query log for transactions.
SELECT
  ROUND(MAX(trx.timer_wait)/1000000000,3) AS trx_time,
  ROUND(SUM(stm.timer_end-stm.timer_start)/1000000000,3) AS query_time,
  ROUND((MAX(trx.timer_wait)-SUM(stm.timer_end-stm.timer_start))/1000000000, 3)
    AS idle_time,
  COUNT(stm.event_id)-1 AS query_count,
  SUM(stm.rows_examined) AS rows_examined,
  SUM(stm.rows_affected) AS rows_affected,
  SUM(stm.rows_sent) AS rows_sent
FROM
      performance_schema.events_transactions_history trx
 JOIN performance_schema.events_statements_history   stm
   ON stm.nesting_event_id = trx.event_id
WHERE
      trx.state = 'COMMITTED'
  AND trx.nesting_event_id IS NOT NULL
GROUP BY
  trx.thread_id, trx.event_id;
-- RESULTS:
-- trx_time: Total transaction time, in milliseconds with microsecond precision.
-- query_time: Total query execution time, in milliseconds with microsecond precision.
-- idle_time: Transaction time minus query time, in milliseconds with microsecond precision. Idle time indicates how much the application stalled while executing the queries in the transaction.
-- query_count: Number of queries executed in the transaction.
-- rows_*: Total number of rows examined, affected, and sent (respectively) by all queries executed in the transaction.


