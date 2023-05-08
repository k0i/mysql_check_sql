/*
  INNODB_TRX table is often the most important resource when it comes to investigating *ongoing* transactions.
  As you know, SHOW ENGINE INNODB STATUS¥G shows the almost same information as the INNODB_TRX table in the `TRANSACTIONS` section.
  However, in MySQL 5.7 and later, read-only non-locking transactions are not included in the InnoDB monitor transaction list.
  For this reason, it is better to use the INNODB_TRX view, if you need to include all active transactions.
*/
SELECT 
        *
FROM information_schema.INNODB_TRX
-- query
-- WHERE trx_query LIKE '%SELECT%';


-- any transaction running for more than a second and modifying more than a handful of rows may be a sign of problems  
-- to find transactions that are older than 10 seconds, you can use the following query:
SELECT 
        thd.thread_id, thd.processlist_id,
        trx.trx_id, stmt.event_id, trx.trx_started,
        TO_SECONDS(NOW()) - TO_SECONDS(trx.trx_started) AS age_seconds,
        trx.trx_rows_locked, trx.trx_rows_modified,
        stmt.timer_wait AS latency,
        stmt.rows_examined, stmt.rows_affected,
        sys.format_statement(SQL_TEXT) as statement
FROM information_schema.INNODB_TRX trx
INNER JOIN performance_schema.threads thd
        ON thd.processlist_id = trx.trx_mysql_thread_id
INNER JOIN performance_schema.events_statements_current stmt
        USING (thread_id)
WHERE trx_started < NOW() - INTERVAL 10 SECOND;
