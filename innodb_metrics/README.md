# INFORMATION_SCHEMA.INNODB_METRICS

TODO: https://engineering.linecorp.com/ja/blog/mysql-research-performance-schema-instruments

# SHOW ENGINE INNODB STATUS

> InnoDB metrics are exposed in the `information_schema.innodb_metrics` table.  
> Before this table was mainstream, InnoDB metrics were exposed using the `SHOW ENGINE INNODB STATUS` command, but the output is a long blob of text.  
> The text is divided into sections, which makes it a little easier for humans to read, but it’s programmatically unorganized: it requires parsing and pattern matching to extract specific metric values.  
> Some MySQL monitors still use SHOW ENGINE INNODB STATUS, but avoid this if you can because using the `Information Schema` (and Performance Schema) is the best practice.
> I no longer consider `SHOW ENGINE INNODB STATUS` authoritative.  
> For example, with respect to active transactions, `BEGIN; SELECT col FROM tbl;` does not show as active in `SHOW ENGINE INNODB STATUS`,  
> but it correctly shows as active in `innodb.trx_active_transactions`.
> The transaction list only includes one active transaction (the one for the UPDATE statement).  
> In MySQL 5.7 and later, read-only non-locking transactions are not included in the InnoDB monitor transaction list.  
> For this reason, it is better to use the INNODB_TRX view , if you need to include all active transactions.

The InnoDB monitor report is created with the `SHOW ENGINE INNODB STATUS` statement.  
Alternatively, it can be written to the stderr (usually redirected to the error log) every 15 seconds by enabling the `innodb_status_output` option.  
The report itself is divided into several sections, including:

| Name                                  | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BACKGROUND THREAD                     | The work done by the main background thread.                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| SEMAPHORES                            | Semaphore statistics. The section is most important in cases where contention causes long semaphore waits in which case the section can be used to get information about the locks and who holds them.                                                                                                                                                                                                                                                                                                                    |
| LATEST FOREIGN KEY ERROR              | If a foreign key error has been encountered, this section includes details of the error. Otherwise, the section is omitted.                                                                                                                                                                                                                                                                                                                                                                                               |
| LATEST DETECTED DEADLOCK              | If a deadlock has occurred, this section includes details of the two transactions and the locks that caused the deadlock. Otherwise, the section is omitted.                                                                                                                                                                                                                                                                                                                                                              |
| TRANSACTIONS                          | Information about the InnoDB transactions. Only transactions with at least one exclusive lock on InnoDB tables are included. If the `innodb_status_output_locks` option is enabled, the locks held for each transaction are listed; otherwise, it is just locks involved in lock waits. It is in general better to use the `information_schema.INNODB_TRX` view to query the transaction information and for lock information to use the `performance_schema.data_locks` and `performance_schema.data_lock_waits` tables. |
| FILE I/O                              | Information about the I/O threads used by InnoDB including the insert buffer thread, log thread, read threads, and write threads.                                                                                                                                                                                                                                                                                                                                                                                         |
| INSERT BUFFER AND ADAPTIVE HASH INDEX | Information about the change buffer (this was formerly called the insert buffer) and the adaptive hash index.                                                                                                                                                                                                                                                                                                                                                                                                             |
| LOG                                   | Information about the redo log.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| BUFFER POOL AND MEMORY                | Information about the InnoDB buffer pool. This information is better obtained from the information_schema.INNODB_BUFFER_POOL_STATS view.                                                                                                                                                                                                                                                                                                                                                                                  |
| INDIVIDUAL BUFFER POOL INFO           | If `innodb_buffer_pool_instances` is greater than 1, this section includes information about the individual buffer pool instances with the same information as for the global summary in the previous section. Otherwise, the section is omitted. This information is better obtained from the `information_schema.INNODB_BUFFER_POOL_STATS` view.                                                                                                                                                                        |
| ROW OPERATIONS                        | This section shows various information about InnoDB including the current activity and what the main thread is .                                                                                                                                                                                                                                                                                                                                                                                                          |

## LATEST DETECTED DEADLOCK

This section in the InnoDB monitor output only includes information for deadlocks involving InnoDB record locks.  
For deadlocks involving non-InnoDB locks such as user-level locks, there is no equivalent information.

## SEMAPHORES

EXAMPLE:

```
----------
SEMAPHORES
----------
OS WAIT ARRAY INFO: reservation count 831
--Thread 28544 has waited at buf0buf.cc line 4637 for 0 seconds the semaphore:
Mutex at 000001F1AD24D5E8, Mutex BUF_POOL_LRU_LIST created buf0buf.cc:1228, lock var 1
--Thread 10676 has waited at buf0flu.cc line 1639 for 1 seconds the semaphore:
Mutex at 000001F1AD24D5E8, Mutex BUF_POOL_LRU_LIST created buf0buf.cc:1228, lock var 1
--Thread 10900 has waited at buf0lru.cc line 1051 for 0 seconds the semaphore:
Mutex at 000001F1AD24D5E8, Mutex BUF_POOL_LRU_LIST created buf0buf.cc:1228, lock var 1
--Thread 28128 has waited at buf0buf.cc line 2797 for 1 seconds the semaphore:
Mutex at 000001F1AD24D5E8, Mutex BUF_POOL_LRU_LIST created buf0buf.cc:1228, lock var 1
--Thread 33584 has waited at buf0buf.cc line 2945 for 0 seconds the semaphore:
Mutex at 000001F1AD24D5E8, Mutex BUF_POOL_LRU_LIST created buf0buf.cc:1228, lock var 1
OS WAIT ARRAY INFO: signal count 207
RW-shared spins 51, rounds 86, OS waits 35
RW-excl spins 39, rounds 993, OS waits 35
RW-sx spins 30, rounds 862, OS waits 25
Spin rounds per wait: 1.69 RW-shared, 25.46 RW-excl, 28.73 RW-sx
```

You have to refer sourcecode to analyze semaphores (`buf0buf.cc:1228`).

The semaphores section is useful to see the waits that are ongoing, but it is of little use when monitoring over time.  
For that the InnoDB mutex monitor is a better option. You access the mutex monitor using the SHOW ENGINE INNODB MUTEX statement:

```
mysql> SHOW ENGINE INNODB MUTEX;
+--------+------------------------------+------------+
| Type | Name | Status |
+--------+------------------------------+------------+
| InnoDB | rwlock: dict0dict.cc:2455 | waits=748 |
| InnoDB | rwlock: dict0dict.cc:2455 | waits=171 |
| InnoDB | rwlock: fil0fil.cc:3206 | waits=38 |
| InnoDB | rwlock: sync0sharded_rw.h:72 | waits=1 |
| InnoDB | rwlock: sync0sharded_rw.h:72 | waits=1 |
| InnoDB | rwlock: sync0sharded_rw.h:72 | waits=1 |
| InnoDB | sum rwlock: buf0buf.cc:778 | waits=2436 |
+--------+------------------------------+------------+
7 rows in set (0.0111 sec)
```

The file name and line number refers to where the mutex is created.  
The mutex monitor is not the most user-friendly tool in MySQL as each mutex may be present multiple times and the waits cannot be summed without parsing the output.  
However, it is enabled by default, so you can use it at any time.  
`SHOW ENGINE INNODB MUTEX` only includes mutexes and rw-lock semaphores that has had at least one OS wait.

| File Name         | Source Code Path          | Functional Area                          |
| ----------------- | ------------------------- | ---------------------------------------- |
| btr0sea.cc        | btr/btr0sea.cc            | The adaptive hash index.                 |
| buf0buf.cc        | buf/buf0buf.cc            | The buffer pool.                         |
| buf0flu.cc        | buf/buf0flu.cc            | The buffer pool flushing algorithm.      |
| dict0dict.cc      | dict/dict0dict.cc         | The InnoDB data dictionary.              |
| sync0sharded_rw.h | include/sync0sharded_rw.h | The sharded read-write lock for threads. |
| hash0hash.cc      | ha/hash0hash.cc           | For protecting hash tables.              |
| fil0fil.cc        | fil/fil0fil.cc            | The tablespace memory cache.             |
