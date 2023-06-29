CREATE OR REPLACE PROCEDURE export_csv(IN tablename text, IN path_to_save text, IN del char)
AS $$
BEGIN
	EXECUTE format ('COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;', $1, $2, $3);
END;
$$ LANGUAGE plpgsql;

CALL export_csv('checks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\checks.csv', ',');
CALL export_csv('friends', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\friends.csv', ',');
CALL export_csv('p2p', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\p2p.csv', ',');
CALL export_csv('peers', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\peers.csv', ',');
CALL export_csv('recommendations', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\recommendations.csv', ',');
CALL export_csv('tasks', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\tasks.csv', ',');
CALL export_csv('timetracking', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\timetracking.csv', ',');
CALL export_csv('transferredpoints', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\transferredpoints.csv', ',');
CALL export_csv('verter', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\verter.csv', ',');
CALL export_csv('xp', 'C:\Users\dim22\Desktop\SQL2_Info21_v1.0-1\src\part1\csv_files\xp.csv', ',');
