ALTER TABLE Records ADD COLUMN homeWin INTEGER DEFAULT 0;
ALTER TABLE Records ADD COLUMN draw INTEGER DEFAULT 0;
ALTER TABLE Records ADD COLUMN awayWin INTEGER DEFAULT 0;

UPDATE Records
SET
  homeWin = CASE WHEN homeSecondHalfScore > awaySecondHalfScore THEN 1 ELSE 0 END,
  draw = CASE WHEN homeSecondHalfScore = awaySecondHalfScore THEN 1 ELSE 0 END,
  awayWin = CASE WHEN homeSecondHalfScore < awaySecondHalfScore THEN 1 ELSE 0 END
WHERE FINISHED = 1;
