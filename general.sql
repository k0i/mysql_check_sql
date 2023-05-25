-- explain a connection's query
-- check connection id by 
-- SHOW PROCESSLIST;

EXPLAIN FOR CONNECTION 1;

-- current running queries
-- The sys.session and sys.processlist views by default sort the queries according to the execution time in descending order. 
SELECT
        thd_id, conn_id, state,
        current_statement,
        statement_latency
FROM sys.session
WHERE command = 'Query';
