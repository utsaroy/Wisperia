// ============================================================
// Whisperia: routes/answers.js
// Answer CRUD routes
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const oracledb = require('oracledb');
const { isAuthenticated } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

// POST /api/answers - Create answer (uses stored procedure, triggers notification)
router.post('/', isAuthenticated, [
  body('questionId').isNumeric().withMessage('Question ID required'),
  body('answerText').trim().isLength({ min: 5 }).withMessage('Answer must be at least 5 characters')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  let connection;
  try {
    connection = await db.getConnection();
    const { questionId, answerText } = req.body;

    const result = await connection.execute(
      `BEGIN CreateAnswer(:questionId, :userId, :answerText, :answerId); END;`,
      {
        questionId: parseInt(questionId),
        userId: req.session.user.id,
        answerText,
        answerId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );

    res.status(201).json({
      message: 'Answer posted successfully',
      answerId: result.outBinds.answerId
    });

  } catch (err) {
    console.error('Create answer error:', err);
    res.status(500).json({ error: 'Failed to post answer' });
  } finally {
    if (connection) await connection.close();
  }
});

// PUT /api/answers/:id - Update answer (owner only)
router.put('/:id', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const answerId = parseInt(req.params.id);
    const { answerText } = req.body;

    const check = await connection.execute(
      `SELECT UserID FROM Answers WHERE AnswerID = :id`, { id: answerId }
    );
    if (check.rows.length === 0) return res.status(404).json({ error: 'Answer not found' });
    if (check.rows[0].USERID !== req.session.user.id && req.session.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    await connection.execute(
      `UPDATE Answers SET AnswerText = :answerText WHERE AnswerID = :id`,
      { answerText, id: answerId }
    );

    res.json({ message: 'Answer updated successfully' });

  } catch (err) {
    console.error('Update answer error:', err);
    res.status(500).json({ error: 'Failed to update answer' });
  } finally {
    if (connection) await connection.close();
  }
});

// DELETE /api/answers/:id - Delete answer (owner or admin)
router.delete('/:id', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const answerId = parseInt(req.params.id);

    const check = await connection.execute(
      `SELECT UserID FROM Answers WHERE AnswerID = :id`, { id: answerId }
    );
    if (check.rows.length === 0) return res.status(404).json({ error: 'Answer not found' });
    if (check.rows[0].USERID !== req.session.user.id && req.session.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    await connection.execute(`DELETE FROM Answers WHERE AnswerID = :id`, { id: answerId });
    res.json({ message: 'Answer deleted successfully' });

  } catch (err) {
    console.error('Delete answer error:', err);
    res.status(500).json({ error: 'Failed to delete answer' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
