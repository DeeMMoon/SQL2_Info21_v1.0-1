-- Создание базы данных
-- CREATE DATABASE test
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;
	
-- Создание таблицы Peers и добавление тестового значения	
CREATE TABLE Peers (
	Nickname varchar PRIMARY KEY,
	Birthday date  NOT NULL
);

-- Создание таблицы Tasks и добавление тестовых значений
CREATE TABLE Tasks (
	Title varchar PRIMARY KEY DEFAULT NULL,
	ParentTask varchar DEFAULT NULL,
	MaxXP integer NOT NULL CHECK (MaxXP > 0),
	FOREIGN KEY (ParentTask) REFERENCES Tasks(Title)
);

-- Создание перечисления Check status
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

-- Создание таблицы Checks
CREATE TABLE Checks (
	ID serial PRIMARY KEY ,
	Peer varchar NOT NULL,
	Task varchar NOT NULL,
	"Date" date NOT NULL,
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
	FOREIGN KEY (Task) REFERENCES Tasks(Title)
);

-- Создание таблицы P2P
CREATE TABLE P2P (
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
CREATE TABLE Verter (
	ID serial PRIMARY KEY ,
	"Check" bigint NOT NULL,
	State check_status NOT NULL,
	"Time" time without time zone NOT NULL,
	FOREIGN KEY ("Check") REFERENCES Checks(ID)
);

-- Создание таблицы TransferredPoints
CREATE TABLE TransferredPoints (
	ID serial PRIMARY KEY ,
	CheckingPeer varchar NOT NULL,
	CheckedPeer varchar NOT NULL CHECK (CheckedPeer != CheckingPeer),
	PointsAmount integer,
	FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
	FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname)
);

-- Создание таблицы Friends
CREATE TABLE Friends (
	ID serial PRIMARY KEY ,
	Peer1 varchar NOT NULL,
	Peer2 varchar NOT NULL CHECK (Peer1 != Peer2),
	FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
	FOREIGN KEY (Peer2) REFERENCES Peers(Nickname)
);

-- Создание таблицы Recommendation
CREATE TABLE Recommendations (
	ID serial PRIMARY KEY ,
	Peer varchar NOT NULL,
	RecommendedPeer varchar NOT NULL CHECK (Peer != RecommendedPeer),
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
	FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname)
);

-- Создание таблицы XP
CREATE TABLE XP (
	ID serial PRIMARY KEY ,
	"Check" bigint NOT NULL,
	XPAmount integer CHECK (XPAmount >= 0),
	FOREIGN KEY ("Check") REFERENCES Checks(ID)
);

-- Создание таблицы TimeTracking
CREATE TABLE TimeTracking (
	ID serial PRIMARY KEY ,
	Peer varchar NOT NULL,
	"Date" date NOT NULL,
	"Time" time without time zone NOT NULL,
	State integer CHECK(State IN(1,2)),
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname)
);

