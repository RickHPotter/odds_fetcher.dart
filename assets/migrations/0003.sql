CREATE INDEX IF NOT EXISTS idx_records_matchDate ON Records(MatchDate);
CREATE INDEX IF NOT EXISTS idx_records_odds ON Records(earlyOdds1, earlyOddsX, earlyOdds2, finalOdds1, finalOddsX, finalOdds2);
