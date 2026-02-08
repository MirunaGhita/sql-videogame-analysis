/*===================================================================
                           VIDEO GAMES ANALYSIS
=====================================================================

=====================================================================
1) Find the top-performing genres, platforms, and games per region.
=====================================================================*/
-- Top genre: 
SELECT TOP 10
    Genre,
    ROUND(SUM(NA_Sales), 2) AS NA_Sales,
    ROUND(SUM(EU_Sales), 2) AS EU_Sales,
    ROUND(SUM(JP_Sales), 2) AS JP_Sales,
    ROUND(SUM(Global_Sales), 2) AS Global_Sales
FROM dbo.vgsales
GROUP BY Genre
ORDER BY Global_Sales DESC;
-- Top platform: 
SELECT TOP 10
    Platform,
    ROUND(SUM(NA_Sales), 2) AS NA_Sales,
    ROUND(SUM(EU_Sales), 2) AS EU_Sales,
    ROUND(SUM(JP_Sales), 2) AS JP_Sales,
    ROUND(SUM(Global_Sales), 2) AS Global_Sales
FROM dbo.vgsales
GROUP BY Platform
ORDER BY Global_Sales DESC;
-- Top games: 
SELECT TOP 10
    Name AS Game,
    ROUND(SUM(NA_Sales), 2) AS NA_Sales,
    ROUND(SUM(EU_Sales), 2) AS EU_Sales,
    ROUND(SUM(JP_Sales), 2) AS JP_Sales,
    ROUND(SUM(Global_Sales), 2) AS Global_Sales
FROM dbo.vgsales
GROUP BY Name
ORDER BY Global_Sales DESC;
/*=====================================================================
2) Identify the #1 platform for each decade based on total sales
=====================================================================*/
WITH PlatformDecades AS (
    SELECT 
        Platform,
        CASE 
            WHEN TRY_CAST(Year AS INT) BETWEEN 1980 AND 1989 THEN '1980s'
            WHEN TRY_CAST(Year AS INT) BETWEEN 1990 AND 1999 THEN '1990s'
            WHEN TRY_CAST(Year AS INT) BETWEEN 2000 AND 2009 THEN '2000s'
            WHEN TRY_CAST(Year AS INT) BETWEEN 2010 AND 2019 THEN '2010s'
            WHEN TRY_CAST(Year AS INT) >= 2020 THEN '2020s'
            ELSE 'Unknown'
        END AS Decade,
        Global_Sales
    FROM dbo.vgsales
),
DecadeSummary AS (
    SELECT 
        Decade,
        Platform,
        COUNT(*) AS Game_Count,
        ROUND(SUM(Global_Sales), 2) AS Total_Sales,
        RANK() OVER (PARTITION BY Decade ORDER BY SUM(Global_Sales) DESC) AS Platform_Rank
    FROM PlatformDecades
    WHERE Decade != 'Unknown'
    GROUP BY Decade, Platform
)
SELECT 
    Decade,
    Platform,
    Game_Count,
    Total_Sales
FROM DecadeSummary
WHERE Platform_Rank = 1
ORDER BY Decade;

/*=====================================================================
3) Genre “Mood Tracker”
- Assign moods to genres (RPG = adventurous, Simulation = chill, etc).
- Track “gamer mood” per region over time 
- Show trends
=====================================================================*/

-- Mood by decade
SELECT
    CASE 
        WHEN TRY_CAST(Year AS INT) BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 1990 AND 1999 THEN '1990s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2000 AND 2009 THEN '2000s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2010 AND 2019 THEN '2010s'
        WHEN TRY_CAST(Year AS INT) >= 2020 THEN '2020s'
        ELSE 'Unknown'
    END AS Decade,
    Mood
FROM (
    SELECT
        Year,
        CASE
            WHEN Genre IN ('RPG','Adventure') THEN 'Adventurous'
            WHEN Genre IN ('Action','Shooter','Fighting') THEN 'Intense'
            WHEN Genre IN ('Sports','Racing') THEN 'Competitive'
            WHEN Genre IN ('Simulation','Puzzle') THEN 'Chill'
            WHEN Genre = 'Platform' THEN 'Fun'
            WHEN Genre = 'Strategy' THEN 'Thoughtful'
            ELSE 'Misc'
        END AS Mood
    FROM dbo.vgsales
) AS MoodTable
WHERE TRY_CAST(Year AS INT) IS NOT NULL
GROUP BY
    CASE 
        WHEN TRY_CAST(Year AS INT) BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 1990 AND 1999 THEN '1990s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2000 AND 2009 THEN '2000s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2010 AND 2019 THEN '2010s'
        WHEN TRY_CAST(Year AS INT) >= 2020 THEN '2020s'
        ELSE 'Unknown'
    END,
    Mood
ORDER BY Decade, Mood;

-- Mood by region
WITH MoodBase AS (
    SELECT
        CASE
            WHEN Genre IN ('RPG','Adventure') THEN 'Adventurous'
            WHEN Genre IN ('Action','Shooter','Fighting') THEN 'Intense'
            WHEN Genre IN ('Sports','Racing') THEN 'Competitive'
            WHEN Genre IN ('Simulation','Puzzle') THEN 'Chill'
            WHEN Genre = 'Platform' THEN 'Fun'
            WHEN Genre = 'Strategy' THEN 'Thoughtful'
            ELSE 'Misc'
        END AS Mood,
        TRY_CAST(NA_Sales AS FLOAT) AS NA_Sales,
        TRY_CAST(EU_Sales AS FLOAT) AS EU_Sales,
        TRY_CAST(JP_Sales AS FLOAT) AS JP_Sales
    FROM dbo.vgsales
),
RegionMood AS (
    SELECT 'North America' AS Region, Mood
    FROM MoodBase
    WHERE NA_Sales > 0

    UNION ALL

    SELECT 'Europe', Mood
    FROM MoodBase
    WHERE EU_Sales > 0

    UNION ALL

    SELECT 'Japan', Mood
    FROM MoodBase
    WHERE JP_Sales > 0
)
SELECT
    Region,
    Mood
FROM RegionMood
GROUP BY Region, Mood
ORDER BY Region, Mood;


-- Overall Mood Tracker with sales
SELECT
    CASE 
        WHEN TRY_CAST(Year AS INT) BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 1990 AND 1999 THEN '1990s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2000 AND 2009 THEN '2000s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2010 AND 2019 THEN '2010s'
        WHEN TRY_CAST(Year AS INT) >= 2020 THEN '2020s'
        ELSE 'Unknown'
    END AS Decade,
    Mood,
    ROUND(SUM(Global_Sales), 2) AS Global_Sales,
    ROUND(SUM(NA_Sales), 2) AS NA_Sales,
    ROUND(SUM(EU_Sales), 2) AS EU_Sales,
    ROUND(SUM(JP_Sales), 2) AS JP_Sales
FROM (
    SELECT *,
        CASE
            WHEN Genre IN ('RPG','Adventure') THEN 'Adventurous'
            WHEN Genre IN ('Action','Shooter','Fighting') THEN 'Intense'
            WHEN Genre IN ('Sports','Racing') THEN 'Competitive'
            WHEN Genre IN ('Simulation','Puzzle') THEN 'Chill'
            WHEN Genre IN ('Platform') THEN 'Fun'
            WHEN Genre IN ('Strategy') THEN 'Thoughtful'
            ELSE 'Misc'
        END AS Mood
    FROM dbo.vgsales
) AS MoodTable
GROUP BY 
    CASE 
        WHEN TRY_CAST(Year AS INT) BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 1990 AND 1999 THEN '1990s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2000 AND 2009 THEN '2000s'
        WHEN TRY_CAST(Year AS INT) BETWEEN 2010 AND 2019 THEN '2010s'
        WHEN TRY_CAST(Year AS INT) >= 2020 THEN '2020s'
        ELSE 'Unknown'
    END,
    Mood
ORDER BY Decade, Global_Sales DESC;

