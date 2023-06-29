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


CREATE OR REPLACE PROCEDURE import_csv(IN tablename text, IN path_to_save text, IN del char)
AS $$
BEGIN
	EXECUTE format ('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;', $1, $2, $3);
END;
$$ LANGUAGE plpgsql;

CALL import_csv('peers', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\peers.csv', ',');
CALL import_csv('tasks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\tasks.csv', ',');
CALL import_csv('checks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\checks.csv', ',');
CALL import_csv('p2p', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\p2p.csv', ',');
CALL import_csv('friends', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\friends.csv', ',');
CALL import_csv('recommendations', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\recommendations.csv', ',');
CALL import_csv('timetracking', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\timetracking.csv', ',');
CALL import_csv('transferredpoints', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\transferredpoints.csv', ',');
CALL import_csv('verter', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\verter.csv', ',');
CALL import_csv('xp', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\xp.csv', ',');
