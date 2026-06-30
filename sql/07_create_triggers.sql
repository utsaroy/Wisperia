-- ============================================================
-- Whisperia: 07_create_triggers.sql
-- Row-level Triggers for automated notifications & validation
-- ============================================================
-- DBMS Concepts: BEFORE/AFTER triggers, :NEW/:OLD pseudo-records,
--   RAISE_APPLICATION_ERROR, FOR EACH ROW
-- ============================================================

-- TRIGGER 1: NotifyOnNewAnswer
-- When a new answer is posted, notify the question owner
CREATE OR REPLACE TRIGGER NotifyOnNewAnswer
AFTER INSERT ON Answers
FOR EACH ROW
DECLARE
    v_question_owner NUMBER;
    v_question_title VARCHAR2(300);
    v_answerer_name  VARCHAR2(50);
BEGIN
    -- Get the question owner
    SELECT UserID, Title INTO v_question_owner, v_question_title
    FROM Questions WHERE QuestionID = :NEW.QuestionID;

    -- Get answerer's username
    SELECT Username INTO v_answerer_name
    FROM Users WHERE UserID = :NEW.UserID;

    -- Don't notify if user answers their own question
    IF v_question_owner != :NEW.UserID THEN
        INSERT INTO Notifications (NotificationID, UserID, Message, IsRead, CreatedAt)
        VALUES (notification_seq.NEXTVAL, v_question_owner,
                v_answerer_name || ' answered your question: "' || SUBSTR(v_question_title, 1, 80) || '"',
                0, SYSDATE);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Don't fail the answer insert if notification fails
END;
/

-- TRIGGER 2: NotifyOnVote
-- When an answer receives a vote, notify the answer owner
CREATE OR REPLACE TRIGGER NotifyOnVote
AFTER INSERT ON Votes
FOR EACH ROW
DECLARE
    v_answer_owner NUMBER;
    v_voter_name   VARCHAR2(50);
    v_vote_word    VARCHAR2(10);
BEGIN
    -- Get answer owner
    SELECT UserID INTO v_answer_owner
    FROM Answers WHERE AnswerID = :NEW.AnswerID;

    -- Get voter username
    SELECT Username INTO v_voter_name
    FROM Users WHERE UserID = :NEW.UserID;

    -- Set vote word
    IF :NEW.VoteType = 'up' THEN
        v_vote_word := 'upvoted';
    ELSE
        v_vote_word := 'downvoted';
    END IF;

    -- Don't notify if user votes on their own answer
    IF v_answer_owner != :NEW.UserID THEN
        INSERT INTO Notifications (NotificationID, UserID, Message, IsRead, CreatedAt)
        VALUES (notification_seq.NEXTVAL, v_answer_owner,
                v_voter_name || ' ' || v_vote_word || ' your answer',
                0, SYSDATE);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- TRIGGER 3: PreventDuplicateVote
-- Prevents a user from inserting a duplicate vote on the same answer
-- (This is a backup to the UNIQUE constraint)
CREATE OR REPLACE TRIGGER PreventDuplicateVote
BEFORE INSERT ON Votes
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Votes
    WHERE UserID = :NEW.UserID AND AnswerID = :NEW.AnswerID;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Duplicate vote: User has already voted on this answer.');
    END IF;
END;
/
