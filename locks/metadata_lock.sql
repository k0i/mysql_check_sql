-- shows the metadata locks that are currently in effect
-- `wait/lock/metadata/sql/mdl instrument` should be enabled
-- SELECT * FROM performance_schema.setup_instruments where NAME LIKE '%metadata%';
SELECT
        * 
FROM performance_schema.metadata_locks
WHERE OBJECT_TYPE = 'TABLE';
-- table name
-- AND OBJECT_SCHEMA = 'world'

-- detect metadata locks
SELECT 
        OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME,
        w.OWNER_THREAD_ID AS WAITING_THREAD_ID,
        b.OWNER_THREAD_ID AS BLOCKING_THREAD_ID
FROM performance_schema.metadata_locks w
INNER JOIN performance_schema.metadata_locks b
        USING (OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME)
WHERE w.LOCK_STATUS = 'PENDING' AND b.LOCK_STATUS = 'GRANTED';

-- alternatively, use the following query to detect metadata locks
--  `wait/lock/table/sql/handler` instrument should be enabled
-- SELECT * FROM performance_schema.setup_instruments where NAME LIKE '%handler%';
-- INTERNAL_LOCK column contains lock information at the SQL level such as explicit table locks on non-InnoDB tables
-- while the EXTERNAL_LOCK contains lock information at the storage engine level including explicit table locks for all tables
-- this query cannot use this query to investigate metadata lock contention
SELECT
        *
FROM performance_schema.table_handles;
