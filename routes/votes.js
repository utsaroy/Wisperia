// ============================================================
// Whisperia: routes/votes.js
// Voting routes (uses stored procedure)
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const oracledb = require('oracledb');
const { isAuthenticated } = require('../middleware/auth');

// POST /api/votes - Vote on an answer (toggles via stored procedure)
router.post('/', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const { answerId, voteType } = req.body;

    if (!['up', 'down'].includes(voteType)) {
      return res.status(400).json({ error: 'Vote type must be "up" or "down"' });
    }

    // Don't allow voting on own answers
    const ansCheck = await connection.execute(
      `SELECT UserID FROM Answers WHERE AnswerID = :aid`, { aid: parseInt(answerId) }
    );
    if (ansCheck.rows.length === 0) return res.status(404).json({ error: 'Answer not found' });
    if (ansCheck.rows[0].USERID === req.session.user.id) {
      return res.status(400).json({ error: 'Cannot vote on your own answer' });
    }

    const result = await connection.execute(
      `BEGIN VoteAnswer(:userId, :answerId, :voteType, :voteId); END;`,
      {
        userId: req.session.user.id,
        answerId: parseInt(answerId),
        voteType,
        voteId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );

    const voteId = result.outBinds.voteId;
    const action = voteId === -1 ? 'removed' : 'recorded';

    // Get updated vote total
    const totalResult = await connection.execute(
      `SELECT GetTotalVotes(:aid) AS total FROM DUAL`,
      { aid: parseInt(answerId) }
    );

    res.json({
      message: `Vote ${action}`,
      voteTotal: totalResult.rows[0].TOTAL
    });

  } catch (err) {
    console.error('Vote error:', err);
    res.status(500).json({ error: 'Failed to vote' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
