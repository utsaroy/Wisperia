// ============================================================
// Whisperia: Footer Component
// ============================================================
function renderFooter() {
  const footer = document.getElementById('footer');
  if (!footer) return;

  footer.innerHTML = `
  <footer style="border-top:1px solid var(--color-border);margin-top:80px;padding:40px 24px">
    <div style="max-width:1200px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:16px">
      <div style="display:flex;align-items:center;gap:8px">
        <span style="font-size:1.2rem">✦</span>
        <span class="gradient-text" style="font-weight:700">Whisperia</span>
        <span style="color:var(--color-muted);font-size:0.85rem">— Question & Answer Platform</span>
      </div>
      <div style="color:var(--color-muted);font-size:0.8rem">
        University DBMS Project • Built with Node.js, Oracle &amp; Tailwind CSS
      </div>
    </div>
  </footer>`;
}
