// ─── CONFIGURAÇÃO DE AMBIENTE ──────────────────────────────────────────────
let BASE = '';
let ngosCache = [];

// ─── HEALTH CHECK ──────────────────────────────────────────────────────────
async function checkHealth() {
  if (!BASE) return;
  const checks = [
    { path: '/ngos/health',       dot: 'dot-ngo' },
    { path: '/donations/health',  dot: 'dot-don' },
    { path: '/volunteers/health', dot: 'dot-vol' },
  ];
  let allOk = true;
  
  for (const c of checks) {
    try {
      const r = await fetch(BASE + c.path, { signal: AbortSignal.timeout(4000) });
      const el = document.getElementById(c.dot);
      if (r.ok) { 
        el.classList.remove('offline'); 
      } else { 
        el.classList.add('offline'); 
        allOk = false; 
      }
    } catch {
      document.getElementById(c.dot).classList.add('offline');
      allOk = false;
    }
  }
  
  const dot   = document.getElementById('status-dot');
  const label = document.getElementById('status-label');
  
  if (allOk) {
    dot.classList.remove('offline');
    label.textContent = 'Online';
  } else {
    dot.classList.add('offline');
    label.textContent = 'Parcial';
  }
}

// ─── SISTEMA DE TOAST (NOTIFICAÇÕES) ───────────────────────────────────────
let toastTimer;
function toast(msg, isError = false) {
  const el = document.getElementById('toast');
  el.textContent = (isError ? '⚠ ' : '✓ ') + msg;
  el.className   = 'show' + (isError ? ' error' : '');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = ''; }, 3500);
}

// ─── NAVEGAÇÃO DE TABS ─────────────────────────────────────────────────────
window.switchTab = function(name, btn) {
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
  document.getElementById('panel-' + name).classList.add('active');
  btn.classList.add('active');
};

// ─── ONGs ──────────────────────────────────────────────────────────────────
window.loadNgos = async function() {
  const el = document.getElementById('ngo-list');
  el.innerHTML = '<div class="loading"><div class="spinner"></div><span>Buscando organizações...</span></div>';
  try {
    const r = await fetch(BASE + '/ngos');
    if (!r.ok) throw new Error(r.status);
    ngosCache = await r.json();
    renderNgos(ngosCache);
    populateNgoSelects(ngosCache);
  } catch(e) {
    el.innerHTML = '<div class="empty"><div class="empty-icon">⚠</div><p>Não foi possível conectar à API.</p></div>';
  }
};

function renderNgos(list) {
  const el = document.getElementById('ngo-list');
  document.getElementById('ngo-count').textContent = list.length;
  if (!list.length) {
    el.innerHTML = '<div class="empty"><div class="empty-icon">🏢</div><p>Nenhuma ONG cadastrada ainda.</p></div>';
    return;
  }
  el.innerHTML = '<div class="list">' + list.map((n, i) => `
    <div class="list-item fade-in" style="animation-delay: ${i * 0.05}s">
      <div class="item-row">
        <div>
          <div class="item-name">${esc(n.name)}</div>
          <div class="item-meta">
            <span>📧 ${esc(n.email)}</span>
            <span>📍 ${esc(n.city)}</span>
          </div>
        </div>
        <div style="text-align:right">
          <span class="badge green">${esc(n.cause)}</span>
          <div style="margin-top:6px;font-size:11px;color:var(--text-muted);font-weight:500;">ID ${n.id}</div>
        </div>
      </div>
    </div>`).join('') + '</div>';
}

function populateNgoSelects(list) {
  const opts = '<option value="">Selecione uma ONG…</option>' +
    list.map(n => `<option value="${n.id}">#${n.id} — ${esc(n.name)}</option>`).join('');
  ['don-ngo','vol-ngo','vol-filter-ngo'].forEach(id => {
    document.getElementById(id).innerHTML = opts;
  });
}

window.createNgo = async function() {
  const name  = document.getElementById('ngo-name').value.trim();
  const email = document.getElementById('ngo-email').value.trim();
  const cause = document.getElementById('ngo-cause').value.trim();
  const city  = document.getElementById('ngo-city').value.trim();
  if (!name || !email || !cause || !city) { toast('Preencha todos os campos.', true); return; }
  const btn = document.getElementById('btn-ngo');
  btn.disabled = true; btn.innerHTML = '<div class="spinner" style="border-color: rgba(255,255,255,0.3); border-top-color: #fff;"></div>';
  try {
    const r = await fetch(BASE + '/ngos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, cause, city })
    });
    if (r.status === 409) { toast('E-mail já cadastrado.', true); return; }
    if (!r.ok) throw new Error();
    toast('ONG cadastrada com sucesso!');
    ['ngo-name','ngo-email','ngo-cause','ngo-city'].forEach(id => document.getElementById(id).value = '');
    loadNgos();
  } catch { toast('Erro ao cadastrar ONG.', true); }
  finally { btn.disabled = false; btn.innerHTML = '<span>Cadastrar ONG</span>'; }
};

// ─── DOAÇÕES ───────────────────────────────────────────────────────────────
window.loadDonations = async function() {
  const el = document.getElementById('don-list');
  el.innerHTML = '<div class="loading"><div class="spinner"></div><span>Verificando histórico...</span></div>';
  try {
    const r = await fetch(BASE + '/donations');
    if (!r.ok) throw new Error();
    const list = await r.json();
    renderDonations(list);
    document.getElementById('impact-counter').textContent = list.length;
  } catch {
    el.innerHTML = '<div class="empty"><div class="empty-icon">⚠</div><p>Não foi possível conectar.</p></div>';
  }
};

function renderDonations(list) {
  const el = document.getElementById('don-list');
  document.getElementById('don-count').textContent = list.length;
  if (!list.length) {
    el.innerHTML = '<div class="empty"><div class="empty-icon">💚</div><p>Nenhuma doação registrada ainda.</p></div>';
    return;
  }
  el.innerHTML = '<div class="list">' + list.map((d, i) => `
    <div class="list-item fade-in" style="animation-delay: ${i * 0.05}s">
      <div class="item-row">
        <div>
          <div class="item-name">${esc(d.donor_name)}</div>
          <div class="item-meta">
            <span>🏢 ONG #${d.ngo_id}</span>
            <span>🕒 ${fmtDate(d.created_at)}</span>
          </div>
        </div>
        <div style="text-align:right">
          <div class="amount"><small>R$</small> ${fmtMoney(d.amount)}</div>
          <span class="badge ${d.status==='APPROVED'?'green':'gold'}">${esc(d.status)}</span>
        </div>
      </div>
    </div>`).join('') + '</div>';
}

window.createDonation = async function() {
  const donor_name = document.getElementById('don-name').value.trim();
  const ngo_id     = parseInt(document.getElementById('don-ngo').value);
  const amount     = parseFloat(document.getElementById('don-amount').value);
  if (!donor_name || !ngo_id || !amount || amount <= 0) { toast('Preencha todos os campos.', true); return; }
  const btn = document.getElementById('btn-don');
  btn.disabled = true; btn.innerHTML = '<div class="spinner" style="border-color: rgba(255,255,255,0.3); border-top-color: #fff;"></div>';
  try {
    const r = await fetch(BASE + '/donations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ donor_name, ngo_id, amount })
    });
    if (!r.ok) throw new Error();
    toast('Doação registrada! Obrigado 💚');
    ['don-name','don-amount'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('don-ngo').value = '';
    loadDonations();
  } catch { toast('Erro ao registrar doação.', true); }
  finally { btn.disabled = false; btn.innerHTML = '<span>Confirmar doação</span>'; }
};

// ─── VOLUNTÁRIOS ───────────────────────────────────────────────────────────
window.loadVolunteers = async function() {
  const ngo_id = document.getElementById('vol-filter-ngo').value;
  if (!ngo_id) { toast('Selecione uma ONG para buscar.', true); return; }
  const el = document.getElementById('vol-list');
  el.innerHTML = '<div class="loading"><div class="spinner"></div><span>Localizando voluntários...</span></div>';
  try {
    const r = await fetch(BASE + '/volunteers/' + ngo_id);
    if (!r.ok) throw new Error();
    const list = await r.json();
    renderVolunteers(list);
  } catch {
    el.innerHTML = '<div class="empty"><div class="empty-icon">⚠</div><p>Não foi possível conectar.</p></div>';
  }
};

function renderVolunteers(list) {
  const el = document.getElementById('vol-list');
  if (!list.length) {
    el.innerHTML = '<div class="empty"><div class="empty-icon">🙋</div><p>Nenhum voluntário cadastrado para esta ONG.</p></div>';
    return;
  }
  el.innerHTML = '<div class="list">' + list.map((v, i) => `
    <div class="list-item fade-in" style="animation-delay: ${i * 0.05}s">
      <div class="item-row">
        <div>
          <div class="item-name">${esc(v.name)}</div>
          <div class="item-meta">
            <span>📧 ${esc(v.email)}</span>
          </div>
        </div>
        <div style="text-align:right">
          <span class="badge blue">Voluntário</span>
          <div style="margin-top:6px;font-size:11px;color:var(--text-muted);font-weight:500;">Desde ${fmtTs(v.registered_at)}</div>
        </div>
      </div>
    </div>`).join('') + '</div>';
}

window.createVolunteer = async function() {
  const name   = document.getElementById('vol-name').value.trim();
  const email  = document.getElementById('vol-email').value.trim();
  const ngo_id = parseInt(document.getElementById('vol-ngo').value);
  if (!name || !email || !ngo_id) { toast('Preencha todos os campos.', true); return; }
  const btn = document.getElementById('btn-vol');
  btn.disabled = true; btn.innerHTML = '<div class="spinner" style="border-color: rgba(255,255,255,0.3); border-top-color: #fff;"></div>';
  try {
    const r = await fetch(BASE + '/volunteers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, ngo_id })
    });
    if (!r.ok) throw new Error();
    toast('Voluntário registrado com sucesso!');
    ['vol-name','vol-email'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('vol-ngo').value = '';
  } catch { toast('Erro ao registrar voluntário.', true); }
  finally { btn.disabled = false; btn.innerHTML = '<span>Registrar voluntário</span>'; }
};

// ─── UTILS ─────────────────────────────────────────────────────────────────
function esc(s) {
  return String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function fmtMoney(v) {
  return Number(v).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
function fmtDate(s) {
  if (!s) return '—';
  try { return new Date(s).toLocaleDateString('pt-BR', { day:'2-digit', month:'short', year:'numeric' }); }
  catch { return s; }
}
function fmtTs(ts) {
  if (!ts) return '—';
  try { return new Date(parseInt(ts) * 1000).toLocaleDateString('pt-BR'); }
  catch { return ts; }
}

function loadAll() {
  loadNgos();
  loadDonations();
}

window.addEventListener('DOMContentLoaded', () => {
  if (typeof window.APP_CONFIG !== 'undefined' && window.APP_CONFIG.API_URL) {
    let url = window.APP_CONFIG.API_URL.replace(/\/$/, '');
    if (!url.startsWith('http')) {
      url = 'http://' + url;
    }
    BASE = url;
  } else {
    BASE = 'http://localhost';
  }

  checkHealth();
  loadAll();
  
  setInterval(checkHealth, 30000);
});
