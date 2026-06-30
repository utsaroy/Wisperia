-- ============================================================
-- Whisperia: 03_create_indexes.sql
-- Performance indexes on frequently queried columns
-- ============================================================
--
-- DBMS Concepts Demonstrated:
--   * B-tree Indexes for query optimization
--   * Indexes on Foreign Key columns (JOIN performance)
--   * Indexes on columns used in WHERE / ORDER BY clauses
--   * Composite indexes for multi-column lookups
--
-- Note: Oracle automatically creates indexes on PRIMARY KEY
--       and UNIQUE constraint columns. We only create indexes
--       on Foreign Key and frequently-searched columns here.
-- ============================================================

-- Index on Questions.UserID (for "questions by user" lookups)
CREATE INDEX idx_questions_userid ON Questions(UserID);

-- Index on Questions.CategoryID (for category filtering)
CREATE INDEX idx_questions_categoryid ON Questions(CategoryID);

-- Index on Questions.CreatedAt (for sorting by date)
CREATE INDEX idx_questions_createdat ON Questions(CreatedAt);

-- Index on Answers.QuestionID (for fetching answers of a question)
CREATE INDEX idx_answers_questionid ON Answers(QuestionID);

-- Index on Answers.UserID (for "answers by user" lookups)
CREATE INDEX idx_answers_userid ON Answers(UserID);

-- Index on Votes.AnswerID (for counting votes on an answer)
CREATE INDEX idx_votes_answerid ON Votes(AnswerID);

-- Index on Votes.UserID (for checking if user already voted)
CREATE INDEX idx_votes_userid ON Votes(UserID);

-- Index on Bookmarks.UserID (for "user's bookmarks" lookups)
CREATE INDEX idx_bookmarks_userid ON Bookmarks(UserID);

-- Index on Bookmarks.QuestionID (for "bookmark count" lookups)
CREATE INDEX idx_bookmarks_questionid ON Bookmarks(QuestionID);

-- Index on Notifications.UserID (for fetching user notifications)
CREATE INDEX idx_notifications_userid ON Notifications(UserID);

-- Index on Notifications.IsRead (for filtering unread notifications)
CREATE INDEX idx_notifications_isread ON Notifications(IsRead);

-- Index on Reports.Status (for admin filtering pending reports)
CREATE INDEX idx_reports_status ON Reports(Status);

-- Index on Tags.TagName (for tag search/lookup)
CREATE INDEX idx_tags_tagname ON Tags(TagName);
