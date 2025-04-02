ALTER TABLE Filters ADD COLUMN filterPastRecordsBySpecificOdds INTEGER;
ALTER TABLE Filters ADD COLUMN filterFutureRecordsBySpecificOdds INTEGER;

ALTER TABLE Filters DROP COLUMN futureDismissNoHistory;
ALTER TABLE Filters DROP COLUMN minGoalsFirstHalf;
ALTER TABLE Filters DROP COLUMN maxGoalsFirstHalf;
ALTER TABLE Filters DROP COLUMN minGoalsSecondHalf;
ALTER TABLE Filters DROP COLUMN maxGoalsSecondHalf;
ALTER TABLE Filters DROP COLUMN minGoalsFullTime;
ALTER TABLE Filters DROP COLUMN maxGoalsFullTime;

ALTER TABLE Filters ADD COLUMN milestoneGoalsFirstHalf;
ALTER TABLE Filters ADD COLUMN milestoneGoalsSecondHalf;
ALTER TABLE Filters ADD COLUMN milestoneGoalsFullTime;

UPDATE Records
SET
  homeWin = CASE WHEN homeSecondHalfScore > awaySecondHalfScore THEN 1
            ELSE 0
            END,
  draw    = CASE WHEN homeSecondHalfScore = awaySecondHalfScore THEN 1
            ELSE 0
            END,
  awayWin = CASE WHEN homeSecondHalfScore < awaySecondHalfScore THEN 1
            ELSE 0
            END
WHERE finished = 1;

UPDATE Filters
SET milestoneGoalsFirstHalf = 1, milestoneGoalsSecondHalf = 1, milestoneGoalsFullTime = 3;

UPDATE Filters
SET futureMinHomeWinPercentage = 0
WHERE futureMinHomeWinPercentage = 101;

UPDATE Filters
SET futureMinDrawPercentage = 0
WHERE futureMinDrawPercentage = 101;

UPDATE Filters
SET futureMinAwayWinPercentage = 0
WHERE futureMinAwayWinPercentage = 101;
