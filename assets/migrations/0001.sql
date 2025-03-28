PRAGMA foreign_keys = ON;

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
  homeFirstHalfScore  INTEGER,
  homeSecondHalfScore INTEGER,
  awayFirstHalfScore  INTEGER,
  awaySecondHalfScore INTEGER,
  homeWin             INTEGER NOT NULL DEFAULT 0,
  draw                INTEGER NOT NULL DEFAULT 0,
  awayWin             INTEGER NOT NULL DEFAULT 0,
  finished            INTEGER NOT NULL DEFAULT 0,

  UNIQUE(bettingHouseId, matchDate, leagueId, homeTeamId, awayTeamId)
);

CREATE TABLE Filters (
  id                           INTEGER PRIMARY KEY AUTOINCREMENT,
  filterName                   TEXT NOT NULL UNIQUE,
  pastYears                    INTEGER,
  specificYears                INTEGER,
  minEarlyHome                 REAL,
  maxEarlyHome                 REAL,
  minEarlyDraw                 REAL,
  maxEarlyDraw                 REAL,
  minEarlyAway                 REAL,
  maxEarlyAway                 REAL,
  minFinalHome                 REAL,
  maxFinalHome                 REAL,
  minFinalDraw                 REAL,
  maxFinalDraw                 REAL,
  minFinalAway                 REAL,
  maxFinalAway                 REAL,
  minGoalsFirstHalf            INTEGER,
  maxGoalsFirstHalf            INTEGER,
  minGoalsSecondHalf           INTEGER,
  maxGoalsSecondHalf           INTEGER,
  minGoalsFullTime             INTEGER,
  maxGoalsFullTime             INTEGER,
  futureNextMinutes            INTEGER,
  futureDismissNoEarlyOdds     INTEGER,
  futureDismissNoFinalOdds     INTEGER,
  futureDismissNoHistory       INTEGER,
  futureOnlySameLeague         INTEGER,
  futureSameEarlyHome          INTEGER,
  futureSameEarlyDraw          INTEGER,
  futureSameEarlyAway          INTEGER,
  futureSameFinalHome          INTEGER,
  futureSameFinalDraw          INTEGER,
  futureSameFinalAway          INTEGER,
  futureMinHomeWinPercentage   INTEGER,
  futureMinDrawPercentage      INTEGER,
  futureMinAwayWinPercentage   INTEGER,
  filterPastRecordsByTeams     INTEGER,
  filterFutureRecordsByTeams   INTEGER,
  filterPastRecordsByLeagues   INTEGER,
  filterFutureRecordsByLeagues INTEGER
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
