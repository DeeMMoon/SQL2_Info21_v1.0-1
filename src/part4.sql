-- ЗАДАНИЕ 1

--Создание тестовых таблиц

CREATE TABLE tablename(
ID serial PRIMARY KEY,
Nickmame text);

CREATE TABLE tablename_2(
ID serial PRIMARY KEY,
Nickmame text);

CREATE TABLE new_tablename(
ID serial PRIMARY KEY,
Nickmame text);

--1. Создать хранимую процедуру, которая, не уничтожая базу данных,
--уничтожает все те таблицы текущей базы данных,
--имена которых начинаются с фразы 'TableName'.

CREATE OR REPLACE PROCEDURE destroyTable (IN TableName text)
AS
$$
DECLARE destroy_name text;
BEGIN
    FOR destroy_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_name LIKE TableName || '%'
          AND table_schema = current_schema()
        LOOP
            EXECUTE 'DROP TABLE ' || destroy_name;
        END LOOP;
END
$$ LANGUAGE plpgsql;

--Проверка

CALL destroyTable('tablename');

-- ЗАДАНИЕ 2
--Создание тестовых функций

CREATE FUNCTION test1() RETURNS integer AS $$
    SELECT 1 AS result;
$$ LANGUAGE SQL;

CREATE FUNCTION test2(x integer) RETURNS integer AS $$
    SELECT 1 AS result;
$$ LANGUAGE SQL;

CREATE FUNCTION add_em(x integer, y integer) RETURNS integer AS $$
    SELECT x + y;
$$ LANGUAGE SQL;

--2.Создать хранимую процедуру с выходным параметром, которая выводит список имен 
--и параметров всех скалярных SQL функций пользователя в текущей базе данных.
--Имена функций без параметров не выводить. Имена и список параметров должны выводиться в одну строку. 
--Выходной параметр возвращает количество найденных функций.

CREATE OR REPLACE PROCEDURE countFunctions(OUT n int)
AS
$$
DECLARE
	i record;
    name text;
    args text;
BEGIN
	n:=0;
FOR i IN (SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS param
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public')
		LOOP
       		name := i.proname;
        	args := i.param;
       		IF
				args <> '' 
			THEN
         		n := n + 1;
        		RAISE NOTICE 'function: %; params:(%)', name, args;
			END IF;
		END LOOP;
END;
$$
LANGUAGE plpgsql;

-- Проверка
DO
$$
DECLARE functionCount integer;
BEGIN
    CALL pr_count_table(functionCount);
    RAISE NOTICE 'Количество функций: %', functionCount;
END
$$;

--ЗАДАНИЕ 3

--Создание тестовых таблиц, триггер функций и триггеров
CREATE TABLE emp (
    empname           text NOT NULL,
    salary            integer
);

CREATE TABLE emp_audit(
    operation         char(1)   NOT NULL,
    stamp             timestamp NOT NULL,
    userid            text      NOT NULL,
    empname           text      NOT NULL,
    salary integer
);

CREATE OR REPLACE FUNCTION process_emp_audit() RETURNS TRIGGER AS $emp_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO emp_audit SELECT 'D', now(), user, OLD.*;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO emp_audit SELECT 'U', now(), user, NEW.*;
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO emp_audit SELECT 'I', now(), user, NEW.*;
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$emp_audit$ LANGUAGE plpgsql;

CREATE FUNCTION emp_stamp() RETURNS trigger AS $emp_stamp$
    BEGIN
        IF NEW.empname IS NULL THEN
            RAISE EXCEPTION 'empname cannot be null';
        END IF;
        IF NEW.salary IS NULL THEN
            RAISE EXCEPTION '% cannot have null salary', NEW.empname;
        END IF;
        IF NEW.salary < 0 THEN
            RAISE EXCEPTION '% cannot have a negative salary', NEW.empname;
        END IF;
        NEW.last_date := current_timestamp;
        NEW.last_user := current_user;
        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER emp_stamp BEFORE INSERT OR UPDATE ON emp
    FOR EACH ROW EXECUTE PROCEDURE emp_stamp();

CREATE TRIGGER emp_audit
AFTER INSERT OR UPDATE OR DELETE ON emp
    FOR EACH ROW EXECUTE PROCEDURE process_emp_audit();
	
--3. Создать хранимую процедуру с выходным параметром, 
--которая уничтожает все SQL DML триггеры в текущей базе данных.
--Выходной параметр возвращает количество уничтоженных триггеров.

CREATE OR REPLACE PROCEDURE destroyTriggers(OUT count_of_deleted_triggers integer)
AS
$$
DECLARE 
trig_name text;
table_name text;
BEGIN
	count_of_deleted_triggers:=0;
	FOR trig_name, table_name IN (SELECT DISTINCT trigger_name, event_object_table FROM information_schema.triggers
					  WHERE trigger_schema = current_schema())
	LOOP
	  EXECUTE 'DROP TRIGGER IF EXISTS ' || trig_name || ' ON ' || table_name || ' CASCADE';
	 count_of_deleted_triggers:=count_of_deleted_triggers+1;
	END LOOP;
END;
$$
LANGUAGE plpgsql;

-- Проверка
CALL destroyTriggers(NULL);

SELECT trigger_name
FROM information_schema.triggers;

-- ЗАДАНИЕ 4

--Создание таблицы для получения результатов работы процедуры

CREATE TABLE result_table(
	fun_name text,
	fun_type text
);

--Создать хранимую процедуру с входным параметром, которая выводит имена 
--и описания типа объектов (только хранимых процедур и скалярных функций), 
--в тексте которых на языке SQL встречается строка, задаваемая параметром процедуры.

CREATE OR REPLACE PROCEDURE find_obj_by_name(IN str text)
AS
$$
DECLARE
fun_name text;
fun_type text;
BEGIN
	INSERT INTO result_table(fun_name, fun_type)
		SELECT routine_name AS "fun_name", routine_type AS "fun_type"
FROM information_schema.routines
WHERE specific_schema = 'public'
  AND routine_definition LIKE '%'||str||'%';
RETURN;
END
    $$
LANGUAGE plpgsql;

--Проверка
CALL find_obj_by_name('table');
SELECT * FROM result_table;
TRUNCATE result_table;
