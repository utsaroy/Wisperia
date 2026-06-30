-- ============================================================
-- Whisperia: 11_advanced_queries.sql
-- Advanced SQL queries showcasing all required concepts
-- ============================================================

-- ============================================================
-- 1. INNER JOIN: Users who have asked questions
-- ============================================================
SELECT u.Username, q.Title, q.CreatedAt
FROM Users u
INNER JOIN Questions q ON u.UserID = q.UserID
ORDER BY q.CreatedAt DESC;

-- ============================================================
-- 2. LEFT JOIN: All users with their question count (incl. 0)
-- ============================================================
SELECT u.Username, COUNT(q.QuestionID) AS QuestionCount
FROM Users u
LEFT JOIN Questions q ON u.UserID = q.UserID
GROUP BY u.Username
ORDER BY QuestionCount DESC;

-- ============================================================
-- 3. RIGHT JOIN: All categories even without questions
-- ============================================================
SELECT c.CategoryName, q.Title
FROM Questions q
RIGHT JOIN Categories c ON q.CategoryID = c.CategoryID
ORDER BY c.CategoryName;

-- ============================================================
-- 4. FULL OUTER JOIN: All users and all questions
-- ============================================================
SELECT u.Username, q.Title
FROM Users u
FULL OUTER JOIN Questions q ON u.UserID = q.UserID
ORDER BY u.Username;

-- ============================================================
-- 5. IN: Questions in specific categories
-- ============================================================
SELECT q.Title, c.CategoryName
FROM Questions q
JOIN Categories c ON q.CategoryID = c.CategoryID
WHERE c.CategoryName IN ('Programming', 'Database', 'Web Development');

-- ============================================================
-- 6. EXISTS: Users who have posted at least one answer
-- ============================================================
SELECT u.Username, u.Email
FROM Users u
WHERE EXISTS (
    SELECT 1 FROM Answers a WHERE a.UserID = u.UserID
);

-- ============================================================
-- 7. NOT EXISTS: Questions that have no answers
-- ============================================================
SELECT q.Title, q.CreatedAt
FROM Questions q
WHERE NOT EXISTS (
    SELECT 1 FROM Answers a WHERE a.QuestionID = q.QuestionID
);

-- ============================================================
-- 8. Correlated Subquery: Users with more answers than average
-- ============================================================
SELECT u.Username,
       (SELECT COUNT(*) FROM Answers a WHERE a.UserID = u.UserID) AS AnswerCount
FROM Users u
WHERE (SELECT COUNT(*) FROM Answers a WHERE a.UserID = u.UserID) >
      (SELECT AVG(cnt) FROM (SELECT COUNT(*) AS cnt FROM Answers GROUP BY UserID));

-- ============================================================
-- 9. Non-correlated Subquery: Questions by the most active user
-- ============================================================
SELECT q.Title, q.CreatedAt
FROM Questions q
WHERE q.UserID = (
    SELECT UserID FROM (
        SELECT UserID, COUNT(*) AS cnt
        FROM Questions
        GROUP BY UserID
        ORDER BY cnt DESC
        FETCH FIRST 1 ROW ONLY
    )
);

-- ============================================================
-- 10. Nested Subquery: Tags used by questions with answers
-- ============================================================
SELECT DISTINCT t.TagName
FROM Tags t
WHERE t.TagID IN (
    SELECT qt.TagID FROM QuestionTags qt
    WHERE qt.QuestionID IN (
        SELECT DISTINCT a.QuestionID FROM Answers a
    )
);

-- ============================================================
-- 11. UNION: Combined list of question and answer authors
-- ============================================================
SELECT Username, 'Question' AS ContributionType FROM Users WHERE UserID IN (SELECT UserID FROM Questions)
UNION
SELECT Username, 'Answer' AS ContributionType FROM Users WHERE UserID IN (SELECT UserID FROM Answers);

-- ============================================================
-- 12. UNION ALL: All activity (questions + answers) with counts
-- ============================================================
SELECT 'Questions' AS Type, COUNT(*) AS Total FROM Questions
UNION ALL
SELECT 'Answers' AS Type, COUNT(*) AS Total FROM Answers
UNION ALL
SELECT 'Votes' AS Type, COUNT(*) AS Total FROM Votes;

-- ============================================================
-- 13. GROUP BY + HAVING: Categories with more than 1 question
-- ============================================================
SELECT c.CategoryName, COUNT(q.QuestionID) AS QuestionCount
FROM Categories c
JOIN Questions q ON c.CategoryID = q.CategoryID
GROUP BY c.CategoryName
HAVING COUNT(q.QuestionID) > 1
ORDER BY QuestionCount DESC;

-- ============================================================
-- 14. ORDER BY multiple columns
-- ============================================================
SELECT q.Title, c.CategoryName, q.CreatedAt
FROM Questions q
JOIN Categories c ON q.CategoryID = c.CategoryID
ORDER BY c.CategoryName ASC, q.CreatedAt DESC;

-- ============================================================
-- 15. Aggregate Functions: Platform statistics
-- ============================================================
SELECT
    COUNT(DISTINCT q.QuestionID) AS TotalQuestions,
    COUNT(DISTINCT a.AnswerID) AS TotalAnswers,
    MIN(q.CreatedAt) AS FirstQuestion,
    MAX(q.CreatedAt) AS LatestQuestion,
    ROUND(AVG(ac.AnswerCount), 2) AS AvgAnswersPerQuestion
FROM Questions q
LEFT JOIN Answers a ON q.QuestionID = a.QuestionID
LEFT JOIN (
    SELECT QuestionID, COUNT(*) AS AnswerCount
    FROM Answers GROUP BY QuestionID
) ac ON q.QuestionID = ac.QuestionID;
