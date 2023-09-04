/*	1) Написать функцию, возвращающую таблицу TransferredPoints 
	в более человекочитаемом виде.
	
	Ник пира 1, ник пира 2, количество переданных пир поинтов. 
	
	Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
*/

CREATE OR REPLACE FUNCTION fnc_transferred_points()
RETURNS TABLE(Peer1 varchar, Peer2 varchar, PointsAmount integer) 
AS 
$$
	WITH Tmp AS 
		(SELECT peer1, peer2,
		(COALESCE(pointsamount, 0) - COALESCE(pointsamount_rev, 0)) AS pointsamount
		FROM
		(SELECT checkingpeer AS peer1, checkedpeer AS peer2, 
		SUM(pointsamount) AS pointsamount
		FROM TransferredPoints
		GROUP BY peer1, peer2) AS T1
		LEFT OUTER JOIN
		(SELECT checkedpeer AS p1, checkingpeer AS p2, 
		SUM(pointsamount) AS pointsamount_rev
		FROM TransferredPoints
		GROUP BY p1, p2) AS T2
		ON T1.peer1 = T2.p1 AND T1.peer2 = T2.p2)
		
	SELECT peer1, peer2, pointsamount FROM Tmp S
		WHERE S.peer2 < S.peer1 OR
		NOT EXISTS(
			SELECT 1 FROM Tmp
			WHERE peer1 = S.peer2 AND peer2 = S.peer1)
	ORDER BY 1, 2;
$$ 
LANGUAGE SQL;

--	Test 1

SELECT * FROM fnc_transferred_points();

/*	2) Написать функцию, которая возвращает таблицу вида: 
		-ник пользователя
		-название проверенного задания
		-кол-во полученного XP
		
	В таблицу включать только задания, успешно прошедшие проверку
	(определять по таблице Checks). 
		
	Одна задача может быть успешно выполнена несколько раз.
	
	В таком случае в таблицу включать все успешные проверки.
*/

CREATE OR REPLACE FUNCTION fnc_checked_task_xp()
RETURNS TABLE(Peer VARCHAR, Task VARCHAR, XP INTEGER)
AS
$$
	SELECT Checks.Peer, Checks.Task, XP.XPAmount
	FROM Checks
	JOIN XP ON Checks.id = XP."Check"
	ORDER BY 1, 2;
$$
LANGUAGE SQL;
  
-- Test 1

SELECT * FROM fnc_checked_task_xp();

/*	3) Написать функцию, определяющую пиров, 
	которые не выходили из кампуса в течение всего дня.
	
	Функция возвращает только список пиров.
*/

CREATE OR REPLACE FUNCTION fnc_peers_all_day(ddate date)
RETURNS TABLE(Peer VARCHAR)
AS
$$
    SELECT p1 AS peer FROM
	(
	SELECT p1, ts1, MIN(ts2) AS ts2 FROM 
	((SELECT peer AS p1, ("Date"+"Time")::TIMESTAMP AS ts1 FROM timetracking
       WHERE timetracking.state = 1) AS t1
   	JOIN (SELECT peer AS p2, ("Date"+"Time")::TIMESTAMP AS ts2 FROM timetracking
             WHERE timetracking.state = 2) AS t2 
             ON t1.p1 = t2.p2)
	WHERE t2.ts2> t1.ts1
	GROUP by 1,2
	) AS tt
	WHERE ddate < tt.ts2::date AND ddate > tt.ts1::date
	ORDER BY 1;
$$
LANGUAGE SQL;

-- Test 1

SELECT * FROM fnc_peers_all_day(ddate:='12.13.2022');

/*	4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints.
	
	Результат вывести отсортированным по изменению числа поинтов. 
	
	Формат вывода: ник пира, изменение в количество пир поинтов
*/

CREATE OR REPLACE PROCEDURE peer_points_change(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
 		OPEN _result_one FOR 
 			SELECT Peer1 AS peer, (COALESCE(pointschange, 0) - COALESCE(pointschange_rev, 0)) AS pointschange FROM
 			(SELECT checkingpeer AS Peer1,
 			SUM(pointsamount) AS PointsChange
 			FROM TransferredPoints
 		GROUP BY Peer1) AS t1
 		LEFT OUTER JOIN
 			(SELECT checkedpeer AS P1,
 			SUM(pointsamount) AS PointsChange_rev
 			FROM TransferredPoints
 		GROUP BY P1) AS t2 ON t1.Peer1 = t2.P1
		ORDER BY 2 DESC;
	END;
$$;

-- Test 1

BEGIN;
 CALL peer_points_change('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;


/*	5) Посчитать изменение в количестве пир поинтов каждого пира по таблице,
	возвращаемой первой функцией из Part 3.
	
	Результат вывести отсортированным по изменению числа поинтов. 
	
	Формат вывода: ник пира, изменение в количество пир поинтов.
*/

CREATE OR REPLACE PROCEDURE peer_points_change_t1(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
 		OPEN _result_one FOR 
 			SELECT COALESCE(peer1, peer2) AS peer, (COALESCE(pointschange, 0) - COALESCE(pc, 0)) AS pointschange 
			FROM (SELECT peer1, SUM(pointsamount) AS pointschange
			FROM fnc_transferred_points()
		GROUP BY peer1) AS T1
		FULL JOIN
			(SELECT peer2, SUM(pointsamount) AS pc
			FROM fnc_transferred_points()
		GROUP BY peer2) AS T2 ON T1.peer1 = T2.peer2
		ORDER BY 2 DESC;
	END;
$$;

-- Test 1

BEGIN;
 CALL peer_points_change_t1('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	6) Определить самое часто проверяемое задание за каждый день
	
	При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все. 
	
	Формат вывода: день, название задания
*/

CREATE OR REPLACE PROCEDURE most_freq_checked(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
 		OPEN _result_one FOR 
 			SELECT to_char("Date", 'dd.MM.yy') AS day, task FROM
			(SELECT task, "Date", MAX(n) FROM
			(SELECT task, "Date", COUNT(task) AS n FROM CHECKS GROUP BY 1, 2) AS k
		GROUP BY 1, 2) AS m
		ORDER BY "Date";
	END;
$$;

-- Test 1

BEGIN;
 CALL most_freq_checked('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	7) Найти всех пиров, выполнивших весь заданный блок задач и 
	дату завершения последнего задания.
	
	Параметры процедуры: название блока, например "CPP". 
	
	Результат вывести отсортированным по дате завершения. 
	
	Формат вывода: ник пира, дата завершения блока 
	(т.е. последнего выполненного задания из этого блока)
*/

CREATE OR REPLACE PROCEDURE copleted_whole_block(IN block VARCHAR, INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
 		OPEN _result_one FOR 
 			SELECT t3.peer, t4.d AS day FROM
  			(SELECT peer FROM (SELECT peer, COUNT(*) AS co
			FROM (SELECT DISTINCT peer, task FROM Checks
			WHERE (id) IN (SELECT "Check" FROM Xp) AND 
			Task ~ CONCAT(CONCAT('\A', block), '[0-9]')) AS t1
		GROUP BY Peer) AS t2
			WHERE (co) IN (SELECT COUNT(title) FROM Tasks
			WHERE Title ~ CONCAT(CONCAT('\A', block), '[0-9]'))) AS t3
		JOIN 
			(SELECT peer, MAX("Date") d FROM Checks ch
			 WHERE Task ~ CONCAT(CONCAT('\A', block), '[0-9]')
		GROUP BY peer) AS t4 ON t3.peer = t4.peer;
	END;
$$;

-- Test 1

BEGIN;
 CALL copleted_whole_block('C', 'ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся.
	
	Определять нужно исходя из рекомендаций друзей пира 
	т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. 
	
	Формат вывода: ник пира, ник найденного проверяющего.
*/

CREATE OR REPLACE PROCEDURE most_reccomended(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		 OPEN _result_one FOR 
			WITH t3 AS 
				(SELECT peer1, recommendedpeer, COUNT(*) AS co FROM
				(SELECT DISTINCT peer1, peer2 
				FROM (SELECT peer1, peer2 FROM Friends
				UNION
				SELECT peer2 AS peer1, peer1 AS peer2
				FROM FRIENDS) AS t1) AS t2
				CROSS JOIN Recommendations Rec
				WHERE Rec.peer = t2.peer2 AND Rec.RecommendedPeer != t2.peer1
				GROUP BY 1, 2)

			SELECT peer1 AS peer, recommendedpeer 
			FROM t3 WHERE (peer1, co) IN
			(SELECT peer1 AS peer, MAX(co) FROM t3
			GROUP BY Peer)
			ORDER BY 1, 2;
	END;
$$;

-- Test 1

BEGIN;
 CALL most_reccomended('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	9) Определить процент пиров, которые:
	- Приступили только к блоку 1
	- Приступили только к блоку 2
	- Приступили к обоим
	- Не приступили ни к одному

	Пир считается приступившим к блоку, если он проходил хоть 
	одну проверку любого задания из этого блока (по таблице Checks).
	
	Параметры процедуры: название блока 1, например SQL, 
	название блока 2, например A. 
	
	Формат вывода: процент приступивших только к первому блоку,
	процент приступивших только ко второму блоку,
	процент приступивших к обоим, процент не приступивших ни к одному
*/

-- Содание таблицы для вывода результатов

CREATE TABLE IF NOT EXISTS result(
	only_block1_percent int,
	only_block2_percent int,
	both_blocks_percent int,
	neither_block_percent int
);

CREATE OR REPLACE PROCEDURE peer_percent(block1_name text, block2_name text)
LANGUAGE plpgsql
AS 
$$
	DECLARE
		all_peers integer;
		only_block1_count integer;
		only_block2_count integer;
		both_blocks_count integer;
		neither_block_count integer;
		only_block1_percent numeric;
		only_block2_percent numeric;
		both_blocks_percent numeric;
		neither_block_percent numeric;
	BEGIN
		SELECT COUNT(*) FROM Peers
		INTO all_peers;

		SELECT COUNT(DISTINCT peer)
		FROM Checks
		WHERE task LIKE '%' || block1_name || '%'
		INTO only_block1_count;

		SELECT COUNT(DISTINCT peer)
		FROM Checks
		WHERE task LIKE '%' || block2_name || '%'
		INTO only_block2_count;

		SELECT COUNT(DISTINCT peer)
		FROM (
			SELECT peer
			FROM Checks
			WHERE task LIKE '%' || block1_name || '%'
			INTERSECT
			SELECT peer
			FROM Checks
			WHERE task LIKE '%' || block2_name || '%'
		) AS both_blocks
		INTO both_blocks_count;

		SELECT COUNT(DISTINCT nickname)
		FROM Peers
		WHERE nickname NOT IN (
			SELECT DISTINCT peer
			FROM Checks
			WHERE task LIKE '%' || block1_name || '%'
			OR task LIKE '%' || block2_name || '%'
		)
		INTO neither_block_count;

		only_block1_percent := (only_block1_count::numeric / all_peers) * 100;
		only_block2_percent := (only_block2_count::numeric / all_peers) * 100;
		both_blocks_percent := (both_blocks_count::numeric / all_peers) * 100;
		neither_block_percent := (neither_block_count::numeric / all_peers) * 100;
		INSERT INTO result VALUES(only_block1_percent, only_block2_percent,
								  both_blocks_percent, neither_block_percent);
	END;
$$;

-- Test 1

CALL peer_percent('C', 'CPP');
SELECT * FROM result;

-- Удаление таблицы с результатами
DROP TABLE result;

/*	10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения.
	
	Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения. 
	
	Формат вывода: процент пиров, успешно прошедших проверку в день рождения, 
	процент пиров, проваливших проверку в день рождения
*/

CREATE OR REPLACE PROCEDURE birthday_checks(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
BEGIN
 open _result_one for 
 	WITH t1 AS
	(SELECT id, peer, "Date" AS d, Peers.Birthday as bd FROM Checks
	JOIN Peers ON Peers.Nickname = Checks.peer
	WHERE to_char("Date", 'mon-dd') = to_char(Peers.Birthday, 'mon-dd'))
	
	SELECT SuccessfulChecks, (100 - SuccessfulChecks) AS UnsuccessfulChecks
	FROM
	(SELECT (succesful_checks * 100 / all_checks) as SuccessfulChecks FROM
	(SELECT COUNT(DISTINCT peer) as all_checks, t2.co as succesful_checks FROM t1
	CROSS JOIN
	(SELECT COUNT(DISTINCT peer) as co FROM t1
	WHERE (id) in (SELECT "Check" FROM XP)) as t2
	GROUP BY 2) as t3) as t4;
END;
$$;

-- Test 1
BEGIN;
 CALL birthday_checks('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	11) Определить всех пиров, которые сдали заданные задания 1 и 2, 
	но не сдали задание 3.
	
	Параметры процедуры: названия заданий 1, 2 и 3. 
	
	Формат вывода: список пиров.
*/

CREATE OR REPLACE PROCEDURE peers_did_tasks(IN task1 VARCHAR, IN task2 VARCHAR,
IN task3 VARCHAR, INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		OPEN _result_one FOR 
			WITH t0 AS (SELECT nickname AS peer, Checks.task AS task FROM Peers
			LEFT OUTER JOIN Checks ON Peers.nickname = Checks.peer)

		SELECT DISTINCT t0.peer FROM t0
		JOIN (SELECT DISTINCT peer FROM t0 WHERE task = task2) AS t1
		ON t0.peer = t1.peer
		LEFT JOIN (SELECT DISTINCT peer, 1 AS st FROM t0 WHERE task = task3) AS t2
		ON t0.peer = t2.peer
		WHERE task = task1 AND t2.st IS NULL;
	END;
$$;

-- Test 1
BEGIN;
 CALL peers_did_tasks('C3_s21_string+', 'C6_s21_matrix', 'CPP1_s21_matrix+', 'ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	12) Используя рекурсивное обобщенное табличное выражение,
	для каждой задачи вывести кол-во предшествующих ей задач.
	
	То есть сколько задач нужно выполнить, исходя из условий входа,
	чтобы получить доступ к текущей.
	
	Формат вывода: название задачи, количество предшествующих
*/

CREATE OR REPLACE PROCEDURE preceding_tasks(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		OPEN _result_one FOR 
			WITH RECURSIVE prev AS (
				SELECT title, parenttask FROM tasks
			UNION ALL
				SELECT e.title, s.parenttask
				FROM tasks e
				INNER JOIN prev s ON s.title = e.parenttask
			)

			SELECT title as task, COUNT(parenttask) as prevcount
			FROM prev GROUP BY title
			ORDER BY 1, 2;
	END;
$$;

-- Test 1
BEGIN;
 CALL preceding_tasks('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	13) Найти "удачные" для проверок дни. День считается "удачным",
	если в нем есть хотя бы N идущих подряд успешных проверки.
	
	Параметры процедуры: количество идущих подряд успешных проверок N. 

	Временем проверки считать время начала P2P этапа. 
	
	Под идущими подряд успешными проверками подразумеваются успешные проверки,
	между которыми нет неуспешных. 
	
	При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального. 

	Формат вывода: список дней.
*/

CREATE OR REPLACE PROCEDURE lucky_days_for_checks(IN n int, INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		OPEN _result_one FOR 
		WITH t0 AS (SELECT checks."Date" AS luckydate, P2P."Time", (checks."Date"+P2P."Time")::TIMESTAMP AS ts,
					CASE WHEN (Checks.id) 
					IN (SELECT "Check" FROM (SELECT "Check", xpamount FROM xp
						JOIN Checks ON xp."Check" = checks.id
						JOIN tasks ON Checks.task = Tasks.title
						WHERE xp.xpamount >= (0.8 * tasks.maxxp)) AS t1)
					THEN 1 ELSE 0 END success
						FROM Checks JOIN P2P ON Checks.id = P2P."Check"
						WHERE P2P.state = 'Start'
					ORDER BY 3)
			SELECT t6.luckydate FROM (SELECT t5.luckydate, t5.success, t5.co, COUNT(*) AS res FROM
				(SELECT t0.luckydate, t0.ts, t0.success, t4.co FROM t0
			FULL JOIN
			(SELECT luckydate, ts, COUNT(t3.ts2) AS co FROM 			
			(SELECT t0.luckydate, t0.ts, t2.ts AS ts2, t0.success FROM t0
			CROSS JOIN (SELECT luckydate, ts, success FROM t0 WHERE success = 0) AS t2
			WHERE t2.ts < t0.ts AND t0.success = 1 ORDER BY 2) AS t3 GROUP BY 1, 2
				ORDER BY 2) AS t4 ON t0.ts = t4.ts) AS t5
			GROUP BY 1, 2, 3 ORDER BY 1) AS t6
		WHERE res >= n;
	END;
$$;

-- Test 1
BEGIN;
 CALL lucky_days_for_checks(3, 'ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;


/*	14) Определить пира с наибольшим количеством XP.

	Формат вывода: ник пира, количество XP.
*/

CREATE OR REPLACE PROCEDURE highest_xp_peer(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		 OPEN _result_one FOR 
		 SELECT peer, SUM(xp) AS xp FROM
			(SELECT peer, task, MAX(xp) AS xp FROM fnc_checked_task_xp()
			GROUP BY peer, task ORDER BY 1,2,3) AS t1
			GROUP BY peer
			ORDER BY xp DESC
			LIMIT 1;
	END;
$$;

-- Test 1

BEGIN;
 CALL highest_xp_peer('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	15) Определить пиров, приходивших раньше заданного времени не менее N раз за всё время.
	
	Параметры процедуры: время, количество раз N. 
	
	Формат вывода: список пиров
*/

CREATE OR REPLACE PROCEDURE came_before_time_n_times(IN cc TIME, IN n int,
	INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		 OPEN _result_one FOR 
		 SELECT peer FROM
			(SELECT peer, COUNT(*) AS c1 FROM TimeTracking tt
				WHERE tt."Time" < cc
			GROUP BY peer) AS t1 WHERE t1.c1 >= n;
	END;
$$;

-- Test 1
BEGIN;
 CALL came_before_time_n_times('15:00', 1, 'ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	16) Определить пиров, выходивших за последние N дней из кампуса больше M раз.
	
	Параметры процедуры: количество дней N, количество раз M. 
	
	Формат вывода: список пиров.
*/

CREATE OR REPLACE PROCEDURE left_n_days_m_times(IN n int, IN m int,
	INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		OPEN _result_one FOR SELECT peer FROM
			(SELECT peer, SUM(c1) AS s FROM
				(SELECT peer, "Date" AS d1, COUNT(*) AS c1
				FROM TimeTracking tt
				WHERE tt.state = 2
			GROUP BY peer, d1) AS t1
		WHERE t1.d1 <= CURRENT_DATE::date AND 
			t1.d1 > CURRENT_DATE - concat(coalesce(CAST(n AS text), 'N/A'), 'day')::interval
		GROUP BY peer) AS t2
		WHERE t2.s > m;
	END;
$$;

-- Test 1

BEGIN;
 CALL left_n_days_m_times(840, 2, 'ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;

/*	17) Определить для каждого месяца процент ранних входов.

	Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц,
	приходили в кампус за всё время (будем называть это общим числом входов).
	
	Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц,
	приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов). 
	
	Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов. 
	
	Формат вывода: месяц, процент ранних входов.
*/

CREATE OR REPLACE PROCEDURE early_entries(INOUT _result_one refcursor)
LANGUAGE plpgsql
AS
$$
	BEGIN
		OPEN _result_one FOR 
			WITH t2 AS (SELECT nickname, to_char(birthday, 'Month') AS month, 
						birthday, t1.d AS date_came, t1.t AS time_came FROM peers
				CROSS JOIN 
						(SELECT peer, "Date" AS d, "Time" AS t FROM timetracking
					  	WHERE state = 1) AS t1
			WHERE t1.peer = nickname)

		SELECT t4.month, (t4.co2 * 100 / t4.co1) AS earlyentries FROM
			(SELECT t2.month, COUNT(*) AS co1, COALESCE(t3.co2, 0) AS co2 FROM t2
		LEFT JOIN 
			 (SELECT t2.month, COUNT(*) AS co2 FROM t2 WHERE t2.time_came < '12:00'
			 GROUP BY 1) AS t3
		ON t3.month = t2.month GROUP BY 1, 3) AS t4
		ORDER BY to_date(month, 'Month');
	END;
$$;

-- Test 1

BEGIN;
 CALL early_entries('ref');
 FETCH ALL IN ref;
 
-- Использовать после выполнения теста
ROLLBACK;
