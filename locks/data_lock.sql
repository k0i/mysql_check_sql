-- if SHOW ENGINE INNODB STATUS¥G does not show any information about LATEST DETECTED DEADLOCK, try it
-- deadlock section in the InnoDB monitor output only includes information for deadlocks involving InnoDB record locks
-- for deadlocks involving non-InnoDB locks such as user-level locks, there is no equivalent information
SET GLOBAL innodb_status_output_locks = ON;


/* The data lock information is split into two tables:
   1. data_locks: This table contains details of table and records locks at the InnoDB level. It shows all locks currently held or are pending.
   2. data_lock_waits : Like the data_locks table, it shows locks related to InnoDB, but only those waiting to be granted with information on which thread is blocking the request.

   MySQL 8 has seen a change in the way that the lock monitoring tables work.
   In MySQL 5.7 and earlier, the information was available in two InnoDB-specific views in the Information Schema, INNODB_LOCKS and INNODB_LOCK_WAITS .
   The major differences are that the Performance Schema tables are created to be storage engine agnostic and information about all locks are always made available, 
   whereas in MySQL 5.7 and earlier, only information about locks involved in lock waits were exposed. 
   That all locks are always available for investigation makes the MySQL 8 tables much more useful to learn about locks.

   You can then join on the data_locks table using the REQUESTING_ENGINE_TRANSACTION_ID and BLOCKING_ENGINE_TRANSACTION_ID columns as well as to other tables to obtain more information.
   A good example of this is the sys.innodb_lock_waits view.
*/

-- only mysql 8
 SELECT 
        *
FROM performance_schema.data_locks;

-- retrieve the statistics for lock wait timeouts and deadlocks
-- while this does not help you identify which statements encounter the errors
-- it can help you monitor the frequency you encounter the errors and, in that way, determine whether lock errors become more frequent
-- only mysql 8
SELECT 
        *
FROM performance_schema.events_errors_summary_global_by_error
WHERE error_name IN ('ER_LOCK_WAIT_TIMEOUT','ER_LOCK_DEADLOCK')

-- `innodb_row_lock_%` metrics show how many locks are currently waiting and statistics for the amount of time in milliseconds spent on waiting to acquire InnoDB record locks
-- `lock_deadlocks` and `lock_timeouts` metrics show the number of deadlocks and lock wait timeouts that have been encountered, respectively
SELECT 
        Variable_name,
        Variable_value AS Value,
        Enabled
FROM sys.metrics
WHERE Variable_name LIKE 'innodb_row_lock%'
        OR Variable_name LIKE 'Table_locks%'
        OR Variable_name LIKE 'innodb_rwlock_%'
        OR Type = 'InnoDB Metrics - lock';
