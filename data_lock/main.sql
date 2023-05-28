-- current locks
SELECT index_name, lock_type, lock_mode, lock_status, lock_data
FROM   performance_schema.data_locks
-- table name
WHERE  object_name = '';

-- current locks for current thread
SELECT *
FROM performance_schema.data_locks
WHERE THREAD_ID = PS_CURRENT_THREAD_ID()

-- using sys schema
SELECT * FROM sys.innodb_lock_waits;

