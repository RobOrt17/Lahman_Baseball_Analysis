-- 1
SELECT MIN(yearid), MAX(yearid)
FROM teams;
-- A: 1871, 2016

-- 2 
SELECT namegiven, namefirst, namelast, MIN(height) AS min_height, teams.name
FROM people
LEFT JOIN batting 
ON people.playerid = batting.playerid
LEFT JOIN teams
ON teams.teamid = batting.teamid
GROUP BY namegiven, namefirst, namelast, teams.name
ORDER BY min_height 
LIMIT 1;
-- A: Edward Gaedel, 43in. / Team: St. Louis Browns

-- 3 
SELECT people.namefirst, people.namelast, SUM(salaries.salary) AS total_salary_earned, schools.schoolname
FROM people
INNER JOIN salaries
ON people.playerid = salaries.playerid 
INNER JOIN collegeplaying
ON people.playerid = collegeplaying.playerid
INNER JOIN schools
ON people.playerid = collegeplaying.playerid
WHERE schools.schoolname = 'Vanderbilt University'
GROUP BY people.namefirst, people.namelast, salaries.salary, schools.schoolname
ORDER BY SUM(salaries.salary) DESC;

SELECT namefirst, namelast, SUM(COALESCE(salary,0))::int::money AS total_salary_earned
FROM people
LEFT JOIN salaries
USING (playerid)
WHERE playerid IN (SELECT playerid FROM collegeplaying WHERE schoolid = 'vandy')
GROUP BY playerid
ORDER BY total_salary_earned DESC;
-- A: David Price, highest earner from Vanderbilt


-- 4
SELECT  SUM(po),
		CASE WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		END AS position
FROM fielding
GROUP BY position;


-- 5 helps with number --> 5
SELECT yearid/10*10 AS decades, ROUND(AVG(so),2) AS avg_so_per_game
FROM teams
WHERE yearid >= '1920'
GROUP BY yearid /10
ORDER BY decades

SELECT (yearid/10)*10 as decade, ROUND((SUM(so)::DECIMAL) / (SUM(ghome)::DECIMAL),2) AS so_per_game
FROM teams
WHERE yearid >=1920
GROUP BY decade
ORDER BY decade;
-- ^^S/O

SELECT (yearid/10)*10 as decade, ROUND((SUM(hr)::DECIMAL) / (SUM(ghome)::DECIMAL),2) AS hr_per_game
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;
-- ^^H/R

-- 6 
SELECT people.namefirst, people.namelast, people.namegiven, ROUND((sb * 100)/ (sb + cs)::numeric,2) AS success_percentage
FROM batting
LEFT JOIN people
ON batting.playerid = people.playerid
WHERE yearid = '2016'
AND cs + sb >= 20
ORDER BY success_percentage DESC;


-- 7
SELECT w, name, yearid, wswin
FROM teams
WHERE wswin = 'N'
AND yearid BETWEEN 1970 AND 2016
GROUP BY w, name, yearid, wswin
ORDER BY w DESC
LIMIT 1;
-- A: Seattle Mariners, 2001 @116 wins w/ no WSWin

-- 7b
SELECT w, name, yearid, wswin
FROM teams
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
GROUP BY w, name, yearid, wswin
ORDER BY w 
LIMIT 1;
-- A: LA Dodgers, 1981 @63 wins w/ WSWin ---> strike that year

-- 7c
SELECT w, name, yearid, wswin
FROM teams
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
AND yearid <> '1981'
GROUP BY w, name, yearid, wswin
ORDER BY w 
LIMIT 1;
-- A: St. Louis Cardinals, 2006 @83 wins w/ WSWin

-- 7d
SELECT w, name, yearid, wswin
FROM teams
WHERE wswin = 'N'
AND yearid BETWEEN 1970 AND 2016
AND yearid <> '1981'
GROUP BY w, name, yearid, wswin
ORDER BY w DESC;

WITH ws_win_percentage AS (SELECT yearid, name, wswin,
					(CASE WHEN w = MAX(w) OVER (PARTITION BY yearid) AND wswin = 'Y' THEN 1 ELSE 0 END) AS max_win
				FROM teams
				WHERE yearid BETWEEN 1970 AND 2016
				AND yearid <> '1981')
SELECT ROUND(SUM(max_win)::DECIMAL / COUNT(wswin) * 100,1) AS max_win_perc
FROM ws_win_percentage
WHERE wswin = 'Y';
-- A: 26.7%

-- 8
SELECT p.park_name, t.name, ROUND(AVG(h.attendance / h.games)::DECIMAL, 0) AS avg_attendance
FROM homegames AS h
LEFT JOIN teams AS t
ON h.team = t.teamid
AND h.year = t.yearid
LEFT JOIN parks AS p
ON h.park = p.park
WHERE year = '2016'
AND h.games > 10
GROUP BY t.name, p.park_name
ORDER BY avg_attendance DESC
LIMIT 5;
-- A: Highest Attendance

-- 8b
SELECT Distinct p.park_name, t.name, ROUND(AVG(h.attendance / h.games)::DECIMAL, 0) AS avg_attendance
FROM homegames AS h
LEFT JOIN teams AS t
ON h.team = t.teamid
AND h.year = t.yearid
LEFT JOIN parks AS p
ON h.park = p.park
WHERE year = '2016'
AND h.games > '10'
GROUP BY t.name, p.park_name
ORDER BY avg_attendance 
LIMIT 5;
-- A: Lowest Attendance


-- 9
SELECT p.namefirst, p.namelast, a.awardid, a.lgid, t.name, a.yearid
FROM awardsmanagers AS a
LEFT JOIN people AS p
	ON a.playerid = p.playerid
LEFT JOIN managers AS m 
	ON m.yearid = a.yearid
	AND m.playerid = a.playerid
LEFT JOIN teams AS t
	ON m.yearid = t.yearid
	AND m.teamid = t.teamid
WHERE a.playerid IN (SELECT playerid
			FROM awardsmanagers
			WHERE awardid ILIKE 'TSN%'
			AND lgid = 'AL'
			INTERSECT
			SELECT playerid
			FROM awardsmanagers 
			WHERE awardid ILIKE 'TSN%' 
			AND lgid = 'NL')
AND a.awardid = 'TSN Manager of the Year'
ORDER BY a.yearid;
-- A: JIM LEYLAND & DAVEY JOHNSON WON TSN AWAR IN BOTH AL & NL


-- WORKUP FOR 9
FROM people AS p
LEFT JOIN awardsmanagers AS a
ON p.playerid = a.playerid
LEFT JOIN  teams AS t
ON a.yearid = t.yearid
AND a.lgid = t.lgid
LEFT JOIN managers AS m
ON t.teamid = m.teamid
AND t.yearid = m.yearid
SELECT p.namefirst, p.namelast, t.name, a.awardid, a.lgid, a.yearid
FROM awardsmanagers AS a
LEFT JOIN teams AS t
ON a.yearid = t.yearid
AND a.lgid = t.lgid
LEFT JOIN people AS p
ON a.playerid = p.playerid
WHERE a.awardid = 'TSN Manager of the Year'
AND a.lgid IN ('NL', 'AL')
GROUP BY p.namefirst, p.namelast, t.name, a.awardid, a.lgid, a.yearid
ORDER BY a.yearid DESC;

SELECT p.namefirst, p.namelast
FROM people AS p
LEFT JOIN awardsmanagers AS a
ON p.playerid = a.playerid
WHERE
		(SELECT a.lgid, a.yearid
		FROM awardsmanagers AS a
		WHERE a.awardid = 'TSN Manager of the Year' 
		INTERSECT
		SELECT t.lgid, t.yearid
		FROM teams AS t);

 

WHERE a.awardid = 'TSN Manager of the Year'
AND a.lgid = 'NL' 
AND a.lgid = 'AL'

p.namefirst, p.namelast, t.name

