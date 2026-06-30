// ============================================================
// Whisperia: routes/admin.js
// Admin panel routes (dashboard, user mgmt, reports, categories)
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { isAuthenticated } = require('../middleware/auth');
const { isAdmin } = require('../middleware/admin');

// Apply both middleware to all admin routes
router.use(isAuthenticated, isAdmin);

// GET /api/admin/dashboard - Dashboard statistics & reports
router.get('/dashboard', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();

    // Platform stats
    const stats = await connection.execute(`
      SELECT
        (SELECT COUNT(*) FROM Users WHERE Role = 'user') AS TotalUsers,
        (SELECT COUNT(*) FROM Questions) AS TotalQuestions,
        (SELECT COUNT(*) FROM Answers) AS TotalAnswers,
        (SELECT COUNT(*) FROM Votes) AS TotalVotes,
        (SELECT COUNT(*) FROM Reports WHERE Status = 'pending') AS PendingReports
      FROM DUAL
    `);

    // Top contributors (from view)
    const contributors = await connection.execute(
      `SELECT * FROM TopContributors FETCH FIRST 5 ROWS ONLY`
    );

    // Category statistics (from view)
    const categories = await connection.execute(
      `SELECT * FROM CategoryStatistics`
    );

    // Questions per month
    const monthly = await connection.execute(`
      SELECT EXTRACT(YEAR FROM CreatedAt) AS Year,
             EXTRACT(MONTH FROM CreatedAt) AS Month,
             COUNT(*) AS QuestionCount
      FROM Questions
      GROUP BY EXTRACT(YEAR FROM CreatedAt), EXTRACT(MONTH FROM CreatedAt)
      ORDER BY Year DESC, Month DESC
      FETCH FIRST 12 ROWS ONLY
    `);

    // Most popular tags
    const tags = await connection.execute(`
      SELECT t.TagName, COUNT(qt.QuestionID) AS UsageCount
      FROM Tags t JOIN QuestionTags qt ON t.TagID = qt.TagID
      GROUP BY t.TagName
      ORDER BY UsageCount DESC
      FETCH FIRST 10 ROWS ONLY
    `);

    res.json({
      stats: stats.rows[0],
      topContributors: contributors.rows,
      categoryStats: categories.rows,
      monthlyQuestions: monthly.rows,
      popularTags: tags.rows
    });

  } catch (err) {
    console.error('Admin dashboard error:', err);
    res.status(500).json({ error: 'Failed to load dashboard' });
  } finally {
    if (connection) await connection.close();
  }
});

// GET /api/admin/users - List all users
router.get('/users', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(`SELECT * FROM UserActivity ORDER BY JOINDATE DESC`);
    res.json({ users: result.rows });
  } catch (err) {
    console.error('Admin users error:', err);
    res.status(500).json({ error: 'Failed to fetch users' });
  } finally {
    if (connection) await connection.close();
  }
});

// DELETE /api/admin/users/:id - Delete user
router.delete('/users/:id', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const userId = parseInt(req.params.id);

    // Don't allow deleting yourself
    if (userId === req.session.user.id) {
      return res.status(400).json({ error: 'Cannot delete your own account' });
    }

    await connection.execute(`DELETE FROM Users WHERE UserID = :id`, { id: userId });
    res.json({ message: 'User deleted successfully' });

  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  } finally {
    if (connection) await connection.close();
  }
});

// GET /api/admin/reports - List all reports
router.get('/reports', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(`
      SELECT r.ReportID, r.Reason, r.Status, r.CreatedAt,
             u.Username AS Reporter,
             q.QuestionID, q.Title AS QuestionTitle,
             a.AnswerID, SUBSTR(a.AnswerText, 1, 100) AS AnswerPreview
      FROM Reports r
      JOIN Users u ON r.UserID = u.UserID
      LEFT JOIN Questions q ON r.QuestionID = q.QuestionID
      LEFT JOIN Answers a ON r.AnswerID = a.AnswerID
      ORDER BY CASE r.Status WHEN 'pending' THEN 0 ELSE 1 END, r.CreatedAt DESC
    `);
    res.json({ reports: result.rows });
  } catch (err) {
    console.error('Admin reports error:', err);
    res.status(500).json({ error: 'Failed to fetch reports' });
  } finally {
    if (connection) await connection.close();
  }
});

// PUT /api/admin/reports/:id - Resolve report
router.put('/reports/:id', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const { action } = req.body; // 'resolve' or 'dismiss'
    const reportId = parseInt(req.params.id);

    if (action === 'resolve') {
      // Get the report details
      const report = await connection.execute(
        `SELECT QuestionID, AnswerID FROM Reports WHERE ReportID = :id`, { id: reportId }
      );
      if (report.rows.length === 0) return res.status(404).json({ error: 'Report not found' });

      const r = report.rows[0];
      // Delete the offending content
      if (r.ANSWERID) {
        await connection.execute(`DELETE FROM Answers WHERE AnswerID = :id`, { id: r.ANSWERID });
      } else if (r.QUESTIONID) {
        await connection.execute(`DELETE FROM Questions WHERE QuestionID = :id`, { id: r.QUESTIONID });
      }
    }

    const status = action === 'resolve' ? 'resolved' : 'dismissed';
    await connection.execute(
      `UPDATE Reports SET Status = :status WHERE ReportID = :id`,
      { status, id: reportId }
    );

    res.json({ message: `Report ${status}` });

  } catch (err) {
    console.error('Resolve report error:', err);
    res.status(500).json({ error: 'Failed to resolve report' });
  } finally {
    if (connection) await connection.close();
  }
});

// GET /api/admin/categories - List categories
router.get('/categories', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(
      `SELECT c.CategoryID, c.CategoryName, COUNT(q.QuestionID) AS QuestionCount
       FROM Categories c LEFT JOIN Questions q ON c.CategoryID = q.CategoryID
       GROUP BY c.CategoryID, c.CategoryName ORDER BY c.CategoryName`
    );
    res.json({ categories: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch categories' });
  } finally {
    if (connection) await connection.close();
  }
});

// POST /api/admin/categories - Add category
router.post('/categories', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const { name } = req.body;
    await connection.execute(
      `INSERT INTO Categories (CategoryID, CategoryName) VALUES (category_seq.NEXTVAL, :name)`,
      { name }
    );
    res.status(201).json({ message: 'Category created' });
  } catch (err) {
    if (err.errorNum === 1) return res.status(409).json({ error: 'Category already exists' });
    res.status(500).json({ error: 'Failed to create category' });
  } finally {
    if (connection) await connection.close();
  }
});

// DELETE /api/admin/categories/:id - Delete category
router.delete('/categories/:id', async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.execute(
      `DELETE FROM Categories WHERE CategoryID = :id`, { id: parseInt(req.params.id) }
    );
    res.json({ message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete category' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
