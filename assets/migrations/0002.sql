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
