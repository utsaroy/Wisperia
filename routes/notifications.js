// ============================================================
// Whisperia: routes/notifications.js
// Notification routes
// ============================================================
const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { isAuthenticated } = require('../middleware/auth');

// GET /api/notifications - Get user's notifications
router.get('/', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    const result = await connection.execute(
      `SELECT NotificationID, Message, IsRead, CreatedAt
       FROM Notifications
       WHERE UserID = :userId
       ORDER BY CreatedAt DESC
       FETCH FIRST 50 ROWS ONLY`,
      { userId: req.session.user.id }
    );

    const unreadCount = await connection.execute(
      `SELECT COUNT(*) AS cnt FROM Notifications WHERE UserID = :userId AND IsRead = 0`,
      { userId: req.session.user.id }
    );

    res.json({
      notifications: result.rows.map(r => ({
        id: r.NOTIFICATIONID,
        message: r.MESSAGE,
        isRead: r.ISREAD === 1,
        createdAt: r.CREATEDAT
      })),
      unreadCount: unreadCount.rows[0].CNT
    });

  } catch (err) {
    console.error('Get notifications error:', err);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  } finally {
    if (connection) await connection.close();
  }
});

// PUT /api/notifications/:id/read - Mark notification as read
router.put('/:id/read', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.execute(
      `UPDATE Notifications SET IsRead = 1
       WHERE NotificationID = :id AND UserID = :userId`,
      { id: parseInt(req.params.id), userId: req.session.user.id }
    );
    res.json({ message: 'Notification marked as read' });
  } catch (err) {
    console.error('Mark read error:', err);
    res.status(500).json({ error: 'Failed to mark notification' });
  } finally {
    if (connection) await connection.close();
  }
});

// PUT /api/notifications/read-all - Mark all as read
router.put('/read-all', isAuthenticated, async (req, res) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.execute(
      `UPDATE Notifications SET IsRead = 1 WHERE UserID = :userId AND IsRead = 0`,
      { userId: req.session.user.id }
    );
    res.json({ message: 'All notifications marked as read' });
  } catch (err) {
    console.error('Mark all read error:', err);
    res.status(500).json({ error: 'Failed to mark notifications' });
  } finally {
    if (connection) await connection.close();
  }
});

module.exports = router;
