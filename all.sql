/*
 * Show ENGINE INNODB STATUS 勘所 https://www.slideshare.net/myfinder/show-innodb-status-6345058
 * なぜあなたは SHOW ENGINE INNODB STATUS を読まないのか https://soudai.hatenablog.com/entry/2017/12/20/030013 
 * MySQL InnoDBにおけるロック競合の解析手順 https://sh2.hatenablog.jp/entries/2009/06/18   
 * InnoDBのHistory list lengthの監視と原因スレッドの特定と https://yoku0825.blogspot.com/2020/10/innodbhistory-list-length.html
 * MySQLのperformance-schema-instruments利用によるパフォーマンス影響を調べてみた https://engineering.linecorp.com/ja/blog/mysql-research-performance-schema-instruments/
 */

/*
 *  General
 * */
-- Server System settings
SHOW GLOBAL VARIABLES;
-- MySQL Server status. SEE: 誰も教えてくれなかったMySQLの障害解析方法 https://qiita.com/muran001/items/14f19959d4723ffc29cc
SHOW GLOBAL STATUS where VALUE <> 0;
-- Running Time: check whether mysql rebooted recently.
SHOW GLOBAL STATUS LIKE 'uptime';

-- The INNODB_METRICS table provides a wide variety of InnoDB performance information
select name,count,status,comment from information_schema.innodb_metrics;
select type, count(*) from sys.metrics group by type;

/*
 *  SHOW INNODB STATUS
 */
-- Put them ON if you want to output the relevant status to the error log.
SHOW GLOBAL VARIABLES LIKE "innodb_status_output%";
Show ENGINE INNODB STATUS;

-- SHOW ENGINE INNODB STATUSのHistory List Lengthが大きい時
 /* 
  * 「パージされずに残っているUNDOログレコードの数」、
  *  主に「トランザクション開始したまま COMMIT も ROLLBACK も QUIT もせずに残ってるコネクション」があると増えていく。
  * これが伸びるのはデフォルトの REPEATABLE-READ を保証するためなので、ロックの有無には一切関係ない（ロックフリーな SELECT だけしか含まないトランザクションでも、残っている限り降り積もる）
  * 10万件を超えるとかだったら注意
  * */
SELECT name, subsystem, comment, count FROM information_schema.innodb_metrics WHERE name = 'trx_rseg_history_len';
-- History Listを伸ばしてるthreadを特定する
/*
 *　ここで手に入れた trx_mysql_thread_id が SHOW PROCESSLIST の ID になる。 つまりforeground_thraed_idだと思われる
 */
SELECT * FROM information_schema.innodb_trx ORDER BY trx_started ASC;

/*
 *  Lock Detection
 */
select t_b.trx_mysql_thread_id blocking_id,
       t_w.trx_mysql_thread_id requesting_id,
       p_b.HOST blocking_host,
       p_w.HOST requesting_host,
       l.lock_table lock_table,
       l.lock_index lock_index,
       l.lock_mode lock_mode,
       p_w.TIME seconds,
       p_b.INFO blocking_info,
       p_w.INFO requesting_info
from information_schema.INNODB_LOCK_WAITS w,
     information_schema.INNODB_LOCKS l,
     information_schema.INNODB_TRX t_b,
     information_schema.INNODB_TRX t_w,
     information_schema.PROCESSLIST p_b,
     information_schema.PROCESSLIST p_w
where w.blocking_lock_id = l.lock_id
  and w.blocking_trx_id = t_b.trx_id
  and w.requesting_trx_id = t_w.trx_id
  and t_b.trx_mysql_thread_id = p_b.ID
  and t_w.trx_mysql_thread_id = p_w.ID
order by requesting_id,
         blocking_id;

-- 以下上のクエリの部分解説     
/* INNODB_TRXは現在実行中のトランザクションを表示するテーブルです。
 * InnoDBが内部で持っているトランザクションID(trx_id)やトランザクションの開始時刻(trx_started)、
 * 実行中のSQLがあればそのSQL文(trx_query)が出力されます。InnoDBのトランザクションIDとshow processlistで表示されるスレッドID(trx_mysql_thread_id)との対応づけができるところもポイントです
 * */
select * from information_schema.INNODB_TRX order by trx_id;
/*
 * INNODB_LOCKSはロック競合を起こしているトランザクションの情報を表示するテーブルです。
 * 待たせている方と待たされている方の両方が出力されます。一方、ロックを取得していても他のセッションと競合していないトランザクションは出力されません。
 * */
 SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS;
/*
 * INNODB_LOCK_WAITSはどのトランザクションがどのトランザクションを待たせているのかを出力するテーブルです。
 * blockingが待たせている方、requestingが待たされている方になります。
 * */
 SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;

-- Errors and Warnings
SHOW WARNINGS;
SHOW ERRORS;

-- Threads
SHOW GLOBAL STATUS LIKE 'Thread_%';
SELECT * FROM performance_schema.status_by_thread;

-- Procedure
SHOW PROCEDURE STATUS;

-- Auth
SHOW GRANTS;

-- Table
SHOW TABLE status;
-- Memory
SELECT @@GLOBAL.KEY_BUFFER_SIZE as GLOBAL_KEY_BUFFER_SIZE,@@GLOBAL.INNODB_BUFFER_POOL_SIZE as GLOBAL_INNODB_BUFFER_POOL_SIZE,@@GLOBAL.INNODB_LOG_BUFFER_SIZE as GLOBAL_INNODB_LOG_BUFFER_SIZE,@@GLOBAL.SORT_BUFFER_SIZE + @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + @@GLOBAL.READ_BUFFER_SIZE + @@GLOBAL.JOIN_BUFFER_SIZE + @@GLOBAL.READ_RND_BUFFER_SIZE as THREAD_BUFFER_SIZE,
@@GLOBAL.KEY_BUFFER_SIZE + @@GLOBAL.INNODB_BUFFER_POOL_SIZE + @@GLOBAL.INNODB_LOG_BUFFER_SIZE + @@GLOBAL.NET_BUFFER_LENGTH + (@@GLOBAL.SORT_BUFFER_SIZE + @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + @@GLOBAL.READ_BUFFER_SIZE + @@GLOBAL.JOIN_BUFFER_SIZE + @@GLOBAL.READ_RND_BUFFER_SIZE) * @@GLOBAL.MAX_CONNECTIONS AS TOTAL_MEMORY_SIZE,
 (@@GLOBAL.KEY_BUFFER_SIZE + @@GLOBAL.INNODB_BUFFER_POOL_SIZE + @@GLOBAL.INNODB_LOG_BUFFER_SIZE + @@GLOBAL.NET_BUFFER_LENGTH + (@@GLOBAL.SORT_BUFFER_SIZE + @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + @@GLOBAL.READ_BUFFER_SIZE + @@GLOBAL.JOIN_BUFFER_SIZE + @@GLOBAL.READ_RND_BUFFER_SIZE) * @@GLOBAL.MAX_CONNECTIONS)/1024 AS TOTAL_MEMORY_SIZE_kb, (@@GLOBAL.KEY_BUFFER_SIZE + @@GLOBAL.INNODB_BUFFER_POOL_SIZE + @@GLOBAL.INNODB_LOG_BUFFER_SIZE + @@GLOBAL.NET_BUFFER_LENGTH
+ (@@GLOBAL.SORT_BUFFER_SIZE + @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + @@GLOBAL.READ_BUFFER_SIZE + @@GLOBAL.JOIN_BUFFER_SIZE + @@GLOBAL.READ_RND_BUFFER_SIZE) * @@GLOBAL.MAX_CONNECTIONS)/1024/1024 AS TOTAL_MEMORY_SIZE_mb,(@@GLOBAL.KEY_BUFFER_SIZE + @@GLOBAL.INNODB_BUFFER_POOL_SIZE + @@GLOBAL.INNODB_LOG_BUFFER_SIZE + @@GLOBAL.NET_BUFFER_LENGTH + (@@GLOBAL.SORT_BUFFER_SIZE + @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + @@GLOBAL.READ_BUFFER_SIZE + @@GLOBAL.JOIN_BUFFER_SIZE + @@GLOBAL.READ_RND_BUFFER_SIZE) * @@GLOBAL.MAX_CONNECTIONS)/1024/1024/1024 AS TOTAL_MEMORY_SIZE_gb;

SELECT SUBSTRING_INDEX(EVENT_NAME, '/', -1) AS EVENT,CURRENT_NUMBER_OF_BYTES_USED/1024/1024 AS CURRENT_MB, HIGH_NUMBER_OF_BYTES_USED/1024/1024 AS HIGH_MB FROM performance_schema.memory_summary_global_by_event_name WHERE EVENT_NAME LIKE 'memory/performance_schema/%'ORDER BY CURRENT_NUMBER_OF_BYTES_USED DESC LIMIT 10;

/*
 * PROCESSLIST: 実行中のクエリ表示
 * 
 * Command: Query 
 * State: Lockedのものはデッドロックかロック待ち。 SHOW ENGINE INNODB STATUSでロック原因を確認せよ
 *  上でロック原因が出ない場合そもそも設定ミス
 * ロック時にSHOW ENGINE INNODB STATUSコマンドでロック原因を特定できるようにする
 * 
 * # vi /etc/my.cnf
 * # デッドロック関連のログをエラーログに出力させる
 * innodb_print_all_deadlocks=ON
 * # ロックモニターの有効化：SHOW ENGINE INNODB STATUSでロック原因を特定できるように
 * innodb_status_output=ON
 * innodb_status_output_locks=ON
 * 
 * デッドロック発生時にタイムアウトを設定する
 * # vi /etc/my.cnf
 * ## デッドロック ====================================
 * #テーブルロックタイムアウト時間 必須 初期値50秒
 * innodb_lock_wait_timeout = 5
 * */
 SHOW PROCESSLIST;

/*
 * performance_schema
 */
-- 有効になってる指標の確認
SELECT * FROM performance_schema.setup_instruments;
SELECT * FROM performance_schema.setup_consumers;

-- performance_schema自体の状態
SHOW ENGINE PERFORMANCE_SCHEMA STATUS;
-- 怪しいクエリ
SELECT * FROM performance_schema.events_statements_history_long WHERE ROWS_EXAMINED > ROWS_SENT OR ROWS_EXAMINED > ROWS_AFFECTED OR ERRORS > 0 OR CREATED_TMP_DISK_TABLES > 0 OR CREATED_TMP_TABLES > 0 OR SELECT_FULL_JOIN > 0 OR SELECT_FULL_RANGE_JOIN > 0 OR SELECT_RANGE > 0 OR SELECT_RANGE_CHECK > 0 OR SELECT_SCAN > 0 OR SORT_MERGE_PASSES > 0 OR SORT_RANGE > 0 OR SORT_ROWS > 0 OR SORT_SCAN > 0 OR NO_INDEX_USED > 0 OR NO_GOOD_INDEX_USED > 0;
-- INDEXを有効利用できてないクエリ
SELECT THREAD_ID, SQL_TEXT, ROWS_SENT, ROWS_EXAMINED,CREATED_TMP_TABLES,NO_INDEX_USED, NO_GOOD_INDEX_USED FROM performance_schema.events_statements_history_long WHERE NO_INDEX_USED > 0 OR NO_GOOD_INDEX_USED > 0;
-- 一時テーブルを作ってしまってるクエリ
SELECT THREAD_ID, SQL_TEXT, ROWS_SENT, ROWS_EXAMINED, CREATED_TMP_TABLES,CREATED_TMP_DISK_TABLES FROM performance_schema.events_statements_history_long WHERE CREATED_TMP_TABLES > 0 OR CREATED_TMP_DISK_TABLES > 0; 
-- auto_incrementが設定されているカラムのキースペース確認
SELECT t.TABLE_SCHEMA AS `schema`,t.TABLE_NAME AS `table`,t.AUTO_INCREMENT AS `auto_increment`,c.DATA_TYPE AS `pk_type`,(t.AUTO_INCREMENT /(CASE DATA_TYPE WHEN 'tinyint'THEN IF(COLUMN_TYPE LIKE '%unsigned',255,127)WHEN 'smallint'THEN IF(COLUMN_TYPE LIKE '%unsigned',65535,32767)WHEN 'mediumint'THEN IF(COLUMN_TYPE LIKE '%unsigned',16777215,8388607)WHEN 'int'THEN IF(COLUMN_TYPE LIKE '%unsigned',4294967295,2147483647)WHEN 'bigint'
	THEN IF(COLUMN_TYPE LIKE '%unsigned',18446744073709551615,9223372036854775807)END / 100)) AS `is_max_value`FROM information_schema.TABLES t INNER JOIN information_schema.COLUMNS c ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME WHERE t.AUTO_INCREMENT IS NOT NULL AND c.COLUMN_KEY = 'PRI' AND c.DATA_TYPE LIKE '%int';
