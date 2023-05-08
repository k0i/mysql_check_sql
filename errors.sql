SELECT 
        thread_id, 
        event_id,
        lock_time,
        sys.format_statement(SQL_TEXT) AS statement,
        digest, mysql_errno,
        returned_sqlstate, message_text, errors
FROM 
        performance_schema.events_statements_history
WHERE 
        mysql_errno > 0;

-- only mysql 8
SELECT
        thread_id, event_id,
        FORMAT_PICO_TIME(lock_time) AS lock_time,
        sys.format_statement(SQL_TEXT) AS statement,
        digest, mysql_errno,
        returned_sqlstate, message_text, errors
FROM 
        performance_schema.events_statements_history
WHERE
        mysql_errno > 0\G
