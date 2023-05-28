# Important Tables

## performance schema

| Table           | Description                                                                                                                                                                                                                                                                                                                                     |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| data_locks      | This table contains details of table and records locks at the InnoDB level. It shows all locks currently held or are pending.                                                                                                                                                                                                                   |
| data_lock_waits | Like the data_locks table, it shows locks related to InnoDB, but only those waiting to be granted with information on which threads is blocking the request.                                                                                                                                                                                    |
| metadata_locks  | This table contains information about user-level locks, metadata locks, and similar. To record information, the `wait/lock/metadata/sql/mdl` Performance Schema instrument must be enabled (it is enabled by default in MySQL 8). The `OBJECT_TYPE` column shows which kind of lock is held, and the `LOCK_TYPE` column shows the access level. |
| table_handles   | This table holds information about which table locks are currently in effect. The wait/lock/table/sql/handler Performance Schema instrument must be enabled for data to be recorded (this is the default). This table is less frequently used than the other tables.                                                                            |

## sys schema

| Table                   | Description                                                                                           |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| innodb_lock_waits       | This view shows ongoing InnoDB row lock waits. It uses the `data_locks` and `data_lock_waits` tables. |
| schema_table_lock_waits | This view shows ongoing metadata and user lock waits. It uses the metadata_locks table.               |

## information schema

| Table      | Description                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| INNODB_TRX | This Information Schema view includes details for InnoDB transactions and is the best resource for studying ongoing InnoDB transactions. |

# Per Usage

## TRANSACTION INFORMATION

The transaction tables can be used to find information about individual transactions or aggregated data.

| Table                            | Description                                                                                                                                                                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| events_transactions_current      | Transactions that are ongoing as well as the latest transaction for threads that are still connected but that have not yet started a new transaction.                                                                           |
| events_transactions_history      | The last ten transactions (can be changed with the performance_schema_events_transactions_history_size) for each existing thread.                                                                                               |
| events_transactions_history_long | The last 10000 transactions (the performance_schema_events_transactions_history_long_size option) for the instance. It also includes transactions for disconnected threads. The consumer for this table is disabled by default. |
| INNODB_TRX                       | This `Information Schema` view includes details for InnoDB transactions and is the best resource for studying ongoing InnoDB transactions.                                                                                      |

There are five transaction summary tables grouping the data globally or by account, host, thread, or user.

| Table                                                | Description                                                                       |
| ---------------------------------------------------- | --------------------------------------------------------------------------------- |
| events_transactions_summary_global_by_event_name     | All transactions aggregated. There is only a single row in this table.            |
| events_transactions_summary_by_account_by_event_name | The transactions grouped by username and hostname.                                |
| events_transactions_summary_by_host_by_event_name    | The transactions grouped by hostname of the account.                              |
| events_transactions_summary_by_thread_by_event_name  | The transactions grouped by thread. Only currently existing threads are included. |
| events_transactions_summary_by_user_by_event_name    | The events grouped by the username part of the account.                           |

## STATEMENT INFORMATION

The statement tables follow the same pattern as the transaction tables with three tables with information about individual events and several summary tables with aggregate data.  
Additionally, there is the threads table .

| Table                          | Description                                                                                                                                                                                                                                                                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| events_statements_current      | The statements currently executing or for idle connections the latest executed query. When executing stored programs, there may be more than one row per connection.                                                                                                                                                          |
| events_statements_history      | The last statements for each connection. The number of statements per connection is capped at performance_schema_events_statements_history_size (defaults to 10). The statements for a connection are removed when the connection is closed.                                                                                  |
| events_statements_history_long | The latest queries for the instance irrespective of which connection executed it. This table also includes statements from connections that have been closed. The consumer for this table is disabled by default. The number of rows is capped at performance_schema_events_statements_history_long_size (defaults to 10000). |
| threads                        | Information about all current threads in the instance, both background and foreground threads. You can use this table instead of the SHOW PROCESSLIST command. In addition to the process list information, there are columns showing whether the thread is instrumented, the operating system thread id, and more.           |

The statement summary tables group the data by the statement digest, event name, user, etc.

| Table                                              | Description                                                                                                                                                                                                                                  |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| events_statements_summary_by_digest                | The statement statistics grouped by the default schema and digest.                                                                                                                                                                           |
| events_statements_summary_by_account_by_event_name | The statement statistics grouped by the account and event name. The event name shows what kind of statement is executed, for example, statement/sql/select for a SELECT statement executed directly (not executed through a stored program). |
| events_statements_summary_by_host_by_event_name    | The statement statistics grouped by the hostname of the account and the event name.                                                                                                                                                          |
| events_statements_summary_by_program               | The statement statistics grouped by the stored program (event, function, procedure, table, or trigger) that executed the statement. This is useful to find the stored programs that perform the most work.                                   |
| events_statements_summary_by_thread_by_event_name  | The statement statistics grouped by thread and event name. Only threads currently connected are included.                                                                                                                                    |
| events_statements_summary_by_user_by_event_name    | The statement statistics grouped by the username of the account and the event name.                                                                                                                                                          |
| events_statements_summary_global_by_event_name     | The statement statistics grouped by the event name.                                                                                                                                                                                          |
| events_statements_histogram_by_digest              | Histogram statistics grouped by the default schema and digest.                                                                                                                                                                               |
| events_statements_histogram_global                 | Histogram statistics where all queries are aggregated in one histogram.                                                                                                                                                                      |
| prepared_statements_instances                      | Statistics for prepared statements with one row per prepared statement (the same statement prepared by two threads count as two unique prepared statements).                                                                                 |

Of these tables, the `events_statements_summary_by_digest` is the most used.  
One important thing to note is that queries executed as prepared statements are not included in the statement tables, and instead the `prepared_statements_instances` table must be used to get information about them.  
The sys schema includes a view that serves as an advanced process list as well as views returning statements filtered by criteria such as whether they perform full tables scans, performs sorting, etc.

| Table                                       | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| session                                     | This view returns an advanced process list based on the threads and events_statements_current tables with some additional information from other Performance Schema tables. The view includes the current statement for active connections and the last executed statement for idle connections. The rows are returned in descending order according to the process list time and the duration of the previous statement. The session view is particularly useful to understand what is happening right now. |
| statement_analysis                          | This view is a formatted version of the events_statements_summary_by_digest table ordered by the total latency in descending order.                                                                                                                                                                                                                                                                                                                                                                          |
| statements_with_errors_or_warnings          | This view returns the statements that cause errors or warnings. The rows are ordered in descending order by the number of errors and then number of warnings.                                                                                                                                                                                                                                                                                                                                                |
| statements_with_full_table_scans            | This view returns the statements that include a full table scan. The rows are first ordered by the percentage of times no index is used and then by the total latency, both in descending order.                                                                                                                                                                                                                                                                                                             |
| statements_with_runtimes_in_95th_percentile | This view returns the statements that are in the 95th percentile of all queries in the events_statements_summary_by_digest table. The rows are ordered by the average latency in descending order.                                                                                                                                                                                                                                                                                                           |
| statements_with_sorting                     | This view returns the statements that sort the rows in its result. The rows are ordered by the total latency in descending order.                                                                                                                                                                                                                                                                                                                                                                            |
| statements_with_temp_tables                 | This view returns the statements that use internal temporary tables. The rows are ordered in descending order by the number of internal temporary tables on disk and internal temporary tables in memory.                                                                                                                                                                                                                                                                                                    |

## METADATA INFORMATION

In `metadata_locks` table, the most commonly encountered object types are GLOBAL and TABLE.

| Object Type       | Description                                                                                              |
| ----------------- | -------------------------------------------------------------------------------------------------------- |
| ACL_CACHE         | For the access control list (ACL) cache.                                                                 |
| BACKUP_LOCK       | For the backup lock.                                                                                     |
| CHECK_CONSTRAINT  | For the names of CHECK constraints.                                                                      |
| COLUMN_STATISTICS | For histograms and other column statistics.                                                              |
| COMMIT            | For blocking commits. It is related to the global read lock.                                             |
| EVENT             | For stored events.                                                                                       |
| FOREIGN_KEY       | For the foreign key names.                                                                               |
| FUNCTION          | For stored functions.                                                                                    |
| GLOBAL            | For the global read lock (triggered by `FLUSH TABLES WITH READ LOCK`).                                   |
| LOCKING_SERVICE   | For locks acquired using the locking service interface.                                                  |
| PROCEDURE         | For stored procedures.                                                                                   |
| RESOURCE_GROUPS   | For the resource groups.                                                                                 |
| SCHEMA            | For `schema/databases`. These are similar to the metadata locks for tables except they are for a schema. |
| SRID              | For the spatial reference systems (SRIDs).                                                               |
| TABLE             | For tables and views. This includes what is called metadata locks in this book.                          |
| TABLESPACE        | For tablespaces.                                                                                         |
| TRIGGER           | For triggers (on tables).                                                                                |
| USER_LEVEL_LOCK   | For user-level locks.                                                                                    |

Also, `METADATA LOCK TYPES` are:

| Lock Type             | Description                                                                                                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| INTENTION_EXCLUSIVE   | An intention exclusive lock that can later be upgraded to an exclusive lock. This is also used when accessing the dictionary cache.                                                         |
| SHARED                | For shared access to only the metadata of the object. For example, used with stored procedures and when preparing prepared statements.                                                      |
| SHARED_HIGH_PRIO      | A high-priority shared lock which is used when only accessing the metadata, for example, when populating the Information Schema view with metadata for the tables.                          |
| SHARED_READ           | A shared lock for cases where it is intended to read the data of the object.                                                                                                                |
| SHARED_WRITE          | A shared lock on the metadata for cases where the intention is to modify the data of the object.                                                                                            |
| SHARED_WRITE_LOW_PRIO | The same as SHARED_WRITE but for statements that use the LOW_PRIORITY clause. This is not supported by InnoDB.                                                                              |
| SHARED_UPGRADABLE     | A shared lock that allows concurrent read/write of the table data. It can later be upgraded to lock types preventing data changes. It is used by the first phase of ALTER TABLE statements. |
| SHARED_READ_ONLY      | This lock type is used with LOCK TABLES … READ to take a shared lock while preventing modification of the table’s metadata and data.                                                        |
| SHARED_NO_WRITE       | Another upgradable shared lock which blocks writes to the data. It is also used with the first phase of ALTER TABLE statements.                                                             |
| SHARED_NO_READ_WRITE  | An upgradable lock holding a shared lock on the metadata but prevents both reads and writes of the table data. This is used by LOCK TABLES ... WRITE.                                       |
| EXCLUSIVE             | No other access to neither the metadata nor table data is allowed. This is used with CREATE TABLE, DROP TABLE, and RENAME TABLE statements as well as some phases of other DDL statements.  |
