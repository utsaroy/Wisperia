-- ============================================================
-- Whisperia: 08_seed_data.sql
-- Initial seed data for demo purposes
-- ============================================================
-- Password hashes generated with bcrypt (10 rounds)
-- admin123 => $2a$10$rDkOvIMHstXMFPmBaOPYne8OOBcfGjWhsWJTUXCm3siGqBMYOY6.i
-- user123  => $2a$10$YO8OSbR3K9AEDBs6xP2gbe0vIjFjT0GDMHJKMZMih1LKFW0F7USyq
-- ============================================================

-- Seed Admin User
INSERT INTO Users (UserID, Username, Email, PasswordHash, Role, JoinDate)
VALUES (user_seq.NEXTVAL, 'admin', 'admin@whisperia.com',
        '$2a$10$rDkOvIMHstXMFPmBaOPYne8OOBcfGjWhsWJTUXCm3siGqBMYOY6.i',
        'admin', SYSDATE);

-- Seed Regular Users
INSERT INTO Users (UserID, Username, Email, PasswordHash, Role, JoinDate)
VALUES (user_seq.NEXTVAL, 'alice', 'alice@example.com',
        '$2a$10$YO8OSbR3K9AEDBs6xP2gbe0vIjFjT0GDMHJKMZMih1LKFW0F7USyq',
        'user', SYSDATE - 30);

INSERT INTO Users (UserID, Username, Email, PasswordHash, Role, JoinDate)
VALUES (user_seq.NEXTVAL, 'bob', 'bob@example.com',
        '$2a$10$YO8OSbR3K9AEDBs6xP2gbe0vIjFjT0GDMHJKMZMih1LKFW0F7USyq',
        'user', SYSDATE - 25);

INSERT INTO Users (UserID, Username, Email, PasswordHash, Role, JoinDate)
VALUES (user_seq.NEXTVAL, 'charlie', 'charlie@example.com',
        '$2a$10$YO8OSbR3K9AEDBs6xP2gbe0vIjFjT0GDMHJKMZMih1LKFW0F7USyq',
        'user', SYSDATE - 20);

INSERT INTO Users (UserID, Username, Email, PasswordHash, Role, JoinDate)
VALUES (user_seq.NEXTVAL, 'diana', 'diana@example.com',
        '$2a$10$YO8OSbR3K9AEDBs6xP2gbe0vIjFjT0GDMHJKMZMih1LKFW0F7USyq',
        'user', SYSDATE - 15);

-- Seed Categories
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Programming');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Database');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Web Development');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Artificial Intelligence');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Networking');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Operating Systems');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'Mathematics');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, 'General');

-- Seed Tags
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'javascript');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'python');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'sql');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'oracle');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'html');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'css');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'nodejs');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'react');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'java');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'algorithms');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'plsql');
INSERT INTO Tags (TagID, TagName) VALUES (tag_seq.NEXTVAL, 'express');

-- Seed Questions (UserIDs: alice=2, bob=3, charlie=4, diana=5)
INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
VALUES (question_seq.NEXTVAL, 2, 2, 'What is normalization in DBMS?',
        'Can someone explain the different normal forms (1NF, 2NF, 3NF) with examples? I am confused about transitive dependencies.', SYSDATE - 10);

INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
VALUES (question_seq.NEXTVAL, 3, 1, 'How does async/await work in JavaScript?',
        'I understand callbacks and promises but async/await confuses me. How does it work under the hood?', SYSDATE - 9);

INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
VALUES (question_seq.NEXTVAL, 4, 3, 'Best practices for REST API design?',
        'What are the industry-standard best practices for designing RESTful APIs? Looking for naming conventions, status codes, and versioning strategies.', SYSDATE - 8);

INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
VALUES (question_seq.NEXTVAL, 5, 2, 'Difference between INNER JOIN and LEFT JOIN?',
        'When should I use INNER JOIN vs LEFT JOIN? Can someone provide a clear example with sample data?', SYSDATE - 7);

INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
VALUES (question_seq.NEXTVAL, 2, 4, 'How to get started with machine learning?',
        'I have a background in programming. What is the best path to learn machine learning from scratch?', SYSDATE - 6);

INSERT INTO Questions (QuestionID, UserID, CategoryID, Title, Description, CreatedAt)
VALUES (question_seq.NEXTVAL, 3, 2, 'What are Oracle sequences and how to use them?',
        'I am learning Oracle and confused about sequences. How do they compare to AUTO_INCREMENT in MySQL?', SYSDATE - 5);

-- Seed QuestionTags
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (1, 3);  -- normalization + sql
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (1, 4);  -- normalization + oracle
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (2, 1);  -- async + javascript
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (2, 7);  -- async + nodejs
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (3, 7);  -- rest + nodejs
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (3, 12); -- rest + express
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (4, 3);  -- join + sql
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (4, 4);  -- join + oracle
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (5, 2);  -- ml + python
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (5, 10); -- ml + algorithms
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (6, 4);  -- sequences + oracle
INSERT INTO QuestionTags (QuestionID, TagID) VALUES (6, 11); -- sequences + plsql

-- Seed Answers
INSERT INTO Answers (AnswerID, QuestionID, UserID, AnswerText, CreatedAt)
VALUES (answer_seq.NEXTVAL, 1, 3, 'Normalization is the process of organizing data to reduce redundancy. 1NF: No repeating groups. 2NF: No partial dependencies. 3NF: No transitive dependencies. For example, storing a student''s department name directly in the student table violates 3NF because department name depends on department ID, not the student.', SYSDATE - 9);

INSERT INTO Answers (AnswerID, QuestionID, UserID, AnswerText, CreatedAt)
VALUES (answer_seq.NEXTVAL, 1, 5, 'To add to the above: a transitive dependency means A->B->C. If StudentID->DeptID->DeptName, then DeptName transitively depends on StudentID. To fix, move DeptName to a separate Departments table.', SYSDATE - 8);

INSERT INTO Answers (AnswerID, QuestionID, UserID, AnswerText, CreatedAt)
VALUES (answer_seq.NEXTVAL, 2, 4, 'async/await is syntactic sugar over Promises. When you write `await fetch(url)`, the engine pauses execution of that function (not the whole thread) until the promise resolves. Under the hood it uses the event loop and microtask queue.', SYSDATE - 8);

INSERT INTO Answers (AnswerID, QuestionID, UserID, AnswerText, CreatedAt)
VALUES (answer_seq.NEXTVAL, 4, 2, 'INNER JOIN returns only matching rows from both tables. LEFT JOIN returns all rows from the left table and matched rows from the right (NULLs for no match). Use LEFT JOIN when you want to keep all records from one table regardless of matches.', SYSDATE - 6);

INSERT INTO Answers (AnswerID, QuestionID, UserID, AnswerText, CreatedAt)
VALUES (answer_seq.NEXTVAL, 6, 4, 'Oracle sequences are database objects that generate unique numbers. Unlike MySQL AUTO_INCREMENT which is tied to a table, Oracle sequences are independent objects. Use sequence_name.NEXTVAL to get the next value. They are great for primary keys.', SYSDATE - 4);

-- Seed Votes
INSERT INTO Votes (VoteID, UserID, AnswerID, VoteType, CreatedAt)
VALUES (vote_seq.NEXTVAL, 2, 1, 'up', SYSDATE - 8);
INSERT INTO Votes (VoteID, UserID, AnswerID, VoteType, CreatedAt)
VALUES (vote_seq.NEXTVAL, 4, 1, 'up', SYSDATE - 7);
INSERT INTO Votes (VoteID, UserID, AnswerID, VoteType, CreatedAt)
VALUES (vote_seq.NEXTVAL, 5, 3, 'up', SYSDATE - 7);
INSERT INTO Votes (VoteID, UserID, AnswerID, VoteType, CreatedAt)
VALUES (vote_seq.NEXTVAL, 2, 3, 'up', SYSDATE - 6);
INSERT INTO Votes (VoteID, UserID, AnswerID, VoteType, CreatedAt)
VALUES (vote_seq.NEXTVAL, 3, 4, 'up', SYSDATE - 5);

-- Seed Bookmarks
INSERT INTO Bookmarks (BookmarkID, UserID, QuestionID, CreatedAt)
VALUES (bookmark_seq.NEXTVAL, 2, 2, SYSDATE - 5);
INSERT INTO Bookmarks (BookmarkID, UserID, QuestionID, CreatedAt)
VALUES (bookmark_seq.NEXTVAL, 3, 1, SYSDATE - 4);
INSERT INTO Bookmarks (BookmarkID, UserID, QuestionID, CreatedAt)
VALUES (bookmark_seq.NEXTVAL, 5, 4, SYSDATE - 3);

COMMIT;
