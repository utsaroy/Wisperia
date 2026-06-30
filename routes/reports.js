// ============================================================
// Whisperia: routes/reports.js
// Content reporting routes
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const oracledb = require('oracledb');
const { isAuthenticated } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

// POST /api/reports - Submit a report
router.post('/', isAuthenticated, [
  body('reason').trim().isLength({ min: 5 }).withMessage('Reason must be at least 5 characters')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  let connection;
  try {
    connection = await db.getConnection();
    const { questionId, answerId, reason } = req.body;

    if (!questionId && !answerId) {
      return res.status(400).json({ error: 'Must specify questionId or answerId' });
    }

    await connection.execute(
      `INSERT INTO Reports (ReportID, UserID, QuestionID, AnswerID, Reason, Status, CreatedAt)
       VALUES (report_seq.NEXTVAL, :userId, :questionId, :answerId, :reason, 'pending', SYSDATE)`,
      {
        userId: req.session.user.id,
        questionId: questionId ? parseInt(questionId) : null,
        answerId: answerId ? parseInt(answerId) : null,
        reason
      }
    );

    res.status(201).json({ message: 'Report submitted successfully' });

  } catch (err) {
    console.error('Submit report error:', err);
    res.status(500).json({ error: 'Failed to submit report' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
