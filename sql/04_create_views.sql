-- ============================================================
-- Whisperia: 04_create_views.sql
-- Database Views for commonly accessed aggregated data
-- ============================================================
--
-- DBMS Concepts Demonstrated:
--   * CREATE OR REPLACE VIEW
--   * JOIN (INNER, LEFT)
--   * GROUP BY with Aggregate Functions (COUNT, SUM, AVG)
--   * ORDER BY
--   * Subqueries within views
--   * COALESCE / NVL for null handling
--   * FETCH FIRST N ROWS ONLY (Oracle 12c+)
-- ============================================================

-- ============================================================
-- VIEW 1: TopContributors
-- Ranks users by total contributions (questions + answers)
-- Demonstrates: LEFT JOIN, GROUP BY, COUNT, ORDER BY, NVL
-- ============================================================
CREATE OR REPLACE VIEW TopContributors AS
SELECT
    u.UserID,
    u.Username,
    u.JoinDate,
    NVL(q.QuestionCount, 0) AS QuestionsAsked,
    NVL(a.AnswerCount, 0)   AS AnswersPosted,
    NVL(q.QuestionCount, 0) + NVL(a.AnswerCount, 0) AS TotalContributions
FROM Users u
LEFT JOIN (
    SELECT UserID, COUNT(*) AS QuestionCount
    FROM Questions
    GROUP BY UserID
) q ON u.UserID = q.UserID
LEFT JOIN (
    SELECT UserID, COUNT(*) AS AnswerCount
    FROM Answers
    GROUP BY UserID
) a ON u.UserID = a.UserID
WHERE u.Role = 'user'
ORDER BY TotalContributions DESC;

-- ============================================================
-- VIEW 2: PopularQuestions
-- Ranks questions by answer count and total votes received
-- Demonstrates: LEFT JOIN, GROUP BY, COUNT, SUM, CASE, NVL
-- ============================================================
CREATE OR REPLACE VIEW PopularQuestions AS
SELECT
    q.QuestionID,
    q.Title,
    q.CreatedAt,
    u.Username AS Author,
    c.CategoryName,
    NVL(ans.AnswerCount, 0) AS AnswerCount,
    NVL(v.TotalVotes, 0)    AS TotalVotes
FROM Questions q
JOIN Users u ON q.UserID = u.UserID
JOIN Categories c ON q.CategoryID = c.CategoryID
LEFT JOIN (
    SELECT QuestionID, COUNT(*) AS AnswerCount
    FROM Answers
    GROUP BY QuestionID
) ans ON q.QuestionID = ans.QuestionID
LEFT JOIN (
    SELECT a.QuestionID,
           SUM(CASE WHEN v.VoteType = 'up' THEN 1 ELSE -1 END) AS TotalVotes
    FROM Votes v
    JOIN Answers a ON v.AnswerID = a.AnswerID
    GROUP BY a.QuestionID
) v ON q.QuestionID = v.QuestionID
ORDER BY TotalVotes DESC, AnswerCount DESC;

-- ============================================================
-- VIEW 3: CategoryStatistics
-- Shows question count and average answers per category
-- Demonstrates: JOIN, LEFT JOIN, GROUP BY, COUNT, AVG, NVL
-- ============================================================
CREATE OR REPLACE VIEW CategoryStatistics AS
SELECT
    c.CategoryID,
    c.CategoryName,
    COUNT(DISTINCT q.QuestionID) AS QuestionCount,
    COUNT(a.AnswerID)            AS TotalAnswers,
    ROUND(NVL(COUNT(a.AnswerID) / NULLIF(COUNT(DISTINCT q.QuestionID), 0), 0), 2) AS AvgAnswersPerQuestion
FROM Categories c
LEFT JOIN Questions q ON c.CategoryID = q.CategoryID
LEFT JOIN Answers a ON q.QuestionID = a.QuestionID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY QuestionCount DESC;

-- ============================================================
-- VIEW 4: RecentQuestions
-- Last 50 questions with author and category info
-- Demonstrates: JOIN, ORDER BY, FETCH FIRST N ROWS
-- ============================================================
CREATE OR REPLACE VIEW RecentQuestions AS
SELECT
    q.QuestionID,
    q.Title,
    q.Description,
    q.CreatedAt,
    u.UserID,
    u.Username AS Author,
    c.CategoryID,
    c.CategoryName
FROM Questions q
JOIN Users u ON q.UserID = u.UserID
JOIN Categories c ON q.CategoryID = c.CategoryID
ORDER BY q.CreatedAt DESC
FETCH FIRST 50 ROWS ONLY;

-- ============================================================
-- VIEW 5: UserActivity
-- Per-user statistics: questions, answers, votes given
-- Demonstrates: LEFT JOIN with subqueries, GROUP BY, NVL
-- ============================================================
CREATE OR REPLACE VIEW UserActivity AS
SELECT
    u.UserID,
    u.Username,
    u.Email,
    u.Role,
    u.JoinDate,
    NVL(q.QuestionCount, 0) AS QuestionsAsked,
    NVL(a.AnswerCount, 0)   AS AnswersPosted,
    NVL(v.VotesGiven, 0)    AS VotesGiven,
    NVL(b.BookmarkCount, 0) AS BookmarksMade
FROM Users u
LEFT JOIN (
    SELECT UserID, COUNT(*) AS QuestionCount FROM Questions GROUP BY UserID
) q ON u.UserID = q.UserID
LEFT JOIN (
    SELECT UserID, COUNT(*) AS AnswerCount FROM Answers GROUP BY UserID
) a ON u.UserID = a.UserID
LEFT JOIN (
    SELECT UserID, COUNT(*) AS VotesGiven FROM Votes GROUP BY UserID
) v ON u.UserID = v.UserID
LEFT JOIN (
    SELECT UserID, COUNT(*) AS BookmarkCount FROM Bookmarks GROUP BY UserID
) b ON u.UserID = b.UserID;
