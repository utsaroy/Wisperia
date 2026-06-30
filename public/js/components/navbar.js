// ============================================================
// Whisperia: Navbar Component
// ============================================================
async function renderNavbar() {
  const user = await getCurrentUser();
  const nav = document.getElementById('navbar');
  if (!nav) return;

  const isAdmin = user && user.role === 'admin';

  nav.innerHTML = `
  <nav class="glass-card-static" style="position:sticky;top:0;z-index:50;border-radius:0;border-left:0;border-right:0;border-top:0">
    <div style="max-width:1200px;margin:0 auto;padding:14px 24px;display:flex;align-items:center;justify-content:space-between">
      <a href="/" style="text-decoration:none;display:flex;align-items:center;gap:10px">
        <span style="font-size:1.5rem">✦</span>
        <span class="gradient-text" style="font-size:1.3rem;font-weight:800;letter-spacing:-0.5px">Whisperia</span>
      </a>
      <div style="display:flex;align-items:center;gap:6px" id="nav-links">
        <a href="/questions.html" class="btn-ghost">Questions</a>
        ${user ? `
          <a href="/ask.html" class="btn-ghost" style="color:#8b5cf6">✦ Ask</a>
          <a href="/bookmarks.html" class="btn-ghost">Bookmarks</a>
          <a href="/notifications.html" class="btn-ghost" style="position:relative">
            Notifications<span id="notif-badge" style="display:none" class="badge badge-danger" style="position:absolute;top:2px;right:2px"></span>
          </a>
          ${isAdmin ? '<a href="/admin/dashboard.html" class="btn-ghost" style="color:#f59e0b">⚡ Admin</a>' : ''}
          <a href="/profile.html?id=${user.id}" class="btn-ghost">${createAvatar(user.username, 28)}</a>
          <button onclick="handleLogout()" class="btn-ghost" style="color:#ef4444">Logout</button>
        ` : `
          <a href="/login.html" class="btn-secondary" style="padding:8px 20px">Login</a>
          <a href="/register.html" class="btn-primary" style="padding:8px 20px;text-decoration:none">Sign Up</a>
        `}
      </div>
    </div>
  </nav>`;

  // Load unread notification count
  if (user) {
    try {
      const data = await api('/notifications');
      if (data.unreadCount > 0) {
        const badge = document.getElementById('notif-badge');
        if (badge) { badge.textContent = data.unreadCount; badge.style.display = 'inline-flex'; }
      }
    } catch {}
  }
}

async function handleLogout() {
  try {
    await api('/auth/logout', { method: 'POST' });
    showToast('Logged out successfully', 'success');
    setTimeout(() => navigate('/'), 500);
  } catch (err) {
    showToast(err.message, 'error');
  }
}
