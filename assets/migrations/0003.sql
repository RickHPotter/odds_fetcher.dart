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
  homeWin             INTEGER NOT NULL DEFAULT 0,
  draw                INTEGER NOT NULL DEFAULT 0,
  awayWin             INTEGER NOT NULL DEFAULT 0,
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
  homeWin,
  draw,
  awayWin,
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
  CASE WHEN homeSecondHalfScore > awaySecondHalfScore THEN 1 ELSE 0 END,
  CASE WHEN homeSecondHalfScore = awaySecondHalfScore THEN 1 ELSE 0 END,
  CASE WHEN homeSecondHalfScore < awaySecondHalfScore THEN 1 ELSE 0 END,
  finished
From Records;

DROP TABLE Records;

ALTER TABLE newRecords RENAME TO Records;

CREATE INDEX IF NOT EXISTS idx_records_matchDate ON Records(MatchDate);
CREATE INDEX IF NOT EXISTS idx_records_odds ON Records(earlyOdds1, earlyOddsX, earlyOdds2, finalOdds1, finalOddsX, finalOdds2);
