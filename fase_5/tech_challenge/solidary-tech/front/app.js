let ngosCache=[];
let toastTimer;

function getBase(){ return document.getElementById('api-url').value.replace(/\/$/,''); }

function applyConfig(){ checkHealth(); loadNgos(); loadDonations(); }

function resetLocal(){
  document.getElementById('api-url').value='http://localhost';
  applyConfig();
}

async function checkHealth(){
  const b=getBase();
  const map=[{path:'/ngos/health',dot:'dot-ngo'},{path:'/donations/health',dot:'dot-don'},{path:'/volunteers/health',dot:'dot-vol'}];
  for(const c of map){
    try{
      const r=await fetch(b+c.path,{signal:AbortSignal.timeout(4000)});
      const el=document.getElementById(c.dot);
      r.ok?el.classList.add('ok'):el.classList.remove('ok');
    }catch{ document.getElementById(c.dot).classList.remove('ok'); }
  }
}

let toastT;
function toast(msg,isErr=false){
  const el=document.getElementById('toast');
  el.textContent=(isErr?'⚠ ':'✓ ')+msg;
  el.className='show'+(isErr?' error':'');
  clearTimeout(toastT);
  toastT=setTimeout(()=>{el.className='';},3500);
}

function switchTab(name,btn){
  document.querySelectorAll('.panel').forEach(p=>p.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(b=>b.classList.remove('active'));
  document.getElementById('panel-'+name).classList.add('active');
  btn.classList.add('active');
  if(name==='donations') loadDonations();
}

function esc(s){ return String(s??'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function fmtMoney(v){ return Number(v).toLocaleString('pt-BR',{minimumFractionDigits:2,maximumFractionDigits:2}); }
function fmtDate(s){ try{ return new Date(s).toLocaleDateString('pt-BR',{day:'2-digit',month:'short',year:'numeric'}); }catch{return s||'—';} }
function fmtTs(ts){ try{ return new Date(parseInt(ts)*1000).toLocaleDateString('pt-BR'); }catch{return ts||'—';} }

function fillSelects(list){
  const opts='<option value="">Selecione uma ONG\u2026</option>'+list.map(n=>`<option value="${n.id}">#${n.id} \u2014 ${esc(n.name)}</option>`).join('');
  ['don-ngo','vol-ngo','vol-filter'].forEach(id=>{document.getElementById(id).innerHTML=opts;});
}

async function loadNgos(){
  const el=document.getElementById('ngo-list');
  el.innerHTML='<div class="loading"><div class="spinner"></div>Carregando…</div>';
  try{
    const r=await fetch(getBase()+'/ngos');
    if(!r.ok) throw new Error();
    ngosCache=await r.json();
    renderNgos(ngosCache);
    fillSelects(ngosCache);
  }catch{
    el.innerHTML='<div class="empty"><div class="empty-icon">⚠</div><p>Não foi possível conectar. Verifique a URL e tente novamente.</p></div>';
  }
}

function renderNgos(list){
  const el=document.getElementById('ngo-list');
  document.getElementById('ngo-count').textContent=list.length;
  if(!list.length){el.innerHTML='<div class="empty"><div class="empty-icon">🏢</div><p>Nenhuma ONG cadastrada.</p></div>';return;}
  el.innerHTML=list.map(n=>`
    <div class="list-item">
      <div class="item-row">
        <div>
          <div class="item-name">${esc(n.name)}</div>
          <div class="item-meta"><span>📧 ${esc(n.email)}</span><span>📍 ${esc(n.city)}</span></div>
        </div>
        <span class="badge blue">${esc(n.cause)}</span>
      </div>
      <div style="margin-top:3px;font-size:11px;color:var(--muted)">ID ${n.id}</div>
    </div>`).join('');
}

async function createNgo(){
  const name=document.getElementById('ngo-name').value.trim();
  const email=document.getElementById('ngo-email').value.trim();
  const cause=document.getElementById('ngo-cause').value.trim();
  const city=document.getElementById('ngo-city').value.trim();
  if(!name||!email||!cause||!city){toast('Preencha todos os campos.',true);return;}
  const btn=document.getElementById('btn-ngo');
  btn.disabled=true;btn.innerHTML='<div class="spinner" style="border-top-color:#fff"></div>';
  try{
    const r=await fetch(getBase()+'/ngos',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,email,cause,city})});
    if(r.status===409){toast('E-mail já cadastrado.',true);return;}
    if(!r.ok) throw new Error();
    toast('ONG cadastrada com sucesso!');
    ['ngo-name','ngo-email','ngo-cause','ngo-city'].forEach(id=>document.getElementById(id).value='');
    loadNgos();
  }catch{toast('Erro ao cadastrar ONG.',true);}
  finally{btn.disabled=false;btn.innerHTML='<span>Cadastrar ONG</span>';}
}

async function loadDonations(){
  const el=document.getElementById('don-list');
  el.innerHTML='<div class="loading"><div class="spinner"></div>Carregando…</div>';
  try{
    const r=await fetch(getBase()+'/donations');
    if(!r.ok) throw new Error();
    const list=await r.json();
    renderDonations(list);
    document.getElementById('impact-num').textContent=list.length;
  }catch{
    el.innerHTML='<div class="empty"><div class="empty-icon">⚠</div><p>Não foi possível conectar.</p></div>';
  }
}

function renderDonations(list){
  const el=document.getElementById('don-list');
  document.getElementById('don-count').textContent=list.length;
  if(!list.length){el.innerHTML='<div class="empty"><div class="empty-icon">💚</div><p>Nenhuma doação registrada.</p></div>';return;}
  el.innerHTML=list.map(d=>`
    <div class="list-item">
      <div class="item-row">
        <div>
          <div class="item-name">${esc(d.donor_name)}</div>
          <div class="item-meta"><span>🏢 ONG #${d.ngo_id}</span><span>🕒 ${fmtDate(d.created_at)}</span></div>
        </div>
        <div style="text-align:right">
          <div class="amount"><small>R$</small> ${fmtMoney(d.amount)}</div>
          <span class="badge ${d.status==='APPROVED'?'green':'gold'}">${esc(d.status)}</span>
        </div>
      </div>
    </div>`).join('');
}

async function createDonation(){
  const donor_name=document.getElementById('don-name').value.trim();
  const ngo_id=parseInt(document.getElementById('don-ngo').value);
  const amount=parseFloat(document.getElementById('don-amount').value);
  if(!donor_name||!ngo_id||!amount||amount<=0){toast('Preencha todos os campos.',true);return;}
  const btn=document.getElementById('btn-don');
  btn.disabled=true;btn.innerHTML='<div class="spinner" style="border-top-color:#fff"></div>';
  try{
    const r=await fetch(getBase()+'/donations',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({donor_name,ngo_id,amount})});
    if(!r.ok) throw new Error();
    toast('Doação registrada! Obrigado 💚');
    ['don-name','don-amount'].forEach(id=>document.getElementById(id).value='');
    document.getElementById('don-ngo').value='';
    loadDonations();
  }catch{toast('Erro ao registrar doação.',true);}
  finally{btn.disabled=false;btn.innerHTML='<span>Confirmar doação</span>';}
}

async function loadVolunteers(){
  const ngo_id=document.getElementById('vol-filter').value;
  if(!ngo_id){toast('Selecione uma ONG.',true);return;}
  const el=document.getElementById('vol-list');
  el.innerHTML='<div class="loading"><div class="spinner"></div>Carregando…</div>';
  try{
    const r=await fetch(getBase()+'/volunteers/'+ngo_id);
    if(!r.ok) throw new Error();
    const list=await r.json();
    document.getElementById('vol-count').textContent=list.length;
    if(!list.length){el.innerHTML='<div class="empty"><div class="empty-icon">🙋</div><p>Nenhum voluntário para esta ONG.</p></div>';return;}
    el.innerHTML=list.map(v=>`
      <div class="list-item">
        <div class="item-row">
          <div>
            <div class="item-name">${esc(v.name)}</div>
            <div class="item-meta"><span>📧 ${esc(v.email)}</span></div>
          </div>
          <span class="badge sky">Voluntário</span>
        </div>
        <div style="margin-top:3px;font-size:11px;color:var(--muted)">Desde ${fmtTs(v.registered_at)}</div>
      </div>`).join('');
  }catch{el.innerHTML='<div class="empty"><div class="empty-icon">⚠</div><p>Erro ao buscar voluntários.</p></div>';}
}

async function createVolunteer(){
  const name=document.getElementById('vol-name').value.trim();
  const email=document.getElementById('vol-email').value.trim();
  const ngo_id=parseInt(document.getElementById('vol-ngo').value);
  if(!name||!email||!ngo_id){toast('Preencha todos os campos.',true);return;}
  const btn=document.getElementById('btn-vol');
  btn.disabled=true;btn.innerHTML='<div class="spinner" style="border-top-color:#fff"></div>';
  try{
    const r=await fetch(getBase()+'/volunteers',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,email,ngo_id})});
    if(!r.ok) throw new Error();
    toast('Voluntário registrado com sucesso!');
    ['vol-name','vol-email'].forEach(id=>document.getElementById(id).value='');
    document.getElementById('vol-ngo').value='';
  }catch{toast('Erro ao registrar voluntário.',true);}
  finally{btn.disabled=false;btn.innerHTML='<span>Registrar voluntário</span>';}
}

window.addEventListener('DOMContentLoaded',()=>{
  checkHealth();
  loadNgos();
  loadDonations();
  setInterval(checkHealth,30000);
});

