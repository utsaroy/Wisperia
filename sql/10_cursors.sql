-- ============================================================
-- Whisperia: 10_cursors.sql
-- Explicit Cursor examples for PL/SQL demonstrations
-- ============================================================
-- DBMS Concepts: Explicit Cursors, OPEN/FETCH/CLOSE,
--   %ROWTYPE, %NOTFOUND, Parameterized Cursors, DBMS_OUTPUT
-- ============================================================

SET SERVEROUTPUT ON;

-- CURSOR 1: Top Contributors Report
-- Iterates through users and displays their contribution stats
DECLARE
    CURSOR c_contributors IS
        SELECT u.UserID, u.Username,
               NVL(q.cnt, 0) AS QCount,
               NVL(a.cnt, 0) AS ACount
        FROM Users u
        LEFT JOIN (SELECT UserID, COUNT(*) cnt FROM Questions GROUP BY UserID) q ON u.UserID = q.UserID
        LEFT JOIN (SELECT UserID, COUNT(*) cnt FROM Answers GROUP BY UserID) a ON u.UserID = a.UserID
        WHERE u.Role = 'user'
        ORDER BY (NVL(q.cnt, 0) + NVL(a.cnt, 0)) DESC;

    v_rec c_contributors%ROWTYPE;
    v_rank NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('       TOP CONTRIBUTORS REPORT          ');
    DBMS_OUTPUT.PUT_LINE('========================================');

    OPEN c_contributors;
    LOOP
        FETCH c_contributors INTO v_rec;
        EXIT WHEN c_contributors%NOTFOUND;
        v_rank := v_rank + 1;
        DBMS_OUTPUT.PUT_LINE(
            v_rank || '. ' || RPAD(v_rec.Username, 20) ||
            ' Questions: ' || v_rec.QCount ||
            ' | Answers: ' || v_rec.ACount ||
            ' | Total: ' || (v_rec.QCount + v_rec.ACount)
        );
    END LOOP;
    CLOSE c_contributors;

    DBMS_OUTPUT.PUT_LINE('========================================');
END;
/

-- CURSOR 2: Most Active Categories Report
-- Uses %ROWTYPE with explicit cursor
DECLARE
    CURSOR c_categories IS
        SELECT c.CategoryName,
               COUNT(q.QuestionID) AS QuestionCount,
               COUNT(a.AnswerID) AS AnswerCount
        FROM Categories c
        LEFT JOIN Questions q ON c.CategoryID = q.CategoryID
        LEFT JOIN Answers a ON q.QuestionID = a.QuestionID
        GROUP BY c.CategoryName
        ORDER BY QuestionCount DESC;

    v_cat c_categories%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('     MOST ACTIVE CATEGORIES REPORT      ');
    DBMS_OUTPUT.PUT_LINE('========================================');

    OPEN c_categories;
    LOOP
        FETCH c_categories INTO v_cat;
        EXIT WHEN c_categories%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_cat.CategoryName, 25) ||
            ' Questions: ' || v_cat.QuestionCount ||
            ' | Answers: ' || v_cat.AnswerCount
        );
    END LOOP;
    CLOSE c_categories;
END;
/

-- CURSOR 3: Monthly Activity Report (Parameterized Cursor)
-- Accepts a year parameter to filter results
DECLARE
    CURSOR c_monthly(p_year NUMBER) IS
        SELECT EXTRACT(MONTH FROM q.CreatedAt) AS MonthNum,
               COUNT(*) AS QuestionCount
        FROM Questions q
        WHERE EXTRACT(YEAR FROM q.CreatedAt) = p_year
        GROUP BY EXTRACT(MONTH FROM q.CreatedAt)
        ORDER BY MonthNum;

    v_month c_monthly%ROWTYPE;
    v_year  NUMBER := EXTRACT(YEAR FROM SYSDATE);
    v_month_name VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('   MONTHLY ACTIVITY REPORT FOR ' || v_year);
    DBMS_OUTPUT.PUT_LINE('========================================');

    OPEN c_monthly(v_year);
    LOOP
        FETCH c_monthly INTO v_month;
        EXIT WHEN c_monthly%NOTFOUND;

        CASE v_month.MonthNum
            WHEN 1 THEN v_month_name := 'January';
            WHEN 2 THEN v_month_name := 'February';
            WHEN 3 THEN v_month_name := 'March';
            WHEN 4 THEN v_month_name := 'April';
            WHEN 5 THEN v_month_name := 'May';
            WHEN 6 THEN v_month_name := 'June';
            WHEN 7 THEN v_month_name := 'July';
            WHEN 8 THEN v_month_name := 'August';
            WHEN 9 THEN v_month_name := 'September';
            WHEN 10 THEN v_month_name := 'October';
            WHEN 11 THEN v_month_name := 'November';
            WHEN 12 THEN v_month_name := 'December';
        END CASE;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_month_name, 15) || ': ' || v_month.QuestionCount || ' questions'
        );
    END LOOP;
    CLOSE c_monthly;
END;
/
