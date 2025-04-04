PRAGMA foreign_keys=ON;
PRAGMA journal_mode=WAL;

CREATE TABLE BettingHouses (
  id               INTEGER PRIMARY KEY,
  bettingHouseName TEXT NOT NULL UNIQUE
);

INSERT INTO BettingHouses(id, bettingHouseName) VALUES (17, "Bet365");

CREATE TABLE Leagues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  leagueCode TEXT NOT NULL,
  leagueName TEXT NOT NULL,

  UNIQUE(leagueCode, leagueName)
);

CREATE TABLE Folders (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  folderName TEXT NOT NULL UNIQUE
);

CREATE TABLE LeaguesFolders (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  leagueId INTEGER NOT NULL REFERENCES Leagues(id),
  folderId INTEGER NOT NULL REFERENCES Folders(id),

  UNIQUE(leagueId, folderId)
);

CREATE TABLE Teams (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  teamName TEXT NOT NULL UNIQUE
);

CREATE TABLE Records (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  bettingHouseId      INTEGER REFERENCES BettingHouses(id),
  matchDate           INTEGER NOT NULL,
  leagueId            INTEGER NOT NULL REFERENCES Leagues(id),
  homeTeamId          INTEGER NOT NULL REFERENCES Teams(id),
  awayTeamId          INTEGER NOT NULL REFERENCES Teams(id),
  earlyOdds1          TEXT,
  earlyOddsX          TEXT,
  earlyOdds2          TEXT,
  finalOdds1          TEXT,
  finalOddsX          TEXT,
  finalOdds2          TEXT,
  homeHalfTimeScore   INTEGER,
  awayHalfTimeScore   INTEGER,
  homeFullTimeScore   INTEGER,
  awayFullTimeScore   INTEGER,
  homeWin             INTEGER NOT NULL DEFAULT 0,
  draw                INTEGER NOT NULL DEFAULT 0,
  awayWin             INTEGER NOT NULL DEFAULT 0,
  finished            INTEGER NOT NULL DEFAULT 0,

  UNIQUE(bettingHouseId, matchDate, leagueId, homeTeamId, awayTeamId)
);

CREATE TABLE Filters (
  id                               INTEGER PRIMARY KEY AUTOINCREMENT,
  filterName                       TEXT NOT NULL UNIQUE,
  pivotNextMinutes                 INTEGER,
  pastYears                        INTEGER,
  specificYears                    INTEGER,

  minEarlyHome                     REAL,
  maxEarlyHome                     REAL,
  minEarlyDraw                     REAL,
  maxEarlyDraw                     REAL,
  minEarlyAway                     REAL,
  maxEarlyAway                     REAL,
  minFinalHome                     REAL,
  maxFinalHome                     REAL,
  minFinalDraw                     REAL,
  maxFinalDraw                     REAL,
  minFinalAway                     REAL,
  maxFinalAway                     REAL,

  pivotDismissNoEarlyOdds          INTEGER NOT NULL DEFAULT 1,
  pivotDismissNoFinalOdds          INTEGER NOT NULL DEFAULT 0,

  pivotOnlySameLeague              INTEGER NOT NULL DEFAULT 0,

  pivotSameEarlyHome               INTEGER NOT NULL DEFAULT 1,
  pivotSameEarlyDraw               INTEGER NOT NULL DEFAULT 0,
  pivotSameEarlyAway               INTEGER NOT NULL DEFAULT 1,
  pivotSameFinalHome               INTEGER NOT NULL DEFAULT 0,
  pivotSameFinalDraw               INTEGER NOT NULL DEFAULT 0,
  pivotSameFinalAway               INTEGER NOT NULL DEFAULT 0,

  milestoneGoalsFirstHalf          INTEGER NOT NULL DEFAULT 1,
  milestoneGoalsSecondHalf         INTEGER NOT NULL DEFAULT 1,
  milestoneGoalsFullTime           INTEGER NOT NULL DEFAULT 3,

  pivotMinOverFirstPercentage      INTEGER NOT NULL DEFAULT 0,
  pivotMinOverSecondPercentage     INTEGER NOT NULL DEFAULT 0,
  pivotMinOverFullPercentage       INTEGER NOT NULL DEFAULT 0,

  pivotMinHomeWinPercentage        INTEGER NOT NULL DEFAULT 0,
  pivotMinDrawPercentage           INTEGER NOT NULL DEFAULT 0,
  pivotMinAwayWinPercentage        INTEGER NOT NULL DEFAULT 0,

  filterPastRecordsByTeams         INTEGER NOT NULL DEFAULT 0,
  filterPivotRecordsByTeams        INTEGER NOT NULL DEFAULT 0,
  filterPastRecordsByLeagues       INTEGER NOT NULL DEFAULT 0,
  filterPivotRecordsByLeagues      INTEGER NOT NULL DEFAULT 0,
  filterPastRecordsBySpecificOdds  INTEGER NOT NULL DEFAULT 0,
  filterPivotRecordsBySpecificOdds INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE FiltersBettingHouses (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  filterId       INTEGER NOT NULL REFERENCES Filters(id),
  bettingHouseId INTEGER NOT NULL REFERENCES BettingHouses(id),
  type           CHAR(1) NOT NULL DEFAULT 'I',

  UNIQUE(filterId, bettingHouseId)
);

CREATE TABLE FiltersTeams (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  filterId INTEGER NOT NULL REFERENCES Filters(id),
  teamId   INTEGER NOT NULL REFERENCES Teams(id),
  type     CHAR(1) NOT NULL DEFAULT 'I',

  UNIQUE(filterId, teamId)
);

CREATE TABLE FiltersLeagues (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  filterId INTEGER NOT NULL REFERENCES Filters(id),
  leagueId INTEGER NOT NULL REFERENCES Leagues(id),
  type     CHAR(1) NOT NULL DEFAULT 'I',

  UNIQUE(filterId, leagueId)
);

CREATE TABLE FiltersFolders (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  filterId INTEGER NOT NULL REFERENCES Filters(id),
  folderId INTEGER NOT NULL REFERENCES Folders(id),
  type     CHAR(1) NOT NULL DEFAULT 'I',

  UNIQUE(filterId, folderId)
);

CREATE INDEX IF NOT EXISTS idx_records_matchDate ON Records(MatchDate);
CREATE INDEX IF NOT EXISTS idx_records_odds ON Records(earlyOdds1, earlyOddsX, earlyOdds2, finalOdds1, finalOddsX, finalOdds2);

CREATE INDEX IF NOT EXISTS idx_leagues_league_code ON Leagues(leagueCode);

INSERT INTO Folders (id, folderName) VALUES (1, 'Liga Global');
INSERT INTO Folders (id, folderName) VALUES (2, 'Liga Elite');

INSERT INTO LeaguesFolders (folderId, leagueId)
SELECT count(*), id FROM Leagues WHERE leagueCode IN (
  'JPN D1', 'JPN D2', 'AUS D1', 'KOR D1', 'BUL D1', 'TUR D1', 'TUR D2',
  'POR D1', 'POR D2', 'POL D1', 'POL D2', 'HOL D1', 'HOL D2', 'ITA D1',
  'ITA D2', 'ENG PR', 'ENG LCH', 'ENG D1', 'ENG D2', 'ENG CONF', 'CZE D1',
  'BEL D1', 'BEL D2', 'GER D1', 'GER D2', 'SPA D1', 'SPA D2', 'DEN SASL',
  'DEN 1', 'ROM D1', 'FRA D1', 'FRA D2', 'IND SL', 'SVK D1', 'HUN D1',
  'CHI D1', 'SUI D1', 'SUI D2', 'AUT D1', 'AUT D2', 'SER SL', 'SLO D1',
  'CYP D1', 'ISR D1', 'ECU D1', 'ARG D1', 'ARG D2', 'COL D1', 'COL D2',
  'URU D1', 'PER D1', 'CRC D1', 'BRA RJ', 'PAR D1', 'USA MLS', 'MEX D1',
  'MEX D2', 'GUA D1', 'CRO D1', 'FIN D1', 'FIN D2', 'SWE D1', 'SWE D2',
  'SCO PR', 'SCO LCH', 'QAT D1', 'BRA SP', 'BRA D1', 'BRA D2', 'UEFA CL',
  'UEFA EL', 'UEFA NL', 'NOR D1', 'NOR D2'
);

INSERT INTO LeaguesFolders (folderId, leagueId)
SELECT 2, id FROM Leagues WHERE leagueCode IN (
  'JPN D1', 'AUS D1', 'TUR D1', 'POR D1', 'POL D1', 'HOL D1', 'ITA D1',
  'ENG PR', 'ENG LCH', 'CZE D1', 'BEL D1', 'GER D1', 'SPA D1', 'DEN SASL',
  'ROM D1', 'FRA D1', 'IND SL', 'SVK D1', 'CHI D1', 'SUI D1', 'AUT D1',
  'SER SL', 'SLO D1', 'CYP D1', 'ISR D1', 'ECU D1', 'ARG D1', 'COL D1',
  'URU D1', 'PER D1', 'CRC D1', 'PAR D1', 'USA MLS', 'MEX D1', 'CRO D1',
  'FIN D1', 'SWE D1', 'SCO PR', 'BRA D1', 'UEFA CL', 'UEFA EL'
);
