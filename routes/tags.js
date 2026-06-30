// ============================================================
// Whisperia: routes/tags.js
// Tag browsing routes
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');

// GET /api/tags - All tags with usage count
router.get('/', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(
      `SELECT t.TagID, t.TagName, COUNT(qt.QuestionID) AS UsageCount
       FROM Tags t
       LEFT JOIN QuestionTags qt ON t.TagID = qt.TagID
       GROUP BY t.TagID, t.TagName
       ORDER BY UsageCount DESC`
    );

    res.json({
      tags: result.rows.map(r => ({
        id: r.TAGID, name: r.TAGNAME, usageCount: r.USAGECOUNT
      }))
    });

  } catch (err) {
    console.error('Get tags error:', err);
    res.status(500).json({ error: 'Failed to fetch tags' });
  } finally {
    if (connection) await connection.close();
  }
});

// GET /api/categories - All categories
router.get('/categories', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(
      `SELECT CategoryID, CategoryName FROM Categories ORDER BY CategoryName`
    );
    res.json({
      categories: result.rows.map(r => ({
        id: r.CATEGORYID, name: r.CATEGORYNAME
      }))
    });
  } catch (err) {
    console.error('Get categories error:', err);
    res.status(500).json({ error: 'Failed to fetch categories' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
