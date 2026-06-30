-- ============================================================
-- Whisperia: 09_reports.sql
-- 10 Reporting Queries demonstrating SQL concepts
-- ============================================================

-- REPORT 1: Top 10 Contributors
-- Concepts: UNION ALL, GROUP BY, ORDER BY, FETCH FIRST, NVL
SELECT UserID, Username,
       SUM(QCount) AS QuestionsAsked,
       SUM(ACount) AS AnswersPosted,
       SUM(QCount) + SUM(ACount) AS TotalContributions
FROM (
    SELECT u.UserID, u.Username, COUNT(*) AS QCount, 0 AS ACount
    FROM Users u JOIN Questions q ON u.UserID = q.UserID
    GROUP BY u.UserID, u.Username
    UNION ALL
    SELECT u.UserID, u.Username, 0 AS QCount, COUNT(*) AS ACount
    FROM Users u JOIN Answers a ON u.UserID = a.UserID
    GROUP BY u.UserID, u.Username
)
GROUP BY UserID, Username
ORDER BY TotalContributions DESC
FETCH FIRST 10 ROWS ONLY;

-- REPORT 2: Questions per Category
-- Concepts: JOIN, GROUP BY, COUNT, ORDER BY
SELECT c.CategoryName, COUNT(q.QuestionID) AS QuestionCount
FROM Categories c
LEFT JOIN Questions q ON c.CategoryID = q.CategoryID
GROUP BY c.CategoryName
ORDER BY QuestionCount DESC;

-- REPORT 3: Answers per Question
-- Concepts: LEFT JOIN, GROUP BY, COUNT
SELECT q.QuestionID, q.Title,
       COUNT(a.AnswerID) AS AnswerCount
FROM Questions q
LEFT JOIN Answers a ON q.QuestionID = a.QuestionID
GROUP BY q.QuestionID, q.Title
ORDER BY AnswerCount DESC;

-- REPORT 4: Most Popular Tags
-- Concepts: JOIN (3 tables), GROUP BY, COUNT, ORDER BY
SELECT t.TagName, COUNT(qt.QuestionID) AS UsageCount
FROM Tags t
JOIN QuestionTags qt ON t.TagID = qt.TagID
JOIN Questions q ON qt.QuestionID = q.QuestionID
GROUP BY t.TagName
ORDER BY UsageCount DESC;

-- REPORT 5: Questions Without Answers
-- Concepts: NOT EXISTS, Correlated Subquery
SELECT q.QuestionID, q.Title, u.Username AS Author, q.CreatedAt
FROM Questions q
JOIN Users u ON q.UserID = u.UserID
WHERE NOT EXISTS (
    SELECT 1 FROM Answers a WHERE a.QuestionID = q.QuestionID
)
ORDER BY q.CreatedAt DESC;

-- REPORT 6: Average Answers per Category (min 1 question)
-- Concepts: JOIN, GROUP BY, AVG, HAVING, ROUND
SELECT c.CategoryName,
       COUNT(DISTINCT q.QuestionID) AS QuestionCount,
       COUNT(a.AnswerID) AS TotalAnswers,
       ROUND(COUNT(a.AnswerID) / NULLIF(COUNT(DISTINCT q.QuestionID), 0), 2) AS AvgAnswers
FROM Categories c
JOIN Questions q ON c.CategoryID = q.CategoryID
LEFT JOIN Answers a ON q.QuestionID = a.QuestionID
GROUP BY c.CategoryName
HAVING COUNT(DISTINCT q.QuestionID) >= 1
ORDER BY AvgAnswers DESC;

-- REPORT 7: Most Active Users (questions + answers + votes)
-- Concepts: UNION ALL, GROUP BY, SUM, ORDER BY
SELECT UserID, Username, SUM(ActionCount) AS TotalActions
FROM (
    SELECT u.UserID, u.Username, COUNT(*) AS ActionCount FROM Users u JOIN Questions q ON u.UserID = q.UserID GROUP BY u.UserID, u.Username
    UNION ALL
    SELECT u.UserID, u.Username, COUNT(*) FROM Users u JOIN Answers a ON u.UserID = a.UserID GROUP BY u.UserID, u.Username
    UNION ALL
    SELECT u.UserID, u.Username, COUNT(*) FROM Users u JOIN Votes v ON u.UserID = v.UserID GROUP BY u.UserID, u.Username
)
GROUP BY UserID, Username
ORDER BY TotalActions DESC;

-- REPORT 8: Questions Created per Month
-- Concepts: EXTRACT, GROUP BY, COUNT, ORDER BY
SELECT EXTRACT(YEAR FROM CreatedAt) AS Year,
       EXTRACT(MONTH FROM CreatedAt) AS Month,
       COUNT(*) AS QuestionCount
FROM Questions
GROUP BY EXTRACT(YEAR FROM CreatedAt), EXTRACT(MONTH FROM CreatedAt)
ORDER BY Year DESC, Month DESC;

-- REPORT 9: Votes Received by Each Answer
-- Concepts: JOIN, GROUP BY, SUM, CASE
SELECT a.AnswerID,
       SUBSTR(a.AnswerText, 1, 100) AS AnswerPreview,
       u.Username AS AnswerAuthor,
       SUM(CASE WHEN v.VoteType = 'up' THEN 1 ELSE 0 END) AS Upvotes,
       SUM(CASE WHEN v.VoteType = 'down' THEN 1 ELSE 0 END) AS Downvotes,
       SUM(CASE WHEN v.VoteType = 'up' THEN 1 ELSE -1 END) AS NetVotes
FROM Answers a
JOIN Users u ON a.UserID = u.UserID
LEFT JOIN Votes v ON a.AnswerID = v.AnswerID
GROUP BY a.AnswerID, SUBSTR(a.AnswerText, 1, 100), u.Username
ORDER BY NetVotes DESC;

-- REPORT 10: Most Bookmarked Questions
-- Concepts: JOIN, GROUP BY, COUNT, ORDER BY, FETCH FIRST
SELECT q.QuestionID, q.Title, u.Username AS Author,
       COUNT(b.BookmarkID) AS BookmarkCount
FROM Questions q
JOIN Users u ON q.UserID = u.UserID
JOIN Bookmarks b ON q.QuestionID = b.QuestionID
GROUP BY q.QuestionID, q.Title, u.Username
ORDER BY BookmarkCount DESC
FETCH FIRST 10 ROWS ONLY;
