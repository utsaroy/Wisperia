// ============================================================
// Whisperia: routes/users.js
// User profile routes
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');

// GET /api/users/:id - Get user profile with stats
router.get('/:id', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const userId = parseInt(req.params.id);

    // Get user info from UserActivity view
    const userResult = await connection.execute(
      `SELECT * FROM UserActivity WHERE UserID = :id`, { id: userId }
    );
    if (userResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const u = userResult.rows[0];

    // Get reputation using function
    const repResult = await connection.execute(
      `SELECT GetUserReputation(:id) AS reputation FROM DUAL`, { id: userId }
    );

    // Get user's questions
    const questions = await connection.execute(
      `SELECT q.QuestionID, q.Title, q.CreatedAt, c.CategoryName,
              NVL(ans.cnt, 0) AS AnswerCount
       FROM Questions q
       JOIN Categories c ON q.CategoryID = c.CategoryID
       LEFT JOIN (SELECT QuestionID, COUNT(*) cnt FROM Answers GROUP BY QuestionID) ans
         ON q.QuestionID = ans.QuestionID
       WHERE q.UserID = :id ORDER BY q.CreatedAt DESC`,
      { id: userId }
    );

    // Get user's answers
    const answers = await connection.execute(
      `SELECT a.AnswerID, a.AnswerText, a.CreatedAt,
              q.QuestionID, q.Title AS QuestionTitle,
              GetTotalVotes(a.AnswerID) AS VoteTotal
       FROM Answers a
       JOIN Questions q ON a.QuestionID = q.QuestionID
       WHERE a.UserID = :id ORDER BY a.CreatedAt DESC`,
      { id: userId }
    );

    res.json({
      user: {
        id: u.USERID,
        username: u.USERNAME,
        email: u.EMAIL,
        role: u.ROLE,
        joinDate: u.JOINDATE,
        reputation: repResult.rows[0].REPUTATION,
        questionsAsked: u.QUESTIONSASKED,
        answersPosted: u.ANSWERSPOSTED,
        votesGiven: u.VOTESGIVEN,
        bookmarksMade: u.BOOKMARKSMADE
      },
      questions: questions.rows.map(q => ({
        id: q.QUESTIONID, title: q.TITLE, createdAt: q.CREATEDAT,
        categoryName: q.CATEGORYNAME, answerCount: q.ANSWERCOUNT
      })),
      answers: answers.rows.map(a => ({
        id: a.ANSWERID, answerText: a.ANSWERTEXT, createdAt: a.CREATEDAT,
        questionId: a.QUESTIONID, questionTitle: a.QUESTIONTITLE, voteTotal: a.VOTETOTAL
      }))
    });

  } catch (err) {
    console.error('Get user profile error:', err);
    res.status(500).json({ error: 'Failed to fetch profile' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
