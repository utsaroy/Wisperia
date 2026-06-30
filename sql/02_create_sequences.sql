-- ============================================================
-- Whisperia: 02_create_sequences.sql
-- Oracle Sequences for auto-incrementing primary keys
-- ============================================================
--
-- DBMS Concepts Demonstrated:
--   * Oracle Sequences (surrogate key generation)
--   * NEXTVAL / CURRVAL usage
--   * START WITH, INCREMENT BY, NOCACHE, NOCYCLE options
--
-- Note: Oracle does not have AUTO_INCREMENT like MySQL.
--       Sequences are the Oracle-standard approach for
--       generating unique numeric primary keys.
-- ============================================================

-- Drop existing sequences (for re-runs)
BEGIN
   FOR s IN (
      SELECT sequence_name FROM user_sequences
      WHERE sequence_name IN (
         'USER_SEQ','CATEGORY_SEQ','QUESTION_SEQ','ANSWER_SEQ',
         'TAG_SEQ','VOTE_SEQ','BOOKMARK_SEQ','NOTIFICATION_SEQ','REPORT_SEQ'
      )
   ) LOOP
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
   END LOOP;
END;
/

-- Sequence for Users.UserID
CREATE SEQUENCE user_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Categories.CategoryID
CREATE SEQUENCE category_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Questions.QuestionID
CREATE SEQUENCE question_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Answers.AnswerID
CREATE SEQUENCE answer_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Tags.TagID
CREATE SEQUENCE tag_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Votes.VoteID
CREATE SEQUENCE vote_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Bookmarks.BookmarkID
CREATE SEQUENCE bookmark_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Notifications.NotificationID
CREATE SEQUENCE notification_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for Reports.ReportID
CREATE SEQUENCE report_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
