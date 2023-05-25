-- One important consideration when looking to kill a query is how much data has been changed.  
-- For a pure SELECT query (not involving stored routines), that is always nothing, and from the perspective of work done, it is safe to kill it.
-- For INSERT, UPDATE, DELETE, and similar queries, however, the changed data must be rolled back if the query is killed.
-- It will usually take longer to roll back changes than making them in the first place, so be prepared to wait a long time for the rollback if there are many changes.
-- You can use the `information_schema.INNODB_TRX` view to estimate the amount of work done by looking at the `trx_rows_modified column`.
-- If there is a lot of work to roll back:
-- IT IS USUALLY BETTER TO LET THE QUERY COMPLETE.


-- check processlist_id by 
-- SHOW PROCESSLIST;
-- KILL permits an optional CONNECTION or QUERY modifier:
-- KILL CONNECTION is the same as KILL with no modifier:
-- It terminates the connection, after terminating any statement the connection is executing.
-- KILL QUERY terminates the statement the connection is currently executing, but leaves the connection itself intact.
KILL processlist_id;
