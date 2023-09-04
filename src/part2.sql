/* 
	1) Написать процедуру добавления P2P проверки.
	
	Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время. 
	
	Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю). 
	Добавить запись в таблицу P2P.
	
	Если задан статус "начало", в качестве проверки указать только что добавленную запись, иначе указать проверку 
	с незавершенным P2P этапом.
*/

CREATE PROCEDURE add_p2p_review
(checked_peer varchar, checking_peer varchar, task_name text, review_status check_status, review_time TIME)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (review_status = 'Start') -- если задан статус начало,
		THEN -- добавить запись в таблицу Checks, если подобной записи о проверки нет в таблицах Checks и p2p
		IF ((SELECT COUNT(*) FROM p2p 
			 INNER JOIN checks ch ON p2p."Check" = ch.id 
			 WHERE p2p.checkingpeer = checking_peer	AND ch.peer = checked_peer 
			 	AND ch.task = task_name) = 0)
			THEN
				INSERT INTO Checks 
					VALUES ((SELECT MAX(id) FROM Checks) + 1, checked_peer, task_name, NOW());
				INSERT INTO p2p -- добавляем запись о начале проверки в таблицу p2p
					VALUES ((SELECT MAX(id) FROM p2p) + 1, (SELECT MAX(id) FROM checks), 
							checking_peer, review_status, review_time);
     	ELSE
     		RAISE EXCEPTION 'Ошибка: Проверка уже началась';
     	END IF;
	ELSE -- иначе указать проверку с незавершенным P2P этапом
     	INSERT INTO p2p
            VALUES ((SELECT MAX(id) FROM p2p) + 1, (SELECT "Check" FROM p2p
            	INNER JOIN checks ON p2p."Check" = checks.id
                WHERE p2p.checkingpeer = checking_peer AND checks.peer = checked_peer
					AND checks.task = task_name), checking_peer, review_status, review_time);
	END IF;
END;
$$

/*	Test 1 
	Добавление записей в таблицы Checks, p2p (happy case).
*/

CALL add_p2p_review('gantedil', 'hvayon', 'CPP2_s21_containers', 'Start', '18:00:00');
SELECT * FROM Checks;
SELECT * FROM p2p;

/*	Test 2
	Начало новой проверки между двумя пирами, которые еще не завершили предыдущую.
	
	Добавление записи в таблицы Checks, p2p.
	
	Получение ошибки 'Ошибка: Проверка уже началась'.
*/

CALL add_p2p_review('gantedil', 'hvayon', 'CPP2_s21_containers', 'Start', '18:00:00');

/*	Test 3
	Добавление записей об успешном завершении проверки в таблицы Checks, p2p (happy case).
*/

CALL add_p2p_review('gantedil', 'hvayon', 'CPP2_s21_containers', 'Success', '18:30:00');
SELECT * FROM Checks;
SELECT * FROM p2p;

/*	Test 4
	Добавление статуса об успешном завершении проверки для проверки, которая не начиналась.
	
	Получение ошибки.
*/

CALL add_p2p_review('queuerter', 'merymor', 'CPP3_SmartCalc_v2.0', 'Success', '05:00:00');

/* 
	2) Написать процедуру добавления проверки Verter'ом.
	
	Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время. 
	
	Добавить запись в таблицу Verter 
	(в качестве проверки указать проверку соответствующего 
	задания с самым поздним (по времени) успешным P2P этапом).
*/

CREATE PROCEDURE add_verter_review
(checked_peer varchar, task_name text, verter_status check_status, verter_time TIME)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (verter_status = 'Start')
		THEN
			IF ((SELECT MAX(p2p."Time") FROM p2p -- проверка задания с самым поздним (по времени) успешным P2P этапом
                    INNER JOIN checks ON p2p."Check" = checks.id
                    WHERE checks.peer = checked_peer AND checks.task = task_name
                    AND p2p.state = 'Success') IS NOT NULL)
				THEN
				INSERT INTO verter -- добавить запись в таблицу Verter 
                    VALUES ((SELECT MAX(id) FROM verter) + 1, (SELECT DISTINCT checks.id FROM p2p
                    INNER JOIN checks ON p2p."Check" = checks.id WHERE checks.peer = checked_peer 
					AND p2p.state = 'Success' AND checks.task = task_name), verter_status, verter_time);
			ELSE
				RAISE EXCEPTION 'Ошибка: проверка еще не завершена или имеет статус Failure';
			            END IF;
	ELSE
		INSERT INTO verter
		VALUES ((SELECT MAX(id) FROM verter) + 1,
				(SELECT "Check" FROM verter GROUP BY "Check" HAVING COUNT(*) % 2 = 1), 
				verter_status, verter_time);
	END IF;
END;
$$

/*
	Test 1 
	Добавление записей о начале проверки в таблицy Verter (happy case).
*/

CALL add_verter_review('gantedil', 'CPP2_s21_containers', 'Start', '18:32:00');
SELECT * FROM verter;

/*
	Test 2
	Добавление записей о завершении проверки в таблицy Verter (happy case).
*/

CALL add_verter_review('gantedil', 'CPP2_s21_containers', 'Success', '18:39:00');
SELECT * FROM verter;

/*
	Test 3
	Добавление записей в таблицy Verter для незавершенной P2P проверки.
	
	Получение ошибки.
*/

CALL add_p2p_review('gantedil', 'merymor', 'CPP3_SmartCalc_v2.0', 'Start', '19:00:00');
CALL add_verter_review('gantedil', 'CPP3_SmartCalc_v2.0', 'Start', '19:01:00');

/*
	Test 4
	Добавление записей в таблицy Verter для P2P проверки со статусом Failure.
	
	Получение ошибки.
*/

CALL add_verter_review('merymor', 'C2_SimpleBashUtils', 'Start', '13:34:00');

/* 
	3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, 
	изменить соответствующую запись в таблице TransferredPoints.
*/

CREATE FUNCTION fnc_trg_add_to_transferredpoints()
RETURNS TRIGGER LANGUAGE plpgsql AS $trg_add_to_transferredpoints$
DECLARE checked_peer varchar = ((SELECT checks.peer FROM p2p INNER JOIN checks 
						 ON p2p."Check" = checks.id WHERE checks.id = NEW."Check")
						 UNION
						 (SELECT checks.peer FROM p2p INNER JOIN checks 
						 ON p2p."Check" = checks.id WHERE checks.id = NEW."Check"));
BEGIN
	IF (NEW.State = 'Start')
		THEN
		UPDATE transferredpoints tf
		SET pointsamount = pointsamount + 1
		WHERE  tf.checkedpeer = checked_peer
		AND  tf.checkingpeer = NEW.checkingpeer;
	 END IF;
	   IF ((SELECT COUNT(*)
		  FROM transferredpoints WHERE checkedpeer = checked_peer
		  AND checkingpeer = NEW.checkingpeer) = 0 AND NEW.state = 'Start')
		  THEN
		  INSERT INTO transferredpoints
		  VALUES (DEFAULT, NEW.checkingpeer, checked_peer,'1');
	   END IF;
	   RETURN NULL;
    END;
$trg_add_to_transferredpoints$

-- Создаем триггер.
								
CREATE TRIGGER trg_add_to_transferredpoints
AFTER INSERT ON P2P
FOR EACH ROW EXECUTE FUNCTION fnc_trg_add_to_transferredpoints();

/*	
	Test 1
	Проверка работы триггера после добавления записи в таблицу P2P
	со статусом "Start".
	
	В таблицу transferredpoints добавляется запись с одним пир пойнтом.
*/
								
CALL add_p2p_review('neeksel', 'mirrorar', 'C3_s21_string+', 'Start', '19:30:00');

SELECT * FROM transferredpoints;

/*	
	Test 2
	Проверка работы триггера после добавления записи в таблицу P2P
	c помощью INSERT.
	
	В таблице transferredpoints в запись для пары пиров monkeydluffy - gantedil
	добавляется +1 peer point.
*/

INSERT INTO p2p VALUES ((SELECT MAX(id) FROM p2p) + 1, 32, 'monkeydluffy', 'Start', '20:00:00');

SELECT * FROM transferredpoints;

/*
	4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
	Запись считается корректной, если:
	- Количество XP не превышает максимальное доступное для проверяемой задачи
	- Поле Check ссылается на успешную проверку
	- Если запись не прошла проверку, не добавлять её в таблицу.
*/

CREATE FUNCTION fnc_check_insert_xp() 
RETURNS TRIGGER LANGUAGE plpgsql AS $trg_check_insert_xp$
 BEGIN
        IF ((SELECT maxxp FROM checks
            INNER JOIN tasks ON checks.task = tasks.title
            WHERE NEW."Check" = checks.id) < NEW.xpamount OR
            (SELECT state FROM p2p
             WHERE NEW."Check" = p2p."Check" AND p2p.state IN ('Success', 'Failure')) = 'Failure' OR
            (SELECT state FROM verter
             WHERE NEW."Check" = verter."Check" AND verter.state = 'Failure') = 'Failure') 
			 THEN
                RAISE EXCEPTION 'Ошибка: Результат проверки не успешен или некорректное количество xp';
        END IF;
    RETURN (NEW.id, NEW."Check", NEW.xpamount);
    END;
$trg_check_insert_xp$

-- Создаем триггер.

CREATE TRIGGER trg_check_insert_xp
BEFORE INSERT ON XP
FOR EACH ROW EXECUTE FUNCTION fnc_check_insert_xp();

/*
	Test 1
	Добавления записи в таблицу xp (happy case).
	
	Ожидается добавление в таблицу xp так как и проверка p2p,
	и проверка Verter прошли успешно.
*/

INSERT INTO xp (id, "Check", xpamount)
VALUES ((SELECT MAX(id) FROM xp) + 1, 31, 350);

SELECT * FROM XP;

/*
	Test 2
	Добавления записи в таблицу xp.
	
	Получение ошибки.
	
	Ожидается, что запись не добавится, так как проверка Verter неуспешна,
	и мы получим ошибку.
	
*/

INSERT INTO xp (id, "Check", xpamount)
VALUES ((SELECT MAX(id) FROM xp) + 1, 19, 300);

/*
	Возвращения тестовых данных к исходным значениям.
*/

DELETE FROM p2p WHERE "Check" IN (31, 32, 33);
DELETE FROM Verter WHERE "Check" IN (31, 32, 33);
DELETE FROM xp WHERE "Check" IN (31, 32, 33);
DELETE FROM transferredpoints WHERE id IN (33);
UPDATE transferredpoints SET pointsamount = 1 WHERE id = 7;

DELETE FROM checks WHERE id IN (31, 32, 33);

/*
	Удаление процедур и функций.
	
	DROP PROCEDURE IF EXISTS add_p2p_review CASCADE;
	DROP PROCEDURE IF EXISTS add_verter_review CASCADE;
	DROP FUNCTION IF EXISTS fnc_trg_add_to_transferredpoints() CASCADE;
	DROP FUNCTION IF EXISTS fnc_check_insert_xp() CASCADE;
*/