-- ============================================================
-- Whisperia: 01_create_tables.sql
-- Creates all 10 tables with full relational constraints
-- ============================================================
--
-- DBMS Concepts Demonstrated:
--   * Primary Keys (surrogate keys via sequences)
--   * Foreign Keys with ON DELETE CASCADE
--   * Candidate Keys (Username, Email are UNIQUE)
--   * NOT NULL, UNIQUE, CHECK, DEFAULT constraints
--   * One-to-Many relationships (User -> Questions, Question -> Answers)
--   * Many-to-Many relationships (Questions <-> Tags via QuestionTags)
--   * Composite Primary Key (QuestionTags)
--   * Third Normal Form (3NF) normalization
-- ============================================================

-- Drop tables in reverse dependency order (for re-runs)
BEGIN
   FOR t IN (
      SELECT table_name FROM user_tables
      WHERE table_name IN (
         'REPORTS','NOTIFICATIONS','BOOKMARKS','VOTES',
         'QUESTIONTAGS','TAGS','ANSWERS','QUESTIONS',
         'CATEGORIES','USERS'
      )
   ) LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
   END LOOP;
END;
/

-- ============================================================
-- 1. USERS TABLE
-- ============================================================
-- Candidate Keys: Username, Email (both UNIQUE)
-- Role column enables role-based authorization
-- ============================================================
CREATE TABLE Users (
    UserID       NUMBER        PRIMARY KEY,
    Username     VARCHAR2(50)  NOT NULL UNIQUE,       -- Candidate Key
    Email        VARCHAR2(100) NOT NULL UNIQUE,       -- Candidate Key
    PasswordHash VARCHAR2(255) NOT NULL,
    Role         VARCHAR2(20)  DEFAULT 'user' NOT NULL,
    JoinDate     DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT chk_user_role CHECK (Role IN ('user', 'admin'))
);

-- ============================================================
-- 2. CATEGORIES TABLE
-- ============================================================
-- Simple lookup table, CategoryName is a Candidate Key
-- ============================================================
CREATE TABLE Categories (
    CategoryID   NUMBER        PRIMARY KEY,
    CategoryName VARCHAR2(100) NOT NULL UNIQUE        -- Candidate Key
);

-- ============================================================
-- 3. QUESTIONS TABLE
-- ============================================================
-- One-to-Many: One User can ask many Questions
-- One-to-Many: One Category can have many Questions
-- ON DELETE CASCADE: If a user is deleted, their questions are removed
-- ============================================================
CREATE TABLE Questions (
    QuestionID  NUMBER         PRIMARY KEY,
    UserID      NUMBER         NOT NULL,
    CategoryID  NUMBER         NOT NULL,
    Title       VARCHAR2(300)  NOT NULL,
    Description CLOB           NOT NULL,
    CreatedAt   DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_questions_user
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT fk_questions_category
        FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE CASCADE
);

-- ============================================================
-- 4. ANSWERS TABLE
-- ============================================================
-- One-to-Many: One Question can have many Answers
-- One-to-Many: One User can post many Answers
-- ============================================================
CREATE TABLE Answers (
    AnswerID   NUMBER PRIMARY KEY,
    QuestionID NUMBER NOT NULL,
    UserID     NUMBER NOT NULL,
    AnswerText CLOB   NOT NULL,
    CreatedAt  DATE   DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_answers_question
        FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID) ON DELETE CASCADE,
    CONSTRAINT fk_answers_user
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- ============================================================
-- 5. TAGS TABLE
-- ============================================================
-- TagName is a Candidate Key (UNIQUE)
-- ============================================================
CREATE TABLE Tags (
    TagID   NUMBER        PRIMARY KEY,
    TagName VARCHAR2(50)  NOT NULL UNIQUE              -- Candidate Key
);

-- ============================================================
-- 6. QUESTIONTAGS TABLE (Junction / Bridge Table)
-- ============================================================
-- Many-to-Many: Questions <-> Tags
-- Composite Primary Key: (QuestionID, TagID)
-- ============================================================
CREATE TABLE QuestionTags (
    QuestionID NUMBER NOT NULL,
    TagID      NUMBER NOT NULL,
    CONSTRAINT pk_questiontags PRIMARY KEY (QuestionID, TagID),
    CONSTRAINT fk_qt_question
        FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID) ON DELETE CASCADE,
    CONSTRAINT fk_qt_tag
        FOREIGN KEY (TagID) REFERENCES Tags(TagID) ON DELETE CASCADE
);

-- ============================================================
-- 7. VOTES TABLE
-- ============================================================
-- One-to-Many: One Answer can have many Votes
-- UNIQUE constraint on (UserID, AnswerID) prevents duplicate votes
-- CHECK constraint ensures VoteType is 'up' or 'down'
-- ============================================================
CREATE TABLE Votes (
    VoteID    NUMBER      PRIMARY KEY,
    UserID    NUMBER      NOT NULL,
    AnswerID  NUMBER      NOT NULL,
    VoteType  VARCHAR2(4) NOT NULL,
    CreatedAt DATE        DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_votes_user
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT fk_votes_answer
        FOREIGN KEY (AnswerID) REFERENCES Answers(AnswerID) ON DELETE CASCADE,
    CONSTRAINT chk_vote_type CHECK (VoteType IN ('up', 'down')),
    CONSTRAINT uq_user_answer_vote UNIQUE (UserID, AnswerID)
);

-- ============================================================
-- 8. BOOKMARKS TABLE
-- ============================================================
-- One-to-Many: One User can bookmark many Questions
-- UNIQUE constraint prevents duplicate bookmarks
-- ============================================================
CREATE TABLE Bookmarks (
    BookmarkID NUMBER PRIMARY KEY,
    UserID     NUMBER NOT NULL,
    QuestionID NUMBER NOT NULL,
    CreatedAt  DATE   DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_bookmarks_user
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT fk_bookmarks_question
        FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID) ON DELETE CASCADE,
    CONSTRAINT uq_user_question_bookmark UNIQUE (UserID, QuestionID)
);

-- ============================================================
-- 9. NOTIFICATIONS TABLE
-- ============================================================
-- One-to-Many: One User can have many Notifications
-- IsRead defaults to 0 (unread)
-- ============================================================
CREATE TABLE Notifications (
    NotificationID NUMBER        PRIMARY KEY,
    UserID         NUMBER        NOT NULL,
    Message        VARCHAR2(500) NOT NULL,
    IsRead         NUMBER(1)     DEFAULT 0 NOT NULL,
    CreatedAt      DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT chk_isread CHECK (IsRead IN (0, 1))
);

-- ============================================================
-- 10. REPORTS TABLE
-- ============================================================
-- Users can report either a Question or an Answer (one must be non-null)
-- Nullable Foreign Keys for QuestionID and AnswerID
-- Status tracks report lifecycle
-- ============================================================
CREATE TABLE Reports (
    ReportID   NUMBER         PRIMARY KEY,
    UserID     NUMBER         NOT NULL,
    QuestionID NUMBER         NULL,
    AnswerID   NUMBER         NULL,
    Reason     VARCHAR2(500)  NOT NULL,
    Status     VARCHAR2(20)   DEFAULT 'pending' NOT NULL,
    CreatedAt  DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_reports_user
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT fk_reports_question
        FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID) ON DELETE SET NULL,
    CONSTRAINT fk_reports_answer
        FOREIGN KEY (AnswerID) REFERENCES Answers(AnswerID) ON DELETE SET NULL,
    CONSTRAINT chk_report_target
        CHECK (QuestionID IS NOT NULL OR AnswerID IS NOT NULL),
    CONSTRAINT chk_report_status
        CHECK (Status IN ('pending', 'resolved', 'dismissed'))
);
