CREATE TABLE NewRecords (
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
  finished            INTEGER NOT NULL DEFAULT 0,

  UNIQUE(bettingHouseId, matchDate, leagueId, homeTeamId, awayTeamId)
);

INSERT INTO NewRecords (
  bettingHouseId,
  matchDate,
  leagueId,
  homeTeamId,
  awayTeamId,
  earlyOdds1,
  earlyOddsX,
  earlyOdds2,
  finalOdds1,
  finalOddsX,
  finalOdds2,
  homeFirstHalfScore,
  homeSecondHalfScore,
  awayFirstHalfScore,
  awaySecondHalfScore,
  finished
)
SELECT
  bettingHouseId,
  CAST(printf('%04d%02d%02d%02d%02d', MatchDateYear, MatchDateMonth, MatchDateDay, MatchDateHour, MatchDateMinute) AS INTEGER) As MatchDate,
  leagueId,
  homeTeamId,
  awayTeamId,
  earlyOdds1,
  earlyOddsX,
  earlyOdds2,
  finalOdds1,
  finalOddsX,
  finalOdds2,
  homeFirstHalfScore,
  homeSecondHalfScore,
  awayFirstHalfScore,
  awaySecondHalfScore,
  finished
From Records;

DROP TABLE Records;

ALTER TABLE newRecords RENAME TO Records;

CREATE INDEX IF NOT EXISTS idx_records_matchDate ON Records(MatchDate);
