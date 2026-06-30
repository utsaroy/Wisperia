-- ============================================================
-- Whisperia: 05_create_functions.sql
-- PL/SQL Functions for computed values
-- ============================================================
-- DBMS Concepts: PL/SQL Functions, SELECT INTO, NVL, CASE, Exception Handling
-- ============================================================

-- FUNCTION 1: GetUserReputation
-- +10 per question, +5 per answer, +/-1 per vote received
CREATE OR REPLACE FUNCTION GetUserReputation(p_user_id IN NUMBER)
RETURN NUMBER
IS
    v_question_score NUMBER := 0;
    v_answer_score   NUMBER := 0;
    v_vote_score     NUMBER := 0;
    v_total          NUMBER := 0;
BEGIN
    SELECT NVL(COUNT(*) * 10, 0) INTO v_question_score
    FROM Questions WHERE UserID = p_user_id;

    SELECT NVL(COUNT(*) * 5, 0) INTO v_answer_score
    FROM Answers WHERE UserID = p_user_id;

    SELECT NVL(SUM(CASE WHEN v.VoteType = 'up' THEN 1 WHEN v.VoteType = 'down' THEN -1 ELSE 0 END), 0)
    INTO v_vote_score
    FROM Votes v JOIN Answers a ON v.AnswerID = a.AnswerID
    WHERE a.UserID = p_user_id;

    v_total := v_question_score + v_answer_score + v_vote_score;
    IF v_total < 0 THEN v_total := 0; END IF;
    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN RETURN 0;
END GetUserReputation;
/

-- FUNCTION 2: GetQuestionAnswerCount
CREATE OR REPLACE FUNCTION GetQuestionAnswerCount(p_question_id IN NUMBER)
RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Answers WHERE QuestionID = p_question_id;
    RETURN v_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
END GetQuestionAnswerCount;
/

-- FUNCTION 3: GetTotalVotes (net: upvotes - downvotes)
CREATE OR REPLACE FUNCTION GetTotalVotes(p_answer_id IN NUMBER)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(CASE WHEN VoteType = 'up' THEN 1 WHEN VoteType = 'down' THEN -1 ELSE 0 END), 0)
    INTO v_total FROM Votes WHERE AnswerID = p_answer_id;
    RETURN v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
END GetTotalVotes;
/
