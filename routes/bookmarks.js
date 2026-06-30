// ============================================================
// Whisperia: routes/bookmarks.js
// Bookmark routes (uses stored procedure)
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const oracledb = require('oracledb');
const { isAuthenticated } = require('../middleware/auth');

// GET /api/bookmarks - Get user's bookmarks
router.get('/', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(
      `SELECT b.BookmarkID, b.CreatedAt AS BookmarkedAt,
              q.QuestionID, q.Title, q.CreatedAt,
              u.Username AS Author, c.CategoryName,
              NVL(ans.cnt, 0) AS AnswerCount
       FROM Bookmarks b
       JOIN Questions q ON b.QuestionID = q.QuestionID
       JOIN Users u ON q.UserID = u.UserID
       JOIN Categories c ON q.CategoryID = c.CategoryID
       LEFT JOIN (SELECT QuestionID, COUNT(*) cnt FROM Answers GROUP BY QuestionID) ans
         ON q.QuestionID = ans.QuestionID
       WHERE b.UserID = :userId
       ORDER BY b.CreatedAt DESC`,
      { userId: req.session.user.id }
    );

    res.json({
      bookmarks: result.rows.map(r => ({
        bookmarkId: r.BOOKMARKID,
        bookmarkedAt: r.BOOKMARKEDAT,
        questionId: r.QUESTIONID,
        title: r.TITLE,
        createdAt: r.CREATEDAT,
        author: r.AUTHOR,
        categoryName: r.CATEGORYNAME,
        answerCount: r.ANSWERCOUNT
      }))
    });

  } catch (err) {
    console.error('Get bookmarks error:', err);
    res.status(500).json({ error: 'Failed to fetch bookmarks' });
  } finally {
    if (connection) await connection.close();
  }
});

// POST /api/bookmarks - Toggle bookmark (uses stored procedure)
router.post('/', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const { questionId } = req.body;

    const result = await connection.execute(
      `BEGIN BookmarkQuestion(:userId, :questionId, :action); END;`,
      {
        userId: req.session.user.id,
        questionId: parseInt(questionId),
        action: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 20 }
      }
    );

    res.json({ message: `Bookmark ${result.outBinds.action}`, action: result.outBinds.action });

  } catch (err) {
    console.error('Bookmark error:', err);
    res.status(500).json({ error: 'Failed to toggle bookmark' });
  } finally {
    if (connection) await connection.close();
  }
});

// DELETE /api/bookmarks/:id - Remove bookmark by ID
router.delete('/:id', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.execute(
      `DELETE FROM Bookmarks WHERE BookmarkID = :id AND UserID = :userId`,
      { id: parseInt(req.params.id), userId: req.session.user.id }
    );
    res.json({ message: 'Bookmark removed' });
  } catch (err) {
    console.error('Delete bookmark error:', err);
    res.status(500).json({ error: 'Failed to remove bookmark' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
