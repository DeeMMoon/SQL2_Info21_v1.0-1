/*	Создание базы данных.
	Если база данных создана, то запускать не нужно.
	Если запустить фрагмент скрипта,
	то после создания базы данных нужно переключиться на нее.
	
CREATE DATABASE info21_v1_0
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
*/
	
-- Создание таблицы Peers и добавление тестового значения	
CREATE TABLE IF NOT EXISTS Peers (
	Nickname varchar PRIMARY KEY,
	Birthday date  NOT NULL
);

-- Создание таблицы Tasks и добавление тестовых значений
CREATE TABLE IF NOT EXISTS Tasks (
	Title varchar PRIMARY KEY DEFAULT NULL,
	ParentTask varchar DEFAULT NULL,
	MaxXP integer NOT NULL CHECK (MaxXP > 0),
	FOREIGN KEY (ParentTask) REFERENCES Tasks(Title)
);

-- Создание перечисления Check status
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

-- Создание таблицы Checks
CREATE TABLE IF NOT EXISTS Checks (
	ID serial PRIMARY KEY ,
	Peer varchar NOT NULL,
	Task varchar NOT NULL,
	"Date" date NOT NULL,
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
	FOREIGN KEY (Task) REFERENCES Tasks(Title)
);

-- Создание таблицы P2P
CREATE TABLE IF NOT EXISTS P2P (
	ID serial PRIMARY KEY,
	"Check" bigint NOT NULL,
	CheckingPeer varchar NOT NULL,
	State check_status NOT NULL,
	"Time" time without time zone NOT NULL,
	FOREIGN KEY ("Check") REFERENCES Checks(ID),
	FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
	UNIQUE ("Check", CheckingPeer, State)
);

-- Создание таблицы Verter
CREATE TABLE IF NOT EXISTS Verter (
	ID serial PRIMARY KEY ,
	"Check" bigint NOT NULL,
	State check_status NOT NULL,
	"Time" time without time zone NOT NULL,
	FOREIGN KEY ("Check") REFERENCES Checks(ID)
);

-- Создание таблицы TransferredPoints
CREATE TABLE IF NOT EXISTS TransferredPoints (
	ID serial PRIMARY KEY ,
	CheckingPeer varchar NOT NULL,
	CheckedPeer varchar NOT NULL CHECK (CheckedPeer != CheckingPeer),
	PointsAmount integer,
	FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
	FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname)
);

-- Создание таблицы Friends
CREATE TABLE IF NOT EXISTS Friends (
	ID serial PRIMARY KEY ,
	Peer1 varchar NOT NULL,
	Peer2 varchar NOT NULL CHECK (Peer1 != Peer2),
	FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
	FOREIGN KEY (Peer2) REFERENCES Peers(Nickname)
);

-- Создание таблицы Recommendation
CREATE TABLE IF NOT EXISTS Recommendations (
	ID serial PRIMARY KEY ,
	Peer varchar NOT NULL,
	RecommendedPeer varchar NOT NULL CHECK (Peer != RecommendedPeer),
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
	FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname)
);

-- Создание таблицы XP
CREATE TABLE IF NOT EXISTS XP (
	ID serial PRIMARY KEY ,
	"Check" bigint NOT NULL,
	XPAmount integer CHECK (XPAmount >= 0),
	FOREIGN KEY ("Check") REFERENCES Checks(ID)
);

-- Создание таблицы TimeTracking
CREATE TABLE IF NOT EXISTS TimeTracking (
	ID serial PRIMARY KEY ,
	Peer varchar NOT NULL,
	"Date" date NOT NULL,
	"Time" time without time zone NOT NULL,
	State integer CHECK(State IN(1,2)),
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname)
);

-- Добавление данных для таблицы Peers

INSERT INTO Peers (Nickname, Birthday)
VALUES ('gantedil', '2001-05-01'),
       ('mirrorar', '2002-06-20'),
       ('hvayon', '2001-10-22'),
       ('merymor', '1995-11-17'),
       ('mrtester', '1970-05-28'),
       ('queuerter', '1996-04-04'),
       ('neeksel', '2003-03-22'),
       ('monkeydluffy', '2009-07-13');
	   
-- Добавление данных для таблицы Tasks
	   
INSERT INTO Tasks (Title, ParentTask, MaxXP)
VALUES ('C2_SimpleBashUtils', NULL, 250),
	   ('D01_Linux', 'C2_SimpleBashUtils', 300),
       ('DO2_Linux_Network', 'D01_Linux', 250),
       ('DO3_Linux_Monitoring', 'DO2_Linux_Network', 350),
       ('DO5_SimpleDocker', 'DO3_Linux_Monitoring', 300),
       ('DO6_CI/CD', 'DO5_SimpleDocker', 300),
       ('C3_s21_string+', 'C2_SimpleBashUtils', 500),
       ('C5_s21_decimal', 'C3_s21_string+', 350),
       ('C6_s21_matrix', 'C5_s21_decimal', 200),
       ('C7_SmartCalc_v1.0', 'C6_s21_matrix', 500),
       ('C8_3DViewer_v1.0', 'C7_SmartCalc_v1.0', 750),
       ('CPP1_s21_matrix+', 'C8_3DViewer_v1.0', 300),
       ('CPP2_s21_containers', 'CPP1_s21_matrix+', 350),
	   ('CPP3_SmartCalc_v2.0', 'CPP2_s21_containers', 600),
	   ('CPP4_3DViewer_v2.0', 'CPP3_SmartCalc_v2.0', 750),
	   ('A1_Maze', 'CPP4_3DViewer_v2.0', 300),
	   ('A2_SimpleNavigator v1.0', 'A1_Maze', 400);

-- Добавление данных для таблицы Checks

INSERT INTO Checks (ID, Peer, Task, "Date")
VALUES (0, 'gantedil', 'C2_SimpleBashUtils', '2021-06-05'),
       (1, 'mirrorar', 'C2_SimpleBashUtils', '2021-06-20'),
       (2, 'hvayon', 'C2_SimpleBashUtils', '2021-09-06'),
       (3, 'merymor', 'C2_SimpleBashUtils', '2021-09-09'),
       (4, 'mrtester', 'C2_SimpleBashUtils', '2022-05-28'),
       (5, 'gantedil', 'C3_s21_string+', '2022-09-17'),
       (6, 'mirrorar', 'C3_s21_string+', '2022-09-17'),
	   (7, 'hvayon', 'C3_s21_string+', '2022-09-17'),
       (8, 'queuerter', 'C2_SimpleBashUtils', '2022-09-18'),
       (9, 'mirrorar', 'C5_s21_decimal', '2022-09-20'),
       (10, 'mirrorar', 'C6_s21_matrix', '2022-09-28'),
       (11, 'mirrorar', 'C7_SmartCalc_v1.0', '2022-10-10'),
       (12, 'mirrorar', 'C8_3DViewer_v1.0', '2022-10-15'),
       (13, 'neeksel', 'C2_SimpleBashUtils', '2022-10-16'),
	   (14, 'hvayon', 'C5_s21_decimal', '2022-10-22'),
       (15, 'hvayon', 'C6_s21_matrix', '2022-10-26'),
	   (16, 'gantedil', 'C5_s21_decimal', '2022-10-29'),
       (17, 'hvayon', 'C7_SmartCalc_v1.0', '2022-11-01'),
       (18, 'hvayon', 'C8_3DViewer_v1.0', '2022-11-10'),
	   (19, 'mirrorar', 'CPP1_s21_matrix+', '2022-11-10'),
	   (20, 'gantedil', 'D01_Linux', '2022-11-17'),
	   (21, 'gantedil', 'C6_s21_matrix', '2023-05-01'),
	   (22, 'gantedil', 'C7_SmartCalc_v1.0', '2023-05-01'),
       (23, 'gantedil', 'C8_3DViewer_v1.0', '2023-05-19'),
	   (24, 'gantedil', 'CPP1_s21_matrix+', '2023-05-20'),
	   (25, 'hvayon', 'D01_Linux', '2023-06-20'),
	   (26, 'hvayon', 'DO2_Linux_Network', '2023-06-20'),
	   (27, 'merymor', 'D01_Linux', '2023-06-20'),
	   (28, 'hvayon', 'DO3_Linux_Monitoring', '2023-06-22'),
	   (29, 'hvayon', 'DO5_SimpleDocker', '2023-06-23'),
	   (30, 'hvayon', 'DO6_CI/CD', '2023-06-27');
	   

-- Добавление данных для таблицы P2P

INSERT INTO P2P ("Check", CheckingPeer, State, "Time")
VALUES (0, 'mirrorar', 'Start', '13:00'),
       (0, 'mirrorar', 'Success', '13:30'),
       (1, 'hvayon', 'Start', '14:00'),
       (1, 'hvayon', 'Success', '14:30'),
       (2, 'gantedil', 'Start', '15:00'),
       (2, 'gantedil', 'Success', '15:30'),
       (3, 'gantedil', 'Start', '11:15'),
       (3, 'gantedil', 'Failure', '11:45'),
       (4, 'merymor', 'Start', '13:00'),
       (4, 'merymor', 'Failure', '13:30'),
       (5, 'monkeydluffy', 'Start', '17:00'),
       (5, 'monkeydluffy', 'Success', '17:30'),
       (6, 'monkeydluffy', 'Start', '17:30'),
       (6, 'monkeydluffy', 'Success', '18:00'),
       (7, 'monkeydluffy', 'Start', '12:15'),
       (7, 'monkeydluffy', 'Success', '12:45'),
       (8, 'gantedil', 'Start', '12:00'),
       (8, 'gantedil', 'Success', '12:30'),
       (9, 'gantedil', 'Start', '05:00'),
       (9, 'gantedil', 'Success', '05:30'),
       (10, 'neeksel', 'Start', '06:00'),
       (10, 'neeksel', 'Success', '06:30'),
       (11, 'mrtester', 'Start', '08:00'),
       (11, 'mrtester', 'Success', '09:00'),
       (12, 'hvayon', 'Start', '14:00'),
       (12, 'hvayon', 'Success', '14:30'),
	   (13, 'hvayon', 'Start', '12:00'),
       (13, 'hvayon', 'Success', '12:30'),
	   (14, 'merymor', 'Start', '04:00'),
       (14, 'merymor', 'Success', '04:30'),
	   (15, 'neeksel', 'Start', '18:30'),
       (15, 'neeksel', 'Success', '19:00'),
	   (16, 'neeksel', 'Start', '11:00'),
       (16, 'neeksel', 'Success', '11:30'),
	   (17, 'mirrorar', 'Start', '14:00'),
       (17, 'mirrorar', 'Success', '15:00'),
	   (18, 'queuerter', 'Start', '22:00'),
       (18, 'queuerter', 'Failure', '22:30'),
	   (19, 'queuerter', 'Start', '00:00'),
       (19, 'queuerter', 'Success', '00:30'),
	   (20, 'neeksel', 'Start', '01:00'),
       (20, 'neeksel', 'Success', '01:30'),
	   (21, 'gantedil', 'Start', '11:00'),
       (21, 'gantedil', 'Success', '11:30'),
	   (22, 'gantedil', 'Start', '21:00'),
       (22, 'gantedil', 'Success', '21:30'),
	   (23, 'gantedil', 'Start', '18:00'),
       (23, 'gantedil', 'Success', '18:30'),
	   (24, 'gantedil', 'Start', '22:00'),
       (24, 'gantedil', 'Success', '22:30'),
	   (25, 'hvayon', 'Start', '22:00'),
       (25, 'hvayon', 'Success', '22:30'),
	   (26, 'hvayon', 'Start', '23:00'),
       (26, 'hvayon', 'Success', '23:30'),
	   (27, 'merymor', 'Start', '23:00'),
       (27, 'merymor', 'Success', '23:30'),
	   (28, 'hvayon', 'Start', '15:00'),
       (28, 'hvayon', 'Success', '15:30'),
	   (29, 'hvayon', 'Start', '16:00'),
       (29, 'hvayon', 'Success', '16:30'),
	   (30, 'hvayon', 'Start', '17:00'),
       (30, 'hvayon', 'Success', '17:30');

-- Добавление данных для таблицы Verter

INSERT INTO Verter ("Check", State, "Time")
VALUES (0, 'Start', '13:31'),
       (0, 'Success', '13:33'),
       (1, 'Start', '14:31'),
       (1, 'Success', '15:35'),
       (2, 'Start', '15:31'),
       (2, 'Success', '15:33'),
       (5, 'Start', '17:31'),
       (5, 'Success', '17:34'),
	   (6, 'Start', '18:02'),
       (6, 'Success', '18:07'),
       (7, 'Start', '12:46'),
       (7, 'Success', '12:48'),
       (8, 'Start', '12:31'),
       (8, 'Failure', '12:32'),
       (9, 'Start', '05:31'),
       (9, 'Success', '05:38'),
       (10, 'Start', '06:31'),
       (10, 'Success', '06:33'),
       (11, 'Start', '09:01'),
       (11, 'Success', '09:09'),
       (12, 'Start', '14:31'),
       (12, 'Success', '14:33'),
	   (13, 'Start', '12:32'),
       (13, 'Success', '12:40'),
	   (14, 'Start', '04:32'),
       (14, 'Success', '04:36'),
	   (15, 'Start', '19:02'),
       (15, 'Success', '19:05'),
	   (16, 'Start', '11:32'),
       (16, 'Failure', '11:33'),
	   (17, 'Start', '15:02'),
       (17, 'Success', '15:04'),
	   (19, 'Start', '00:32'),
       (19, 'Failure', '00:40'),
	   (20, 'Start', '01:32'),
       (20, 'Success', '01:39'),
	   (21, 'Start', '11:31'),
       (21, 'Success', '11:32'),
	   (22, 'Start', '21:32'),
       (22, 'Success', '21:40'),
	   (23, 'Start', '18:31'),
       (23, 'Success', '18:33'),
	   (24, 'Start', '22:32'),
       (24, 'Success', '22:40'),
	   (25, 'Start', '22:32'),
       (25, 'Success', '22:34'),
	   (26, 'Start', '23:31'),
       (26, 'Success', '23:37'),
	   (27, 'Start', '23:32'),
       (27, 'Success', '23:40'),
	   (28, 'Start', '15:31'),
       (28, 'Success', '15:27'),
	   (29, 'Start', '16:32'),
       (29, 'Success', '16:40'),
	   (30, 'Start', '17:35'),
       (30, 'Success', '17:42');

-- Добавление данных для таблицы TransferredPoints

INSERT INTO TransferredPoints (CheckingPeer, CheckedPeer, PointsAmount)
VALUES ('mirrorar', 'gantedil', 1),
       ('hvayon', 'mirrorar', 1),
       ('gantedil', 'hvayon', 1),
       ('gantedil', 'merymor', 1),
       ('merymor', 'mrtester', 1),
	   ('monkeydluffy', 'mirrorar', 1),
       ('monkeydluffy', 'gantedil', 1),
       ('monkeydluffy', 'mirrorar', 1),
       ('monkeydluffy', 'hvayon', 1),
       ('gantedil', 'queuerter', 1),
       ('gantedil', 'mirrorar', 1),
       ('neeksel', 'mirrorar', 1),
       ('mrtester', 'mirrorar', 1),
       ('hvayon', 'mirrorar', 1),
       ('hvayon', 'neeksel', 1),
	   ('merymor', 'hvayon', 1),
	   ('neeksel', 'hvayon', 1),
	   ('neeksel', 'gantedil', 1),
	   ('mirrorar', 'hvayon', 1),
	   ('queuerter', 'hvayon', 1),
	   ('queuerter', 'mirrorar', 1),
	   ('neeksel', 'gantedil', 1),
	   ('gantedil', 'mirrorar', 1),
       ('gantedil', 'neeksel', 1),
	   ('gantedil', 'hvayon', 1),
	   ('gantedil', 'hvayon', 1),
	   ('hvayon', 'gantedil', 1),
	   ('hvayon', 'mirrorar', 1),
	   ('merymor', 'hvayon', 1),
	   ('hvayon', 'mirrorar', 1),
	   ('hvayon', 'monkeydluffy', 1),
	   ('hvayon', 'neeksel', 1);

-- Добавление данных для таблицы Friends

INSERT INTO Friends (Peer1, Peer2)
VALUES ('mirrorar', 'gantedil'),
       ('gantedil', 'hvayon'),
       ('hvayon', 'mirrorar'),
       ('monkeydluffy', 'gantedil'),
       ('hvayon', 'neeksel');

-- Добавление данных для таблицы Recommendations

INSERT INTO Recommendations (Peer, RecommendedPeer)
VALUES ('gantedil', 'mirrorar'),
       ('gantedil', 'hvayon'),
       ('gantedil', 'monkeydluffy'),
       ('mirrorar', 'hvayon'),
       ('monkeydluffy', 'gantedil'),
       ('hvayon', 'gantedil'),
       ('gantedil', 'mirrorar'),
       ('neeksel', 'mrtester'),
       ('mrtester', 'hvayon');

-- Добавление данных для таблицы XP

INSERT INTO XP ("Check", XPAmount)
VALUES (0, 250),
       (1, 250),
       (2, 250),
       (5, 500),
	   (6, 500),
       (7, 500),
       (9, 350),
       (10, 200),
       (11, 500),
       (12, 750),
       (13, 250),
	   (14, 350),
	   (15, 200),
	   (17, 500),
	   (20, 300),
	   (21, 200),
	   (22, 500),
	   (23, 750),
	   (24, 300),
	   (25, 300),
	   (26, 250),
	   (27, 300),
	   (28, 350),
	   (29, 300),
	   (30, 300);

-- Добавление данных для таблицы TimeTracking

INSERT INTO TimeTracking (Peer, "Date", "Time", State)
VALUES ('mirrorar', '2022-09-06', '12:30', 1),
       ('mirrorar', '2022-09-06', '12:52', 2),
       ('mirrorar', '2022-09-06', '13:00', 1),
       ('mirrorar', '2022-09-06', '20:32', 2),
       ('gantedil', '2022-09-06', '10:30', 1),
       ('gantedil', '2022-09-06', '18:32', 2),
       ('mirrorar', '2022-10-19', '11:43', 1),
       ('mirrorar', '2022-10-19', '16:32', 2),
       ('gantedil', '2022-11-14', '10:10', 1),
       ('gantedil', '2022-11-14', '12:12', 2),
       ('hvayon', '2022-11-07', '11:00', 1),
       ('hvayon', '2022-11-07', '16:52', 2),
       ('monkeydluffy', '2022-12-10', '16:00', 1),
       ('monkeydluffy', '2022-12-10', '17:00', 2),
       ('monkeydluffy', '2022-12-10', '17:30', 1),
       ('neeksel', '2022-12-10', '17:32', 1),
       ('neeksel', '2022-12-10', '18:59', 2),
       ('monkeydluffy', '2022-12-10', '19:00', 2),
	   ('neeksel', '2022-12-10', '17:30', 1),
       ('neeksel', '2022-12-11', '18:00', 2),
	   ('neeksel', '2022-12-12', '17:32', 1),
       ('neeksel', '2022-12-15', '18:59', 2);

-- Процедура для эспорта данных в csv файл

CREATE OR REPLACE PROCEDURE export_csv(IN tablename text, IN path_to_save text, IN del char)
AS $$
BEGIN
	EXECUTE format ('COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;', $1, $2, $3);
END;
$$ LANGUAGE plpgsql;

/*	Экспорт данных в файлы 
	(Для тестов на своем компьютере нужно создать папку csv_files
	и создать в ней соответствующие файлы формата .csv)
*/

CALL export_csv('checks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\checks.csv', ',');
CALL export_csv('friends', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\friends.csv', ',');
CALL export_csv('p2p', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\p2p.csv', ',');
CALL export_csv('peers', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\peers.csv', ',');
CALL export_csv('recommendations', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\recommendations.csv', ',');
CALL export_csv('tasks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\tasks.csv', ',');
CALL export_csv('timetracking', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\timetracking.csv', ',');
CALL export_csv('transferredpoints', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\transferredpoints.csv', ',');
CALL export_csv('verter', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\verter.csv', ',');
CALL export_csv('xp', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\xp.csv', ',');

-- Процедура для импорта данных из csv файла

CREATE OR REPLACE PROCEDURE import_csv(IN tablename text, IN path_to_save text, IN del char)
AS $$
BEGIN
	EXECUTE format ('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;', $1, $2, $3);
END;
$$ LANGUAGE plpgsql;

-- Удаление данных из таблиц для тестирования процедуры для импорта данных

TRUNCATE checks CASCADE;
TRUNCATE tasks CASCADE;
TRUNCATE friends CASCADE;
TRUNCATE p2p CASCADE;
TRUNCATE peers CASCADE;
TRUNCATE recommendations CASCADE;
TRUNCATE timetracking CASCADE;
TRUNCATE transferredpoints CASCADE;
TRUNCATE verter CASCADE;
TRUNCATE xp CASCADE;

-- Импорт данных из файлы

CALL import_csv('peers', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\peers.csv', ',');
CALL import_csv('tasks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\tasks.csv', ',');
CALL import_csv('checks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\checks.csv', ',');
CALL import_csv('p2p', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\p2p.csv', ',');
CALL import_csv('friends', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\friends.csv', ',');
CALL import_csv('recommendations', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\recommendations.csv', ',');
CALL import_csv('timetracking', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\timetracking.csv', ',');
CALL import_csv('transferredpoints', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\transferredpoints.csv', ',');
CALL import_csv('verter', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\verter.csv', ',');
CALL import_csv('xp', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\csv_files\xp.csv', ',');