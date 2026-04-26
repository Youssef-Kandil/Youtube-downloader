const $ = (sel) => document.querySelector(sel);

const urlsEl    = $('#urls');
const qualityEl = $('#quality');
const folderEl  = $('#folder');
const browseBtn = $('#browseBtn');
const startBtn  = $('#startBtn');
const statusEl  = $('#globalStatus');
const resultsEl = $('#results');
const listEl    = $('#resultsList');

let pollTimer = null;

browseBtn.addEventListener('click', async () => {
  browseBtn.disabled = true;
  try {
    const r = await fetch('/pick-folder', { method: 'POST' });
    const data = await r.json();
    if (data.folder) folderEl.value = data.folder;
  } catch (e) {
    flash('تعذر فتح متصفح الفولدرات', 'err');
  } finally {
    browseBtn.disabled = false;
  }
});

startBtn.addEventListener('click', startDownload);

async function startDownload() {
  const urls = urlsEl.value.trim();
  const folder = folderEl.value.trim();
  const quality = qualityEl.value;

  if (!urls) return flash('أدخل رابطًا واحدًا على الأقل', 'err');
  if (!folder) return flash('اختر فولدر التحميل', 'err');

  setBusy(true);
  flash('جارٍ بدء التحميل...', '');

  try {
    const r = await fetch('/download', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ urls, quality, folder }),
    });
    const data = await r.json();
    if (!r.ok) {
      setBusy(false);
      return flash(data.error || 'حدث خطأ', 'err');
    }
    flash('التحميل قيد التنفيذ', '');
    resultsEl.hidden = false;
    pollStatus(data.job_id);
  } catch (e) {
    setBusy(false);
    flash('فشل الاتصال بالخادم', 'err');
  }
}

function pollStatus(jobId) {
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(async () => {
    try {
      const r = await fetch(`/status/${jobId}`);
      const job = await r.json();
      render(job);
      if (job.status === 'completed') {
        clearInterval(pollTimer);
        setBusy(false);
        const errs = job.items.filter(i => i.status === 'error').length;
        if (errs === 0) flash(`اكتمل التحميل (${job.total} فيديو)`, 'ok');
        else flash(`اكتمل مع ${errs} خطأ من ${job.total}`, 'err');
      }
    } catch (_) { /* keep trying */ }
  }, 700);
}

function render(job) {
  listEl.innerHTML = '';
  job.items.forEach((item, i) => {
    const div = document.createElement('div');
    div.className = `item ${item.status}`;

    const title = item.title || `فيديو ${i + 1}`;
    const meta = [];
    if (item.size && item.status === 'downloading') meta.push(item.size);
    if (item.speed && item.status === 'downloading') meta.push(`⚡ ${item.speed}`);
    if (item.eta && item.status === 'downloading') meta.push(`⏱ ${item.eta}`);
    if (item.status === 'completed') meta.push('✓ تم الحفظ');

    div.innerHTML = `
      <div class="item-head">
        <div class="item-title">
          ${escapeHtml(title)}
          <span class="url">${escapeHtml(item.url)}</span>
        </div>
        <span class="badge ${item.status}">${badgeLabel(item.status)}</span>
      </div>
      <div class="bar"><div class="bar-fill" style="width: ${item.progress || 0}%"></div></div>
      <div class="item-meta">
        ${meta.map(m => `<span>${escapeHtml(m)}</span>`).join('')}
        ${item.error ? `<span class="err-msg">${escapeHtml(item.error)}</span>` : ''}
      </div>
    `;
    listEl.appendChild(div);
  });
}

function badgeLabel(s) {
  return ({
    pending: 'في الانتظار',
    downloading: 'جارٍ التحميل',
    processing: 'معالجة',
    completed: 'مكتمل',
    error: 'خطأ',
  })[s] || s;
}

function setBusy(busy) {
  startBtn.disabled = busy;
  if (busy) {
    startBtn.innerHTML = `<span class="spinner"></span> جارٍ التحميل...`;
  } else {
    startBtn.innerHTML = `
      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12"/><path d="m6 9 6 6 6-6"/><path d="M5 21h14"/></svg>
      ابدأ التحميل`;
  }
}

function flash(msg, kind) {
  statusEl.className = 'status-pill show ' + (kind || '');
  statusEl.textContent = msg;
  if (!msg) statusEl.classList.remove('show');
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[c]));
}
