# MySQL 8.0.16

| Table             | Description                                                                                                                                                                                      | Table              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ |
| data_locks        | This table contains details of table and records locks at the InnoDB level. It shows all locks currently held or are pending.                                                                    | performance_schema |
| data_lock_waits   | Like the data_locks table, it shows locks related to InnoDB, but only those waiting to be granted with information on which threads is blocking the request.                                     | performance_schema |
| innodb_lock_waits | The innodb_lock_waits view uses the data_locks and data_lock_waits view in the Performance Schema to return all cases of lock waits for InnoDB record locks. This table can be used in MySQL 5.7 | sys                |

The `data_locks` and `data_lock_waits` tables are new in MySQL 8. In MySQL 5.7 and earlier, there were two similar tables in the Information Schema named `INNODB_LOCKS` and `INNODB_LOCK_WAITS`.  
An advantage of using the `innodb_lock_waits` view is that it works the same (but with some extra information in MySQL 8) across the MySQL versions.

# MySQL 5.7 and older

As stated above, it is best to use `sys.innodb_lock_waits`, but there is another way to investigate locks in MySQL 5.7 and older.  
You must first `SET GLOBAL innodb_status_output_locks=ON`, which requires `SUPER` MySQL privileges, then execute `SHOW ENGINE INNODB STATUS` and shift through the output to find the relevant transaction and locks.  
[MySQL Data Locks: Mapping 8.0 to 5.7](https://hackmysql.com/post/mysql-data-locks-mapping-80-to-57/)

---

# InnoDB data locks

| Lock type             | Abbreviation     | Locks gap | Locks                                       |
| --------------------- | ---------------- | --------- | ------------------------------------------- |
| Record lock           | REC_NOT_GAP      |           | Locks a single record                       |
| Gap lock              | GAP              | ✓         | Locks the gap before (less than) a record   |
| Next-key lock         |                  | ✓         | Locks a single record and the gap before it |
| Insert intention lock | INSERT_INTENTION |           | Allows INSERT into gasp                     |

# data_locks

| Column Name           | Description                                                                                                                                                                                                                                                                                                                             |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ENGINE                | The storage engine for the data. For MySQL Server, this will always be InnoDB.                                                                                                                                                                                                                                                          |
| ENGINE_LOCK_ID        | The internal id of the lock as used by the storage engine. You should not rely on the id having a particular format.                                                                                                                                                                                                                    |
| ENGINE_TRANSACTION_ID | The transaction id specific to the storage engine. For InnoDB, you can use this id to join on the trx_id column in the information_schema.INNODB_TRX view. You should not rely on the id having a particular format, and the id may change in the duration of a transaction.                                                            |
| THREAD_ID             | The Performance Schema thread id of the thread that made the lock request.                                                                                                                                                                                                                                                              |
| EVENT_ID              | The Performance Schema event id of the event that made the lock request. You can use this id to join with several of the events\_% tables to find more information on what triggered the lock request.                                                                                                                                  |
| OBJECT_SCHEMA         | The schema the object that is subject of the lock request is in.                                                                                                                                                                                                                                                                        |
| OBJECT_NAME           | The name of the object that is subject of the lock request.                                                                                                                                                                                                                                                                             |
| PARTITION_NAME        | For locks involving partitions, the name of the partition.                                                                                                                                                                                                                                                                              |
| SUBPARTITION_NAME     | For locks involving subpartitions, the name of the subpartition.                                                                                                                                                                                                                                                                        |
| INDEX_NAME            | For locks involving indexes, the name of the index. Since everything is an index for InnoDB, the index name is always set for record level locks on InnoDB tables. If the row is locked, the value will be PRIMARY or GEN_CLUST_INDEX depending on whether you have an explicit primary key or the table used a hidden clustered index. |
| OBJECT_INSTANCE_BEGIN | The memory address of the lock request.                                                                                                                                                                                                                                                                                                 |
| LOCK_TYPE             | The level of the lock request. For InnoDB, the possible values are TABLE and RECORD.                                                                                                                                                                                                                                                    |
| LOCK_MODE             | The locking mode used. This includes whether it is a shared or exclusive lock and the finer details of the lock, for example, REC_NOT_GAP for a record lock but no gap lock.                                                                                                                                                            |
| LOCK_STATUS           | Whether the lock is pending (WAITING) or has been granted (GRANTED).                                                                                                                                                                                                                                                                    |
| LOCK_DATA             | Information about the data that is locked. This can, for example, be the index value of the locked index record.                                                                                                                                                                                                                        |

# sys.innodb_lock_waits

This view joins show imformation joining`information_schema.INNODB_TRX`,`data_locks` and `data_lock_waits` tables.
EXAMPLE:

```sql
SELECT * FROM sys.innodb_lock_waits\G
*************************** 1. row ***************************
                wait_started: 2020-08-07 18:04:56
                    wait_age: 00:00:16
               wait_age_secs: 16
                locked_table: `world`.`city`
         locked_table_schema: world
           locked_table_name: city
      locked_table_partition: NULL
   locked_table_subpartition: NULL
                locked_index: PRIMARY
                 locked_type: RECORD
              waiting_trx_id: 537516
         waiting_trx_started: 2020-08-07 18:04:56
             waiting_trx_age: 00:00:16
     waiting_trx_rows_locked: 2
   waiting_trx_rows_modified: 0
                 waiting_pid: 739
               waiting_query: UPDATE world.city SET Populati ... 1.10 WHERE CountryCode = 'AUS'
             waiting_lock_id: 2711671601760:1923:7:44:2711634704240
           waiting_lock_mode: X,REC_NOT_GAP
             blocking_trx_id: 537515
                blocking_pid: 738
              blocking_query: NULL
            blocking_lock_id: 2711671600928:1923:7:44:2711634698920
          blocking_lock_mode: X,REC_NOT_GAP
        blocking_trx_started: 2020-08-07 18:04:56
            blocking_trx_age: 00:00:16
    blocking_trx_rows_locked: 1
  blocking_trx_rows_modified: 1
     sql_kill_blocking_query: KILL QUERY 738
sql_kill_blocking_connection: KILL 738
1 row in set (0.0805 sec)
```

| Type       | Description                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| wait\*     | These columns show some general information around the age of the lock wait.                                                                                                                                                                                                                                                                                                                                                 |
| locked\*   | These columns show what is locked ranging from the schema to the index as well as the lock type.                                                                                                                                                                                                                                                                                                                             |
| waiting\*  | These columns show details of the transaction that is waiting for the lock to be granted including the query and the lock mode requested.                                                                                                                                                                                                                                                                                    |
| blocking\* | These columns show details of the transaction that is blocking the lock request. Note that in the example, the blocking query is NULL. This means the transaction is idle at the time the output was generated. Even when there is a blocking query listed, the query may not have anything to do with the lock that there is contention for – other than the query is executed by the same transaction that holds the lock. |
| sql*kill*  | These two columns provide the KILL queries that can be used to kill the blocking query or connection.                                                                                                                                                                                                                                                                                                                        |

The `column blocking_query` is the query currently executed (if any) for the blocking transaction.  
It does not mean that the query itself is necessarily causing the lock request to block.  
The case where the `blocking_query` column is NULL is a common situation. It means that the blocking transaction is currently not executing a query.  
This may be because it is between two queries.  
If this period is an extended period, it suggests the application is doing work that ideally should be done outside the transaction.  
More commonly, the transaction is not executing a query because it has been forgotten about, either in an interactive session where the human has forgotten to end the transaction or an application flow that does not ensure transactions are committed or rolled back.
