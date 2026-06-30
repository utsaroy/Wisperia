// ============================================================
// Whisperia: public/js/app.js - Shared utilities
// ============================================================
const API_BASE = '/api';

async function api(url, options = {}) {
  const config = {
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    ...options
  };
  if (config.body && typeof config.body === 'object') {
    config.body = JSON.stringify(config.body);
  }
  const response = await fetch(`${API_BASE}${url}`, config);
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || data.errors?.[0]?.msg || 'Something went wrong');
  }
  return data;
}

async function getCurrentUser() {
  try { const d = await api('/auth/me'); return d.user; } catch { return null; }
}

function showToast(message, type = 'info') {
  let c = document.querySelector('.toast-container');
  if (!c) { c = document.createElement('div'); c.className = 'toast-container'; document.body.appendChild(c); }
  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.textContent = message;
  c.appendChild(t);
  setTimeout(() => t.remove(), 3000);
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const diffMs = Date.now() - date;
  const mins = Math.floor(diffMs / 60000);
  const hrs = Math.floor(diffMs / 3600000);
  const days = Math.floor(diffMs / 86400000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  if (hrs < 24) return `${hrs}h ago`;
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function getAvatarColor(name) {
  const colors = ['#8b5cf6','#06b6d4','#ec4899','#f59e0b','#10b981','#6366f1','#ef4444','#14b8a6'];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return colors[Math.abs(hash) % colors.length];
}

function createAvatar(username, size = 40) {
  const color = getAvatarColor(username);
  return `<div class="avatar" style="width:${size}px;height:${size}px;background:${color};font-size:${size*0.4}px">${username.charAt(0).toUpperCase()}</div>`;
}

function truncate(text, max = 150) {
  if (!text || typeof text === 'object') return '';
  return text.length <= max ? text : text.substring(0, max) + '...';
}

function navigate(path) { window.location.href = path; }

function getParam(name) { return new URLSearchParams(window.location.search).get(name); }

function escapeHtml(text) {
  if (!text || typeof text === 'object') return '';
  const d = document.createElement('div'); d.textContent = text; return d.innerHTML;
}
