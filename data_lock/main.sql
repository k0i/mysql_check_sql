-- if SHOW ENGINE INNODB STATUS¥G does not show any information about LATEST DETECTED DEADLOCK, try it
-- deadlock section in the InnoDB monitor output only includes information for deadlocks involving InnoDB record locks
-- for deadlocks involving non-InnoDB locks such as user-level locks, there is no equivalent information
SET GLOBAL innodb_status_output_locks = ON;

-- global metrics about lock
SELECT 
        Variable_name,
        Variable_value AS Value,
        Enabled
FROM sys.metrics
WHERE Variable_name LIKE 'innodb_row_lock%'
        OR Variable_name LIKE 'Table_locks%'
        OR Variable_name LIKE 'innodb_rwlock_%'
        OR Type = 'InnoDB Metrics - lock';

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

