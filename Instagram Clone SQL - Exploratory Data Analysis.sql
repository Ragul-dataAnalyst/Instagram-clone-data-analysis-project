/* ---------------------------------------------------------------
   INSTAGRAM CLONE EXPLORATORY DATA ANALYSIS USING SQL SERVER
   SQL SKILLS: Joins, date manipulation, string manipulation,
   aggregate functions, views, stored procedures
-----------------------------------------------------------------*/

---------------------------------------------------------------
-- Q1. The first 10 users on the platform
---------------------------------------------------------------
SELECT TOP 10 *
FROM users
ORDER BY created_at ASC;

---------------------------------------------------------------
-- Q2. Total number of registrations
---------------------------------------------------------------
SELECT COUNT(*) AS [Total Registration]
FROM users;

---------------------------------------------------------------
-- Q3. The day of the week most users register on
---------------------------------------------------------------
SELECT DATENAME(WEEKDAY, created_at) AS [Day of the Week],
       COUNT(*) AS [Total Registration]
FROM users
GROUP BY DATENAME(WEEKDAY, created_at)
ORDER BY [Total Registration] DESC;

---------------------------------------------------------------
-- Q4. The users who have never posted a photo
---------------------------------------------------------------
SELECT u.username
FROM users u
LEFT JOIN photos p ON p.user_id = u.id
WHERE p.id IS NULL;

---------------------------------------------------------------
-- Q5. The most likes on a single photo
---------------------------------------------------------------
SELECT TOP 1 u.username, p.image_url, COUNT(*) AS total
FROM photos p
INNER JOIN likes l ON l.photo_id = p.id
INNER JOIN users u ON p.user_id = u.id
GROUP BY u.username, p.image_url, p.id
ORDER BY total DESC;

-- Version 2: Average posts per user
SELECT ROUND(
        CAST((SELECT COUNT(*) FROM photos) AS FLOAT) /
        NULLIF((SELECT COUNT(*) FROM users), 0), 2
) AS [Average Posts by Users];

---------------------------------------------------------------
-- Q6. The number of photos posted by most active users
---------------------------------------------------------------
SELECT TOP 5 
    u.username AS [Username],
    COUNT(p.image_url) AS [Number of Posts]
FROM users u
JOIN photos p ON u.id = p.user_id
GROUP BY u.username
ORDER BY [Number of Posts] DESC;

---------------------------------------------------------------
-- Q7. The total number of posts
---------------------------------------------------------------
SELECT SUM(user_posts.total_posts_per_user) AS [Total Posts by Users]
FROM (
    SELECT u.username, COUNT(p.image_url) AS total_posts_per_user
    FROM users u
    JOIN photos p ON u.id = p.user_id
    GROUP BY u.username
) AS user_posts;

---------------------------------------------------------------
-- Q8. The total number of users with posts
---------------------------------------------------------------
SELECT COUNT(DISTINCT u.id) AS total_number_of_users_with_posts
FROM users u
JOIN photos p ON u.id = p.user_id;

---------------------------------------------------------------
-- Q9. The usernames with numbers as ending
---------------------------------------------------------------
SELECT id, username
FROM users
WHERE username LIKE '%[0-9]';

---------------------------------------------------------------
-- Q10. The usernames with characters as ending
---------------------------------------------------------------
SELECT id, username
FROM users
WHERE username LIKE '%[a-zA-Z]';

---------------------------------------------------------------
-- Q11. The number of usernames that start with A
---------------------------------------------------------------
SELECT COUNT(id) AS total_A
FROM users
WHERE username LIKE 'A%';

---------------------------------------------------------------
-- Q12. The most popular tag names by usage
---------------------------------------------------------------
SELECT TOP 10 
    t.tag_name, COUNT(*) AS seen_used
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY seen_used DESC;

---------------------------------------------------------------
-- Q13. The most popular tag names by likes
---------------------------------------------------------------
SELECT TOP 10 
    t.tag_name AS [Tag Name],
    COUNT(l.photo_id) AS [Number of Likes]
FROM photo_tags pt
JOIN likes l ON l.photo_id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY [Number of Likes] DESC;

---------------------------------------------------------------
-- Q14. The users who have liked every single photo on the site
---------------------------------------------------------------
SELECT u.id, u.username, COUNT(l.user_id) AS total_likes_by_user
FROM users u
JOIN likes l ON u.id = l.user_id
GROUP BY u.id, u.username
HAVING COUNT(l.user_id) = (SELECT COUNT(*) FROM photos);

---------------------------------------------------------------
-- Q15. Total number of users without comments
---------------------------------------------------------------
SELECT COUNT(*) AS total_number_of_users_without_comments
FROM users u
LEFT JOIN comments c ON u.id = c.user_id
WHERE c.comment_text IS NULL;

---------------------------------------------------------------
-- Q16. The percentage of users who have either never commented on a photo or liked every photo
---------------------------------------------------------------
-- Users who never commented
WITH never_commented AS (
    SELECT COUNT(DISTINCT u.id) AS total_A
    FROM users u
    LEFT JOIN comments c ON u.id = c.user_id
    WHERE c.comment_text IS NULL
),
likes_all AS (
    SELECT COUNT(*) AS total_B
    FROM (
        SELECT u.id
        FROM users u
        JOIN likes l ON u.id = l.user_id
        GROUP BY u.id
        HAVING COUNT(*) = (SELECT COUNT(*) FROM photos)
    ) x
)
SELECT 
    total_A AS [Number Of Users who never commented],
    CAST(total_A AS FLOAT) / (SELECT COUNT(*) FROM users) * 100 AS [% who never commented],
    total_B AS [Number of Users who like every photo],
    CAST(total_B AS FLOAT) / (SELECT COUNT(*) FROM users) * 100 AS [% who like all photos]
FROM never_commented, likes_all;

---------------------------------------------------------------
-- Q17. Clean URLs of photos posted on the platform
---------------------------------------------------------------
SELECT RIGHT(image_url, LEN(image_url) - CHARINDEX('/', image_url)) AS IMAGE_URL
FROM photos;

---------------------------------------------------------------
-- Q18. The average time on the platform
---------------------------------------------------------------
SELECT ROUND(AVG(DATEDIFF(DAY, created_at, GETDATE())) / 365.0, 2) AS Total_Years_on_Platform
FROM users;

---------------------------------------------------------------
-- STORED PROCEDURES
---------------------------------------------------------------

-- SP1. Popular hashtags list

CREATE OR ALTER PROCEDURE spPopularTags
AS
BEGIN
    SELECT t.tag_name, COUNT(*) AS HashtagCounts
    FROM tags t
    JOIN photo_tags pt ON t.id = pt.tag_id
    GROUP BY t.tag_name
    ORDER BY HashtagCounts DESC;
END;
GO

EXEC spPopularTags;
GO
-- SP2. Users who have engaged at least one time on the platform
CREATE OR ALTER PROCEDURE spEngagedUser
AS
BEGIN
    SELECT DISTINCT u.username
    FROM users u
    LEFT JOIN photos p ON p.user_id = u.id
    LEFT JOIN likes l ON l.user_id = u.id
    WHERE p.id IS NOT NULL OR l.user_id IS NOT NULL;
END;
GO

EXEC spEngagedUser;
GO

-- SP3. Total number of comments by the users on the platform
CREATE OR ALTER PROCEDURE spUserComments
AS
BEGIN
    SELECT COUNT(*) AS [Total Number of Comments]
    FROM comments c
    WHERE c.comment_text IS NOT NULL;
END;
GO

EXEC spUserComments;
GO

-- SP4. The username, image posted, tags used and comments made by a specific user
CREATE OR ALTER PROCEDURE spUserInfo @userid INT
AS
BEGIN
    SELECT u.id, u.username, p.image_url, c.comment_text, t.tag_name
    FROM users u
    LEFT JOIN photos p ON p.user_id = u.id
    LEFT JOIN comments c ON c.user_id = u.id
    LEFT JOIN photo_tags pt ON pt.photo_id = p.id
    LEFT JOIN tags t ON t.id = pt.tag_id
    WHERE u.id = @userid;
END;
GO

EXEC spUserInfo 2;
GO
