/* Cutuca o banco do clube para ele não hibernar.
   Roda uma vez por dia pelo .github/workflows/manter-acordado.yml.
   Não usa senha: lê a URL e a chave publicável do próprio config.js. */
import fs from 'node:fs';
import vm from 'node:vm';

function falhar(msg){
  console.log('::error::'+msg);
  console.log('::error::Se o projeto estiver em pausa, retome em https://supabase.com/dashboard (botao "Resume project").');
  console.log('::error::Se faltar a tabela "pulso", rode de novo o supabase/schema.sql no SQL Editor.');
  process.exit(1);
}

const ctx = { window:{} };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync('config.js','utf8'), ctx);
const cfg = ctx.window.APP_CONFIG || ctx.window.TCC_CONFIG || {};

const url = String(cfg.SUPABASE_URL||'').trim()
  .replace(/\/+$/,'')
  .replace(/\/(rest|auth|storage|realtime)\/v1$/,'');
const key = String(cfg.SUPABASE_ANON_KEY||'').trim();

if(!url || key.length < 30){
  console.log('config.js sem URL ou chave: o app esta em modo local de teste, nao ha banco para manter acordado.');
  process.exit(0);
}

console.log('Consultando '+url+' ...');
let resp, corpo='';
try{
  resp = await fetch(url+'/rest/v1/pulso?select=visto_em&limit=1', {
    headers:{ apikey:key, Authorization:'Bearer '+key },
    signal: AbortSignal.timeout(30000),
  });
  corpo = (await resp.text()).slice(0,300);
}catch(e){
  falhar('nao consegui falar com o banco: '+(e && e.message ? e.message : e));
}

console.log('HTTP '+resp.status+' - '+corpo);
if(resp.status === 200){
  console.log('Banco acordado e respondendo.');
  process.exit(0);
}
falhar('o banco nao respondeu como esperado (HTTP '+resp.status+').');
