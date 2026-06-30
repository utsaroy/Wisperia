-- ============================================================
-- Whisperia: 06_create_procedures.sql
-- Stored Procedures with Transactions
-- ============================================================
-- DBMS Concepts: Procedures, IN/OUT params, Transactions, COMMIT/ROLLBACK, Exception Handling
-- ============================================================

-- PROCEDURE 1: CreateQuestion
-- Inserts question + associates tags in a single transaction
CREATE OR REPLACE PROCEDURE CreateQuestion(
    p_user_id    IN NUMBER,
    p_category_id IN NUMBER,
    p_title      IN VARCHAR2,
    p_description IN CLOB,
    p_tag_ids    IN VARCHAR2,  -- Comma-separated tag IDs
    p_question_id OUT NUMBER
)
IS
    v_tag_id NUMBER;
    v_pos    NUMBER;
    v_str    VARCHAR2(4000);
    v_token  VARCHAR2(100);
BEGIN
    -- Insert the question
    SELECT question_seq.NEXTVAL INTO p_question_id FROM DUAL;

    INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
    VALUES (p_question_id, p_user_id, p_category_id, p_title, p_description, SYSDATE);

    -- Parse and insert tags (comma-separated)
    IF p_tag_ids IS NOT NULL AND LENGTH(TRIM(p_tag_ids)) > 0 THEN
        v_str := p_tag_ids || ',';
        WHILE LENGTH(v_str) > 0 LOOP
            v_pos := INSTR(v_str, ',');
            EXIT WHEN v_pos = 0;
            v_token := TRIM(SUBSTR(v_str, 1, v_pos - 1));
            v_str := SUBSTR(v_str, v_pos + 1);

            IF v_token IS NOT NULL AND LENGTH(v_token) > 0 THEN
                v_tag_id := TO_NUMBER(v_token);
                BEGIN
                    INSERT INTO QuestionTags (QuestionID, TagID)
                    VALUES (p_question_id, v_tag_id);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN NULL; -- Skip duplicates
                END;
            END IF;
        END LOOP;
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CreateQuestion;
/

-- PROCEDURE 2: CreateAnswer
-- Inserts an answer (trigger handles notification)
CREATE OR REPLACE PROCEDURE CreateAnswer(
    p_question_id IN NUMBER,
    p_user_id     IN NUMBER,
    p_answer_text IN CLOB,
    p_answer_id   OUT NUMBER
)
IS
BEGIN
    SELECT answer_seq.NEXTVAL INTO p_answer_id FROM DUAL;

    INSERT INTO Answers (AnswerID, QuestionID, UserID, AnswerText, CreatedAt)
    VALUES (p_answer_id, p_question_id, p_user_id, p_answer_text, SYSDATE);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CreateAnswer;
/

-- PROCEDURE 3: VoteAnswer
-- Handles voting with duplicate prevention
CREATE OR REPLACE PROCEDURE VoteAnswer(
    p_user_id   IN NUMBER,
    p_answer_id IN NUMBER,
    p_vote_type IN VARCHAR2,
    p_vote_id   OUT NUMBER
)
IS
    v_existing_id NUMBER;
    v_existing_type VARCHAR2(4);
BEGIN
    -- Check for existing vote
    BEGIN
        SELECT VoteID, VoteType INTO v_existing_id, v_existing_type
        FROM Votes WHERE UserID = p_user_id AND AnswerID = p_answer_id;

        -- If same vote type, remove it (toggle off)
        IF v_existing_type = p_vote_type THEN
            DELETE FROM Votes WHERE VoteID = v_existing_id;
            p_vote_id := -1; -- Indicate removal
        ELSE
            -- Change vote type
            UPDATE Votes SET VoteType = p_vote_type WHERE VoteID = v_existing_id;
            p_vote_id := v_existing_id;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- No existing vote, create new
            SELECT vote_seq.NEXTVAL INTO p_vote_id FROM DUAL;
            INSERT INTO Votes (VoteID, UserID, AnswerID, VoteType, CreatedAt)
            VALUES (p_vote_id, p_user_id, p_answer_id, p_vote_type, SYSDATE);
    END;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END VoteAnswer;
/

-- PROCEDURE 4: BookmarkQuestion
-- Toggles bookmark (add if not exists, remove if exists)
CREATE OR REPLACE PROCEDURE BookmarkQuestion(
    p_user_id     IN NUMBER,
    p_question_id IN NUMBER,
    p_action      OUT VARCHAR2  -- 'added' or 'removed'
)
IS
    v_existing NUMBER;
BEGIN
    BEGIN
        SELECT BookmarkID INTO v_existing
        FROM Bookmarks WHERE UserID = p_user_id AND QuestionID = p_question_id;

        -- Bookmark exists, remove it
        DELETE FROM Bookmarks WHERE BookmarkID = v_existing;
        p_action := 'removed';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- No bookmark, add it
            INSERT INTO Bookmarks (BookmarkID, UserID, QuestionID, CreatedAt)
            VALUES (bookmark_seq.NEXTVAL, p_user_id, p_question_id, SYSDATE);
            p_action := 'added';
    END;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END BookmarkQuestion;
/
