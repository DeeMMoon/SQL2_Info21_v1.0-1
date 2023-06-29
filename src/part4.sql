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

--Создать хранимую процедуру, которая, не уничтожая базу данных,
--уничтожает все те таблицы текущей базы данных,
--имена которых начинаются с фразы 'TableName'.

CREATE OR REPLACE PROCEDURE destroyTable (IN TableName varchar)
AS
$$plpgsql
DECLARE destroy_name text;
BEGIN
    FOR destroy_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_name LIKE TableName || '%'
          AND table_schema = current_schema()
        LOOP
            EXECUTE 'DROP TABLE ' || TableName;
        END LOOP;
END
$$ LANGUAGE plpgsql;

--Проверка

CALL destroyTable('tablename');

--Создать хранимую процедуру с выходным параметром, которая выводит список имен 
--и параметров всех скалярных SQL функций пользователя в текущей базе данных.
--Имена функций без параметров не выводить. Имена и список параметров должны выводиться в одну строку. 
--Выходной параметр возвращает количество найденных функций.

CREATE FUNCTION one() RETURNS integer AS $$
    SELECT 1 AS result;
$$ LANGUAGE SQL;

CREATE FUNCTION add_em(x integer, y integer) RETURNS integer AS $$
    SELECT x + y;
$$ LANGUAGE SQL;

CREATE OR REPLACE PROCEDURE pr_count_table(OUT n int)
AS
$$
declare
    function_name text;
    param_list text;
BEGIN
    n = (SELECT count(*)
         FROM (SELECT routines.routine_name, (SELECT parameters.data_type FROM information_schema.parameters WHERE parameters.data_type IS NOT NULL)
               FROM information_schema.routines
               WHERE routines.specific_schema = 'public'
              ) as foo);
for function_name, param_list in
        (SELECT routines.routine_name, routines.data_type
		 FROM information_schema.routines
		 WHERE routines.specific_schema = 'public' AND routines.data_type <> 'void' )
    loop
        raise notice 'function: %, params: %', function_name, param_list;
    end loop;
END
$$ LANGUAGE plpgsql;

DO
$$
DECLARE functionCount integer;
BEGIN
    -- Вызов процедуры
    CALL pr_count_table(functionCount);
        -- Вывод количества найденных функций
    RAISE NOTICE 'Количество функций: %', functionCount;
END
$$;

