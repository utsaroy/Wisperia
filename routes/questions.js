// ============================================================
// Whisperia: routes/questions.js
// Question CRUD with search, filter, and pagination
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const oracledb = require('oracledb');
const { isAuthenticated } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

// GET /api/questions - Browse all questions with search/filter/pagination
router.get('/', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const { search, category, tag, page = 1, limit = 12 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let whereClauses = [];
    let binds = {};

    if (search) {
      whereClauses.push(`(LOWER(q.Title) LIKE :search OR LOWER(q.Description) LIKE :search)`);
      binds.search = `%${search.toLowerCase()}%`;
    }
    if (category) {
      whereClauses.push(`q.CategoryID = :category`);
      binds.category = parseInt(category);
    }
    if (tag) {
      whereClauses.push(`q.QuestionID IN (SELECT qt.QuestionID FROM QuestionTags qt WHERE qt.TagID = :tag)`);
      binds.tag = parseInt(tag);
    }

    const whereSQL = whereClauses.length > 0 ? 'WHERE ' + whereClauses.join(' AND ') : '';

    // Count total
    const countResult = await connection.execute(
      `SELECT COUNT(*) AS total FROM Questions q ${whereSQL}`, binds
    );
    const total = countResult.rows[0].TOTAL;

    // Fetch questions with author, category, answer count, vote count
    const sql = `
      SELECT q.QuestionID, q.Title, q.Description, q.CreatedAt,
             u.UserID, u.Username AS Author,
             c.CategoryID, c.CategoryName,
             NVL(ans.AnswerCount, 0) AS AnswerCount,
             NVL(vt.VoteTotal, 0) AS VoteTotal
      FROM Questions q
      JOIN Users u ON q.UserID = u.UserID
      JOIN Categories c ON q.CategoryID = c.CategoryID
      LEFT JOIN (
        SELECT QuestionID, COUNT(*) AS AnswerCount FROM Answers GROUP BY QuestionID
      ) ans ON q.QuestionID = ans.QuestionID
      LEFT JOIN (
        SELECT a2.QuestionID,
               SUM(CASE WHEN v.VoteType = 'up' THEN 1 WHEN v.VoteType = 'down' THEN -1 ELSE 0 END) AS VoteTotal
        FROM Votes v JOIN Answers a2 ON v.AnswerID = a2.AnswerID
        GROUP BY a2.QuestionID
      ) vt ON q.QuestionID = vt.QuestionID
      ${whereSQL}
      ORDER BY q.CreatedAt DESC
      OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
    `;

    binds.offset = offset;
    binds.limit = parseInt(limit);

    const result = await connection.execute(sql, binds);

    // Fetch tags for each question
    const questions = [];
    for (const row of result.rows) {
      const tagResult = await connection.execute(
        `SELECT t.TagID, t.TagName FROM Tags t
         JOIN QuestionTags qt ON t.TagID = qt.TagID
         WHERE qt.QuestionID = :qid`,
        { qid: row.QUESTIONID }
      );
      questions.push({
        id: row.QUESTIONID,
        title: row.TITLE,
        description: row.DESCRIPTION,
        createdAt: row.CREATEDAT,
        userId: row.USERID,
        author: row.AUTHOR,
        categoryId: row.CATEGORYID,
        categoryName: row.CATEGORYNAME,
        answerCount: row.ANSWERCOUNT,
        voteTotal: row.VOTETOTAL,
        tags: tagResult.rows.map(t => ({ id: t.TAGID, name: t.TAGNAME }))
      });
    }

    res.json({
      questions,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit))
    });

  } catch (err) {
    console.error('Get questions error:', err);
    res.status(500).json({ error: 'Failed to fetch questions' });
  } finally {
    if (connection) await connection.close();
  }
});

// GET /api/questions/:id - Get single question with answers
router.get('/:id', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const questionId = parseInt(req.params.id);

    // Fetch question
    const qResult = await connection.execute(
      `SELECT q.QuestionID, q.Title, q.Description, q.CreatedAt,
              u.UserID, u.Username AS Author, u.JoinDate,
              c.CategoryID, c.CategoryName
       FROM Questions q
       JOIN Users u ON q.UserID = u.UserID
       JOIN Categories c ON q.CategoryID = c.CategoryID
       WHERE q.QuestionID = :id`,
      { id: questionId }
    );

    if (qResult.rows.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    const q = qResult.rows[0];

    // Fetch tags
    const tagResult = await connection.execute(
      `SELECT t.TagID, t.TagName FROM Tags t
       JOIN QuestionTags qt ON t.TagID = qt.TagID
       WHERE qt.QuestionID = :qid`,
      { qid: questionId }
    );

    // Fetch answers with vote counts
    const ansResult = await connection.execute(
      `SELECT a.AnswerID, a.AnswerText, a.CreatedAt,
              u.UserID, u.Username AS Author,
              GetTotalVotes(a.AnswerID) AS VoteTotal
       FROM Answers a
       JOIN Users u ON a.UserID = u.UserID
       WHERE a.QuestionID = :qid
       ORDER BY VoteTotal DESC, a.CreatedAt ASC`,
      { qid: questionId }
    );

    // Check if current user has bookmarked this question
    let isBookmarked = false;
    if (req.session && req.session.user) {
      const bmResult = await connection.execute(
        `SELECT BookmarkID FROM Bookmarks WHERE UserID = :uid AND QuestionID = :qid`,
        { uid: req.session.user.id, qid: questionId }
      );
      isBookmarked = bmResult.rows.length > 0;
    }

    // Check current user's votes on each answer
    const answers = [];
    for (const a of ansResult.rows) {
      let userVote = null;
      if (req.session && req.session.user) {
        const vResult = await connection.execute(
          `SELECT VoteType FROM Votes WHERE UserID = :uid AND AnswerID = :aid`,
          { uid: req.session.user.id, aid: a.ANSWERID }
        );
        if (vResult.rows.length > 0) userVote = vResult.rows[0].VOTETYPE;
      }
      answers.push({
        id: a.ANSWERID,
        answerText: a.ANSWERTEXT,
        createdAt: a.CREATEDAT,
        userId: a.USERID,
        author: a.AUTHOR,
        voteTotal: a.VOTETOTAL,
        userVote
      });
    }

    // Bookmark count
    const bmCount = await connection.execute(
      `SELECT COUNT(*) AS cnt FROM Bookmarks WHERE QuestionID = :qid`,
      { qid: questionId }
    );

    res.json({
      question: {
        id: q.QUESTIONID,
        title: q.TITLE,
        description: q.DESCRIPTION,
        createdAt: q.CREATEDAT,
        userId: q.USERID,
        author: q.AUTHOR,
        authorJoinDate: q.JOINDATE,
        categoryId: q.CATEGORYID,
        categoryName: q.CATEGORYNAME,
        tags: tagResult.rows.map(t => ({ id: t.TAGID, name: t.TAGNAME })),
        answerCount: answers.length,
        bookmarkCount: bmCount.rows[0].CNT,
        isBookmarked
      },
      answers
    });

  } catch (err) {
    console.error('Get question detail error:', err);
    res.status(500).json({ error: 'Failed to fetch question details' });
  } finally {
    if (connection) await connection.close();
  }
});

// POST /api/questions - Create a new question (uses stored procedure)
router.post('/', isAuthenticated, [
  body('title').trim().isLength({ min: 5, max: 300 }).withMessage('Title must be 5-300 characters'),
  body('description').trim().isLength({ min: 10 }).withMessage('Description must be at least 10 characters'),
  body('categoryId').isNumeric().withMessage('Category required')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  let connection;
  try {
    connection = await db.getConnection();
    const { title, description, categoryId, tagIds } = req.body;
    const tagIdsStr = tagIds ? tagIds.join(',') : '';

    const result = await connection.execute(
      `BEGIN CreateQuestion(:userId, :categoryId, :title, :description, :tagIds, :questionId); END;`,
      {
        userId: req.session.user.id,
        categoryId: parseInt(categoryId),
        title,
        description,
        tagIds: tagIdsStr,
        questionId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );

    res.status(201).json({
      message: 'Question created successfully',
      questionId: result.outBinds.questionId
    });

  } catch (err) {
    console.error('Create question error:', err);
    res.status(500).json({ error: 'Failed to create question' });
  } finally {
    if (connection) await connection.close();
  }
});

// PUT /api/questions/:id - Update question (owner only)
router.put('/:id', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const questionId = parseInt(req.params.id);
    const { title, description, categoryId } = req.body;

    // Check ownership
    const check = await connection.execute(
      `SELECT UserID FROM Questions WHERE QuestionID = :id`,
      { id: questionId }
    );
    if (check.rows.length === 0) return res.status(404).json({ error: 'Question not found' });
    if (check.rows[0].USERID !== req.session.user.id && req.session.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to edit this question' });
    }

    await connection.execute(
      `UPDATE Questions SET Title = :title, Description = :description, CategoryID = :categoryId
       WHERE QuestionID = :id`,
      { title, description, categoryId: parseInt(categoryId), id: questionId }
    );

    res.json({ message: 'Question updated successfully' });

  } catch (err) {
    console.error('Update question error:', err);
    res.status(500).json({ error: 'Failed to update question' });
  } finally {
    if (connection) await connection.close();
  }
});

// DELETE /api/questions/:id - Delete question (owner or admin)
router.delete('/:id', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const questionId = parseInt(req.params.id);

    const check = await connection.execute(
      `SELECT UserID FROM Questions WHERE QuestionID = :id`,
      { id: questionId }
    );
    if (check.rows.length === 0) return res.status(404).json({ error: 'Question not found' });
    if (check.rows[0].USERID !== req.session.user.id && req.session.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    await connection.execute(`DELETE FROM Questions WHERE QuestionID = :id`, { id: questionId });
    res.json({ message: 'Question deleted successfully' });

  } catch (err) {
    console.error('Delete question error:', err);
    res.status(500).json({ error: 'Failed to delete question' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
